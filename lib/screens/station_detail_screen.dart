import 'package:cmproject/models/station.dart';
import 'package:cmproject/data/app_colors.dart';
import 'package:cmproject/screens/incident_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _lineColor(String lineName) {
  final l = lineName.toLowerCase();
  for (final entry in AppColors.kLineColors.entries) {
    if (l.contains(entry.key)) return entry.value;
  }
  return AppColors.kGrey;
}

String _destinationName(String id) {
  if (id == '10') return 'Reboleira';
  if (id == '20') return 'Santa Apolónia';
  if (id == '30') return 'Cais do Sodré';
  if (id == '40') return 'Telheiras';
  if (id == '60') return 'Aeroporto';
  if (id == '38') return 'S. Sebastião';
  return id;
}

Color _severityBg(double avg) {
  if (avg == 0) return AppColors.kFieldBg;
  if (avg < 2)  return AppColors.kSuccessGreen.withValues(alpha: 0.12);
  if (avg < 4)  return AppColors.kYellow.withValues(alpha: 0.12);
  return AppColors.kErrorRed.withValues(alpha: 0.12);
}

Color _severityFg(double avg) {
  if (avg == 0) return AppColors.kGrey;
  if (avg < 2)  return AppColors.kSuccessGreen;
  if (avg < 4)  return AppColors.kYellow;
  return AppColors.kErrorRed;
}

Color _severityDotBg(int rate) {
  if (rate >= 4) return AppColors.kErrorRed.withValues(alpha: 0.12);
  if (rate >= 2) return AppColors.kYellow.withValues(alpha: 0.12);
  return AppColors.kSuccessGreen.withValues(alpha: 0.12);
}

Color _severityDotFg(int rate) {
  if (rate >= 4) return AppColors.kErrorRed;
  if (rate >= 2) return AppColors.kYellow;
  return AppColors.kSuccessGreen;
}

// ── Screen ────────────────────────────────────────────────────────────────────
class StationDetailScreen extends StatelessWidget {
  final Station station;
  const StationDetailScreen({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final reports = List.from(station.reports)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final avg      = station.averageRating;
    final fullLine = station.lineName.toLowerCase().startsWith('linha')
        ? station.lineName
        : 'Linha ${station.lineName}';

    return Scaffold(
      key: const Key('detail-screen'),
      backgroundColor: const Color(0xFFFAFAF8),
      appBar: AppBar(
        backgroundColor: AppColors.kNavyBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              station.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Row(children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _lineColor(station.lineName),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                fullLine,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ]),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('detail-screen-incidents-list'),
          children: [

            // ── Metrics row ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(children: [
                // Incident count
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.kFieldBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.kFieldBorder),
                    ),
                    child: Row(children: [
                      Text(
                        '${station.reports.length}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'incidentes\nreportados',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.kFieldText,
                          height: 1.3,
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(width: 8),
                // Avg severity card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: avg == 0
                          ? AppColors.kSuccessGreen.withValues(alpha: 0.12)
                          : _severityBg(avg),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: avg == 0
                            ? AppColors.kSuccessGreen.withValues(alpha: 0.4)
                            : _severityFg(avg).withValues(alpha: 0.4),
                      ),
                    ),
                    child: avg == 0
                        ? Row(children: [
                      Icon(Icons.check_rounded,
                          size: 20, color: AppColors.kSuccessGreen),
                      const SizedBox(width: 8),
                      Text(
                        'Sem\nocorrências',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.kSuccessGreen,
                          height: 1.3,
                        ),
                      ),
                    ])
                        : Row(children: [
                      Text(
                        avg.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _severityFg(avg),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'severidade\nmédia',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.kFieldText,
                          height: 1.3,
                        ),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),

            // ── Waiting times ─────────────────────────────────────────────
            if (station.waitingTimes.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PRÓXIMAS PARTIDAS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.6,
                        color: Color(0xFF6B6B7A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.kFieldBorder),
                      ),
                      child: Column(
                        children: station.waitingTimes.asMap().entries.map((entry) {
                          final index  = entry.key;
                          final wt     = entry.value;
                          final isLast = index == station.waitingTimes.length - 1;

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Plataforma ${index + 1}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.kFieldText,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(children: [
                                            Container(
                                              width: 3,
                                              height: 14,
                                              decoration: BoxDecoration(
                                                color: _lineColor(
                                                    station.lineName),
                                                borderRadius:
                                                BorderRadius.circular(2),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '→ ${_destinationName(wt.destinationId)}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1A1A2E),
                                              ),
                                            ),
                                          ]),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: wt.arrivalsMinutes
                                          .map((m) => Padding(
                                        padding: const EdgeInsets.only(
                                            left: 6),
                                        child: Container(
                                          width: 40,
                                          padding:
                                          const EdgeInsets.symmetric(
                                              vertical: 7),
                                          decoration: BoxDecoration(
                                            color: AppColors.kFieldBg,
                                            borderRadius:
                                            BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            mainAxisSize:
                                            MainAxisSize.min,
                                            children: [
                                              Text(
                                                '$m',
                                                style: const TextStyle(
                                                  fontWeight:
                                                  FontWeight.w700,
                                                  fontSize: 14,
                                                  color:
                                                  Color(0xFF111827),
                                                ),
                                              ),
                                              Text(
                                                'min',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: AppColors
                                                      .kFieldText,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ))
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isLast)
                                Divider(
                                  height: 1,
                                  color: AppColors.kFieldBorder,
                                  indent: 14,
                                  endIndent: 14,
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Section header with report button ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'INCIDENTES REPORTADOS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.6,
                      color: Color(0xFF6B6B7A),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => IncidentReportScreen(
                            preselectedStation: station,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.kFieldBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.kFieldBorder),
                      ),
                      child: const Text(
                        '+ Reportar',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.kNavyBlue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Incident list or empty state ──────────────────────────────
            if (reports.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.kFieldBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_outline_rounded,
                        size: 24,
                        color: AppColors.kGrey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Sem incidentes reportados',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Esta estação não tem ocorrências registadas.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.kFieldText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...reports.asMap().entries.map((entry) {
                final i      = entry.key;
                final report = entry.value;
                final isLast = i == reports.length - 1;
                final formattedDate =
                DateFormat('dd/MM/yyyy HH:mm').format(report.timestamp);

                final rate = report.rate;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Description first — larger, bold
                                if (report.notes != null)
                                  Text(
                                    report.notes!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),
                                const SizedBox(height: 3),
                                // Date below — smaller, grey
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.kFieldText,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Type pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.kFieldBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: AppColors.kFieldBorder),
                                  ),
                                  child: Text(
                                    report.type.displayName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.kFieldText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Severity dot using report.rate
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: _severityDotBg(rate),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _severityDotFg(rate)
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$rate',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _severityDotFg(rate),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: AppColors.kFieldBorder,
                        indent: 16,
                        endIndent: 16,
                      ),
                  ],
                );
              }),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}