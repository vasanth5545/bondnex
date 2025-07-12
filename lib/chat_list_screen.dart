// File: lib/screens/chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  final List<Map<String, String>> chatData = const [
    {'name': 'Sophia', 'message': 'Hey, how are you?', 'time': '10:30 AM'},
    {'name': 'Ethan', 'message': "I'm doing great, thanks!", 'time': 'Yesterday'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(child: Icon(Icons.person)),
        ),
        title: const Text('Messages'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Enter phone number or unique user ID',
                  prefixIcon: const Icon(Icons.search),
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: chatData.length,
                itemBuilder: (context, index) {
                  final chat = chatData[index];
                  return ListTile(
                    leading: const CircleAvatar(radius: 28, child: Icon(Icons.person, size: 30)),
                    title: Text(chat['name']!, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    subtitle: Text(chat['message']!, overflow: TextOverflow.ellipsis),
                    trailing: Text(chat['time']!, style: GoogleFonts.poppins(fontSize: 12)),
                    onTap: () {},
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
