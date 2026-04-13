import 'package:cmproject/models/station.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StationDetailScreen extends StatelessWidget {
  final Station station;
  const StationDetailScreen({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final reports = List.from(station.reports)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      key: const Key('detail-screen'),
      backgroundColor: const Color(0xFFFAFAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAF8),
        elevation: 0,
        leading: CupertinoNavigationBarBackButton(
          color: const Color(0xFF003087),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(station.name,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E))),
            Text("Linha ${station.lineName}",
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B6B7A))),
          ],
        ),
      ),
      body: ListView(
        key: const Key('detail-screen-incidents-list'),
        padding: const EdgeInsets.all(16),
        children: reports.isEmpty
            ? [
          const Text('Sem incidentes reportados.',
              style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B6B7A),
                  fontStyle: FontStyle.italic)),
        ]
            : reports.map((report) {
          final formattedDate =
          DateFormat('dd/MM/yyyy HH:mm').format(report.timestamp);
          return ListTile(
            title: Text(formattedDate),
            subtitle: report.notes != null ? Text(report.notes!) : null,
          );
        }).toList(),
      ),
    );
  }
}