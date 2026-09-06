// ignore_for_file: unused_local_variable

import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final packageName = input.packageName;
  //   final cbuilder = CBuilder.library(
  //     name: packageName,
  //     assetName: '${packageName}_bindings_generated.dart',
  //     sources: ['src/$packageName.c'],
  //   );
  //   await cbuilder.run(
  //     input: input,
  //     output: output,
  //     logger: Logger('')
  //       ..level = .ALL
  //       ..onRecord.listen((record) => print(record.message)),
  //   );
  });
}
