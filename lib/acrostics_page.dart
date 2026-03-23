// results.dart

import 'dart:convert';
import 'dart:typed_data';
//import 'dart:math';

//import 'package:flutter/foundation.dart';
import 'package:acrostics_maker/services/ads.dart';
import 'package:acrostics_maker/services/get_acrostics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:http/http.dart';
import 'package:acrostics_maker/globals.dart';
import 'package:acrostics_maker/components/menu.dart';
import 'package:acrostics_maker/services/helpers.dart';

import 'main.dart';
import 'package:http/http.dart' as http;

// ignore: must_be_immutable
class AcrosticsPage extends StatefulWidget {
  AcrosticsPage();

  @override
  // ignore: library_private_types_in_public_api
  AcrosticsPageState createState() => AcrosticsPageState();
}

class AcrosticsPageState extends State<AcrosticsPage> {
  bool areTablesLoaded = false;
  List<dynamic> dropdownTables = [];
  dynamic selectedTable;
  List<dynamic> acrosticsData = [];

  ///List<TableRow> acrosticRows = [];

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await initiateAcrostics(context);
      areTablesLoaded = true;
      setState(() {});
    });
  }

  Future<void> initiateAcrostics(context) async {
    debugPrint("initiateAcrostics called");
    dropdownTables = await GetAcrostics.getAcrosticTablesHaveAcrsotics(context);
    debugPrint(
        "initiateAcrostics GOT dropdownTables = ${json.encode(dropdownTables)}");
    if (dropdownTables.isNotEmpty) {
      String? gotSelectedTableString =
          await HelpersService.getData("SELECTED_TABLE");
      if (gotSelectedTableString != null) {
        dynamic gotSelectedTable = json.decode(gotSelectedTableString);
        selectedTable = dropdownTables.firstWhere(
            (dynamic selTbl) => selTbl["TABLE"] == gotSelectedTable["TABLE"],
            orElse: () => null);
      }
      selectedTable ??= dropdownTables[0];
      await getAcrostics(context);
    }
  }

  Future<void> getAcrostics(context) async {
    debugPrint("getAcrostics called");
    acrosticsData = [];
    bool isRequestSuccess = true;
    Response response = http.Response("", 200);
    try {
      String progressMessage = FlutterI18n.translate(
          context, "LOADING_ACROSTICS",
          translationParams: {"tBL": selectedTable["TABLE"]});
      HelpersService.showProgress(context, progressMessage);
      var params = {
        "select_table": selectedTable["TABLE"],
        "select_sort_by_categories": [],
        "one_category_options": [],
        "is_show_all_categories": true,
        "is_information": true,
        "is_acrostics": true,
        "is_images": true,
        "is_mnemonics": "false",
        "is_information_complete": false,
        "is_acrostics_complete": true,
        "is_images_complete": false,
        "is_mnemonics_complete": false,
        "is_information_incomplete": false,
        "is_acrostics_incomplete": false,
        "is_images_incomplete": false,
        "is_mnemonics_incomplete": false,
        "is_read": false
      };
      response = await http.post(
          Uri.parse(
            'https://learnfactsquick.com/lfq_directory/php/acrostics_tables_show_table.php',
          ),
          body: json.encode(params));
    } catch (e) {
      isRequestSuccess = false;
    }
    HelpersService.hideProgress(context);
    if (isRequestSuccess == false) {
      Globals.isAppOnline = false;
      await MyHomeState().doNetworkChange();
    } else {
      if (response.statusCode == 200) {
        // If the server returns a 200 OK response, parse the JSON data
        final Map<String, dynamic> data = json.decode(response.body);
        debugPrint("getAcrostics STATUS=200!!!");
        if (data["SUCCESS"] == true) {
          //debugPrint("getAcrostics DONE SUCCESSFULLY, data = ${json.encode(data)}");
          acrosticsData = List<dynamic>.from(data["ROWS"]);
          debugPrint("GOT acrosticsData.length = ${acrosticsData.length}");
          //FILTER OUT BAD ACROSTICS:
          acrosticsData = acrosticsData
              .where((dynamic acrostic) =>
                  HelpersService.checkIsAcrostic(
                      acrostic["Name"], acrostic["Acrostics"]) ==
                  true)
              .toList();
        } else {
          debugPrint(
            "getAcrostics FAILED data['SUCCESS'] = ${data['SUCCESS']}",
          );
          await HelpersService.showPopup(
            context,
            title: FlutterI18n.translate(context, "PROMPT_ALERT"),
            message:
                "${FlutterI18n.translate(context, "ERROR_LOAD_EXAMPLE_ACROSTICS")}: ${data["ERROR"]}",
          );
        }
      } else {
        //throw Exception('initiateMnemonics Failed to load data');
        await HelpersService.showPopup(
          context,
          title: FlutterI18n.translate(context, "PROMPT_ALERT"),
          message:
              "${FlutterI18n.translate(context, "NETWORK_ERROR")}: ${response.statusCode}",
        );
      }
    }
  }

  updateSelf() {
    debugPrint("AcrosticsPageState updateSelf called");
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double promptFontSize =
        (screenWidth * 0.020 + 5) < 12 ? 12 : (screenWidth * 0.020 + 5);
    double big1FontSize =
        (screenWidth * 0.018 + 4) < 15 ? 15 : (screenWidth * 0.018 + 4);
    double big2FontSize =
        (screenWidth * 0.016 + 3) < 12 ? 12 : (screenWidth * 0.016 + 3);
    return WillPopScope(
        onWillPop: () async {
          AdService.showInterstitialAd(() {
            Navigator.pop(context);
          });
          return false; // prevent default pop (since we already popped)
        },
        child: areTablesLoaded != true
            ? Padding(
                padding: const EdgeInsets.all(50.0),
                child: CircularProgressIndicator(
                  backgroundColor: Colors.lightBlue[50],
                ),
              )
            : Scaffold(
                appBar: AppBar(
                  title: Text(
                    FlutterI18n.translate(context, "EXAMPLE_ACROSTICS"),
                    style: TextStyle(
                        fontSize: promptFontSize, fontWeight: FontWeight.bold),
                  ),
                  centerTitle: true,
                  actions: <Widget>[
                    Menu(
                      context: context,
                      page: 'acrostics_page',
                      updateParent: () {},
                    ),
                  ],
                ),
                body: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Container(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                textAlign: TextAlign.center,
                                softWrap: true,
                                "${FlutterI18n.translate(context, "SELECT_TABLE")}:(${dropdownTables.length})",
                                style: TextStyle(
                                    fontSize: promptFontSize,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              width: screenWidth *
                                  0.5, // Set the width of the dropdown
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.white,
                              ),
                              child: DropdownButton<dynamic>(
                                isExpanded:
                                    true, // Expands the dropdown to fill the width
                                value: selectedTable,
                                underline: SizedBox.shrink(),
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                ), // Custom arrow icon on the right
                                iconSize: 24, // Size of the dropdown arrow
                                dropdownColor: Colors.white,
                                onChanged: (dynamic newValue) async {
                                  debugPrint("Table changed! to $newValue");

                                  selectedTable = dropdownTables!
                                      .where(
                                        (dynamic selTbl) =>
                                            selTbl["TABLE"] ==
                                            newValue["TABLE"],
                                      )
                                      .toList()[0];
                                  debugPrint(
                                    "SET selectedTable = ${json.encode(selectedTable)}",
                                  );
                                  await HelpersService.setData("SELECTED_TABLE",
                                      json.encode(selectedTable));
                                  await getAcrostics(context);
                                  setState(() {});
                                },
                                items: dropdownTables == null
                                    ? []
                                    : dropdownTables!
                                        .map<DropdownMenuItem<dynamic>>((
                                        dynamic value,
                                      ) {
                                        return DropdownMenuItem<dynamic>(
                                          value: value,
                                          child: Text(
                                            "${HelpersService.prettify(value["TABLE"])} (${value["COUNT_COMPLETED"]})",
                                            style: TextStyle(
                                              fontSize: promptFontSize,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                              ),
                            ),
                          ],
                        ),
                        Divider(
                          height: 0.5,
                          thickness: 2,
                        ),
                        Expanded(
                            child: ListView.builder(
                          itemCount: acrosticsData.length,
                          itemBuilder: (context, ad) {
                            String img = "";
                            Uint8List? imageBytes;
                            if ((acrosticsData[ad]["Image"] is String &&
                                acrosticsData[ad]["Image"].isNotEmpty)) {
                              img = acrosticsData[ad]["Image"]
                                  .replaceAll(RegExp(r'\s+'), '');
                              //debugPrint("img length for ${acrosticsData[ad]["Name"]} = ${img.length}");
                              try {
                                base64Decode(img);
//                            debugPrint("Valid base64 image");
                              } catch (e) {
                                //debugPrint("Invalid base64: $e");
                              }
                              imageBytes =
                                  HelpersService.decodeBase64Image(img);
                              //debugPrint("EXAmPLE IMAGE DATA FOR, ${acrosticsData[ad]["Name"]}: ${acrosticsData[ad]["Image"]}");
                            }
                            return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                          color: Colors.grey.shade300)),
                                ),
                                child: Column(
                                  children: [
                                    IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          // WORD
                                          Expanded(
                                              flex: 2,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.max,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "${ad + 1}) ${acrosticsData[ad]["Name"]}",
                                                    textAlign: TextAlign.left,
                                                    softWrap: true,
                                                    style: TextStyle(
                                                        fontSize:
                                                            promptFontSize,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        decoration:
                                                            TextDecoration
                                                                .underline),
                                                  ),
                                                  ElevatedButton.icon(
                                                    onPressed: () {
                                                      setState(() {
                                                        acrosticsData[ad][
                                                                "isInformationExpanded"] =
                                                            !(acrosticsData[ad][
                                                                    "isInformationExpanded"] ==
                                                                true);
                                                      });
                                                    },
                                                    icon: Icon(Icons.info,
                                                        size: 16,
                                                        color: acrosticsData[ad]
                                                                    [
                                                                    "isInformationExpanded"] ==
                                                                true
                                                            ? Colors.black
                                                            : Colors.blue),
                                                    label: Text(""),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor: Colors
                                                          .white, // White background
                                                      foregroundColor: Colors
                                                          .black, // Red text/icon color
                                                      padding: EdgeInsets.zero,
                                                      shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                          side:
                                                              const BorderSide(
                                                                  color: Color
                                                                      .fromARGB(
                                                                          255,
                                                                          220,
                                                                          220,
                                                                          220),
                                                                  width: 1)),
                                                      elevation:
                                                          1, // Shadow effect
                                                    ),
                                                  )
                                                ],
                                              )),
                                          if (imageBytes != null)
                                            Container(
                                              constraints: BoxConstraints(
                                                  maxWidth: screenWidth * 0.3),
                                              child: Image.memory(
                                                imageBytes,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          // INFORMATION (expands)
                                          // Information
                                          Expanded(
                                              flex: 4,
                                              child: Container(
                                                constraints: BoxConstraints(
                                                    maxHeight: 150),
                                                child: SingleChildScrollView(
                                                    scrollDirection:
                                                        Axis.vertical,
                                                    child: HelpersService
                                                        .getFormattedAcrostic(
                                                            context,
                                                            acrosticsData[ad]
                                                                ["Name"],
                                                            acrosticsData[ad]
                                                                ["Acrostics"],
                                                            promptFontSize)),
                                              )),
                                        ],
                                      ),
                                    ),
                                    if (acrosticsData[ad]
                                            ["isInformationExpanded"] ==
                                        true)
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                        constraints: BoxConstraints(
                                          maxHeight: 200,
                                        ),
                                        child: SingleChildScrollView(
                                          child: Text(
                                            acrosticsData[ad]["Information"],
                                            style: TextStyle(
                                                fontSize: promptFontSize),
                                          ),
                                        ),
                                      ),
                                  ],
                                ));
                          },
                        )),
                      ],
                    ),
                  ),
                ),
              ));
  }
}
