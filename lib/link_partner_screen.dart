// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import '../providers/user_provider.dart'; // Assuming you have a UserProvider

// class LinkPartnerScreen extends StatefulWidget {
//   // This screen now accepts the unique ID generated from the backend
//   final String? myPermanentId;

//   const LinkPartnerScreen({super.key, this.myPermanentId});

//   @override
//   State<LinkPartnerScreen> createState() => _LinkPartnerScreenState();
// }

// class _LinkPartnerScreenState extends State<LinkPartnerScreen> {
//   late TextEditingController _myPermanentIdController;
//   final TextEditingController _partnerCodeController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     // Initialize the controller with the ID passed from the verification screen
//     // If no ID is passed (e.g., user is already logged in), it will be empty.
//     _myPermanentIdController = TextEditingController(text: widget.myPermanentId ?? '');
//   }
  
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     // If the controller is empty, try to get the ID from the provider
//     // This handles cases where the user is already logged in and comes back to this screen.
//     if (_myPermanentIdController.text.isEmpty) {
//         final userProvider = Provider.of<UserProvider>(context, listen: false);
//         _myPermanentIdController.text = userProvider.myPermanentId;
//     }
//   }

//   @override
//   void dispose() {
//     _myPermanentIdController.dispose();
//     _partnerCodeController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         title: const Text('Link with Your Partner'),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Section to display and share the user's own unique ID
//               Text(
//                 'Share Your Unique ID',
//                 style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Share this ID with your partner so they can link with you.',
//                 style: GoogleFonts.poppins(color: Colors.grey[600]),
//               ),
//               const SizedBox(height: 16),
//               TextField(
//                 controller: _myPermanentIdController,
//                 readOnly: true, // The user cannot edit their own ID
//                 decoration: InputDecoration(
//                   labelText: 'Your Unique ID',
//                   suffixIcon: IconButton(
//                     icon: Icon(Icons.copy, color: Theme.of(context).iconTheme.color),
//                     onPressed: () {
//                       Clipboard.setData(ClipboardData(text: _myPermanentIdController.text));
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text('Your Unique ID has been copied!')),
//                       );
//                     },
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 40),

//               // Section to enter the partner's unique ID
//               Text(
//                 "Enter Your Partner's ID",
//                 style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 "If your partner has shared their ID with you, enter it here.",
//                 style: GoogleFonts.poppins(color: Colors.grey[600]),
//               ),
//               const SizedBox(height: 16),
//               TextField(
//                 controller: _partnerCodeController,
//                 decoration: const InputDecoration(hintText: "Enter partner's ID"),
//               ),
//               const SizedBox(height: 24),
//               ElevatedButton(
//                 onPressed: () {
//                   // TODO: Add logic to send the partner's ID to your backend
//                   // to create the link in your `partners` table.
//                   if (_partnerCodeController.text.isNotEmpty) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('Linking with ${_partnerCodeController.text}...')),
//                     );
//                     // Example: context.read<UserProvider>().linkPartner(_partnerCodeController.text);
//                   } else {
//                      ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Please enter a valid partner ID.')),
//                     );
//                   }
//                 },
//                 child: Text('Send link', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
