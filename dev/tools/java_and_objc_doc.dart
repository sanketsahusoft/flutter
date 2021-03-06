// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;

const String kDocRoot = 'dev/docs/doc';

/// This script downloads an archive of Javadoc and objc doc for the engine from
/// the artifact store and extracts them to the location used for Dartdoc.
Future<Null> main(List<String> args) async {
  final String engineVersion =
      new File('bin/internal/engine.version').readAsStringSync().trim();

  final String javadocUrl =
      'https://storage.googleapis.com/flutter_infra/flutter/$engineVersion/android-javadoc.zip';
  generateDocs(javadocUrl, 'javadoc', 'io/flutter/view/FlutterView.html');

  final String objcdocUrl =
      'https://storage.googleapis.com/flutter_infra/flutter/$engineVersion/ios-objcdoc.zip';
  generateDocs(
      objcdocUrl, 'objcdoc', 'objc/Classes/FlutterViewController.html');
}

Future<Null> generateDocs(
    final String url, String docName, String checkFile) async {
  final http.Response response = await http.get(url);

  final Archive archive = new ZipDecoder().decodeBytes(response.bodyBytes);

  final Directory output = new Directory('$kDocRoot/$docName');
  print('Extracing $docName to ${output.path}');
  output.createSync(recursive: true);

  for (ArchiveFile af in archive) {
    if (af.isFile) {
      final File file = new File('${output.path}/${af.name}');
      file.createSync(recursive: true);
      file.writeAsBytesSync(af.content);
    }
  }

  final File testFile = new File('${output.path}/$checkFile');
  if (!testFile.existsSync()) {
    print('Expected file ${testFile.path} not found');
    exit(1);
  }
  print('$docName ready to go!');
}
