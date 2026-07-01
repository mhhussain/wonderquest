import 'package:flutter/material.dart';

class WonderQuestApp extends StatelessWidget {
  const WonderQuestApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Wonder Quest',
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: Text('Wonder Quest'))),
    );
  }
}
