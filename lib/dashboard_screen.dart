// File: lib/screens/dashboard_screen.dart
// UPDATED: Passed BuildContext to helper methods to resolve 'undefined context' error.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../providers/user_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final bool isPartnerConnected = userProvider.isPartnerConnected;

        return Scaffold(
          floatingActionButton: isPartnerConnected
              ? FloatingActionButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Couple features coming soon!')),
                    );
                  },
                  child: const Icon(Icons.favorite),
                  tooltip: 'Couple Features',
                )
              : FloatingActionButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please link with a partner to enable this.')),
                    );
                  },
                  backgroundColor: Colors.grey,
                  child: const Icon(Icons.sync_disabled),
                  tooltip: 'Link with a partner first',
                ),
          appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundImage: userProvider.userImage != null ? FileImage(userProvider.userImage!) : null,
                child: userProvider.userImage == null ? const Icon(Icons.person) : null,
              ),
            ),
            title: const Text('Dashboard'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.pushNamed(context, '/settings'),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isPartnerConnected
                      // **THE FIX IS HERE**: Passing context to the helper methods
                      ? _buildCoupleProfile(context, userProvider)
                      : _buildSingleProfile(context, userProvider),
                  
                  const SizedBox(height: 30),

                  if (isPartnerConnected) ...[
                    _buildSectionTitle(context, 'Trust Score', '85/100'),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: 0.85,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                      minHeight: 8,
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                    ),
                    const SizedBox(height: 30),
                  ],

                  isPartnerConnected
                      ? _buildCoupleFeaturesGrid(context)
                      : _buildSingleFeaturesGrid(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // **THE FIX IS HERE**: Added BuildContext parameter
  Widget _buildSingleProfile(BuildContext context, UserProvider userProvider) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15.0),
              child: Container(
                height: 150,
                width: double.infinity,
                color: Theme.of(context).colorScheme.surface,
                child: const Icon(Icons.image, size: 50, color: Colors.grey),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  onPressed: () {},
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              child: CircleAvatar(
                radius: 52,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: userProvider.userImage != null ? FileImage(userProvider.userImage!) : null,
                  child: userProvider.userImage == null
                      ? Icon(
                          Icons.person,
                          size: 50,
                          color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 50),
        Text(userProvider.userName, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }
  
  // **THE FIX IS HERE**: Added BuildContext parameter
  Widget _buildCoupleProfile(BuildContext context, UserProvider userProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _ProfileWidget(
          isUser: true,
          name: userProvider.userName,
          imageFile: userProvider.userImage,
          showTrustLevel: true,
        ),
        const _ProfileWidget(
          isUser: false,
          name: 'Partner Name', // TODO: Fetch partner's name
          imageFile: null,
          showTrustLevel: true,
        ),
      ],
    );
  }

  // **THE FIX IS HERE**: Added BuildContext parameter
  Widget _buildSingleFeaturesGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.8,
      children: [
        _FeatureButton(icon: FontAwesomeIcons.locationDot, label: 'Location', onTap: () {}, gradient: const LinearGradient(colors: [Color(0xFF43CEA2), Color(0xFF185A9D)])),
        const _InstagramProfileButton(),
        _FeatureButton(icon: FontAwesomeIcons.whatsapp, label: 'WhatsApp', onTap: () {}, gradient: const LinearGradient(colors: [Color(0xFF25D366), Color(0xFF128C7E)])),
        _FeatureButton(icon: FontAwesomeIcons.calendarDay, label: 'Plan', onTap: () {}, gradient: const LinearGradient(colors: [Color(0xFF43C6AC), Color(0xFF191654)])),
        _FeatureButton(icon: FontAwesomeIcons.solidHeart, label: 'Memories', onTap: () {}, gradient: const LinearGradient(colors: [Color(0xFFFF5F6D), Color(0xFFFFC371)])),
      ],
    );
  }

  // **THE FIX IS HERE**: Added BuildContext parameter
  Widget _buildCoupleFeaturesGrid(BuildContext context) {
    final List<Widget> features = [
      _FeatureButton(icon: FontAwesomeIcons.locationDot, label: 'Location', onTap: () {}, gradient: const LinearGradient(colors: [Color(0xFF43CEA2), Color(0xFF185A9D)])),
      const SizedBox(height: 16),
      _FeatureButton(icon: FontAwesomeIcons.instagram, label: 'Instagram', onTap: () {}, gradient: const LinearGradient(colors: [Color(0xFFFEDA77), Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF), Color(0xFF515BD4)])),
      const SizedBox(height: 16),
      _FeatureButton(icon: FontAwesomeIcons.whatsapp, label: 'WhatsApp', onTap: () {}, gradient: const LinearGradient(colors: [Color(0xFF25D366), Color(0xFF128C7E)])),
      const SizedBox(height: 16),
      _FeatureButton(icon: FontAwesomeIcons.calendarDay, label: 'Plan', onTap: () {}, gradient: const LinearGradient(colors: [Color(0xFF43C6AC), Color(0xFF191654)])),
      const SizedBox(height: 16),
      _FeatureButton(icon: FontAwesomeIcons.solidHeart, label: 'Memories', onTap: () {}, gradient: const LinearGradient(colors: [Color(0xFFFF5F6D), Color(0xFFFFC371)])),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: features)),
        const SizedBox(width: 16),
        Expanded(child: Column(children: features)),
      ],
    );
  }

  // **THE FIX IS HERE**: Added BuildContext parameter
  Widget _buildSectionTitle(BuildContext context, String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
        Text(value, style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])),
      ],
    );
  }
}

