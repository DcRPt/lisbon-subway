enum GenericOperationType {
  GetNames // exemplo
}

/**
 * Caso necessitem de realizar operações com dados que não estejam disponíveis
 * nas classes abstratas DataSource facultadas no projeto, podem criar uma implementação
 * desta classe e realiza-las. Devem seguir estes passos:
 *
 * 1. Definir um tipo de operação no enumerado GenericOperationType, imaginemos GetNames
 * 2. Na classe de implementação, devem verificar o tipo de operação e executar
 * 3. !! Devem salvaguardar-se para o caso em que a função retorne null !!
 *
 * Exemplo:
 *
 * class MyGenericDataSource extends GenericDataSource {
 *
 *   final List<String> names = ["John", "Doe"];
 *
 *   @override
 *   Future<dynamic> execute({required GenericOperationType type, dynamic data}) async {
 *     switch (type) {
 *       case GenericOperationType.GetNames:
 *         return names;
 *     }
 *   }
 * }
 *
 * Utilização:
 *
 * final ds = MyGenericDataSource();
 *
 * final result = await ds.execute(
 *   type: GenericOperationType.GetNames,
 * );
 *
 * print(result); // ["Joen", "Doe"]
 */

abstract class GenericDataSource {

  Future<dynamic> execute({required GenericOperationType type, dynamic data});

}