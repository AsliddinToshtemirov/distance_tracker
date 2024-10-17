import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {

    Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);


    Position currentPosition = await Geolocator.getCurrentPosition();

    // Get previous position (if available)
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double? previousLatitude = prefs.getDouble('previousLatitude');
    double? previousLongitude = prefs.getDouble('previousLongitude');

    // Calculate distance if previous position is available
    if (previousLatitude != null && previousLongitude != null) {
      double distance = Geolocator.distanceBetween(
        previousLatitude,
        previousLongitude,
        currentPosition.latitude,
        currentPosition.longitude,
      );


      double totalDistance = prefs.getDouble('totalDistance') ?? 0.0;
      totalDistance += distance;
      prefs.setDouble('totalDistance', totalDistance);


    }


    prefs.setDouble('previousLatitude', currentPosition.latitude);
    prefs.setDouble('previousLongitude', currentPosition.longitude);

    return Future.value(true);
  });
}