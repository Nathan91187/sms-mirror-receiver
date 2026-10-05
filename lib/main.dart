import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SmsMirrorDisplayApp());
}

class SmsMirrorDisplayApp extends StatelessWidget {
  const SmsMirrorDisplayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const SmsDisplayScreen(),
    );
  }
}

class SmsDisplayScreen extends StatefulWidget {
  const SmsDisplayScreen({super.key});

  @override
  State<SmsDisplayScreen> createState() => _SmsDisplayScreenState();
}

class _SmsDisplayScreenState extends State<SmsDisplayScreen> {
  final DatabaseReference messagesRef =
  FirebaseDatabase.instance.ref('pendingMessages');

  final List<Map<String, dynamic>> messages = [];

  StreamSubscription<DatabaseEvent>? _addedSubscription;
  StreamSubscription<DatabaseEvent>? _removedSubscription;

  @override
  void initState() {
    super.initState();

    _addedSubscription = messagesRef.onChildAdded.listen((event) {
      final data =
      Map<String, dynamic>.from(event.snapshot.value as Map);

      final message = {
        'id': event.snapshot.key,
        'sender': data['sender'],
        'body': data['body'],
        'timestamp': data['timestamp'],
      };

      setState(() {
        messages.insert(0, message);
      });
    });

    _removedSubscription = messagesRef.onChildRemoved.listen((event) {
      final removedId = event.snapshot.key;

      setState(() {
        messages.removeWhere(
              (message) => message['id'] == removedId,
        );
      });
    });
  }

  @override
  void dispose() {
    _addedSubscription?.cancel();
    _removedSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Mirror'),
      ),
      body: messages.isEmpty
          ? const Center(
        child: Text('Waiting for payment SMS...'),
      )
          : ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];

          return ListTile(
            title: Text(message['sender']),
            subtitle: Text(message['body']),
          );
        },
      ),
    );
  }
}