import 'dart:io';

import 'package:prospect_client/src/cli/cli_runner.dart';

Future<void> main(List<String> arguments) async {
  exitCode = await CliRunner().run(arguments);
}
