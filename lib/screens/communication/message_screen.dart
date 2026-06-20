import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';
import 'package:bondnex/services/database/firestore_service.dart';
import 'package:bondnex/services/database/database_helper.dart';
import 'package:bondnex/services/core/shared_prefs_service.dart';
import 'package:bondnex/services/encryption/aes_encryption_service.dart';
import '../profile/public_profile_screen.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isSearching = false;

  // State for search history
  List<Map<String, dynamic>> _recentSearches = [];
  bool _showSearchResults = false;
  Map<String, dynamic>? _searchedUser;

  // Local caching state
  StreamSubscription<QuerySnapshot>? _messageSubscription;
  StreamSubscription<DocumentSnapshot>? _typingSubscription;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoadingMessages = true;
  String? _currentPartnerId;
  bool _partnerIsTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _loadLocalSearchHistory();
    _messageFocusNode.addListener(_onFocusChange);
    _messageController.addListener(_onTypingChanged);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _messageFocusNode.removeListener(_onFocusChange);
    _messageFocusNode.dispose();
    _searchController.dispose();
    _messageController.removeListener(_onTypingChanged);
    _messageController.dispose();
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingTimer?.cancel();
    // Clear typing status on leaving the screen
    _setTypingStatus(false);
    super.dispose();
  }

  /// Debounced typing indicator
  void _onTypingChanged() {
    final text = _messageController.text;
    if (text.isNotEmpty) {
      _setTypingStatus(true);
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _setTypingStatus(false);
      });
    } else {
      _typingTimer?.cancel();
      _setTypingStatus(false);
    }
  }

  void _setTypingStatus(bool isTyping) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isPartnerConnected || userProvider.partnerId == null) {
      return;
    }
    _firestoreService.setTypingStatus(
      userProvider.firebaseUid,
      userProvider.partnerId!,
      isTyping,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = Provider.of<UserProvider>(context);
    if (userProvider.isPartnerConnected && userProvider.partnerId != null) {
      if (_currentPartnerId != userProvider.partnerId) {
        _currentPartnerId = userProvider.partnerId;
        _initMessages(userProvider.firebaseUid, userProvider.partnerId!);
        _initTypingListener(userProvider.firebaseUid, userProvider.partnerId!);
      }
    } else {
      if (_messageSubscription != null) {
        _messageSubscription?.cancel();
        _messageSubscription = null;
      }
      _typingSubscription?.cancel();
      _typingSubscription = null;
      _currentPartnerId = null;
      if (_messages.isNotEmpty) {
        setState(() {
          _messages.clear();
        });
      }
    }
  }

  void _initTypingListener(String currentUid, String partnerUid) {
    _typingSubscription?.cancel();
    _typingSubscription = _firestoreService
        .getChatMetaStream(currentUid, partnerUid)
        .listen((snapshot) {
          if (!mounted) return;
          final data = snapshot.data() as Map<String, dynamic>?;
          final isPartnerTyping = data?['typing_$partnerUid'] as bool? ?? false;
          if (_partnerIsTyping != isPartnerTyping) {
            setState(() {
              _partnerIsTyping = isPartnerTyping;
            });
          }
        });
  }

  void _initMessages(String currentUid, String partnerUid) async {
    setState(() => _isLoadingMessages = true);
    final chatId = await _firestoreService.getChatId(currentUid, partnerUid);

    // 1. Load from local DB
    final dbHelper = DatabaseHelper();
    final localMessages = await dbHelper.getMessagesForChat(chatId);

    if (mounted) {
      setState(() {
        _messages = localMessages.toList(); // Ordered by timestamp DESC
        _isLoadingMessages = false;
      });
    }

    // 2. Get last timestamp
    int lastTimestamp = await dbHelper.getLastMessageTimestamp(chatId);

    // 3. Start Firestore stream for new messages
    _messageSubscription?.cancel();
    _messageSubscription = _firestoreService
        .getMessagesStream(currentUid, partnerUid, lastTimestamp: lastTimestamp)
        .listen((snapshot) async {
          if (snapshot.docs.isNotEmpty) {
            final aesService = AesEncryptionService();
            List<Map<String, dynamic>> newMessages = [];
            
            for (var doc in snapshot.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final timestamp = data['timestamp'] as Timestamp?;
              
              String decryptedText = '[Decryption Error]';
              try {
                if (data.containsKey('encryptedPayload')) {
                   // If sender is us, we still decrypt using partnerUid because partnerUid is the other party
                   decryptedText = await aesService.decrypt(data['encryptedPayload'], partnerUid);
                } else if (data.containsKey('text')) {
                   // Fallback for unencrypted legacy messages
                   decryptedText = data['text'];
                }
              } catch (e) {
                debugPrint('Error decrypting message: $e');
              }

              final msgData = {
                'id': doc.id,
                'chatId': chatId,
                'senderId': data['senderId'],
                'receiverId': data['receiverId'],
                'text': decryptedText,
                'timestamp':
                    timestamp?.millisecondsSinceEpoch ??
                    DateTime.now().millisecondsSinceEpoch,
                'isRead': data['status'] == 'read' ? 1 : 0,
              };
              newMessages.add(msgData);
            }

            await dbHelper.insertMessages(newMessages);

            // Reload messages to get them in correct order
            final updatedMessages = await dbHelper.getMessagesForChat(chatId);
            if (mounted) {
              setState(() {
                _messages = updatedMessages.toList();
              });
            }
          }
        });
  }

  void _loadLocalSearchHistory() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final history = await SharedPrefsService.getLocalSearchHistory(
      userProvider.firebaseUid,
    );
    if (mounted) {
      setState(() {
        _recentSearches = history;
      });
    }
  }

  void _searchPartner() async {
    final query = _searchController.text.trim().toUpperCase();
    if (query.isEmpty) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (query == userProvider.myPermanentId.toUpperCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot search your own ID!')),
      );
      return;
    }

    setState(() => _isSearching = true);
    try {
      final profileData = await _firestoreService.getUserProfileByPremiumId(
        query,
      );
      if (profileData != null && mounted) {
        // Save to search history
        await SharedPrefsService.saveLocalSearch(
          userProvider.firebaseUid,
          profileData,
        );
        await _firestoreService.saveSearchHistory(
          userProvider.firebaseUid,
          profileData,
        );
        _loadLocalSearchHistory();

        setState(() {
          _searchedUser = profileData;
          _showSearchResults = true;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not found. Check the Premium ID.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _deleteSearchItem(String premiumId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await SharedPrefsService.deleteLocalSearch(
      userProvider.firebaseUid,
      premiumId,
    );
    await _firestoreService.deleteSearchHistoryItem(
      userProvider.firebaseUid,
      premiumId,
    );
    _loadLocalSearchHistory();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isPartnerConnected || userProvider.partnerId == null) {
      return;
    }

    _messageController.clear();
    // Stop typing indicator immediately on send
    _typingTimer?.cancel();
    _setTypingStatus(false);

    final chatId = await _firestoreService.getChatId(
      userProvider.firebaseUid,
      userProvider.partnerId!,
    );
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempId = 'temp_$timestamp';

    // Optimistic UI update
    final tempMsg = {
      'id': tempId,
      'chatId': chatId,
      'senderId': userProvider.firebaseUid,
      'receiverId': userProvider.partnerId!,
      'text': text,
      'timestamp': timestamp,
      'isRead': 0,
    };

    setState(() {
      _messages.insert(0, tempMsg);
    });

    try {
      await _firestoreService.sendMessage(
        userProvider.firebaseUid,
        userProvider.partnerId!,
        text,
        timestamp,
      );

      // We do not need to update SQLite manually because the Stream listener
      // will instantly receive the local write from Firestore and insert it.
      // But we should remove the temp message from the UI once the stream takes over.
      // Alternatively, just keeping it here doesn't hurt since the stream will add the real one
      // and we just remove the temp one.
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m['id'] == tempId);
        });
      }
    } catch (e) {
      // Revert temp msg
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m['id'] == tempId);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    // Check and mark messages as read if we are in the chat view
    if (userProvider.isPartnerConnected && userProvider.partnerId != null) {
      _firestoreService.markMessagesAsRead(
        userProvider.firebaseUid,
        userProvider.partnerId!,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: userProvider.isPartnerConnected && userProvider.partnerId != null
          ? _buildChatAppBar(userProvider)
          : _buildSearchAppBar(),
      body: _buildBodyContent(userProvider),
    );
  }

  PreferredSizeWidget _buildChatAppBar(UserProvider userProvider) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.black, // Seamless background
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[900],
            backgroundImage:
                userProvider.partnerProfileImageUrl != null &&
                    userProvider.partnerProfileImageUrl!.isNotEmpty
                ? NetworkImage(userProvider.partnerProfileImageUrl!)
                : null,
            child:
                userProvider.partnerProfileImageUrl == null ||
                    userProvider.partnerProfileImageUrl!.isEmpty
                ? const Icon(Icons.favorite, color: Colors.pinkAccent, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userProvider.partnerName ?? 'Partner',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.lock, color: Colors.greenAccent, size: 10),
                  const SizedBox(width: 4),
                  Text(
                    'End-to-End Encrypted',
                    style: GoogleFonts.poppins(
                      color: Colors.greenAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.phone, color: Colors.blueAccent),
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.pushNamed(context, '/partner_call_history');
          },
        ),
      ],
      bottom: _partnerIsTyping
          ? PreferredSize(
              preferredSize: const Size.fromHeight(20),
              child: Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Row(
                  children: [
                    Text(
                      'typing...',
                      style: GoogleFonts.poppins(
                        color: Colors.pinkAccent,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1E24), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      title: Text(
        'Messages',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              if (_showSearchResults) ...[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() {
                        _showSearchResults = false;
                        _searchController.clear();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search by Premium ID...',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey[500],
                        fontSize: 13,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.pinkAccent,
                        size: 20,
                      ),
                    ),
                    onSubmitted: (_) => _searchPartner(),
                  ),
                ),
              ),
              if (!_showSearchResults) ...[
                const SizedBox(width: 12),
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.pinkAccent, Colors.purpleAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.hardEdge,
                    child: InkWell(
                      onTap: _searchPartner,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.search,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyContent(UserProvider userProvider) {
    if (_showSearchResults && _searchedUser != null) {
      return _buildSearchResultView();
    }

    if (userProvider.isPartnerConnected) {
      return _buildChatInterface(userProvider);
    } else {
      return _buildNoPartnerView();
    }
  }

  Widget _buildSearchResultView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Search Result',
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.pinkAccent.withValues(alpha: 0.1),
                  Colors.purpleAccent.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.pinkAccent.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.pinkAccent.withValues(alpha: 0.05),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.hardEdge,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PublicProfileScreen(profileData: _searchedUser!),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.pinkAccent, Colors.purpleAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.grey[900],
                          backgroundImage:
                              _searchedUser!['profile_image_url'] != null &&
                                  _searchedUser!['profile_image_url'].isNotEmpty
                              ? NetworkImage(
                                  _searchedUser!['profile_image_url'],
                                )
                              : null,
                          child:
                              _searchedUser!['profile_image_url'] == null ||
                                  _searchedUser!['profile_image_url'].isEmpty
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 28,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _searchedUser!['name'] ?? 'Unknown',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _searchedUser!['premium_id'] ?? '',
                              style: GoogleFonts.poppins(
                                color: Colors.pinkAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white54,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPartnerView() {
    return Column(
      children: [
        if (_recentSearches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.history, color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Recent Searches',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _recentSearches.length,
              itemBuilder: (context, index) {
                final user = _recentSearches[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[800]!, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[900],
                        backgroundImage:
                            user['profile_image_url'] != null &&
                                user['profile_image_url'].isNotEmpty
                            ? NetworkImage(user['profile_image_url'])
                            : null,
                        child:
                            user['profile_image_url'] == null ||
                                user['profile_image_url'].isEmpty
                            ? const Icon(
                                Icons.person,
                                color: Colors.grey,
                                size: 20,
                              )
                            : null,
                      ),
                    ),
                    title: Text(
                      user['name'] ?? 'Unknown',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      user['premium_id'] ?? '',
                      style: GoogleFonts.poppins(
                        color: Colors.pinkAccent.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () =>
                          _deleteSearchItem(user['uid'] ?? user['premium_id']),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PublicProfileScreen(profileData: user),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ] else
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.pinkAccent.withValues(alpha: 0.05),
                        border: Border.all(
                          color: Colors.pinkAccent.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_search_rounded,
                        size: 64,
                        color: Colors.pinkAccent,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No partner connected',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Search for a partner using their Premium ID to connect and start chatting.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.grey[500],
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBigProfileHeader(UserProvider userProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.pinkAccent, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[900],
              backgroundImage:
                  userProvider.partnerProfileImageUrl != null &&
                      userProvider.partnerProfileImageUrl!.isNotEmpty
                  ? NetworkImage(userProvider.partnerProfileImageUrl!)
                  : null,
              child:
                  userProvider.partnerProfileImageUrl == null ||
                      userProvider.partnerProfileImageUrl!.isEmpty
                  ? const Icon(
                      Icons.favorite,
                      color: Colors.pinkAccent,
                      size: 50 * 0.95,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userProvider.partnerName ?? 'Partner',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.pinkAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.pinkAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              userProvider.partnerPremiumId ?? '',
              style: GoogleFonts.poppins(
                color: Colors.pinkAccent,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'BondNex',
            style: GoogleFonts.poppins(
              color: Colors.grey[500],
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInterface(UserProvider userProvider) {
    return Column(
      children: [
        // Messages List
        Expanded(
          child: _isLoadingMessages
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  reverse: true,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        top: 8,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final msg = _messages[index];
                          final isMe =
                              msg['senderId'] == userProvider.firebaseUid;
                          final timestamp = msg['timestamp'] as int;
                          final timeString = timestamp > 0
                              ? DateFormat('hh:mm a').format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                    timestamp,
                                  ),
                                )
                              : '';
                          final isRead = msg['isRead'] == 1;

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                gradient: isMe
                                    ? const LinearGradient(
                                        colors: [
                                          Colors.pinkAccent,
                                          Colors.purpleAccent,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: isMe ? null : const Color(0xFF2C2C2E),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 20),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg['text'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        timeString,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.6,
                                          ),
                                          fontSize: 10,
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          isRead ? Icons.done_all : Icons.check,
                                          size: 14,
                                          color: isRead
                                              ? Colors.blue[300]
                                              : Colors.white.withValues(
                                                  alpha: 0.6,
                                                ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }, childCount: _messages.length),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Container(
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.only(top: 16, bottom: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildBigProfileHeader(userProvider),
                            if (_messages.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 24.0),
                                child: Text(
                                  'Say hi to your partner! 👋',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),

        // Message Input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E24),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      focusNode: _messageFocusNode,
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.pinkAccent, Colors.purpleAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.hardEdge,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      padding: const EdgeInsets.all(12),
                      onPressed: _sendMessage,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
