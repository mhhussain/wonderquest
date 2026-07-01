import 'package:flutter/material.dart';
import 'theme/wq_theme.dart';

class WonderQuestApp extends StatelessWidget {
  const WonderQuestApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wonder Quest',
      debugShowCheckedModeBanner: false,
      theme: WqTheme.theme,
      home: const Scaffold(body: Center(child: Text('Wonder Quest'))),
    );
  }
}
