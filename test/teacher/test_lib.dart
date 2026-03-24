import 'package:flutter_test/flutter_test.dart';

const bool skipCheckDependsOn = bool.fromEnvironment(
  'SKIP_DEPENDS_ON',
  defaultValue: false
);

WidgetTesterCallback checkDependsOn(
  WidgetTesterCallback body, {
  bool skipCheckDependsOn = skipCheckDependsOn,
  List<String> dependsOn = const []
}) {
  return (widgetTester) async {
    final testName = widgetTester.testDescription;
    if (!skipCheckDependsOn) {
      if (!TestDependencyRegistry.didPass(dependsOn)) {
        fail(
          "❗O teste '$testName' depende do(s) teste(s):\n"
          "${dependsOn.map((test) => test).join('\n')}\n"
          "para passar, por isso este teste irá falhar automaticamente"
        );
      }
    }

    await body(widgetTester);

    TestDependencyRegistry.markPassed(testName);
  };

}

class TestDependencyRegistry {
  static final Map<String, bool> _results = {};

  static void markPassed(String name) {
    _results[name] = true;
  }

  static bool didPass(List<String> tests) {
    return tests
        .where((test) => _results[test] == true)
        .length == tests.length;
  }
}