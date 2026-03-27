// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:acrostics_maker/components/acrostic_column.dart';
import 'package:acrostics_maker/globals.dart';
import 'package:acrostics_maker/services/ads.dart';
import 'package:acrostics_maker/services/autosync.dart';
import 'package:acrostics_maker/services/get_acrostics.dart';
import 'package:acrostics_maker/services/helpers.dart';
import 'package:acrostics_maker/components/menu.dart';
import 'package:acrostics_maker/services/wiki.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'main.dart';
import 'package:share_plus/share_plus.dart';

class TablePage extends StatefulWidget {
  final String inputWord;
  final List<dynamic> selectedTypesAdjectives;
  final List<dynamic> entries;
  TablePage(
      {required this.inputWord,
      required this.selectedTypesAdjectives,
      required this.entries});

  @override
  // ignore: library_private_types_in_public_api
  TablePageState createState() => TablePageState();
}

class TablePageState extends State<TablePage> {
  List<Map<String, String>> dictSuggestions = [];
  List<bool> isWordLettersDictLoaded = [];

  List<String> selectedAcrosticWords = [];
  List<TextEditingController> inputControllers = [];
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  List<FocusNode> focusNodes = [];
  List<String> letterList = [];
  Set<int> wordBreakIndexes = {};
  List<ScrollController> scrollControllers = [];
  List<String> scrollTopics = [];
  GlobalKey scrollKey = GlobalKey();

  TextEditingController tableController = TextEditingController();
  TextEditingController acrosticInfoController = TextEditingController();
  bool isNewTable = false;
  List<dynamic>? dropdownTables = [];
  dynamic selectedTable;

  bool canUpload = false;
  Uint8List? myImage;

  @override
  void initState() {
    super.initState();
    List<String> charList = widget.inputWord.toUpperCase().split("");
    letterList = charList.where((char) => char != " ").toList();
    wordBreakIndexes = (getWordBreakIndexes(charList)).toSet();
    debugPrint(
        "TablePageState initState called, letterList = ${json.encode(letterList)}, charList = ${json.encode(charList)}");
    for (var i = 0; i < letterList.length; i++) {
      inputControllers.add(TextEditingController());
      focusNodes.add(FocusNode());
      dictSuggestions.add({});
      isWordLettersDictLoaded.add(false);
      scrollControllers.add(ScrollController());
      //scrollTopics.add("");
      scrollTopics.add(
          "${widget.selectedTypesAdjectives[0]["type"]}: ${widget.selectedTypesAdjectives[0]["adjective"]}");
      scrollControllers[i].addListener(() {
        onScroll(i);
      });
    }
  }

  updateSelf() {
    debugPrint("MyHomeState updateSelf called");
    setState(() {});
  }

  List<int> getWordBreakIndexes(List<String> charList) {
    List<int> breaks = [];
    int letterIndex = 0;
    for (int j = 0; j < charList.length; j++) {
      if (charList[j] == " ") {
        breaks.add(letterIndex);
      } else {
        letterIndex++;
      }
    }
    return breaks;
  }

  void onScroll(int i) {
    double scrollOffset = scrollControllers[i].offset;
    debugPrint("scrollControllers[$i] scrolled, scrollOffset = $scrollOffset");
    //int currentIndex = (scrollOffset / 60).clamp(0, _items.length - 1).toInt();

    setState(() {
      scrollTopics[i] = "";
    });
  }

  String yourAcrostic = "";

  isLastWord(index) {
    for (var i = 0; i < selectedAcrosticWords.length; i++) {
      if (i > index && selectedAcrosticWords[i] != "") {
        return false;
      }
    }
    return true;
  }

  copyAcrostic(context) {
    showAcrostic();
    HelpersService.copyToClipboard(context, yourAcrostic);
  }

  showAcrostic() {
    debugPrint("showAcrostic called");
    yourAcrostic = "";
    List<String> words = [];
    canUpload = true;
    for (int i = 0; i < inputControllers.length; i++) {
      if (inputControllers[i].text.trim() != "") {
        words.add(inputControllers[i].text);
      } else {
        canUpload = false;
      }
    }
    yourAcrostic = words.join(" ");
    return yourAcrostic;
  }

  setInput(i, value) {
    String myVal = HelpersService.getFormattedWord(value);
    debugPrint("setInput called, myVal = $myVal");
    selectedAcrosticWords[i] = myVal;
    inputControllers[i].text = myVal;
  }

