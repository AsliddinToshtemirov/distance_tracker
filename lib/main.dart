
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';

import 'background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // Set to false in production
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Position? _currentPosition;
  Position? _previousPosition;
  double _distanceTraveled = 0.0;
  bool _isWaiting = false;
  Duration _waitingTime = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
_determinePosition();
    Workmanager().registerPeriodicTask(
      "locationTask",
      "periodicLocation",
      frequency: const Duration(minutes: 15), // Adjust frequency as needed
    );
  }
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;


    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {

      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {

        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {

      return Future.error(
          'Location permissions are permanently denied.');
    }



    Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        _currentPosition = position;
        if (_previousPosition != null) {
          double distance = Geolocator.distanceBetween(
            _previousPosition!.latitude,
            _previousPosition!.longitude,
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          );
          _distanceTraveled += distance;
        }
        double speed = position.speed;
        if (speed > 8.33) {
          _stopWaiting();
        } else {
          _startWaiting();
        }

        _previousPosition = _currentPosition;
      });
    });

  }



  void _startWaiting() {
    setState(() {
      _isWaiting = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _waitingTime += const Duration(seconds: 1);
        });
      });
    });
  }

  void _stopWaiting() {
    setState(() {
      _isWaiting = false;
      _timer?.cancel();
      // Reset waiting time
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Distance Traveled'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Text(
                'Distance Traveled: ${_distanceTraveled.toStringAsFixed(2)} meters',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                'Waiting Time: ${_waitingTime.toString().split('.')[0]}', // Display waiting time
                style: const TextStyle(fontSize: 16),
              ),
              ElevatedButton(
                onPressed: _isWaiting ? _stopWaiting : _startWaiting,
                child: Text(_isWaiting ? 'Resume' : 'Pause'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel timer when widget is disposed
    super.dispose();
  }
}

