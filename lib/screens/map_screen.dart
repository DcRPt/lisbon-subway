import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('map-screen'),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/map.png',
            fit: BoxFit.cover,
          ),
        ],
      ),
    );
  }
}