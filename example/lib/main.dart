import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:treno/treno.dart' as treno;

void main() {
  treno.startLogger();
  runApp(MyApp());
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
                  var config = treno.Config("${directory.path}/asdf.db");
                  var db = treno.Db(config);
                  db.setKey("banana", "banana");
                  var response = db.getKey("banana");
                  // Scaffold.of(context).showSnackBar(
                  //     SnackBar(content: Text("Response $response")));
                  db.dispose();
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
