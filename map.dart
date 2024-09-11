import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DeliveryMapSample(),
    );
  }
}

class DeliveryMapSample extends StatefulWidget {
  const DeliveryMapSample({Key? key}) : super(key: key);

  @override
  State<DeliveryMapSample> createState() => DeliveryMapSampleState();
}

class DeliveryMapSampleState extends State<DeliveryMapSample> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  
  LatLng _currentLocation = const LatLng(37.42796133580664, -122.085749655962);
  List<LatLng> _orderLocations = [];

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        mapType: MapType.hybrid,
        initialCameraPosition: _initialPosition,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: _markers,
        polylines: _polylines,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Align(
            alignment: Alignment.bottomLeft,
            child: FloatingActionButton(
              onPressed: _addCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.bottomLeft,
            child: FloatingActionButton(
              onPressed: _addOrder,
              child: const Icon(Icons.add_location),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addCurrentLocation() async {
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation,
          infoWindow: const InfoWindow(title: 'Current Location'),
        ),
      );
    });

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(_currentLocation));
  }

  Future<void> _addOrder() async {
    // Simulating new order location
    final newOrderLocation = LatLng(
      _currentLocation.latitude + ((_orderLocations.length + 1) * 0.01),
      _currentLocation.longitude + ((_orderLocations.length + 1) * 0.01),
    );

    setState(() {
      _orderLocations.add(newOrderLocation);
      _markers.add(
        Marker(
          markerId: MarkerId('order_${_orderLocations.length}'),
          position: newOrderLocation,
          infoWindow: InfoWindow(title: 'Order ${_orderLocations.length}'),
        ),
      );

      // Generate a route with multiple waypoints
      List<LatLng> routePoints = _generateRoute(_currentLocation, newOrderLocation);

      // Draw the route
      _polylines.add(
        Polyline(
          polylineId: PolylineId('route_${_orderLocations.length}'),
          color: Colors.blue,
          points: routePoints,
          width: 5,
        ),
      );
    });
  }

  List<LatLng> _generateRoute(LatLng start, LatLng end) {
    List<LatLng> route = [start];
    
    // Number of waypoints
    int numWaypoints = 3 + Random().nextInt(3); // 3 to 5 waypoints
    
    for (int i = 0; i < numWaypoints; i++) {
      double lat = start.latitude + (end.latitude - start.latitude) * (i + 1) / (numWaypoints + 1);
      double lng = start.longitude + (end.longitude - start.longitude) * (i + 1) / (numWaypoints + 1);
      
      // Add some randomness to simulate streets
      lat += (Random().nextDouble() - 0.5) * 0.002;
      lng += (Random().nextDouble() - 0.5) * 0.002;
      
      route.add(LatLng(lat, lng));
    }
    
    route.add(end);
    return route;
  }
}