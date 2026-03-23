import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:acrostics_maker/globals.dart';
import 'package:acrostics_maker/services/helpers.dart';

int deviceID = 0;
String deviceNumber = "";
String deviceModel = "";

class MyObject {
  String name;
  dynamic value;

  MyObject({required this.name, this.value});
}

enum MnemonicTypeID {
  anagram(1),
  mnemonic(2),
  number_major(3),
  peglist(4),
  number_letters(5);

  final int value;
  const MnemonicTypeID(this.value);
}

enum DB_Type_ID {
  DB_ACROSTICS(1),
  DB_MISC(2);

  final int value;
  const DB_Type_ID(this.value);
}

enum Op_Type_ID {
  NO_ACTION(1),
  INSERT(2),
  INSERT_SELECT(3),
  REPLACE(4),
  UPDATE(5),
  UPDATE_IN(6),
  DELETE(7),
  DELETE_IN(8),
  CREATE(9),
  RENAME_TABLE(10),
  ALTER_TABLE(11),
  DROP(12),
  CREATE_INDEX(13),
  DROP_INDEX(14),
  CHANGE_COLUMN(15),
  ADD_COLUMN(16),
  DROP_COLUMN(17),
  RENAME_COLUMN(18),
  CREATE_TRIGGERS(19),
  DROP_TRIGGERS(20),
  ADVANCED_SQLS(21),
  CREATE_USER(22),
  RENAME_MNEMONIC_TABLE(23),
  RENAME_MNEMONIC_TITLE(24),
  RENAME_MNEMONIC_TABLE_AND_TITLE(25),
  DELETE_INNER_JOIN(26),
  DROP_COLUMNS(27),
  ADD_COLUMNS(28),
  INSERT_TYPES(29),
  UPDATE_IMAGE(30),
  INSERT_UPDATE(31),
  UPDATE_NUMBERS(32),
  GET_ID_INSERT_MANY(33);

  final int value;
  const Op_Type_ID(this.value);
}

class SyncQuery {
  bool? IS_APP;
  int? Op_Type_ID;
  int? Op_ID;
  int? User_ID_Old;
  int DB_Type_ID;
  String Table_name;
  int Act_Type_ID;
  List<String> Cols;
  List<dynamic> Vals;
  dynamic Wheres;
  int? User_Action;
  dynamic Names;
  String? Entry;
  String? Entry_Old;

  //SyncQuery(IS_APP,User_ID_Old,DB_Type_ID,Table_name,Act_Type_ID,Cols,Vals,Wheres)
  SyncQuery(
    this.IS_APP,
    this.User_ID_Old,
    this.DB_Type_ID,
    this.Table_name,
    this.Act_Type_ID,
    this.Cols,
    this.Vals,
    this.Wheres,
    this.User_Action,
  );

  // Implement operator [] to get properties dynamically
  dynamic operator [](String key) {
    switch (key) {
      case 'IS_APP':
        return IS_APP;
      case 'Op_Type_ID':
        return Op_Type_ID;
      case 'Op_ID':
        return Op_ID;
      case 'User_ID_Old':
        return User_ID_Old;
      case 'DB_Type_ID':
        return DB_Type_ID;
      case 'Table_name':
        return Table_name;
      case 'Act_Type_ID':
        return Act_Type_ID;
      case 'Cols':
        return Cols;
      case 'Vals':
        return Vals;
      case 'Wheres':
        return Wheres;
      case 'User_Action':
        return User_Action;
      case 'Names':
        return Names;
      case 'Entry':
        return Entry;
      case 'Entry_Old':
        return Entry_Old;
      default:
        throw Exception('Property $key not found');
    }
  }

  // Implement operator []= to set properties dynamically
  void operator []=(String key, dynamic value) {
    switch (key) {
      case 'IS_APP':
        IS_APP = value;
        break;
      case 'Op_Type_ID':
        Op_Type_ID = value;
        break;
      case 'Op_ID':
        Op_ID = value;
        break;
      case 'User_ID_Old':
        User_ID_Old = value;
        break;
      case 'DB_Type_ID':
        DB_Type_ID = value;
        break;
      case 'Table_name':
        Table_name = value;
        break;
      case 'Act_Type_ID':
        Act_Type_ID = value;
        break;
      case 'Cols':
        Cols = value;
        break;
      case 'Vals':
        Vals = value;
        break;
      case 'Wheres':
        Wheres = value;
        break;
      case 'User_Action':
        User_Action = value;
        break;
      case 'Names':
        Names = value;
        break;
      case 'Entry':
        Entry = value;
        break;
      case 'Entry_Old':
        Entry_Old = value;
        break;
      default:
        throw Exception('Property $key not found or is read-only');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'IS_APP': IS_APP,
      'User_ID_Old': User_ID_Old,
      'DB_Type_ID': DB_Type_ID,
      'Table_name': Table_name,
      'Act_Type_ID': Act_Type_ID,
      'Cols': Cols,
      'Vals': Vals,
      'Wheres': Wheres,
      'User_Action': User_Action,
      'Names': Names,
      'Entry': Entry,
      'Entry_Old': Entry_Old,
    };
  }
}

