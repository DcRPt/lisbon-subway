import 'package:cmproject/data/metro_repository.dart';
import 'package:cmproject/screens/station_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ListScreen extends StatelessWidget {
  const ListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stations = context.read<MetroRepository>().getAllStations();

    return Scaffold(
      key: const Key('list-screen'),
      backgroundColor: const Color(0xFFFAFAF8),
      body: SafeArea(
        child: ListView.builder(
          key: const Key('list-view'),
          itemCount: stations.length,
          itemBuilder: (context, i) {
            final station = stations[i];
            return ListTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(station.name),
                  Text(
                    "Linha ${station.lineName}",
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B6B7A)),
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => StationDetailScreen(station: station),
              )),
            );
          },
        ),
      ),
    );
  }
}