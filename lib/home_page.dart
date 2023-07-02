import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Stream<QuerySnapshot> users =
      FirebaseFirestore.instance.collection('users').snapshots();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cloud Firestore Demo'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Read Data From Cloud Firestore',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            Container(
              height: 250,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: StreamBuilder<QuerySnapshot>(
                stream: users,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('something went wrong!');
                  } else if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Text('Loading');
                  } else {
                    final data = snapshot.requireData;
                    return ListView.builder(
                      itemBuilder: (context, index) {
                        return Text(
                            'My Name is ${data.docs[index]['name']} and I am ${data.docs[index]['age']}');
                      },
                      itemCount: data.size,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
