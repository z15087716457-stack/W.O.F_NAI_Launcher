import 'dart:io';

/// Python used by the isolated JSON worker IPC tests.
///
/// `RAG_TEST_PYTHON` wins; otherwise the registered development venv under
/// `.dart_tool/rag-runtime/` is used when present, so the default regression
/// runs these tests instead of skipping them. Tests only spawn fixture scripts.
String? ragTestPython() {
  final configured = Platform.environment['RAG_TEST_PYTHON'];
  if (configured != null && configured.isNotEmpty) return configured;
  final venv = File(
    Platform.isWindows
        ? '.dart_tool/rag-runtime/venv/Scripts/python.exe'
        : '.dart_tool/rag-runtime/venv/bin/python',
  );
  return venv.existsSync() ? venv.absolute.path : null;
}