class SyncOperation {
  int Op_Type_ID = 0;
  int Timestamp = 0;
  int Device_ID = 0;
  int User_ID = 0;
  List<SyncQuery> SYNCS = [];
  dynamic Image;
  SyncOperation(
    this.Op_Type_ID,
    this.Timestamp,
    this.Device_ID,
    this.User_ID,
    this.Image,
  );

  // Implement operator [] to get properties dynamically
  dynamic operator [](String key) {
    switch (key) {
      case 'Op_Type_ID':
        return Op_Type_ID;
      case 'Timestamp':
        return Timestamp;
      case 'Device_ID':
        return Device_ID;
      case 'User_ID':
        return User_ID;
      case 'SYNCS':
        return SYNCS;
      case 'Image':
        return Image;
      default:
        throw Exception('Property $key not found');
    }
  }

  // Implement operator []= to set properties dynamically
  void operator []=(String key, dynamic value) {
    switch (key) {
      case 'Op_Type_ID':
        Op_Type_ID = value;
        break;
      case 'Timestamp':
        Timestamp = value;
        break;
      case 'Device_ID':
        Device_ID = value;
        break;
      case 'User_ID':
        User_ID = value;
        break;
      case 'SYNCS':
        SYNCS = value;
        break;
      case 'Image':
        Image = value;
        break;
      default:
        throw Exception('Property $key not found or is read-only');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'Op_Type_ID': Op_Type_ID,
      'Timestamp': Timestamp,
      'Device_ID': Device_ID,
      'User_ID': User_ID,
      'SYNCS': SYNCS,
      'Image': Image,
    };
  }
}

class OperationSync {
  int Op_Type_ID = 0;
  int Timestamp = 0;
  int Device_ID = 0;
  int User_ID = 0;
  int? User_ID_Old;
  dynamic Names;
  dynamic Entry_Old;
  dynamic Entry;
  List<SyncQuery> REQUESTS = [];
  dynamic Image_Old;
  dynamic Image;
  OperationSync(
    this.Op_Type_ID,
    this.Timestamp,
    this.Device_ID,
    this.User_ID,
    this.User_ID_Old,
    this.Names,
    this.Entry_Old,
    this.Entry,
    this.Image_Old,
    this.Image,
  );

  Map<String, dynamic> toJson() {
    return {
      'Op_Type_ID': Op_Type_ID,
      'Timestamp': Timestamp,
      'Device_ID': Device_ID,
      'User_ID': User_ID,
      'User_ID_Old': User_ID_Old,
      'Names': Names,
      'Entry_Old': Entry_Old,
      'Entry': Entry,
      'REQUESTS': REQUESTS,
      'Image_Old': Image_Old,
      'Image': Image,
    };
  }
}

SyncQuery parseSyncQuery(SyncQuery query) {
  var propsParse = ["Cols", "Vals", "Wheres", "Names", "Entry_Old", "Entry"];
  for (var p = 0; p < propsParse.length; p++) {
    if (query[propsParse[p]] != null &&
        query[propsParse[p]].runtimeType == String) {
      while (HelpersService.isJSON(query[propsParse[p]]) &&
          query[propsParse[p]].runtimeType != dynamic) {
        query[propsParse[p]] = json.decode(query[propsParse[p]]);
      }
    }
  }
  return query;
}

Future<dynamic> autoSync(
  List<SyncQuery> queries,
  int opTypeId,
  int? userIdOld,
  List<dynamic> names,
  dynamic entryOld,
  dynamic entry,
  dynamic imageOld,
  dynamic imageNew,
) async {
  dynamic res = await onlineDoSyncTo(
    queries,
    opTypeId,
    userIdOld,
    names,
    entryOld,
    entry,
    imageOld,
    imageNew,
  );
  return res;
}

