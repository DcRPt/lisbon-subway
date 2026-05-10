import 'package:cmproject/connectivity_module.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService extends ConnectivityModule {
  @override
  Future<bool> checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    return result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi;
  }
}