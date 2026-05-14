class WaitingTime {
  final String destinationId;
  final List<int> arrivalsSeconds;

  const WaitingTime({
    required this.destinationId,
    required this.arrivalsSeconds,
  });

  List<int> get arrivalsMinutes =>
      arrivalsSeconds.map((s) => (s / 60).round()).toList();

  // ── HTTP ──────────────────────────────────────────────────────────────────
  // /tempoEspera/Estacao/{estacao} response shape (one entry per direction):
  // {
  //   "stop_id":       "RM", station id
  //   "destino":       "54", direction of the line
  //   "tempoChegada1": "38",   ← can be "--" meaning no data
  //   "tempoChegada2": "570",
  //   "tempoChegada3": "1169", times of arrival are in seconds.
  //   "sairServico":   "0",
  //   ...
  // }
  // Returns null if any arrival time is "--" (no data available)
  static WaitingTime? fromJson(Map<String, dynamic> json) {
    final t1 = json['tempoChegada1'] as String;
    final t2 = json['tempoChegada2'] as String;
    final t3 = json['tempoChegada3'] as String;

    // Skip entries with no data
    if (t1 == '--' || t2 == '--' || t3 == '--') return null;

    return WaitingTime(
      destinationId:   json['destino'] as String,
      arrivalsSeconds: [
        int.parse(t1),
        int.parse(t2),
        int.parse(t3),
      ],
    );
  }

  // Parses the full response body for a station and returns one WaitingTime per direction
  static List<WaitingTime> listFromResponse(Map<String, dynamic> body) {
    final List resposta = body['resposta'] as List;
    return resposta
        .map((e) => WaitingTime.fromJson(e as Map<String, dynamic>))
        .whereType<WaitingTime>() // drops nulls (entries with "--")
        .toList();
  }
}