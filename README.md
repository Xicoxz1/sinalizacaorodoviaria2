# sinalizacao_rodoviaria

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapScreen extends StatefulWidget {
@override
_MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
GoogleMapController _mapController;
List<Marker> _markers = [];

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: Text('Map'),
),
body: GoogleMap(
onMapCreated: (controller) {
_mapController = controller;
},
onTap: _addPinpoint,
markers: Set.from(_markers),
initialCameraPosition: CameraPosition(
target: LatLng(38.736946, -9.142685),
zoom: 12,
),
),
);
}

void _addPinpoint(LatLng latLng) async {
var image = await _uploadImage();
var dialogResult = await showDialog(
context: context,
builder: (context) => PinpointDialog(),
);
if (dialogResult != null){
var pinpoint = Pinpoint(
location: latLng,
name: dialogResult['name'],
category: dialogResult['category'],
image: image,
);
var marker = Marker(
markerId: MarkerId(latLng.toString()),
position: latLng,
infoWindow: InfoWindow(
title: pinpoint.name,
snippet: pinpoint.category,
),
);
setState(() {
_markers.add(marker);
});
FirebaseFirestore.instance.collection('pinpoints').add({
'name': pinpoint.name,
'category': pinpoint.category,
'latitude': latLng.latitude,
'longitude': latLng.longitude,
'image': pinpoint.image,
});
}
}

Future<String> _uploadImage() async {
var imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
var storageRef = FirebaseStorage.instance.ref().child('images/${DateTime.now()}.jpg');
var uploadTask = storageRef.putFile(imageFile);
var downloadUrl = await (await uploadTask).ref.getDownloadURL();
return downloadUrl.toString();
}
}

class PinpointDialog extends StatefulWidget {
@override
_PinpointDialogState createState() => _PinpointDialogState();
}

class _PinpointDialogState extends State<PinpointDialog> {
String _name;
String _category;

@override
Widget build(BuildContext context) {
return AlertDialog(
title: Text('Add Pinpoint'),
content: Column(
mainAxisSize: MainAxisSize.min,
children: [
TextField(
decoration: InputDecoration(hintText: 'Name'),
onChanged: (value) {
setState(() {
_name = value;
});
},
),
SizedBox(height: 16),
DropdownButtonFormField(
items: [
DropdownMenuItem(child: Text('Category 1'), value: 'Category 1'),
DropdownMenuItem(child: Text('Category 2'), value: 'Category 2'),
DropdownMenuItem(child: Text('Category 3'), value: 'Category 3'),
],
onChanged: (value) {
setState(() {
_category = value;
});
},
value: _category,
decoration: InputDecoration(hintText: 'Category'),
),
],
),
actions: [
FlatButton(
onPressed: () {
Navigator.pop(context);
},
child: Text('Cancel'),
),
FlatButton(
onPressed: () {
Navigator.pop(context, {'name': _name, 'category': _category});
},
child: Text('Add'),
),
],
);
}
}

class Pinpoint {
final LatLng location;
final String name;
final String category;
final String image;

Pinpoint({this.location, this.name, this.category, this.image});
}