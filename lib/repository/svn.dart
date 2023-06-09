import 'dart:convert';
import 'dart:io';

import '../model/class/svn.dart';
import '../model/helper/svn.dart';
import 'assets.dart';

String shellArgumentEscape(String stdin) {
  var escapedStdin = stdin;
  final needEscapeChar = ['^', '&', '<', '>', '|', '"', ' '];
  for (final char in needEscapeChar) {
    escapedStdin = stdin.replaceAll(char, '^$char');
  }
  return escapedStdin;
}

class SvnRepository {
  SvnRepository(this.workingDir);
  final Directory workingDir;

  static Future<ProcessResult> runCommand({
    required Directory currentDirectory,
    required SvnExecs svnExecs,
    required List<String> args,
  }) async {
    final execPath = await AssetsRepository().getSvnExecPath(svnExecs);
    final process = await Process.run(
      execPath.path,
      args,
      workingDirectory: currentDirectory.path,
      stdoutEncoding: Encoding.getByName('utf-8'),
    );
    SvnHelper.handleSvnErr(process);
    return process;
  }

  Future<SvnRepositoryInfo> getRepositoryInfo() async {
    final process = await runCommand(
      currentDirectory: workingDir,
      svnExecs: SvnExecs.svn,
      args: ['info', '--xml'],
    );

    final stdout = process.stdout.toString();
    return SvnHelper.parseRepositoryInfo(stdout);
  }

  Future<List<SvnRevisionLog>> getRevisionsLog() async {
    final process = await runCommand(
      currentDirectory: workingDir,
      svnExecs: SvnExecs.svn,
      args: ['log', '-v', '--xml'],
    );

    final stdout = process.stdout.toString();
    final info = SvnHelper.parseRevisionInfo(stdout);

    // final infoList2Json = info.map((e) => e.toJson()).toList();
    // print(jsonEncode(infoList2Json));
    return info;
  }

  Future<List<SvnStatusEntry>> getSvnStatusEntries() async {
    final process = await runCommand(
      currentDirectory: workingDir,
      svnExecs: SvnExecs.svn,
      args: ['status', '--xml'],
    );

    final stdout = process.stdout.toString();
    return SvnHelper.parseStatusEntries(stdout);
  }

  Future<void> runStagingAll() async {
    await runCommand(
      currentDirectory: workingDir,
      svnExecs: SvnExecs.svn,
      args: ['add', '--force', './'],
    );
  }

  Future<void> runCommit(String commitMessage) async {
    await runCommand(
      currentDirectory: workingDir,
      svnExecs: SvnExecs.svn,
      args: ['commit', '-m', shellArgumentEscape(commitMessage)],
    );
  }
}