  Map<String, String> getDictEntriesFromLetter(String letter) {
    Map<String, String> dictEntries = {};
    return dictEntries;
  }

  doSelectWord(int i, String value) {
    debugPrint("doSelectWord called, selected value = $value");
    setState(() {
      inputControllers[i].text =
          HelpersService.getFormattedWord(value.toString());
      selectedAcrosticWords[i] = value!;
      debugPrint(
          "selected value = $value, selectedAcrosticWords[$i] = ${selectedAcrosticWords[i]}");
      showAcrostic();
    });
  }

  Future<void> uploadAcrostic(BuildContext context) async {
    showAcrostic();

    if (canUpload == false) {
      await HelpersService.showPopup(context,
          message: FlutterI18n.translate(context, "INCOMPLETE_ACROSTIC"));
      return;
    }

    dropdownTables =
        List<dynamic>.from(await GetAcrostics.getAllAcrosticTables(context));
    if (dropdownTables != null && dropdownTables!.isNotEmpty) {
      selectedTable = dropdownTables![0];
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        double screenWidth = MediaQuery.of(context).size.width;
        double screenHeight = MediaQuery.of(context).size.height;
        double dialogTitleFontSize =
            (screenWidth * 0.025 + 5) < 12 ? 12 : (screenWidth * 0.025 + 5);
        double promptFontSize =
            (screenWidth * 0.020 + 5) < 12 ? 12 : (screenWidth * 0.020 + 5);
        double promptFontSizeSmall =
            (screenWidth * 0.018 + 4) < 10 ? 10 : (screenWidth * 0.018 + 4);

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
                insetPadding: EdgeInsets.only(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  top: 16,
                ),
                child: Container(
                  width: screenWidth * 0.95,
                  constraints: BoxConstraints(
                    maxHeight: screenHeight * 0.85,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              textAlign: TextAlign.center,
                              FlutterI18n.translate(context, "UPLOAD_ACROSTIC"),
                              style: TextStyle(
                                  fontSize: dialogTitleFontSize,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () {
                              Navigator.of(context).pop(); // Close the dialog
                            },
                          ),
                        ],
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                        "${FlutterI18n.translate(context, "NAME")}: ",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: promptFontSize,
                                            decoration:
                                                TextDecoration.underline)),
                                    Expanded(
                                      child: Text(widget.inputWord,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: promptFontSizeSmall)),
                                    ),
                                  ],
                                ),
                                Row(children: [
                                  Text(
                                      "${FlutterI18n.translate(context, "IMAGE")}: ",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: promptFontSize,
                                          decoration:
                                              TextDecoration.underline)),
                                  SizedBox(width: 5),
                                  Container(
                                    width: screenWidth * 0.2,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                          color: const Color.fromRGBO(
                                              64, 196, 255, 1)),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: IconButton(
                                      iconSize: 20,
                                      constraints: BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      icon: Icon(Icons.photo_outlined,
                                          color: Colors.blue),
                                      onPressed: () async {
                                        //Uint8List? gotMyImage = await showImageSourceDialog(context);
                                        Uint8List? gotMyImage =
                                            await HelpersService.pickImage(
                                                ImageSource.gallery);
                                        if (gotMyImage != null) {
                                          setState(() {
                                            myImage = gotMyImage;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  if (myImage != null)
                                    Row(
                                      children: [
                                        SizedBox(width: 5),
                                        Container(
                                          width: screenWidth * 0.2,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: Colors.red[50],
                                            border: Border.all(
                                                color: Colors.redAccent),
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: IconButton(
                                            iconSize: 20,
                                            constraints: BoxConstraints(),
                                            padding: EdgeInsets.zero,
                                            icon: Icon(Icons.delete_forever,
                                                color: Colors.red),
                                            onPressed: () {
                                              setState(() {
                                                myImage = null;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                ]),
                                if (myImage != null)
                                  Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          border:
                                              Border.all(color: Colors.grey),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        constraints: BoxConstraints(
                                            maxWidth: screenWidth * 0.5,
                                            maxHeight: screenHeight * 0.25),
                                        child: Image.memory(
                                          myImage!,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ],
                                  ),
                                Row(children: [
                                  Text(
                                      "${FlutterI18n.translate(context, "INFORMATION")}: ",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: promptFontSize,
                                          decoration:
                                              TextDecoration.underline)),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      border:
                                          Border.all(color: Colors.greenAccent),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: TextButton(
                                        onPressed: () async {
                                          String? summary = await WikiService
                                              .getSummaryFromText(
                                                  widget.inputWord);
                                          print("GOT WIKI SUMMARY: $summary");
                                          if (summary != null) {
                                            setState(() {
                                              acrosticInfoController.text =
                                                  summary;
                                            });
                                          }
                                        },
                                        child: Icon(
                                          Icons.info,
                                          color: Colors.blueAccent,
                                        )),
                                  ),
                                ]),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 1),
                                  child: TextField(
                                    minLines: 2,
                                    maxLines: 10,
                                    key: ValueKey("NAME_INFO"),
                                    controller: acrosticInfoController,
                                    style: TextStyle(
                                      fontSize: promptFontSizeSmall,
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.all(5),
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                      enabledBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(
                                            255,
                                            29,
                                            169,
                                            33,
                                          ),
                                          width: 2.0,
                                        ),
                                      ),
                                      focusedBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(
                                            255,
                                            162,
                                            29,
                                            169,
                                          ),
                                          width: 2.0,
                                        ),
                                      ),
                                      hintText: FlutterI18n.translate(
                                          context, "NAME_INFO"),
                                      hintStyle: TextStyle(
                                        fontSize: promptFontSizeSmall,
                                      ),
                                    ),
                                    keyboardType: TextInputType.text,
                                    onEditingComplete: () {
                                      FocusScope.of(context).unfocus();
                                    },
                                  ),
                                ),
                                SizedBox(height: 5),
                                Row(
                                  children: [
                                    Text(
                                        "${FlutterI18n.translate(context, "ACROSTIC")}: ",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: promptFontSize,
                                            decoration:
                                                TextDecoration.underline)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(yourAcrostic,
                                          style: TextStyle(
                                              fontSize: promptFontSizeSmall,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 1),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "${FlutterI18n.translate(context, "TABLE")}:",
                                        style: TextStyle(
                                            fontSize: promptFontSize,
                                            fontWeight: FontWeight.bold,
                                            decoration:
                                                TextDecoration.underline),
                                        overflow: TextOverflow
                                            .ellipsis, // Truncate with ellipsis if it overflows
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              isNewTable = !isNewTable;
                                            });
                                          },
                                          child: Text(
                                            FlutterI18n.translate(
                                              context,
                                              "ENTER_TABLE_PROMPT",
                                            ),
                                            softWrap: true,
                                            style: TextStyle(
                                                fontSize: promptFontSize,
                                                fontWeight: FontWeight.bold),
                                            overflow: TextOverflow
                                                .ellipsis, // Truncate if it overflows
                                          ),
                                        ),
                                        Checkbox(
                                          value: isNewTable,
                                          onChanged: (newValue) {
                                            setState(() {
                                              isNewTable = newValue!;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Visibility(
                                      visible: isNewTable == true,
                                      child: Expanded(
                                        child: Padding(
                                          padding:
                                              EdgeInsets.fromLTRB(5, 0, 5, 0),
                                          child: TextField(
                                            key: ValueKey(
                                                "CREATE_ACROSTIC_TABLE"),
                                            controller: tableController,
                                            style: TextStyle(
                                                fontSize: promptFontSize),
                                            decoration: InputDecoration(
                                              contentPadding: EdgeInsets.zero,
                                              filled: true,
                                              fillColor: Colors.white,
                                              border: OutlineInputBorder(),
                                              hintText: FlutterI18n.translate(
                                                context,
                                                "ENTER_TABLE",
                                              ),
                                              hintStyle: TextStyle(
                                                fontSize: promptFontSize,
                                              ),
                                              labelText: FlutterI18n.translate(
                                                context,
                                                "ENTER_TABLE",
                                              ),
                                              labelStyle: TextStyle(
                                                fontSize: promptFontSize,
                                              ),
                                            ),
                                            keyboardType: TextInputType.text,
                                            onEditingComplete: () {
                                              FocusScope.of(context).unfocus();
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Visibility(
                                  visible: isNewTable == false,
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.fromLTRB(
                                            5, 0, 3, 0),
                                        decoration: BoxDecoration(
                                          border:
                                              Border.all(color: Colors.grey),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          color: Colors.white,
                                        ),
                                        child: DropdownButton<dynamic>(
                                          underline: SizedBox(),
                                          isExpanded:
                                              true, // Expands the dropdown to fill the width
                                          value: selectedTable,
                                          icon: Icon(
                                            Icons.arrow_drop_down,
                                          ), // Custom arrow icon on the right
                                          iconSize:
                                              24, // Size of the dropdown arrow
                                          dropdownColor: Colors.white,
                                          onChanged: (dynamic newValue) {
                                            debugPrint(
                                                "Table changed! to $newValue");
                                            setState(() {
                                              selectedTable = dropdownTables!
                                                  .where(
                                                    (dynamic selTbl) =>
                                                        selTbl["Table_name"] ==
                                                        newValue["Table_name"],
                                                  )
                                                  .toList()[0];
                                              debugPrint(
                                                "SET selectedTable = ${json.encode(selectedTable)}",
                                              );
                                            });
                                          },
                                          items: dropdownTables == null
                                              ? []
                                              : dropdownTables!.map<
                                                  DropdownMenuItem<dynamic>>((
                                                  dynamic value,
                                                ) {
                                                  return DropdownMenuItem<
                                                      dynamic>(
                                                    value: value,
                                                    child: Text(
                                                      HelpersService.prettify(
                                                          value["Table_name"]),
                                                      style: TextStyle(
                                                        fontSize:
                                                            promptFontSize,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      HelpersService.customButton(
                          context,
                          0.9,
                          promptFontSize,
                          FlutterI18n.translate(context, "UPLOAD"),
                          Icon(Icons.upload),
                          const Color.fromARGB(255, 163, 241, 74),
                          Colors.black,
                          5, () async {
                        await doUploadAcrostic(context);
                      }),
                    ],
                  ),
                ));
          },
        );
      },
    );
  }

  Future<Uint8List?> showImageSourceDialog(BuildContext context) async {
    return await showDialog<Uint8List?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Expanded(
                  child: Text(
                FlutterI18n.translate(context, "SELECT_IMAGE"),
                textAlign: TextAlign.center,
              )),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          content: Text(FlutterI18n.translate(context, "CHOOSE_IMAGE_SOURCE")),
          actions: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      border: Border.all(color: Colors.greenAccent),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: TextButton(
                        onPressed: () async {
                          Uint8List? gotMyImage =
                              await HelpersService.pickImage(
                                  ImageSource.gallery);
                          Navigator.pop(context, gotMyImage);
                        },
                        child: Icon(
                          Icons.photo,
                          color: Colors.blueAccent,
                        )),
                  ),
                ),
                SizedBox(width: 5),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blueAccent),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: TextButton(
                        onPressed: () async {
                          Uint8List? gotMyImage =
                              await HelpersService.pickImage(
                                  ImageSource.camera);
                          debugPrint("Image chosen, now should display...");
                          Navigator.pop(context, gotMyImage);
                        },
                        child: Icon(Icons.camera_alt, color: Colors.black)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> doUploadAcrostic(BuildContext context) async {
    debugPrint("doUploadAcrostic called");
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    String table = "";
    String formattedTable = "";
    if (isNewTable == false) {
      table = selectedTable["Table_name"];
      formattedTable = HelpersService.deprettify(table);
    } else {
      table = tableController.text;
      if (table.trim() == "") {
        HelpersService.showPopup(
          context,
          title: FlutterI18n.translate(context, "PROMPT_ALERT"),
          message: FlutterI18n.translate(context, "NO_TABLE_INPUT"),
        );
        return;
      }
      formattedTable = HelpersService.deprettify(table);
      var tablesExist = dropdownTables?.map(
        (dynamic tbl) => tbl["Table_name"],
      );
      if (tablesExist != null && tablesExist.contains(formattedTable)) {
        //CATEOGRY ALREADY EXISTS!:
        HelpersService.showPopup(
          context,
          title: FlutterI18n.translate(context, "PROMPT_ALERT"),
          message: FlutterI18n.translate(context, "TABLE_ALREADY_EXISTS"),
        );
        return;
      }
    }
    var name = widget.inputWord;
    int guestId = 1;
    dynamic checkWheres = {"Name": name};
    bool isExists = false;
    if (isNewTable != true) {
      isExists = await insertCheckExists(
        context,
        DB_Type_ID.DB_ACROSTICS.value,
        formattedTable,
        checkWheres,
      );
      debugPrint(
          "insertCheckExists DONE formattedTable = $formattedTable, checkWheres = $checkWheres, isNewTable FALSE, isExists = $isExists");
    }
    if (isExists == true) {
      //HelpersService.hideProgress(context);
      HelpersService.showPopup(
        context,
        title: FlutterI18n.translate(context, "PROMPT_ALERT"),
        message: FlutterI18n.translate(context, "ACROSTIC_ALREADY_EXISTS",
            translationParams: {"nM": name}),
      );
      return;
    }
    int guestUserID = 1;
    List<String> colsIns = ["User_ID", "Name", "Information", "Acrostics"];
    List<String> valsIns = [
      "$guestUserID",
      name,
      acrosticInfoController.text.trim(),
      yourAcrostic
    ];
    if (myImage != null) {
      colsIns.add("Image");
      valsIns.add(base64Encode(myImage!));
    }
    // SYNC TO LFQ DATABASE:
    List<SyncQuery> queries = [];
    debugPrint("colsIns = $colsIns, valsIns = $valsIns");

    if (isNewTable == true) {
      //CREATE THE TABLE FIRST ====>
      bool isCreated = await createTable(context, formattedTable);
      debugPrint("IS TABLE CREATED = $isCreated");
      if (isCreated == false) {
        return;
      } else {
        //{"Table_name":"animal_orders","User_ID":"8","Username":"harryman75"}
        dropdownTables?.add({
          "Table_name": formattedTable,
          "User_ID": guestUserID,
          "Username": "GUEST"
        });
        dropdownTables?.sort((a, b) => a["Table_name"]
            .toString()
            .toLowerCase()
            .compareTo(b["Table_name"].toString().toLowerCase()));
      }
    }
    HelpersService.showProgress(
      context,
      FlutterI18n.translate(context, "PROGRESS_INSERT_ACROSTIC"),
    );

    //===========================>
    queries.add(SyncQuery(
      null,
      null,
      DB_Type_ID.DB_ACROSTICS.value,
      formattedTable,
      Op_Type_ID.INSERT.value,
      colsIns,
      [valsIns],
      checkWheres,
      null,
    ));
    debugPrint("Prepared queries for autosync: ${json.encode(queries)}");

    //autoSync(queries, opTypeId, userIdOld, names, entryOld, entry, image)

    dynamic res = await autoSync(
      queries,
      Op_Type_ID.INSERT.value,
      1,
      [],
      null,
      null,
      null,
      null,
    );
    debugPrint("res = ${json.encode(res)}");
    HelpersService.hideProgress(context);
    if (res["isSuccess"] == true) {
      debugPrint(
          "INSERT ACROSTIC autosync_text= ${json.encode(res["results"])}");
      isNewTable = false;
      HelpersService.showPopup(
        context,
        title: FlutterI18n.translate(context, "PROMPT_SUCCESS"),
        message: FlutterI18n.translate(context, "INSERTED_ACROSTIC"),
      );
    } else {
      debugPrint("ERROR: ${json.encode(res["results"])}");
      HelpersService.showPopup(
        context,
        title: FlutterI18n.translate(context, "PROMPT_SUCCESS"),
        message:
            "${FlutterI18n.translate(context, "ERROR_INSERT_ACROSTIC")} ${res["results"]}",
      );
    }
  }

  Future<bool> insertCheckExists(
    BuildContext context,
    int myDBTypeID,
    String tableName,
    dynamic wheres,
  ) async {
    HelpersService.showProgress(
        context, FlutterI18n.translate(context, "PROGRESS_CHECKING_EXISTS"));
    dynamic params = {
      "database_type_id": myDBTypeID,
      "table_name": tableName,
      "wheres": wheres,
    };
    print("insertCheckExists params: $params");
    bool isRequestSuccess = true;
    http.Response response = http.Response("", 200);
    try {
      response = await http.post(
        Uri.parse(
          'https://www.learnfactsquick.com/lfq_directory/php/check_exists.php',
        ),
        body: jsonEncode(params),
      );
    } catch (e) {
      isRequestSuccess = false;
      debugPrint(
          "${FlutterI18n.translate(context, "CHECK_EXISTS_ERROR")}: ${e.toString()}");
    }
    HelpersService.hideProgress(context);
    if (isRequestSuccess == true) {
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print("insertCheckExists response data: $data");
        if (data["SUCCESS"] == true) {
          if (data["IS_EXISTS"] == true) {
            return true;
          } else {
            return false;
          }
        } else {
          debugPrint("insertCheckExists LFQ ERROR: ${data["ERROR"]}");
          return false;
        }
      } else {
        debugPrint(
            "insertCheckExists NETWORK ERROR: status code ${response.statusCode}");
        return false;
      }
    } else {
      debugPrint("insertCheckExists REQUEST ERROR");
      return false;
    }
  }

  Future<bool> createTable(BuildContext context, String formattedTable) async {
    debugPrint("createTable called.");
    //"Creating table $table, please wait......"

    //----------------------------------------------------------------------
    //CHECK IF TABLE EXISTS:
    dynamic checkWheres = {
      "Information": "",
      "Name": "",
    };
    bool isExistsTable = true;
    try {
      isExistsTable = await insertCheckExists(
        context,
        DB_Type_ID.DB_ACROSTICS.value,
        formattedTable,
        checkWheres,
      );
    } catch (e) {
      //TABLE PROBABLY DOES NOT EXIST SINCE THERE WAS AN ERROR CHECKING, SO WE CAN PROCEED TO CREATE TABLE.
      isExistsTable = false;
    }
    debugPrint("createTable isExistsTable = $isExistsTable");
    if (isExistsTable == true) {
      //TABLE ALREADY EXISTS
      HelpersService.showPopup(context,
          message: FlutterI18n.translate(context, "CREATE_TABLE_ALREADY_EXISTS",
              translationParams: {"tBL": formattedTable}));
      //HelpersService.hideProgress(context);
      return false;
    } else {
      HelpersService.showProgress(
          context,
          FlutterI18n.translate(context, "PROGRESS_CREATE_TABLE",
              translationParams: {
                "tBL": HelpersService.prettify(formattedTable)
              }));
      //var columns = "`ID` INTEGER PRIMARY KEY AUTOINCREMENT,`Name` tinytext,`Information` TEXT,`Acrostics` TEXT,`Image` blob";
      var cols = ["ID", "Name", "Information", "Acrostics", "Image", "User_ID"];
      var vals = [
        "integer PRIMARY KEY AUTOINCREMENT",
        "varchar(250)",
        "mediumtext",
        "mediumtext",
        "longblob",
        "int(11)"
      ];
      List<String> triggerSqls = [
        "Create Trigger ${Globals.DB_PREFIX}_acrostics.${formattedTable}_DOWNLOAD_INSERT AFTER INSERT ON ${Globals.DB_PREFIX}_acrostics.$formattedTable FOR EACH ROW UPDATE ${Globals.DB_PREFIX}_misc.download_table_sql SET Needs_Update=1 WHERE Table_name='$formattedTable'",
        "Create Trigger ${Globals.DB_PREFIX}_acrostics.${formattedTable}_DOWNLOAD_UPDATE AFTER UPDATE ON ${Globals.DB_PREFIX}_acrostics.$formattedTable FOR EACH ROW UPDATE ${Globals.DB_PREFIX}_misc.download_table_sql SET Needs_Update=1 WHERE Table_name='$formattedTable'",
        "Create Trigger ${Globals.DB_PREFIX}_acrostics.${formattedTable}_DOWNLOAD_DELETE AFTER DELETE ON ${Globals.DB_PREFIX}_acrostics.$formattedTable FOR EACH ROW UPDATE ${Globals.DB_PREFIX}_misc.download_table_sql SET Needs_Update=1 WHERE Table_name='$formattedTable'"
      ];
      List<SyncQuery> queries = [];
      //SyncQuery(IS_APP,User_ID_Old,DB_Type_ID,Table_name,Act_Type_ID,Cols,Vals,Wheres)
      queries.add(SyncQuery(
          null,
          null,
          DB_Type_ID.DB_ACROSTICS.value,
          formattedTable,
          Op_Type_ID.CREATE.value,
          cols,
          vals,
          {"Table": formattedTable},
          null));
      queries.add(SyncQuery(
          null,
          null,
          DB_Type_ID.DB_ACROSTICS.value,
          formattedTable,
          Op_Type_ID.CREATE_INDEX.value,
          ["Name"],
          [],
          {},
          null));
      queries.add(SyncQuery(
          false,
          null,
          DB_Type_ID.DB_ACROSTICS.value,
          formattedTable,
          Op_Type_ID.ADVANCED_SQLS.value,
          [],
          [],
          {"SQLS": triggerSqls},
          null));
      //DateTime now = DateTime.now();
      //FORMAT: 2019-07-20 10:19:45
      //var timestamp = HelpersService.getTimestamp(now);
      int guestId = 1;
      queries.add(SyncQuery(
          null,
          null,
          DB_Type_ID.DB_MISC.value,
          "acrostic_table",
          Op_Type_ID.INSERT.value,
          ["Date_Created", "Date_Modified", "User_ID", "Table_name"],
          [
            [
              HelpersService.getCurrentTimestamp().toString(),
              HelpersService.getCurrentTimestamp().toString(),
              guestId.toString(),
              formattedTable
            ]
          ],
          {"User_ID": guestId, "Table_name": formattedTable},
          null));
      queries.add(SyncQuery(
          false,
          null,
          DB_Type_ID.DB_MISC.value,
          "download_table_sql",
          Op_Type_ID.INSERT.value,
          ["DB_Type_ID", "Table_name", "Needs_Update"],
          [
            [DB_Type_ID.DB_ACROSTICS.value.toString(), formattedTable, "1"]
          ],
          {"Table_name": formattedTable},
          null));
      List<dynamic> names = [
        {"Table": formattedTable}
      ];
      debugPrint("createTable queries = ${json.encode(queries)} ");
      //HelpersService.hideProgress(context);
      //return false;
      //autoSync(queries, opTypeId, userIdOld, names, entryOld, entry, image)

      dynamic res = await autoSync(queries, Op_Type_ID.CREATE.value, null,
          names, null, null, null, null);
      HelpersService.hideProgress(context);
      if (res["isSuccess"] == true) {
        return true;
      } else {
        debugPrint("ERROR: ${res["results"]}");
        HelpersService.showPopup(context,
            title: "ERROR", message: res["results"]);
        HelpersService.hideProgress(context);
        return false;
      }
    } //END NO TABLE ALREADY EXISTS.
  }

  @override
  Widget build(BuildContext context) {
    //PASSED DATA: ===================>
    String inputWord = widget.inputWord;

    //debugPrint("TablePage REBUILD, inputWord = $inputWord, selectedTypesAdjectives = ${json.encode(selectedTypesAdjectives)}, entries = ${json.encode(entries)}}");
    //================================>

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double promptFontSize =
        (screenWidth * 0.020 + 5) < 12 ? 12 : (screenWidth * 0.020 + 5);
    double cellHeight = MediaQuery.of(context).size.height - 175;
//    stateCellHeight = cellHeight;

    var title = FlutterI18n.translate(context, "ACROSTICS_TABLE");

    double columnWidth = 250;
    double computedcolumnWidth = ((screenWidth - 20) / letterList.length);
    columnWidth = computedcolumnWidth > 250 ? computedcolumnWidth : 250;

    double tableWidth = (columnWidth * letterList.length);
    double copyButtonWidth =
        (tableWidth - 15) / 3 > 250 ? 250 : (tableWidth - 15) / 3;
    double shareButtonWidth =
        (tableWidth - 15) / 3 > 250 ? 250 : (tableWidth - 15) / 3;
    double uploadButtonWidth =
        (tableWidth - 15) / 3 > 250 ? 250 : (tableWidth - 15) / 3;

    bool isAcrosticDone = true;
    Map<int, TableColumnWidth> myColumnWidths = {};

    if (selectedAcrosticWords.length >= inputWord.length) {
      isAcrosticDone = true;
      for (int i = 0; i < letterList.length; i++) {
        if (inputControllers[i].text.trim() == '') {
          isAcrosticDone = false;
        }
      }
    } else {
      isAcrosticDone = false;
    }

    //FOR SHOWING YOUR SELECTED ACROSTIC!==>
    List<List<String>> suggestions = [];
    Map<String, String> dicEnt;
    List<String> letterKeys = [];
    List<TextEditingController> autoFields = [];

    for (int i = 0; i < letterList.length; i++) {
      dicEnt = getDictEntriesFromLetter(letterList[i].toLowerCase());
      letterKeys = List<String>.from(dicEnt.keys
          .where((String word) =>
              word[0].toLowerCase() == letterList[i].toLowerCase())
          .toList());
      suggestions.add(letterKeys
          .map((String key) => key + (": ").toString() + dicEnt[key].toString())
          .toList());
      autoFields.add(TextEditingController());
      //debugPrint("suggestions[0] = ${suggestions[0]}");
      myColumnWidths[i] = FixedColumnWidth(columnWidth);
      if (selectedAcrosticWords.length <= i) {
        selectedAcrosticWords.add("");
      }
      if (inputControllers.length <= i) {
        inputControllers.add(TextEditingController());
      }
    }

    return WillPopScope(
        onWillPop: () async {
          AdService.showInterstitialAd(() {
            Navigator.pop(context);
          });
          return false; // prevent default pop (since we already popped)
        },
        child: Scaffold(
            key: scaffoldKey,
            appBar: AppBar(
                title: Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: promptFontSize)),
                centerTitle: true,
                toolbarHeight: 30,
                actions: <Widget>[
                  Menu(
                      context: context, page: 'table', updateParent: updateSelf)
                ]),
            body: Padding(
                padding: const EdgeInsets.all(10.0),
                child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              width: tableWidth,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                      alignment: WrapAlignment.start,
                                      children: [
                                        Text(
                                            "${FlutterI18n.translate(context, "YOUR_ACROSTIC_SENTENCE", translationParams: {
                                                  "acrWor": inputWord
                                                })} ",
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        SizedBox(width: 15),
                                        Visibility(
                                          visible: yourAcrostic.trim() != '',
                                          child: Text(
                                            yourAcrostic,
                                            style: TextStyle(
                                                color: const Color.fromARGB(
                                                    255, 74, 9, 85),
                                                fontStyle: FontStyle.italic,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        )
                                      ]),
                                  Row(children: [
                                    SizedBox(
                                        width: copyButtonWidth,
                                        child: ElevatedButton(
                                            onPressed: () async {
                                              copyAcrostic(context);
                                            },
                                            child: Icon(
                                              Icons.copy,
                                              color: Colors.black,
                                            ))),
                                    SizedBox(width: 5),
                                    Container(
                                        width:
                                            shareButtonWidth, // Set the width of the button
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                              0.0), // Rounded corners
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.pink.shade200,
                                              offset: Offset(0, 1),
                                              blurRadius: 20.0,
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color.fromARGB(
                                                  255,
                                                  206,
                                                  154,
                                                  226), // Transparent background color
                                              foregroundColor:
                                                  Colors.white, // Text color
                                              padding: EdgeInsets.all(
                                                  10.0), // Button padding
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(
                                                    50.0), // Match the container's borderRadius
                                              ),
                                            ),
                                            onPressed: () {
                                              yourAcrostic = showAcrostic();
                                              if (yourAcrostic.isEmpty) {
                                                HelpersService.showPopup(
                                                    context,
                                                    message: FlutterI18n.translate(
                                                        context,
                                                        "CREATE_ACROSTIC_TO_SHARE"));
                                              } else {
                                                debugPrint(
                                                    "Sharing yourAcrostic = $yourAcrostic");
                                                Share.share(yourAcrostic);
                                              }
                                            },
                                            child: Icon(Icons.share,
                                                color: Colors.black))),
                                    SizedBox(width: 5),
                                    SizedBox(
                                      width: copyButtonWidth,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color.fromARGB(
                                            255,
                                            159,
                                            226,
                                            154,
                                          ), // Transparent background color
                                          foregroundColor:
                                              Colors.white, // Text color
                                          padding: EdgeInsets.all(
                                            10.0,
                                          ), // Button padding
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              50.0,
                                            ), // Match the container's borderRadius
                                          ),
                                        ),
                                        onPressed: () {
                                          uploadAcrostic(context);
                                        },
                                        child: Icon(
                                          Icons.upload,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ]),
                                ],
                              )),
                          Row(
                            children: List.generate(letterList.length, (i) {
                              return SizedBox(
                                width: columnWidth,
                                child: AcrosticColumn(
                                    index: i,
                                    letter: letterList[i],
                                    letterList: letterList,
                                    isWordStart: wordBreakIndexes.contains(i),
                                    isAcrosticDone: isAcrosticDone,
                                    isWordLettersDictLoaded:
                                        isWordLettersDictLoaded[i],
                                    inputController: inputControllers[i],
                                    autoController: autoFields[i],
                                    focusNode: focusNodes[i],
                                    scrollTopics: scrollTopics,
                                    dictSuggestions: dictSuggestions[i],
                                    onMainChanged: (value) {
                                      final formatted =
                                          HelpersService.getFormattedWord(
                                              value);
                                      selectedAcrosticWords[i] = formatted;
                                    },
                                    onAutoSelected: (selection) {
                                      doSelectWord(i, selection);
                                    },
                                    doSelectWord: (i, value) {
                                      doSelectWord(i, value);
                                    },
                                    showAcrostic: () {
                                      showAcrostic();
                                    },
                                    setSelectedAcrosticWords: (updatedWords) {
                                      setState(() {
                                        selectedAcrosticWords = updatedWords;
                                      });
                                    },
                                    columnWidth: columnWidth,
                                    cellHeight: cellHeight,
                                    selectedAcrosticWords:
                                        selectedAcrosticWords,
                                    entries: widget.entries,
                                    selectedTypesAdjectives:
                                        widget.selectedTypesAdjectives),
                              );
                            }),
                          )
                        ],
                      ),
                    )))));
  }
}
