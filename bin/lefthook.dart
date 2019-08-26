import 'dart:io';
import 'dart:async';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:system_info/system_info.dart';

const _LEFTHOOK_VERSION = '0.6.3';

void main(List<String> args) async {
  final logger = new Logger.standard();
  final executablePath = Platform.script.resolve('../.exec/lefthook').toFilePath();;

  await _ensureExecutable(executablePath);

  final result = await Process.run(executablePath, args);
  if (result.exitCode != 0) {
    logger.stderr(result.stderr);
  } else {
    logger.stdout(result.stdout);
  }
}

void _ensureExecutable(String targetPath, {bool force = false}) async {
  Logger logger = new Logger.standard();

  final fileAlreadyExist = await _isExecutableExist(targetPath);
  if (fileAlreadyExist && !force) {
    return;
  }

  final url = _resolveDownloadUrl();

  logger.stdout('Download executable for lefthook...');
  logger.stdout(url);

  final file = await _downloadFile(url);

  logger.stdout('Download complete');
  logger.stdout('');
  logger.stdout('Extracting...');

  final extracted = _exctractFile(file);

  logger.stdout('Extracted');
  logger.stdout('');
  logger.stdout('Saving executable file...');
  await _saveFile(targetPath, extracted);

  logger.stdout('Saved to ${targetPath}');
  logger.stdout('');

  await _installLefthook(targetPath, logger);

  logger.stdout('All done!');
}

String _resolveDownloadUrl() {
  String getOS() {
    if (Platform.isLinux) {
      return 'Linux';
    }

    if (Platform.isMacOS) {
      return 'MacOS';
    }

    if (Platform.isWindows) {
      return 'Windows';
    }

    throw new Error();
  }

  String getArchitecture() {
    final arch = SysInfo.kernelArchitecture;

    if (arch == 'x86_64') {
      return arch;
    }

    // TODO: check for i386

    throw new Error();
  }

  final os = getOS();
  final architecture = getArchitecture();

  return 'https://github.com/Arkweid/lefthook/releases/download/v${_LEFTHOOK_VERSION}/lefthook_${_LEFTHOOK_VERSION}_${os}_${architecture}.gz';
}

Future<List<int>> _downloadFile(String url) async {
  HttpClient client = new HttpClient();
  final request = await client.getUrl(Uri.parse(url));
  final response = await request.close();

  final downloadData = List<int>();
  final completer = new Completer();
  response.listen((d) => downloadData.addAll(d), onDone: completer.complete);
  await completer.future;

  return downloadData;
}

List<int> _exctractFile(List<int> downloadedData) {
  return GZipDecoder().decodeBytes(downloadedData);
}

Future<void> _saveFile(String targetPath, List<int> data) async {
  Future<void> makeExecutable(File file) async {
    if (Platform.isWindows) {
      // TODO: write code for Windows case
      throw new Exception("Can' t set executable persmissions on Windows");
    }

    final result = await Process.run("chmod", ["u+x", file.path]);

    if (result.exitCode != 0) {
      throw new Exception(result.stderr);
    }
  }

  final executableFile = new File(targetPath);
  await executableFile.create(recursive: true);
  await executableFile.writeAsBytes(data);
  await makeExecutable(executableFile);
}

Future<void> _installLefthook(String executablePath, Logger logger) async {
  final result = await Process.run(executablePath, ["install", '-f']);

  if (result.exitCode != 0) {
    logger.stderr(result.stderr);
    throw new Exception(result.stderr);
  }

  logger.stdout(result.stdout);
}

Future<bool> _isExecutableExist(String executablePath) async {
  return new File(executablePath).exists();
}
