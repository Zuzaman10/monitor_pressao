import 'package:flutter/material.dart';

void main() {
  runApp(const MonitorPressaoApp());
}

class MonitorPressaoApp extends StatelessWidget {
  const MonitorPressaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitor de Pressão',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitor de Pressão'),
      ),
      body: const Center(
        child: Text(
          'App iniciado com sucesso!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}