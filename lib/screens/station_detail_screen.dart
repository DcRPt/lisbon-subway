import 'package:cmproject/models/station.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ── Cores (mesmas da ListScreen) ──────────────────────────────────────────────
const _navy       = Color(0xFF003087);
const _warmWhite  = Color(0xFFFAFAF8);
const _warmSurface = Color(0xFFF2F0EB);
const _nearBlack  = Color(0xFF1A1A2E);
const _muted      = Color(0xFF6B6B7A);
const _borderDefault = Color(0xFFD8D6CF);

Color _lineColor(String lineName) {
  final l = lineName.toLowerCase();
  if (l.contains('azul')  || l.contains('blue'))   return const Color(0xFF0057A8);
  if (l.contains('amar')  || l.contains('yellow'))  return const Color(0xFFF5A800);
  if (l.contains('verd')  || l.contains('green'))   return const Color(0xFF00A89D);
  if (l.contains('verm')  || l.contains('red'))     return const Color(0xFFEE1D23);
  if (l.contains('rosa')  || l.contains('pink'))    return const Color(0xFFE91E8C);
  if (l.contains('cast')  || l.contains('brown'))   return const Color(0xFF795548);
  return _muted;
}

Color _severityBg(double avg) {
  if (avg == 0) return _warmSurface;
  if (avg < 2)  return const Color(0xFFEDF7E3);
  if (avg < 4)  return const Color(0xFFFFF8E1);
  return const Color(0xFFFCEBEB);
}

Color _severityFg(double avg) {
  if (avg == 0) return _muted;
  if (avg < 2)  return const Color(0xFF2E7D6B);
  if (avg < 4)  return const Color(0xFFB36B00);
  return const Color(0xFFA32D2D);
}

// ── Screen ────────────────────────────────────────────────────────────────────
class StationDetailScreen extends StatelessWidget {
  final Station station;
  const StationDetailScreen({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final reports = List.from(station.reports)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final avg = station.averageRating;
    final fullLine = station.lineName.toLowerCase().startsWith('linha')
        ? station.lineName
        : 'Linha ${station.lineName}';

    return Scaffold(
      key: const Key('detail-screen'),
      backgroundColor: _warmWhite,
      appBar: AppBar(
        backgroundColor: _navy,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(station.name,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            Row(children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                    color: _lineColor(station.lineName),
                    shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(fullLine,
                  style: const TextStyle(fontSize: 11, color: Colors.white70)),
            ]),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('detail-screen-incidents-list'),
          children: [
            // ── Info card ────────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderDefault),
              ),
              child: Row(children: [
                // Linha badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _lineColor(station.lineName).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                            color: _lineColor(station.lineName),
                            shape: BoxShape.circle)),
                    const SizedBox(height: 4),
                    Text(
                      station.lineName.replaceAll(
                          RegExp(r'linha\s*', caseSensitive: false), ''),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _lineColor(station.lineName)),
                    ),
                  ]),
                ),
                const SizedBox(width: 14),
                // Métricas
                Expanded(
                  child: Row(children: [
                    _metric(Icons.warning_amber_rounded,
                        '${station.reports.length}', 'incidentes'),
                    const SizedBox(width: 16),
                    if (avg > 0)
                      _metric(Icons.bar_chart_rounded,
                          avg.toStringAsFixed(1), 'severidade',
                          valueColor: _severityFg(avg),
                          bg: _severityBg(avg)),
                  ]),
                ),
              ]),
            ),

            // ── Section header ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text('Incidentes reportados',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _nearBlack)),
            ),
            Container(height: 1, color: _borderDefault),

            // ── Incident list ─────────────────────────────────────────────
            if (reports.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.check_circle_outline, size: 40, color: _muted),
                  SizedBox(height: 10),
                  Text('Sem incidentes reportados',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _nearBlack)),
                  SizedBox(height: 4),
                  Text('Esta estação não tem ocorrências registadas.',
                      style: TextStyle(fontSize: 13, color: _muted),
                      textAlign: TextAlign.center),
                ]),
              )
            else
              ...reports.asMap().entries.map((entry) {
                final i = entry.key;
                final report = entry.value;
                final formattedDate =
                DateFormat('dd/MM/yyyy HH:mm').format(report.timestamp);
                final isLast = i == reports.length - 1;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      title: Text(formattedDate,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _nearBlack)),
                      subtitle: report.notes != null
                          ? Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(report.notes!,
                            style: const TextStyle(
                                fontSize: 12, color: _muted)),
                      )
                          : null,
                      trailing: report.type != null
                          ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _warmSurface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _borderDefault),
                        ),
                        child: Text(report.type!.displayName,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _muted)),
                      )
                          : null,
                    ),
                    if (!isLast)
                      Divider(height: 1, color: _borderDefault, indent: 16, endIndent: 16),
                  ],
                );
              }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _metric(IconData icon, String value, String label,
      {Color? valueColor, Color? bg}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg ?? _warmSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _borderDefault),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: valueColor ?? _muted),
          const SizedBox(width: 5),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? _nearBlack)),
            Text(label,
                style: const TextStyle(fontSize: 9, color: _muted)),
          ]),
        ]),
      );
}