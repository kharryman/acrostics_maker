// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:acrostics_maker/globals.dart';
import 'package:acrostics_maker/services/ads.dart';
import 'package:acrostics_maker/services/autosync.dart';
import 'package:acrostics_maker/services/get_acrostics.dart';
import 'package:acrostics_maker/services/helpers.dart';
import 'package:acrostics_maker/components/menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'main.dart';
import 'package:share_plus/share_plus.dart';

String visibilityCondition = "";

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
  List<ScrollController> scrollControllers = [];
  List<String> scrollTopics = [];
  GlobalKey scrollKey = GlobalKey();
  double stateCellHeight = 0.0;

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
    letterList = widget.inputWord.toUpperCase().split("");
    for (var i = 0; i < widget.inputWord.length; i++) {
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

  getDicEntry(dynamic entry) {
    List<Widget> texts = [
      Text(entry["Word"] + (": ").toString(),
          style: TextStyle(decoration: TextDecoration.underline))
    ];
    List<String> words = entry["Entry"].toString().split(entry["Table_name"]);
    if (words.length == 1) {
      //Table_name DOESNT EXIST
      texts.add(Text(words[0]));
    } else {
      //Table_name DOES EXIST
      var isFirst = words[0].trim() == '';
      if (isFirst) {
        texts.add(Text(entry["Table_name"],
            style: TextStyle(fontWeight: FontWeight.bold)));
      } else {
        //FOR MIDDLE OR LAST:
        texts.add(Text(words[0]));
        texts.add(Text(entry["Table_name"],
            style: TextStyle(fontWeight: FontWeight.bold)));
      }
      if (words[1].trim() != '') {
        texts.add(Text(words[1]));
      }
    }

    return Wrap(direction: Axis.horizontal, children: texts);
  }

  setInput(i, value) {
    String myVal = getFormattedWord(value);
    debugPrint("setInput called, myVal = $myVal");
    selectedAcrosticWords[i] = myVal;
    inputControllers[i].text = myVal;
  }

  getFormattedWord(String val) {
    String myVal = "";
    if (val.isNotEmpty) {
      myVal = val.substring(0, 1).toUpperCase();
    }
    if (val.length > 1) {
      myVal += val.substring(1).toLowerCase();
    }
    return myVal;
  }

  List<Map<String, String>> convertMapToListMap(Map<String, String> myMap) {
    debugPrint("convertMapToListMap called");
    List<Map<String, String>> myListMap = [];
    List<String> keys = Map<String, String>.from(myMap).keys.toList();
    Map<String, String> listObj = {};
    for (int i = 0; i < keys.length; i++) {
      listObj = {};
      listObj[keys[i]] = myMap[keys[i]]!;
      //debugPrint("ADDING dictObj = ${json.encode(dictObj)}");
      myListMap.add(listObj);
    }
    return myListMap;
  }

  Future<List<Map<String, String>>> loadDictSuggestions(
      BuildContext context, int inputListIndex, String hintText) async {
    debugPrint("loadDictSuggestions called, inputListIndex = $inputListIndex");
    bool isRequestSuccess = true;
    http.Response response = http.Response("", 200);
    String letter = letterList[inputListIndex].toUpperCase();
    debugPrint("loadDictSuggestions: getting words from letter = $letter");
    List<Map<String, String>> myDictSuggestions = [];
    //return myDictSuggestions;
    if (MyHomeState().getIsUseOffline() == true) {
      try {
        dictSuggestions[inputListIndex] = {};
        for (int i = 0; i < Globals.myDic[letter]!.length; i++) {
          dictSuggestions[inputListIndex]
              .addAll(Map<String, String>.from(Globals.myDic[letter]![i]));
          myDictSuggestions.addAll(List<Map<String, String>>.from(
              convertMapToListMap(Globals.myDic[letter]![i])));
        }
      } catch (e) {
        debugPrint("Error getting dict suggs: $e");
      }
      debugPrint(
          "RETURNING myDictSuggestions = ${json.encode(myDictSuggestions)}");
      isWordLettersDictLoaded[inputListIndex] = true;
      return myDictSuggestions;
    } else {
      if (Globals.isAppOnline == false) {
        await HelpersService.showPopup(context,
            message: FlutterI18n.translate(context, "NOT_ONLINE"));
        return myDictSuggestions;
      } else {
        String appLanguageId = Globals.appLanguage["LID"];
        List<String> availLIDs = List<String>.from(
            Globals.availLanguages.map((lang) => lang["LID"]).toList());
        if (!availLIDs.contains(Globals.appLanguage["LID"])) {
          appLanguageId = "8"; //ENGLISH
        }
        HelpersService.showProgress(context,
            FlutterI18n.translate(context, "LOADING_DICTIONARY_WORDS"));
        try {
          response = await http.get(Uri.parse(
              "https://www.learnfactsquick.com/lfq_app_php/get_dict_suggestions.php?letter=$letter&language_id=${Globals.selectedAcrosticsLanguage["LID"]}&app_language_id=$appLanguageId"));
        } catch (e) {
          isRequestSuccess = false;
        }
        // ignore: use_build_context_synchronously
        HelpersService.hideProgress(context);
        dynamic data = {"SUCCESS": false};
        if (isRequestSuccess == false) {
          //await showPopup(context, "${FlutterI18n.translate(context, "NETWORK_ERROR")}!");
          Globals.isAppOnline = false;
          //await doNetworkChange();
          return myDictSuggestions;
        } else {
          //hideProgress(context);
          if (response.statusCode == 200) {
            data = Map<String, dynamic>.from(json.decode(response.body));
            //debugPrint("GET DICT SUGGESTED WORDS: data = ${json.encode(data)}");
            if (data["SUCCESS"] == true) {
              try {
                dictSuggestions[inputListIndex]
                    .addAll(Map<String, String>.from(data["WORDS"]));
                myDictSuggestions.addAll(List<Map<String, String>>.from(
                    convertMapToListMap(
                        Map<String, String>.from(data["WORDS"]))));

                isWordLettersDictLoaded[inputListIndex] = true;
              } catch (e) {
                debugPrint("ERROR GET DICT SUGGS: ${e.toString()}");
              }
              return myDictSuggestions;
            } else {
              debugPrint("GET DICT SUGGESTED WORDS LFQ ERROR");
              return myDictSuggestions;
            }
          } else {
            debugPrint("GET DICT SUGGESTED WORDS NETWORK ERROR");
            return myDictSuggestions;
          }
        }
      }
    }
  }

  Map<String, String> getDictEntriesFromLetter(String letter) {
    Map<String, String> dictEntries = {};
    return dictEntries;
  }

  doSelectWord(int i, String value) {
    debugPrint("doSelectWord called, selected value = $value");
    setState(() {
      inputControllers[i].text = getFormattedWord(value.toString());
      selectedAcrosticWords[i] = value!;
      debugPrint(
          "selected value = $value, selectedAcrosticWords[$i] = ${selectedAcrosticWords[i]}");
      showAcrostic();
    });
  }

  getWordRadios(i) {
    final fI = i;
    List<dynamic> entries = widget.entries;
    List<dynamic> selectedTypesAdjectives = widget.selectedTypesAdjectives;
    List<dynamic> filteredEntriesLetter = [];
    List<dynamic> filteredEntriesAlp = [];
    List<dynamic> filteredEntriesDic = [];
    List<Widget> wordsRadios = [];
    ListTile myRadio;
    filteredEntriesLetter = entries
        .where((dynamic entry) => entry["Letter"] == letterList[fI])
        .toList();
    debugPrint("IM HERE1");
    //debugPrint("filteredEntriesLetter = ${json.encode(filteredEntriesLetter)}");

    List<VisibilityDetector> adjGroups = [];
    for (int j = 0; j < selectedTypesAdjectives.length; j++) {
      wordsRadios = [];
      final fJ = j;
      final typeAdjStr =
          "${selectedTypesAdjectives[fJ]["type"]}: ${selectedTypesAdjectives[fJ]["adjective"]}";
      debugPrint(
          "getWordRadios ADDING RADIO FOR TYPE ${selectedTypesAdjectives[fJ]["adjective"]}");
      //NOW GET entries HAVING inputList[fI]=entry(Letter) AND adjective=selectedTypesAdjectives[fJ].Table=entry(Table_name):
      wordsRadios.add(Column(children: [
        Center(
          child: Text(typeAdjStr,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        )
      ]));
      //ADD ADJECTIVES:=========================================>
      filteredEntriesAlp = filteredEntriesLetter
          .where((dynamic entry) => entry["DICT"] == "0")
          .toList();
      filteredEntriesAlp = filteredEntriesAlp
          .where((dynamic entry) =>
              entry["Table_name"] == selectedTypesAdjectives[fJ]["adjective"])
          .toList();
      //debugPrint("filteredEntries = ${json.encode(filteredEntries)}");
      debugPrint(
          "letterList[fI] = ${letterList[fI]}, filteredEntriesAlp.length = ${filteredEntriesAlp.length}");
      final finalFilteredEntriesAlp = filteredEntriesAlp;
      for (int e = 0; e < finalFilteredEntriesAlp.length; e++) {
        final fE = e;
        //debugPrint("filteredEntries[e] = ${json.encode(filteredEntries[e]["Entry"])}");
        myRadio = ListTile(
            dense: true,
            title: Text(finalFilteredEntriesAlp[fE]["Entry"] ?? ""),
            tileColor:
                selectedAcrosticWords[fI] == finalFilteredEntriesAlp[fE]["Word"]
                    ? Colors.blue.withOpacity(0.2)
                    : Colors.transparent,
            //value: finalFilteredEntriesAlp[e]["Word"] ?? "",
            //groupValue: selectedAcrosticWords[fI],
            onTap: () {
              setState(() {
                String value = finalFilteredEntriesAlp[fE]["Word"].toString();
                String myVal = getFormattedWord(value);
                selectedAcrosticWords[fI] = value;
                inputControllers[fI].text = myVal;
                debugPrint(
                    "selected value alp = $value, selectedAcrosticWords[$fI] = ${selectedAcrosticWords[fI]}");
                showAcrostic();
              });
            });
        wordsRadios.add(myRadio);
      }

      //ADD DICTIONARY:=========================================>
      wordsRadios.add(Column(children: [
        Center(
          child: Text("${FlutterI18n.translate(context, "DICTIONARY_WORDS")}:",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  fontSize: 12)),
        )
      ]));
      filteredEntriesDic = filteredEntriesLetter
          .where((dynamic entry) => entry["DICT"] == "1")
          .toList();
      filteredEntriesDic = filteredEntriesDic
          .where((dynamic entry) =>
              entry["Table_name"] == selectedTypesAdjectives[fJ]["adjective"])
          .toList();
      debugPrint(
          "letterList[fI] = ${letterList[fI]}, filteredEntriesDic.length = ${filteredEntriesDic.length}");
      final finalFilteredEntriesDic = filteredEntriesDic;
      for (int e = 0; e < finalFilteredEntriesDic.length; e++) {
        final fE = e;
        myRadio = ListTile(
            title: getDicEntry(finalFilteredEntriesDic[fE]),
            //value: finalFilteredEntriesDic[e]["Word"],
            //groupValue: selectedAcrosticWords[fI],
            tileColor:
                selectedAcrosticWords[fI] == finalFilteredEntriesDic[fE]["Word"]
                    ? Colors.blue.withOpacity(0.2)
                    : Colors.transparent,
            onTap: () {
              setState(() {
                String value = finalFilteredEntriesDic[fE]["Word"].toString();
                String myVal = getFormattedWord(value);
                selectedAcrosticWords[fI] = value;
                debugPrint(
                    "selected value dict = $value, selectedAcrosticWords[$fI] = ${selectedAcrosticWords[fI]}");
                inputControllers[fI].text = myVal;
                showAcrostic();
              });
            });
        wordsRadios.add(myRadio);
      }
      adjGroups.add(VisibilityDetector(
          key: Key('item_${fI}_$fJ'),
          onVisibilityChanged: (visibilityInfo) {
            // Check if the item is fully visible
            Rect visibleRect = visibilityInfo.visibleBounds;
            double visibleHeight = visibleRect.height;
            double visibleWidth = visibleRect.width;
            if (stateCellHeight == 0.0) {
              stateCellHeight = MediaQuery.of(context).size.height - 175;
            }
            debugPrint(
                "$typeAdjStr visibilityInfo.visibleFraction = ${visibilityInfo.visibleFraction}, visibleHeight = $visibleHeight, stateCellHeight = $stateCellHeight");
            String nowVisibilityCondition = "WORD_${fI}_TYPE_$typeAdjStr";
            if (nowVisibilityCondition != visibilityCondition &&
                (visibilityInfo.visibleFraction == 1.0 ||
                    visibleHeight > (0.5 * stateCellHeight))) {
              debugPrint(
                  "Visibility changed! visibilityCondition = $visibilityCondition, setting state!");
              visibilityCondition = "WORD_${fI}_TYPE_$typeAdjStr";
              setState(() {
                scrollTopics[fI] = typeAdjStr;
              });
            }
          },
          child: Column(
            children: wordsRadios,
          )));
    }
    return adjGroups;
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
    stateCellHeight = cellHeight;

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

    if (selectedAcrosticWords.length >= letterList.length) {
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
                          Table(columnWidths: myColumnWidths, children: [
                            TableRow(children: [
                              for (int i = 0; i < letterList.length; i++)
                                TableCell(
                                    child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                        height: 55,
                                        padding: EdgeInsets.all(2.0),
                                        decoration: BoxDecoration(
                                            border: Border(
                                              left: BorderSide(
                                                  color: (i == 0 &&
                                                          isAcrosticDone ==
                                                              true)
                                                      ? Colors.green
                                                      : Colors.transparent,
                                                  width: 5.0),
                                              top: BorderSide(
                                                  color: isAcrosticDone == true
                                                      ? Colors.green
                                                      : Colors.transparent,
                                                  width: 5.0),
                                              right: BorderSide(
                                                  color: ((i ==
                                                              (letterList
                                                                      .length -
                                                                  1)) &&
                                                          isAcrosticDone ==
                                                              true)
                                                      ? Colors.green
                                                      : Colors.transparent,
                                                  width: 5.0),
                                              bottom: BorderSide(
                                                  color: isAcrosticDone == true
                                                      ? Colors.green
                                                      : Colors.transparent,
                                                  width: 5.0),
                                            ),
                                            color: inputControllers[i]
                                                        .text
                                                        .trim() ==
                                                    ''
                                                ? Colors.pinkAccent
                                                : Colors.lightGreenAccent,
                                            image: DecorationImage(
                                                image: AssetImage(
                                                    'assets/images/transparent.png'),
                                                fit: BoxFit.fill)),
                                        child: SizedBox(
                                          height: 50,
                                          child: TextField(
                                              controller: inputControllers[i],
                                              decoration: InputDecoration(
                                                border: OutlineInputBorder(),
                                                hintText: '..',
                                              ),
                                              keyboardType: TextInputType.text,
                                              onChanged: (value) {
                                                setState(() {
                                                  if (inputControllers[i]
                                                              .text
                                                              .trim() !=
                                                          "" &&
                                                      inputControllers[i]
                                                              .text
                                                              .substring(0, 1)
                                                              .toUpperCase() !=
                                                          letterList[i]
                                                              .toUpperCase()) {
                                                    inputControllers[i].text =
                                                        "";
                                                  } else {
                                                    inputControllers[i].text =
                                                        getFormattedWord(value);
                                                    selectedAcrosticWords[i] =
                                                        value;
                                                    showAcrostic();
                                                    debugPrint(
                                                        "selected value = $value, selectedAcrosticWords[$i] = ${selectedAcrosticWords[i]}");
                                                  }
                                                });
                                              },
                                              onEditingComplete: () {
                                                //if (Platform.isAndroid) {
                                                //  focusNode.unfocus();
                                                //} else if (Platform.isIOS) {
                                                FocusScope.of(context)
                                                    .unfocus();
                                                //}
                                              }),
                                        )),
                                    Container(
                                        height: 55,
                                        width: columnWidth,
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.black)),
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              10, 2, 10, 2),
                                          child: Autocomplete<String>(
                                              fieldViewBuilder: ((context,
                                                  textEditingController,
                                                  focusNode,
                                                  onFieldSubmitted) {
                                            autoFields[i] =
                                                textEditingController;
                                            focusNodes[i] = focusNode;
                                            return TextField(
                                                controller: autoFields[i],
                                                focusNode: focusNodes[i],
                                                onEditingComplete:
                                                    onFieldSubmitted,
                                                cursorColor: Colors.black,
                                                onChanged: (value) =>
                                                    (setState(() {})),
                                                decoration: InputDecoration(
                                                    filled: true,
                                                    fillColor: Colors.white,
                                                    focusColor:
                                                        Colors.amber[50],
                                                    border:
                                                        OutlineInputBorder(),
                                                    hintText:
                                                        FlutterI18n.translate(
                                                            context,
                                                            "SEARCH_DICTIONARY"),
                                                    suffixIcon: Visibility(
                                                        visible: autoFields[i]
                                                            .text
                                                            .isNotEmpty,
                                                        child: IconButton(
                                                            icon: Icon(
                                                              Icons.clear,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                            onPressed: () =>
                                                                setState(() {
                                                                  autoFields[i]
                                                                      .clear();
                                                                })))));
                                          }), optionsBuilder: (TextEditingValue
                                                  textEditingValue) async {
                                            debugPrint(
                                                "autoComplete optionsBuilder$i: textEditingValue.text = ${textEditingValue.text}");
                                            if (textEditingValue.text == '') {
                                              return [];
                                            } else if (textEditingValue.text
                                                    .trim() ==
                                                "") {
                                              autoFields[i].text = "";
                                              return [];
                                            } else {
                                              List<Map<String, String>> suggs =
                                                  [];
                                              debugPrint(
                                                  "dictSuggestions[$i].keys.toList().length = ${dictSuggestions[i].keys.toList().length}");
                                              List<String> options = [];
                                              List<String> dictWords =
                                                  dictSuggestions[i]
                                                      .keys
                                                      .whereType<String>()
                                                      .toList();
                                              if (isWordLettersDictLoaded[i] ==
                                                  true) {
                                                List<Map<String, String>>
                                                    myDictSuggestions = [];
                                                String hintText =
                                                    textEditingValue.text;

                                                //debugPrint("dictWords = ${json.encode(dictWords)}");
                                                for (int d = 0;
                                                    d < dictWords.length;
                                                    d++) {
                                                  if (dictWords[d].length >=
                                                          hintText.length &&
                                                      dictWords[d]
                                                          .toLowerCase()
                                                          .contains(hintText
                                                              .toLowerCase())) {
                                                    Map<String, String>
                                                        dictEntry = {};
                                                    dictEntry[dictWords[d]] =
                                                        dictSuggestions[i]
                                                            [dictWords[d]]!;
                                                    myDictSuggestions.add(Map<
                                                            String,
                                                            String>.from(
                                                        dictEntry));
                                                  }
                                                }
                                                suggs = myDictSuggestions;
                                              } else {
                                                suggs =
                                                    await loadDictSuggestions(
                                                        context,
                                                        i,
                                                        textEditingValue.text);
                                              }
                                              for (int d = 0;
                                                  d < suggs.length;
                                                  d++) {
                                                options.add(
                                                    suggs[d].keys.toList()[0]);
                                              }
                                              return options;
                                            }
                                          }, onSelected: (String selection) {
                                            debugPrint(
                                                'You just selected $selection');
                                            autoFields[i].text = "";
                                            doSelectWord(i, selection);
                                          }, optionsViewBuilder: (BuildContext
                                                      context,
                                                  AutocompleteOnSelected<String>
                                                      onSelected,
                                                  Iterable<String> options) {
                                            return Align(
                                              alignment: Alignment.topLeft,
                                              child: Material(
                                                child: Container(
                                                  height: cellHeight * 0.8,
                                                  width: columnWidth - 10,
                                                  margin: const EdgeInsets.only(
                                                      top: 3.0),
                                                  decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      border: Border.all(
                                                          color: Colors.black)),
                                                  child: ListView.builder(
                                                    padding: EdgeInsets.zero,
                                                    shrinkWrap: true,
                                                    itemCount: options.length,
                                                    itemBuilder:
                                                        (BuildContext context,
                                                            int index) {
                                                      final String option =
                                                          options
                                                              .elementAt(index);
                                                      return Container(
                                                          width:
                                                              columnWidth - 10,
                                                          child: InkWell(
                                                            onTap: () {
                                                              onSelected(
                                                                  option);
                                                            },
                                                            child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(option),
                                                                  Visibility(
                                                                    visible: dictSuggestions[i][option] !=
                                                                            null &&
                                                                        dictSuggestions[i][option]!.trim() !=
                                                                            '',
                                                                    child: Text(
                                                                        " -- ${dictSuggestions[i][option]}"),
                                                                  ),
                                                                  Divider(
                                                                    color: Colors
                                                                        .black,
                                                                    height: 1,
                                                                    thickness:
                                                                        1,
                                                                    indent: 0,
                                                                    endIndent:
                                                                        0,
                                                                  ),
                                                                ]),
                                                          ));
                                                    },
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ))
                                  ],
                                ))
                            ]),
                            TableRow(children: [
                              for (int i = 0; i < letterList.length; i++)
                                TableCell(
                                    child: Container(
                                        height: 50,
                                        padding: EdgeInsets.all(2.0),
                                        decoration: BoxDecoration(
                                          color: Color(0xFFDAC7FD),
                                          border: Border(
                                            left: BorderSide(
                                                color: Colors.black,
                                                width: 2.0),
                                            top: BorderSide(
                                                color: Colors.black,
                                                width: 2.0),
                                            right: BorderSide(
                                                color: Colors.black,
                                                width: 2.0),
                                            bottom: BorderSide(
                                                color: Colors.black,
                                                width: 2.0),
                                          ),
                                        ),
                                        child: Center(
                                            child: Text(letterList[i],
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14)))))
                            ]),
                            TableRow(children: [
                              for (int i = 0; i < letterList.length; i++)
                                TableCell(
                                  child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors
                                                .black), // Set the border color to transparent
                                      ),
                                      height: cellHeight,
                                      width: columnWidth,
                                      child: Stack(children: [
                                        SingleChildScrollView(
                                          scrollDirection: Axis.vertical,
                                          //controller: scrollControllers[i],
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(height: 35),
                                                ...getWordRadios(i),
                                              ]),
                                        ),
                                        Positioned(
                                          top: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            height: 35,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                                color: Color.fromARGB(
                                                    255, 253, 204, 55),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.pink.shade200,
                                                    offset: Offset(0, 1),
                                                    blurRadius: 20.0,
                                                  ),
                                                ],
                                                border: Border.all(
                                                    color: Colors.black26)),
                                            child: Text(
                                              scrollTopics[i],
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ])),
                                )
                            ])
                          ]),
                        ],
                      ),
                    )))));
  }
}
