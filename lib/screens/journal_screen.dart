import 'package:flutter/material.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'صفحه روزنامچه',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
