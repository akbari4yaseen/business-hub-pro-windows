import 'package:flutter/material.dart';

class SchoolScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('School'),
      ),
      body: Center(
        child: Text(
          'School Screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
