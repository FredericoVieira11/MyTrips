import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMaps extends StatefulWidget {
  String tripId;

  GoogleMaps({this.tripId});
  @override
  _GoogleMapsState createState() => _GoogleMapsState();
}

class _GoogleMapsState extends State<GoogleMaps> {

  Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {};
  CameraPosition cameraPosition = CameraPosition(
      target: LatLng(41.235553, -8.626603),
      zoom: 18
  );
  Firestore _firestore = Firestore.instance;

  createMap(GoogleMapController googleMapController){
    _controller.complete(googleMapController);
  }

  addMarkers(LatLng latLng) async{
    List<Placemark> addressList = await Geolocator()
        .placemarkFromCoordinates(latLng.latitude, latLng.longitude);

    if(addressList != null && addressList.length > 0){

      Placemark address = addressList[0];
      //String street = address.thoroughfare;

      Marker marker = Marker(markerId: MarkerId("marcador-${latLng.latitude}-${latLng.longitude}"),
          position: latLng,
          infoWindow: InfoWindow(
              title: address.thoroughfare
          )
      );

      setState(() {
        _markers.add(marker);

        Map<String, dynamic> trip = Map();
        trip["title"] = address.thoroughfare;
        trip["latitude"] = latLng.latitude;
        trip["longitude"] = latLng.longitude;

        _firestore.collection("Trips").add(trip);
      });

    }
  }

  moveCamera() async{

    GoogleMapController googleMapController = await _controller.future;
    googleMapController.animateCamera(
        CameraUpdate.newCameraPosition(
            cameraPosition
        )
    );
  }

  addListenerLocation(){

    var geolocator = Geolocator();
    var localOptions = LocationOptions(accuracy: LocationAccuracy.high);
    geolocator.getPositionStream(localOptions).listen((Position position){
      setState(() {
        cameraPosition = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 18
        );
        moveCamera();
      });
    });
  }

  retrieveTripById(String tripId) async{
    if(tripId != null){
      //show marker for trip id
      DocumentSnapshot documentSnapshot = await _firestore.collection("Trips").document(tripId).get();
      var data = documentSnapshot.data;
      String title = data["title"];
      LatLng latLng = LatLng(
          data["latitude"],
          data["longitude"]
      );

      setState(() {

        Marker marker = Marker(markerId: MarkerId("marcador-${latLng.latitude}-${latLng.longitude}"),
            position: latLng,
            infoWindow: InfoWindow(
                title: title
            )
        );

        _markers.add(marker);
        cameraPosition = CameraPosition(
          target: latLng,
          zoom: 18
        );
        moveCamera();
      });
    }else {
      addListenerLocation();
    }
  }

  @override
  void initState() {
    super.initState();

    retrieveTripById(widget.tripId);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Google Map"),
      ),
      body: GoogleMap(
        markers: _markers,
        mapType: MapType.normal,
        initialCameraPosition: cameraPosition,
        onMapCreated: createMap,
        onLongPress: addMarkers,
      ),
    );
  }
}
