import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class HomePage extends StatelessWidget {
  final dbRef = FirebaseDatabase.instance.ref("users");

  HomePage({super.key});

  void insertData() {
    dbRef.push().set({"name": "Jerwil", "age": 22});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Realtime DB Test")),
      body: Center(
        child: ElevatedButton(
          onPressed: insertData,
          child: Text("Insert Data"),
        ),
      ),
    );
  }
}
