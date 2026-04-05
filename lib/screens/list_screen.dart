import 'package:flutter/material.dart';

class ListScreen extends StatelessWidget {
  const ListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: const Key('list-screen'),
      body: Center(child: Text('List Screen')),
    );
  }
}