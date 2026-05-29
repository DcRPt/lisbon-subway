# Workspace Instructions for GitHub Copilot

## What this project is
- Flutter mobile app built in Dart.
- Focused on a transit/station dashboard, favorites, map view, incident reporting, and search/filter UI.
- Includes student-visible functionality and teacher-managed grading tests under `test/teacher`.

## Key files and directories
- `lib/` - application code.
- `main.dart` - app entrypoint.
- `pubspec.yaml` - dependencies and Flutter configuration.
- `analysis_options.yaml` - lints and analyzer rules.
- `README.md` - user-facing project summary and feature list.
- `.github/workflows/grade.yml` and `.github/workflows/mandatory_tests.yml` - grading CI pipeline.
- `test/teacher/` - teacher-owned tests that are validated by CI hashes.
- `integration_test/` - integration test assets.

## Recommended commands
- `flutter pub get` - install dependencies.
- `dart analyze` - run static analysis.
- `flutter test` - run unit/widget tests.
- `flutter test --name "<test name>"` - run a specific named test as used by grading workflow.
- `flutter run` - run the app locally.

## CI and grading constraints
- The repository uses a grading workflow that validates GitHub Actions and teacher tests hashes.
- Do not modify `.github/workflows/*.yml` unless you intend to change CI behavior intentionally.
- Do not modify `test/teacher` files unless those changes are explicitly required by the project owner.

## Agent guidance
- Prefer small, incremental changes with tests when editing UI or navigation.
- Inspect `README.md` before summarizing features; it contains the implemented functionality and acceptance criteria.
- When asked to refactor or add features, preserve the existing app architecture and keep main app logic in `lib/`.
- Use `analysis_options.yaml` and `flutter_lints` as the code-style baseline.

## Useful references
- `README.md` for project goals and implemented screens.
- `.github/workflows/grade.yml` and `.github/workflows/mandatory_tests.yml` for test expectations and environment.
- `pubspec.yaml` for package versions and plugin list.
