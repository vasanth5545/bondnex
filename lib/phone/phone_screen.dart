// File: lib/phone/phone_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/contacts_provider.dart';
import '../providers/call_log_provider.dart';
import 'outgoing_call_screen.dart';
import 'incoming_call_screen.dart';
import 'save_contact_screen.dart';
import 'phone_settings_screen.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'message_screen.dart';
import 'widgets/call_log_tile.dart';
import 'widgets/swipeable_contact_tile.dart';
import 'call_log_model.dart';


class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.message, color: Colors.transparent,),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MessageScreen()),
            );
          },
        ),
        title: _buildTabSwitcher(),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(MdiIcons.cogOutline, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PhoneSettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPageIndex = index;
            });
          },
          children: const [
            RecentCallsScreen(),
            ContactsPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
      ),
      child: FittedBox(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTab('Phone', 0),
            _buildTab('Contacts', 1),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _currentPageIndex == index;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[800] : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class RecentCallsScreen extends StatefulWidget {
  const RecentCallsScreen({super.key});

  @override
  State<RecentCallsScreen> createState() => _RecentCallsScreenState();
}

class _RecentCallsScreenState extends State<RecentCallsScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CallLogProvider>(context, listen: false).initializeCallLogs();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      Provider.of<CallLogProvider>(context, listen: false).syncDeviceLogsToDb();
    }
  }

  List<CallLogEntry> _getUniqueRecentCalls(List<CallLogEntry> allLogs) {
    final Map<String, CallLogEntry> uniqueLogs = {};
    for (final log in allLogs) {
      final number = log.contact.phones.isNotEmpty
          ? log.contact.phones.first.number.replaceAll(RegExp(r'[^0-9]'), '')
          : log.contact.displayName;
      if (number.isNotEmpty && !uniqueLogs.containsKey(number)) {
        uniqueLogs[number] = log;
      }
    }
    return uniqueLogs.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final callLogProvider = Provider.of<CallLogProvider>(context);
    final uniqueLogs = _getUniqueRecentCalls(callLogProvider.callLogs);

    void _showDialpad() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const DialpadSheet(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showDialpad,
        heroTag: 'phoneFAB',
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(MdiIcons.dialpad),
      ),
      body: SafeArea(
        child: callLogProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => Provider.of<CallLogProvider>(context, listen: false).syncDeviceLogsToDb(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        _buildSearchBar(context),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const IncomingCallScreen(
                                  callerName: 'Olivia Bennett',
                                  callerNumber: '+1 (555) 987-6543',
                                ),
                              ),
                            );
                          },
                          child: const Text('Simulate Incoming Call'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.green,
                              foregroundColor:
                                  Colors.white,
                            ),
                        ),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Recent', context),
                        if (uniqueLogs.isEmpty)
                          const Center(child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text("No recent calls", style: TextStyle(color: Colors.white70)),
                          ))
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: uniqueLogs.length,
                            itemBuilder: (context, index) {
                              final log = uniqueLogs[index];
                              return CallLogTile(log: log);
                            },
                          )
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search contacts',
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(MdiIcons.magnify, color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ContactsProvider>(context, listen: false).fetchContacts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Provider.of<ContactsProvider>(context, listen: false).fetchContacts();
    }
  }

  List<dynamic> _buildDisplayList(List<fc.Contact> allContacts) {
    final filteredContacts = allContacts.where((contact) {
      final nameMatches = contact.displayName.toLowerCase().contains(_searchQuery.toLowerCase());
      final numberMatches = contact.phones.any((p) => p.number.contains(_searchQuery));
      return nameMatches || numberMatches;
    }).toList();

    List<dynamic> tempList = [];
    String? currentLetter;

    for (var contact in filteredContacts) {
      if (contact.displayName.isEmpty) continue;
      String firstLetter = contact.displayName[0].toUpperCase();
      if (firstLetter != currentLetter) {
        currentLetter = firstLetter;
        tempList.add(currentLetter);
      }
      tempList.add(contact);
    }
    return tempList;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContactsProvider>(
      builder: (context, contactsProvider, child) {
        if (contactsProvider.permissionDenied) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.contact_page_outlined, size: 80, color: Colors.white38),
                  const SizedBox(height: 16),
                  const Text(
                    'Permission Denied',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'To see your contacts, please grant contacts permission in your device settings.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    onPressed: () => contactsProvider.fetchContacts(),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.settings, color: Colors.white70),
                    label: const Text('Open Settings', style: TextStyle(color: Colors.white70)),
                    onPressed: () => openAppSettings(),
                  ),
                ],
              ),
            ),
          );
        }

        if (contactsProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final displayList = _buildDisplayList(contactsProvider.contacts);

        return Scaffold(
          backgroundColor: Colors.black,
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (context) => const SaveContactScreen()),
              );
              if (result == true && context.mounted) {
                ScaffoldMessenger.of(context)
                  ..removeCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('Contact saved successfully!')),
                  );
              }
            },
            heroTag: 'contactsFAB',
            child: const Icon(Icons.add),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search contacts',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: displayList.length,
                    itemBuilder: (context, index) {
                      final item = displayList[index];
                      if (item is String) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Text(
                            item,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      } else if (item is fc.Contact) {
                        return SwipeableContactTile(contact: item);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DialpadSheet extends StatefulWidget {
  const DialpadSheet({super.key});

  @override
  _DialpadSheetState createState() => _DialpadSheetState();
}

class _DialpadSheetState extends State<DialpadSheet> {
  final TextEditingController _controller = TextEditingController();

  void _onButtonPressed(String value) {
    setState(() {
      _controller.text += value;
    });
  }

  void _onBackspacePressed() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _controller.text = _controller.text.substring(0, _controller.text.length - 1);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasText = _controller.text.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor.withOpacity(0.98),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: Colors.white.withOpacity(0.1))),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: hasText ? 70 : 0,
                    child: hasText
                        ? Row(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  reverse: true,
                                  child: Text(
                                    _controller.text,
                                    style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.w400),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.backspace_outlined, color: Colors.grey[400]),
                                onPressed: _onBackspacePressed,
                                onLongPress: () {
                                  setState(() {
                                    _controller.clear();
                                  });
                                },
                              ),
                            ],
                          )
                        : null,
                  ),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 1.7,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      ..._getDialButtons(),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(child: _buildCallButton('sim', Colors.green, Icons.phone)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildCallButton('VOIP', Colors.purple, Icons.wifi_calling)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          icon: Icon(Icons.phone, color: Theme.of(context).colorScheme.primary),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(Icons.contacts, color: Colors.grey),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _getDialButtons() {
    const numbers = [
      {'number': '1', 'letters': 'QZ'},
      {'number': '2', 'letters': 'ABC'},
      {'number': '3', 'letters': 'DEF'},
      {'number': '4', 'letters': 'GHI'},
      {'number': '5', 'letters': 'JKL'},
      {'number': '6', 'letters': 'MNO'},
      {'number': '7', 'letters': 'PQRS'},
      {'number': '8', 'letters': 'TUV'},
      {'number': '9', 'letters': 'WXYZ'},
      {'number': '*', 'letters': ''},
      {'number': '0', 'letters': '+'},
      {'number': '#', 'letters': ''},
    ];
    return numbers.map((e) => _buildDialButton(e['number']!, e['letters']!)).toList();
  }

  Widget _buildDialButton(String mainText, String subText) {
    return InkWell(
      onTap: () => _onButtonPressed(mainText),
      onLongPress: mainText == '0' ? () => _onButtonPressed('+') : null,
      borderRadius: BorderRadius.circular(100),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              mainText,
              style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w400),
            ),
            if (subText.isNotEmpty)
              Text(
                subText,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton(String label, Color color, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OutgoingCallScreen(
              contact: fc.Contact(displayName: 'Unknown', phones: [fc.Phone(_controller.text)]),
              callType: label,
            ),
          ),
        );
      },
      icon: Icon(icon, color: Colors.white),
      label: Text(label.toUpperCase()),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }
}
