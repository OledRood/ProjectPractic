import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Loading Page')),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
