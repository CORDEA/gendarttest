import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

void main(List<String> arguments) {
  _run();
}

Future<void> _run() async {
  final files = await _findAddedFiles();
  final classes = await Future.wait(files.map((e) => _findClasses(e)));
  await Future.wait(
    classes.expand((e) => e).map((e) => _generateTestFile(e)),
  );
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

Future<Iterable<_Declaration>> _findClasses(String path) async {
  final parsed =
      parseFile(path: path, featureSet: FeatureSet.latestLanguageVersion());
  return parsed.unit.declarations
      .whereType<ClassDeclaration>()
      .where((element) => !element.isAbstract)
      .map((e) => _Declaration(path, e));
}

Future<void> _generateTestFile(_Declaration declaration) async {
  final testFileName = '${_flattenFileName(declaration.name)}_test.dart';
  final path = File.fromUri(Uri(
    pathSegments: ['test'] +
        declaration.directory.uri.pathSegments.sublist(1) +
        [testFileName],
  ));
  if (await path.exists()) {
    return;
  }
  await path.create(recursive: true);
}

String _flattenFileName(String name) {
  return List.generate(name.length, (index) => index).fold(
    '',
    (previousValue, i) {
      final s = name[i].toString();
      final lowerS = s.toLowerCase();
      if (i > 0 && s != lowerS) {
        return '${previousValue}_$lowerS';
      }
      return '$previousValue$lowerS';
    },
  );
}

class _Declaration {
  _Declaration(this._path, this._declaration);

  final String _path;
  final ClassDeclaration _declaration;

  Directory get directory => File(_path).parent;

  String get name => _declaration.name.name;
}
