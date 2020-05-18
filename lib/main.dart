import 'package:flutter/material.dart';
import 'package:list_view_paginated/list_view_paginated.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ExampleApp(),
    );
  }
}

class ExampleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListViewPaginated<int>(
          loadMore: (int page) async {
            await Future.delayed(Duration(milliseconds: 1000));
            return Future.value(
                List.generate(10, (int p) => (page * 10) + p++));
          },
          itemBuilder: (model) => ListTile(
                title: Text('$model'),
              )),
    );
  }
}
