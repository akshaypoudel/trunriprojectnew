import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class InternetChecker {
  static final InternetChecker _instance = InternetChecker._internal();
  factory InternetChecker() => _instance;
  InternetChecker._internal();

  void startMonitoring() {
    Connectivity().onConnectivityChanged.listen((status) async {
      if (status == ConnectivityResult.none) {
        _showNoInternetDialog();
      } else {
        bool hasInternet = await _hasActualInternet();
        if (!hasInternet) {
          _showNoInternetDialog();
        } else {
          if (Get.isDialogOpen ?? false) {
            Get.back();
          }
        }
      }
    });
  }

  Future<bool> _hasActualInternet() async {
    try {
      final result = await http
          .get(Uri.parse("https://www.google.com"))
          .timeout(const Duration(seconds: 5));
      return result.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void _showNoInternetDialog() {
    if (!(Get.isDialogOpen ?? false)) {
      Get.dialog(
        barrierDismissible: false,
        Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon at top
                Container(
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    color: Colors.deepOrange,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                const Text(
                  "No Internet Connection",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Description
                const Text(
                  "Please connect to the internet to continue using the app.",
                  style: TextStyle(fontSize: 15, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Retry button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text(
                      "Retry",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      bool hasInternet = await _hasActualInternet();
                      if (hasInternet) {
                        Get.back();
                      } else {
                        Get.closeAllSnackbars();
                        Get.snackbar(
                          "Still No Connection",
                          "Please check your internet settings.",
                          backgroundColor: Colors.orange.shade50,
                          colorText: Colors.black,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