Future<dynamic> onlineDoSyncTo(
  List<SyncQuery> queries,
  int opTypeId,
  int? userIdOld,
  List<dynamic> names,
  dynamic entryOld,
  dynamic entry,
  dynamic imageOld,
  dynamic imageNew,
) async {
  debugPrint(
    "onlineDoSyncTo called, opTypeId=$opTypeId, imageOld NULL? = ${(imageOld == null)}, imageNew NULL? = ${(imageNew == null)}",
  );
  //showProgress(context, "Syncing to: Getting sync table entries, please wait...");
  http.Response response = http.Response("", 200);
  debugPrint("onlineDoSyncTo HERE 1");
  if (Globals.isAppOnline == false) {
    //hideProgress(context);
    Map<String, dynamic> retData = {
      "isSuccess": false,
      "results": "NOT ONLINE",
    };
    return retData;
  } else {
    if (imageNew != null &&
        (opTypeId != Op_Type_ID.UPDATE_IMAGE.value ||
            (queries.isNotEmpty &&
                queries[0].Act_Type_ID != Op_Type_ID.UPDATE_IMAGE.value))) {
      imageNew = null;
    }
    dynamic params = {};
    int guestUserId = 1;
    params["TIME_SYNCED"] = HelpersService.getCurrentTimestamp();
    params["USER_ID"] = guestUserId;
    params["Count_To_Sync_Queries"] = 0;
    params["Count_To_Request_Queries"] = 0;
    var timestamp = HelpersService.getCurrentTimestamp();
    debugPrint("onlineDoSyncTo HERE 2");
    if (kIsWeb == false) {
      //params.DEVICE_ID = Helpers.device.Device_Number;
    } else {
      params["DEVICE_ID"] = "358583050470700"; //SAMSUNG S4 GALAXY
    }
    var is_request = isRequest(userIdOld, guestUserId);
    if (is_request == false) {
      params["Count_To_Sync_Queries"] = queries.length;
      //sync_operation: Timestamp, OP_Type_ID, Device_ID, User_ID

      List<SyncOperation> params_sync = [
        SyncOperation(opTypeId, timestamp, deviceID, guestUserId, imageNew),
      ];
      for (var q = 0; q < queries.length; q++) {
        params_sync[0]["SYNCS"].add(parseSyncQuery(queries[q]));
      }
      List<Map<String, dynamic>> jsonParamsSync = [];
      for (var i = 0; i < params_sync.length; i++) {
        jsonParamsSync.add(params_sync[i].toJson());
      }
      params["params_sync"] = jsonParamsSync;
    } else {
      params["Count_To_Request_Queries"] = queries.length;
      List<OperationSync> params_request = [
        OperationSync(
          opTypeId,
          timestamp,
          deviceID,
          guestUserId,
          userIdOld,
          names,
          entryOld,
          entry,
          imageOld,
          imageNew,
        ),
      ];
      for (var q = 0; q < queries.length; q++) {
        params_request[0].REQUESTS.add(parseSyncQuery(queries[q]));
      }
      List<Map<String, dynamic>> jsonParamsRequest = [];
      for (var i = 0; i < params_request.length; i++) {
        jsonParamsRequest.add(params_request[i].toJson());
      }
      params["params_request"] = jsonParamsRequest;
    }

    debugPrint("SYNC TO PARAMS = ${json.encode(params)}");
    var url =
        "https://www.learnfactsquick.com/lfq_app_php/synchronize_to_ionic.php";
    //showProgress(context, "Syncing to: Posting sync entries to LFQ, please wait...");

    bool isRequestSuccess = true;

    try {
      response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(params),
      );
    } catch (e) {
      debugPrint("onlineDoSyncTo HERE 3 ERROR: ${e.toString()}");
      isRequestSuccess = false;
      Map<String, dynamic> retData = {
        "isSuccess": false,
        "results": "SERVER ERROR: ${e.toString()}",
      };
      return retData;
    }
    if (isRequestSuccess == true) {
      if (response.statusCode == 200) {
        Map<String, dynamic> data = Map<String, dynamic>.from(
          json.decode(response.body),
        );
        debugPrint("synchronize_to_ionic.php response = ${json.encode(data)}");
        var results = data["SUCCESS"] == true
            ? (is_request == true ? "Requested." : "Saved.")
            : data["ERROR"];
        Map<String, dynamic> retData = {
          "isSuccess": data["SUCCESS"],
          "results": results,
        };
        //hideProgress(context);
        return retData;
      } else {
        Map<String, dynamic> retData = {
          "isSuccess": false,
          "results": "SERVER NOT RESPONDING.",
        };
        return retData;
      }
    }
  }
}

bool isRequest(int? userIdOld, int userIdNew) {
  var ret = (userIdOld != null &&
      userIdOld != 0 &&
      int.parse(userIdNew.toString().trim()) !=
          int.parse(userIdOld.toString().trim()));
  debugPrint(
    "isRequest called, userIdOld = $userIdOld, userIdNew = $userIdNew ret = $ret",
  );
  return ret;
}
