import 'package:flutter/material.dart';
import 'package:than_media_tag/than_media_tag.dart';

void main() {
  runApp(MaterialApp(theme: .dark(), home: const MyApp()));
}

class MyApp extends StatefulWidget {
  const new({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Placeholder(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showVersionInfo();
        },
      ),
    );
  }
}
