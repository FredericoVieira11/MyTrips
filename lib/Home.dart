import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'GoogleMaps.dart';


class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _controller = StreamController<QuerySnapshot>.broadcast();
  Firestore _firestore = Firestore.instance;

  addLocal() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => GoogleMaps()));
  }

  openMap(String tripId) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => GoogleMaps(tripId: tripId,)));
  }

  excludeTrip(String tripId) {
    _firestore.collection("Trips").document(tripId).delete();
  }

  addListenerTrips(){

    final stream = _firestore.collection("Trips")
        .snapshots();


    stream.listen((dados){
      _controller.add(dados);
    });
  }

  @override
  void initState() {
    super.initState();

    addListenerTrips();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Trips"),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        backgroundColor: Color(0xff0066cc),
        onPressed: () {
          addLocal();
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _controller.stream,
        builder: (context, snapshot){
          switch(snapshot.connectionState){
            case ConnectionState.none:
            case ConnectionState.waiting:
            case ConnectionState.active:
            case ConnectionState.done:

              QuerySnapshot querySnapshot = snapshot.data;
              List<DocumentSnapshot> trips = querySnapshot.documents.toList();

              return Column(
                children: <Widget>[
                  Expanded(
                    child: ListView.builder(
                        itemCount: trips.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot item = trips[index];
                          String title = item["title"];
                          String tripId = item.documentID;

                          return GestureDetector(
                            onTap: () {
                              openMap(tripId);
                            },
                            child: Card(
                              child: ListTile(
                                title: Text(title),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    GestureDetector(
                                      onTap: () {
                                        excludeTrip(tripId);
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Icon(
                                          Icons.remove_circle,
                                          color: Colors.red,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                  )
                ],
              );

              break;
          }
        },
      ),
    );
  }
}
