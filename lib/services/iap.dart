import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class IAP {
  static StreamSubscription<List<PurchaseDetails>>? purchaseSubscription;

  static Future<void> restorePurchases() async {
    debugPrint("restorePurchases called");
    if (kIsWeb == true) {
      //MyHomeState().showPopup(context, "CAN'T RESTORE ADS ON WEB!");
      debugPrint("Cant restore purchases on web-app.");
    } else {
      //setState(() {
      //  isRestoring = true;
      //});
      final InAppPurchase iapInstance = InAppPurchase.instance;
      bool isAvailable = await iapInstance.isAvailable();
      if (isAvailable) {
        // Fetch past purchases
        try {
          await iapInstance.restorePurchases();
        } catch (e) {
          debugPrint("Failed to restore purchases");
          return;
        }
      }
    }
  }

  static Future<void> showSuccessThanksBuy({
    required BuildContext context,
    required VoidCallback onPurchaseComplete,
  }) async {
    debugPrint("showSuccessThanksBuy called");
    if (!context.mounted) return;

    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            elevation: 10,
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 30),
                SizedBox(width: 10),
                Text(
                  FlutterI18n.translate(context, "PROMPT_SUCCESS"),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    FlutterI18n.translate(context, "THANK_YOU_NO_ADS"),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                SizedBox(height: 20),
                Icon(Icons.celebration, color: Colors.orange, size: 40),
              ],
            ),
            actions: <Widget>[
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  onPressed: () {
                    // Execute your logic when the user confirms
                    onPurchaseComplete();
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text(
                    FlutterI18n.translate(context, "PROMPT_LETS_GO"),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 10),
            ],
          );
        });
  }
}
