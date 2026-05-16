import 'package:location/location.dart';
import 'location_module.dart';

class GpsLocationService implements LocationModule {
  final Location _location = Location();

  GpsLocationService() {
    _init();
  }

  Future<void> _init() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
  }

  @override
  Stream<LocationData> onLocationChanged() {
    return _location.onLocationChanged;
  }
}