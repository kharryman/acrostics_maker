import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

bool isLoading = false;

void showProgress(BuildContext context, message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white, // Background color
            borderRadius: BorderRadius.circular(10.0),
          ),
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
              SizedBox(height: 16.0),
              Text(
                message,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.0,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void hideProgress(BuildContext context) {
  print("hideProgress called");
  Navigator.of(context, rootNavigator: true).pop();
  isLoading = false;
}

Future<void> showPopup(BuildContext context, String message) async {
  print("showPopup called");
  return showDialog<void>(
    context: context,
    barrierDismissible:
        false, // Prevent dismissing by tapping outside the popup
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(FlutterI18n.translate(context, "PROMPT_ALERT")),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the popup
            },
            child: Text(FlutterI18n.translate(context, "CLOSE")),
          ),
        ],
      );
    },
  );
}

Future<void> showConfirm(BuildContext context, String title, String message,
    String cancelText, String okText, Function callback) async {
  print("showshowConfirm called");
  return showDialog<void>(
    context: context,
    barrierDismissible:
        false, // Prevent dismissing by tapping outside the popup
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.70,
            child: SingleChildScrollView(child: Html(data: message))),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the popup
            },
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () {
              callback();
            },
            child: Text(okText),
          )
        ],
      );
    },
  );
}
