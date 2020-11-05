import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:treno/treno.dart' as treno;

void main() {
  treno.startLogger();
  runApp(MyApp());
}

Future<String> fetchDb(path) async {
  var config = treno.Config("$path/asdf.db");
  var db = treno.Db(config);
  db.setKey("banana", "banana");
  var response = db.getKey("banana");
  db.dispose();
  return response;
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Builder(
          builder: (BuildContext context) {
            return Center(
              child: MaterialButton(
                child: Text("Try me!"),
                onPressed: () async {
                  final directory = await getApplicationDocumentsDirectory();
                  var response = await compute(fetchDb, directory.path);
                  Scaffold.of(context).showSnackBar(
                      SnackBar(content: Text("Response $response")));
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
