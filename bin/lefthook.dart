import 'dart:io';

import 'package:cli_util/cli_logging.dart';

import 'package:lefthook/download.dart';

void main(List<String> args) async {
  final logger = new Logger.standard();
  final executablePath = Platform.script.resolve('../.exec/lefthook').toFilePath();;

  await ensureExecutable(executablePath);

  final result = await Process.run(executablePath, args);
  if (result.exitCode != 0) {
    logger.stderr(result.stderr);
  } else {
    logger.stdout(result.stdout);
  }
}
