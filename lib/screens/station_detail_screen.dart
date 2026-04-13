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
        children: [
          _StationInfoCard(station: station),
          const SizedBox(height: 20),
          const Text(
            'Incidentes reportados',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          if (reports.isEmpty)
            const Text(
              'Sem incidentes reportados.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B6B7A),
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...reports.map((report) {
              final formattedDate =
              DateFormat('dd/MM/yyyy HH:mm').format(report.timestamp);
              return ListTile(
                title: Text(formattedDate),
                subtitle:
                report.notes != null ? Text(report.notes!) : null,
              );
            }),
        ],
      ),
    );
  }
}

class _StationInfoCard extends StatelessWidget {
  final Station station;
  const _StationInfoCard({required this.station});

  @override
  Widget build(BuildContext context) {
    final avg = station.averageRating;
    final totalReports = station.reports.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nome e linha
          Row(
            children: [
              const Icon(Icons.train, size: 18, color: Color(0xFF003087)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  station.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Linha ${station.lineName}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B7A)),
          ),
          const Divider(height: 20),
          // Métricas
          Row(
            children: [
              _InfoTile(
                icon: Icons.warning_amber_rounded,
                label: 'Incidentes',
                value: '$totalReports',
              ),
              const SizedBox(width: 16),
              _InfoTile(
                icon: Icons.star_rounded,
                label: 'Avaliação média',
                value: avg > 0 ? avg.toStringAsFixed(1) : '—',
                valueColor: avg >= 4
                    ? const Color(0xFFD32F2F)
                    : avg >= 2
                    ? const Color(0xFFF57C00)
                    : const Color(0xFF388E3C),
              ),
              const SizedBox(width: 16),
              _InfoTile(
                icon: Icons.location_on_outlined,
                label: 'Coordenadas',
                value:
                '${station.latitude.toStringAsFixed(4)}, ${station.longitude.toStringAsFixed(4)}',
                fontSize: 10,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final double fontSize;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: const Color(0xFF6B6B7A)),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF6B6B7A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: valueColor ?? const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }
}