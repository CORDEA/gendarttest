import 'dart:io';

void main(List<String> arguments) {
  _run();
}

Future<void> _run() async {
  final files = await _findAddedFiles();
}

Future<Iterable<String>> _findAddedFiles() async {
  final result = await Process.run(
    'git',
    ['ls-files', '-o', '--exclude-standard'],
  );
  if (result.exitCode > 0) {
    throw Exception(result.stderr);
  }
  return (result.stdout as String)
      .split('\n')
      .where((element) => element.endsWith('.dart'));
}
