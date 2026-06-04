import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  // Default center: Brunei (Gadong area)
  LatLng _currentMapPosition = const LatLng(4.9031, 114.9149);
  late GoogleMapController _mapController;

  // Define the brand color
  final Color navyBlue = const Color(0xFF1B263B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick Location", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: navyBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _currentMapPosition),
              style: ElevatedButton.styleFrom(
                backgroundColor: navyBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("CONFIRM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          // THE ACTUAL GOOGLE MAP
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _currentMapPosition, zoom: 15),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) => _currentMapPosition = position.target,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
          ),

          // STATIC CENTER PIN
          Center(
            child: Padding(
              // FIXED: Changed .bottom to .only(bottom: ...)
              padding: const EdgeInsets.only(bottom: 35),
              child: Icon(Icons.location_on, color: navyBlue, size: 50),
            ),
          ),

          Positioned(
            bottom: 30, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1
                    )
                  ]
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: navyBlue),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                        "Move the map to center the pin on the property location",
                        style: TextStyle(fontSize: 12, color: Colors.black87)
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}