// Represents a destination from /infoDestinos/todos
//
// Response shape:
// {
//   "id_destino":   "33",
//   "nome_destino": "Reboleira"
// }

class Destination {
  final String id;
  final String name;

  const Destination({required this.id, required this.name});

  factory Destination.fromJson(Map<String, dynamic> json) => Destination(
    id:   json['id_destino']   as String,
    name: json['nome_destino'] as String,
  );

  // Parses /infoDestinos/todos into a lookup map: id → name
  static Map<String, String> mapFromResponse(Map<String, dynamic> body) {
    final List resposta = body['resposta'] as List;
    return {
      for (final e in resposta)
        (e as Map<String, dynamic>)['id_destino'] as String:
        e['nome_destino'] as String,
    };
  }
}