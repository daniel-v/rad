import 'dart:io';
import 'dart:async';

import 'package:build/build.dart';

Builder styles(BuilderOptions options) => StylesBuilder(options);

///
/// Styles builder
///
/// it's a utility for dev purpose, and is not be shipped with framework.
///
/// it creates .dart files from .css files which then framework can inject
/// inside DOM
///
class StylesBuilder implements Builder {
  BuilderOptions options;

  StylesBuilder(this.options) {
    fetchAvailableImports();
  }

  /*
  |--------------------------------------------------------------------------
  | preparing state
  |--------------------------------------------------------------------------
  */

  // all public imports
  final availableImports = <String, String>{};

  void fetchAvailableImports() {
    File('lib/rad.dart')
        .readAsStringSync()
        .split("\n")
        .forEach(addToAvailableImports);
  }

  void addToAvailableImports(String exportDetails) {
    var exportMatch = exportRegExp.firstMatch(exportDetails);

    if (null != exportMatch) {
      var importStatement = exportMatch.group(1)!;
      var classesExported = exportMatch.group(2)!.split(",");

      if (!importStatement.startsWith("package")) {
        importStatement = 'package:rad/$importStatement';
      }

      importStatement = "import '$importStatement';";

      for (final classInShow in classesExported) {
        if (!availableImports.containsKey(classInShow)) {
          availableImports[classInShow] = importStatement;
        }
      }
    }
  }

  /*
  |--------------------------------------------------------------------------
  | handling assets
  |--------------------------------------------------------------------------
  */

  final allowedLiteralExceptions = ["Target"];

  // gets cleared for each asset
  final importsForCurrentAsset = <String>{};

  static final classRegExp = RegExp(r'(wcontype|wruntype)="([a-zA-Z]*)"');
  static final exportRegExp = RegExp(
    r"'([a-zA-Z_\/]*.dart)' show (.+?)(?:,|$)*;",
  );

  String parseLine(String line) {
    var match = classRegExp.firstMatch(line);

    if (null != match) {
      var className = match.group(2)!;

      if (allowedLiteralExceptions.contains(className)) {
        return line.replaceAll('"', '\\"');
      }

      // add a import requirement
      if (availableImports.containsKey(className)) {
        importsForCurrentAsset.add(availableImports[className]!);
      } else {
        throw "\nRad: Internal widgets should not have any CSS.\n"
            "'$className' is not a public class and is not allowed for CSS styling.\n";
      }

      // interpolate
      line = line.replaceAll(className, "\$$className");
    }

    return line.replaceAll('"', '\\"');
  }

  @override
  final buildExtensions = const {
    '.css': ['.generated.dart']
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    var cssContents = await buildStep.readAsString(buildStep.inputId);

    var genAssetId = buildStep.inputId.changeExtension('.generated.dart');

    var fileName = buildStep.inputId.pathSegments.last;

    var genConstant = fileName.replaceAll('.css', '');

    if (!RegExp(r'^[a-zA-Z_]+$').hasMatch(genConstant)) {
      throw "\nRad: Name of your CSS files can contains only alphabets and underscores\n"
          "File name '$fileName' is not allowed\n";
    }

    genConstant = genConstant.toUpperCase();

    var genContents = '';

    importsForCurrentAsset.clear();

    for (final line in cssContents.split('\n')) {
      genContents += "\n    \" ${parseLine(line)} \"";
    }

    var importStatements = '';

    if (importsForCurrentAsset.isNotEmpty) {
      importStatements = importsForCurrentAsset.join("\n") + "\n\n";
    }

    genContents = "// ignore_for_file: non_constant_identifier_names\n"
        "\n// auto-generated. please don't edit this file\n\n"
        "$importStatements"
        "final GEN_STYLES_${genConstant}_CSS = \"\"$genContents";

    genContents = genContents + ";\n";

    await buildStep.writeAsString(genAssetId, genContents);
  }
}