class _ProfileWidget extends StatelessWidget {
  final String name;
  final bool isUser;
  final File? imageFile;
  final bool showTrustLevel;

  const _ProfileWidget({required this.name, required this.isUser, this.imageFile, required this.showTrustLevel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: theme.colorScheme.surface,
          backgroundImage: imageFile != null ? FileImage(imageFile!) : null,
          child: imageFile == null
              ? Icon(
                  isUser ? Icons.person : Icons.favorite_border,
                  size: 50,
                  color: theme.iconTheme.color?.withOpacity(0.7),
                )
              : null,
        ),
        const SizedBox(height: 12),
        Text(name, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        if (showTrustLevel)
          Text('Trust Level: High', style: GoogleFonts.poppins(color: Colors.grey[600])),
      ],
    );
  }
}

class _InstagramProfileButton extends StatefulWidget {
  const _InstagramProfileButton();

  @override
  State<_InstagramProfileButton> createState() => _InstagramProfileButtonState();
}

class _InstagramProfileButtonState extends State<_InstagramProfileButton> {
  bool _isLoading = false;

  Future<void> _launchInstagram(String? username) async {
    if (username == null || username.isEmpty) {
      _showEditBottomSheet(context, Provider.of<UserProvider>(context, listen: false));
      return;
    }
    final appUrl = Uri.parse("instagram://user?username=$username");
    final webUrl = Uri.parse("https://www.instagram.com/$username/");
    if (await canLaunchUrl(appUrl)) {
      await launchUrl(appUrl);
    } else if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  void _showEditBottomSheet(BuildContext context, UserProvider userProvider) {
    final usernameController = TextEditingController(text: userProvider.instagramUsername);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Link your Instagram', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Enter your username to fetch your profile and follower count.', style: GoogleFonts.poppins(color: Colors.grey[600])),
              const SizedBox(height: 16),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: "Instagram Username"),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (usernameController.text.isNotEmpty) {
                    setState(() => _isLoading = true);
                    Navigator.of(context).pop();
                    await userProvider.updateInstagramProfile(usernameController.text);
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                child: const Text('Fetch & Save Profile'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    const gradient = LinearGradient(
      colors: [Color(0xFFFEDA77), Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF), Color(0xFF515BD4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(12)),
      child: ElevatedButton(
        onPressed: () => _launchInstagram(userProvider.instagramUsername),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0))
            : Row(
                children: [
                  const FaIcon(FontAwesomeIcons.instagram, size: 24, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _showEditBottomSheet(context, userProvider),
                          child: Text(
                            userProvider.instagramUsername ?? 'Add Instagram',
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (userProvider.instagramFollowers != null && userProvider.instagramFollowers!.isNotEmpty)
                          Text(
                            '${userProvider.instagramFollowers} Followers',
                            style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _FeatureButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Gradient? gradient;

  const _FeatureButton({required this.icon, required this.label, required this.onTap, this.gradient});

  @override
  Widget build(BuildContext context) {
    final buttonContent = Row(
      children: [
        FaIcon(icon, size: 20, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: gradient == null ? Theme.of(context).cardTheme.color : Colors.transparent,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.all(16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    if (gradient == null) {
      return ElevatedButton(onPressed: onTap, style: buttonStyle, child: buttonContent);
    }

    return Container(
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(12)),
      child: ElevatedButton(onPressed: onTap, style: buttonStyle, child: buttonContent),
    );
  }
}
