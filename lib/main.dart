import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Map App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  List<Marker> _markers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
      ),
      body: GoogleMap(
        onMapCreated: (controller) {
          _mapController = controller;
        },
        onTap: _addPinpoint,
        markers: Set.from(_markers),
        initialCameraPosition: CameraPosition(
          target: const LatLng(38.736946, -9.142685),
          zoom: 12,
        ),
      ),
    );
  }

  void _addPinpoint(LatLng latLng) async {
    var image = await _uploadImage();
    var dialogResult = await showDialog(
      context: context,
      builder: (context) => const PinpointDialog(),
    );
    if (dialogResult != null) {
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

  Future<String?> _uploadImage() async {
    var imageFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (imageFile != null) {
      var storageRef = FirebaseStorage.instance.ref().child('images/${DateTime.now()}.jpg');
      var uploadTask = storageRef.putFile(File(imageFile.path));
      var snapshot = await uploadTask.whenComplete(() {});
      var downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl.toString();
    }
    return null;
  }
}

class PinpointDialog extends StatefulWidget {
  const PinpointDialog({Key? key}) : super(key: key);

  @override
  _PinpointDialogState createState() => _PinpointDialogState();
}

class _PinpointDialogState extends State<PinpointDialog> {
  String? _name;
  String? _category;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Pinpoint'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: const InputDecoration(hintText: 'Name'),
            onChanged: (value) {
              setState(() {
                _name = value;
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            items: [
              DropdownMenuItem(child: const Text('Category 1'), value: 'Category 1'),
              DropdownMenuItem(child: const Text('Category 2'), value: 'Category 2'),
              DropdownMenuItem(child: const Text('Category 3'), value: 'Category 3'),
            ],
            onChanged: (value) {
              setState(() {
                _category = value;
              });
            },
            value: _category,
            decoration: const InputDecoration(hintText: 'Category'),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {'name': _name, 'category': _category});
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class Pinpoint {
  final LatLng location;
  final String? name;
  final String? category;
  final String? image;

  Pinpoint({required this.location, required this.name, required this.category, required this.image});
}
