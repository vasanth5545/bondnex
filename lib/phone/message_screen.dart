// File: lib/phone/message_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MessageScreen extends StatelessWidget {
  const MessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: 10, // Replace with your actual message list length
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text(
              'Contact Name ${index + 1}',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            subtitle: Text(
              'This is the last message...',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
            trailing: Text(
              '10:${index}0 AM',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}
