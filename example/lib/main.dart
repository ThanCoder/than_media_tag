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
  String text = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(child: Text(text)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          text = getVersionInfo().toString();
          setState(() {});
        },
      ),
    );
  }
}
