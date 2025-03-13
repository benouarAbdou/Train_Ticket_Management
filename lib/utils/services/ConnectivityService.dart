import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxService {
  final _connectivity = Connectivity();
  final RxBool isOnline = true.obs;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _setupConnectivityStream();
  }

  Future<void> _initConnectivity() async {
    try {
      final List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();
      _updateConnectionStatus(results.first);
    } catch (e) {
      isOnline.value = false;
    }
  }

  void _setupConnectivityStream() {
    _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _updateConnectionStatus(results.first);
    });
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    isOnline.value = result != ConnectivityResult.none;
  }

  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }
}
