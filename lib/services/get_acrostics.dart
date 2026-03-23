import 'dart:convert';

import 'package:acrostics_maker/services/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

class GetAcrostics {
  static Future<List<dynamic>> getAllAcrosticTables(
      BuildContext context) async {
    List<dynamic> dropdownTables = [];
    bool isRequestSuccess = true;
    Response response = http.Response("", 200);
    try {
      response = await http.get(
        Uri.parse(
          'https://learnfactsquick.com/lfq_directory/php/edit_tables_get_tables.php',
        ),
      );
    } catch (e) {
      isRequestSuccess = false;
    }
    if (isRequestSuccess != true) {
      return [];
    } else {
      if (response.statusCode == 200) {
        // If the server returns a 200 OK response, parse the JSON data
        final Map<String, dynamic> data = json.decode(response.body);
        debugPrint("initiateAcrostics STATUS=200!!!");
        if (data["SUCCESS"] == true) {
          debugPrint("initiateAcrostics DONE SUCCESSFULLY");
          dropdownTables = List<dynamic>.from(data["TABLE_LIST"]);
          return dropdownTables;
        } else {
          debugPrint(
            "initiateAcrostics FAILED data['SUCCESS'] = ${data['SUCCESS']}",
          );
          await HelpersService.showPopup(
            context,
            title: FlutterI18n.translate(context, "PROMPT_ALERT"),
            message:
                "${FlutterI18n.translate(context, "ERROR_LOAD_ACROSTICS")}: ${data["ERROR"]}",
          );
          return [];
        }
      } else {
        //throw Exception('initiateMnemonics Failed to load data');
        await HelpersService.showPopup(
          context,
          title: FlutterI18n.translate(context, "PROMPT_ALERT"),
          message:
              "${FlutterI18n.translate(context, "NETWORK_ERROR")}: ${response.statusCode}",
        );
        return [];
      }
    }
  }

  static Future<List<dynamic>> getAcrosticTablesHaveAcrsotics(
      BuildContext context) async {
    List<dynamic> acrosticsTables = [];
    bool isRequestSuccess = true;
    Response response = http.Response("", 200);
    try {
      response = await http.get(
        Uri.parse(
          'https://learnfactsquick.com/lfq_directory/php/acrostics_tables_get_have_acrostics.php',
        ),
      );
    } catch (e) {
      isRequestSuccess = false;
    }
    if (isRequestSuccess != true) {
      return [];
    } else {
      if (response.statusCode == 200) {
        // If the server returns a 200 OK response, parse the JSON data
        final Map<String, dynamic> data = json.decode(response.body);
        debugPrint("initiateAcrostics STATUS=200!!!");
        if (data["SUCCESS"] == true) {
          debugPrint("initiateAcrostics DONE SUCCESSFULLY");
          acrosticsTables = List<dynamic>.from(data["TABLES"]);
          return acrosticsTables;
        } else {
          debugPrint(
            "initiateAcrostics FAILED data['SUCCESS'] = ${data['SUCCESS']}",
          );
          await HelpersService.showPopup(
            context,
            title: FlutterI18n.translate(context, "PROMPT_ALERT"),
            message:
                "${FlutterI18n.translate(context, "ERROR_LOAD_ACROSTICS")}: ${data["ERROR"]}",
          );
          return [];
        }
      } else {
        //throw Exception('initiateMnemonics Failed to load data');
        await HelpersService.showPopup(
          context,
          title: FlutterI18n.translate(context, "PROMPT_ALERT"),
          message:
              "${FlutterI18n.translate(context, "NETWORK_ERROR")}: ${response.statusCode}",
        );
        return [];
      }
    }
  }
}
