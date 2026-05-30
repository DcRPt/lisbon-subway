// Represents the status of a metro line from /estadoLinha/todos or /estadoLinha/{linha}
//
// /estadoLinha/todos response shape:
// {
//   "azul":          " Ok",
//   "amarela":       " Ok",
//   "verde":         " Ok",
//   "vermelha":      " Ok",
//   "azul_curta":    "normal",   ← short status: "normal" or disruption description
//   "amarela_curta": "normal",
//   ...
// }
//
// /estadoLinha/{linha} response shape (single line):
// {
//   "azul":       " Ok",
//   "azul_curta": "normal",
//   "tipo_msg_az": "0"
// }

class LineStatus {
  final String lineName;
  final String status;     // full message e.g. " Ok"
  final String shortStatus; // "normal" or disruption description
  final bool isNormal;

  const LineStatus({
    required this.lineName,
    required this.status,
    required this.shortStatus,
  }) : isNormal = shortStatus == 'normal';

  // Parses /estadoLinha/todos into a list of LineStatus.
  // The API occasionally returns {"resposta": []} (empty list) instead of
  // a map when the service is unavailable — guard against that cast failure.
  static List<LineStatus> listFromResponse(Map<String, dynamic> body) {
    final raw = body['resposta'];

    // if resposta is not a Map (e.g. empty list), return all lines as normal
    if (raw is! Map<String, dynamic>) return _allNormal();

    final lines = ['azul', 'amarela', 'verde', 'vermelha'];

    return lines.map((line) => LineStatus(
      lineName: line,
      status: raw[line] as String? ?? '',
      shortStatus: raw['${line}_curta']  as String? ?? 'normal',
    )).toList();
  }

  static LineStatus fromResponse(String line, Map<String, dynamic> body) {
    final raw = body['resposta'];
    if (raw is! Map<String, dynamic>) {
      return LineStatus(lineName: line, status: '', shortStatus: 'normal');
    }
    return LineStatus(
      lineName: line,
      status: raw[line] as String? ?? '',
      shortStatus: raw['${line}_curta'] as String? ?? 'normal',
    );
  }

  // fallback when the API returns no usable data
  static List<LineStatus> _allNormal() => [
    'azul', 'amarela', 'verde', 'vermelha',
  ].map((l) => LineStatus(lineName: l, status: '', shortStatus: 'normal')).toList();
}