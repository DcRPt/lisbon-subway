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

  // Parses /estadoLinha/todos into a list of LineStatus
  static List<LineStatus> listFromResponse(Map<String, dynamic> body) {
    final Map<String, dynamic> resposta = body['resposta'] as Map<String, dynamic>;
    final lines = ['azul', 'amarela', 'verde', 'vermelha'];

    return lines.map((line) => LineStatus(
      lineName:    line,
      status:      resposta[line]          as String? ?? '',
      shortStatus: resposta['${line}_curta'] as String? ?? 'normal',
    )).toList();
  }

  // Parses /estadoLinha/{linha} for a single line
  static LineStatus fromResponse(String line, Map<String, dynamic> body) {
    final Map<String, dynamic> resposta = body['resposta'] as Map<String, dynamic>;
    return LineStatus(
      lineName:    line,
      status:      resposta[line]            as String? ?? '',
      shortStatus: resposta['${line}_curta'] as String? ?? 'normal',
    );
  }
}