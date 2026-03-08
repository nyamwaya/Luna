import 'package:flutter/material.dart';

class ConversationShell extends StatelessWidget {
  const ConversationShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Luma'),
      ),
      body: const Center(
        child: Text('Luma Conversation Shell'),
      ),
    );
  }
}
