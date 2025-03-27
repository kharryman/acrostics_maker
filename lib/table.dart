// results.dart

import 'dart:convert';

import 'package:acrostics_maker/menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:http/http.dart' as http;
import 'package:visibility_detector/visibility_detector.dart';

import 'main.dart';
import 'package:share/share.dart';

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
        onScroll(i); // Pass the index `i` to the onScroll function
      });
    }
  }

  updateSelf() {
    print("MyHomeState updateSelf called");
    setState(() {});
  }

  void onScroll(int i) {
    double scrollOffset = scrollControllers[i].offset;
    print("scrollControllers[$i] scrolled, scrollOffset = $scrollOffset");
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
    MyHomeState().copyToClipboard(context, yourAcrostic);
  }

  showAcrostic() {
    yourAcrostic = "";
    List<String> words = [];
    for (int i = 0; i < inputControllers.length; i++) {
      if (inputControllers[i].text.trim() != "") {
        words.add(inputControllers[i].text);
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
    print("setInput called, myVal = $myVal");
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
    print("convertMapToListMap called");
    List<Map<String, String>> myListMap = [];
    List<String> keys = Map<String, String>.from(myMap).keys.toList();
    Map<String, String> listObj = {};
    for (int i = 0; i < keys.length; i++) {
      listObj = {};
      listObj[keys[i]] = myMap[keys[i]]!;
      //print("ADDING dictObj = ${json.encode(dictObj)}");
      myListMap.add(listObj);
    }
    return myListMap;
  }

  Future<List<Map<String, String>>> loadDictSuggestions(
      BuildContext context, int inputListIndex, String hintText) async {
    print("loadDictSuggestions called, inputListIndex = $inputListIndex");
    bool isRequestSuccess = true;
    http.Response response = http.Response("", 200);
    String letter = letterList[inputListIndex].toUpperCase();
    print("loadDictSuggestions: getting words from letter = $letter");
    List<Map<String, String>> myDictSuggestions = [];
    //return myDictSuggestions;
    if (MyHomeState().getIsUseOffline() == true) {
      try {
        dictSuggestions[inputListIndex] = {};
        for (int i = 0; i < MyHomeState().myDic[letter]!.length; i++) {
          dictSuggestions[inputListIndex].addAll(
              Map<String, String>.from(MyHomeState().myDic[letter]![i]));
          myDictSuggestions.addAll(List<Map<String, String>>.from(
              convertMapToListMap(MyHomeState().myDic[letter]![i])));
        }
      } catch (e) {
        print("Error getting dict suggs: $e");
      }
      print("RETURNING myDictSuggestions = ${json.encode(myDictSuggestions)}");
      isWordLettersDictLoaded[inputListIndex] = true;
      return myDictSuggestions;
    } else {
      String appLanguageId = appLanguage["LID"];
      List<String> availLIDs =
          List<String>.from(availLanguages.map((lang) => lang["LID"]).toList());
      if (!availLIDs.contains(appLanguage["LID"])) {
        appLanguageId = "8"; //ENGLISH
      }
      MyHomeState().showProgress(
          context, FlutterI18n.translate(context, "LOADING_DICTIONARY_WORDS"));
      try {
        response = await http.get(Uri.parse(
            "https://www.learnfactsquick.com/lfq_app_php/get_dict_suggestions.php?letter=$letter&language_id=${selectedAcrosticsLanguage["LID"]}&app_language_id=$appLanguageId"));
      } catch (e) {
        isRequestSuccess = false;
      }
      // ignore: use_build_context_synchronously
      MyHomeState().hideProgress(context);
      dynamic data = {"SUCCESS": false};
      if (isRequestSuccess == false) {
        //await showPopup(context, "${FlutterI18n.translate(context, "NETWORK_ERROR")}!");
        isAppOnline = false;
        //await doNetworkChange();
        return myDictSuggestions;
      } else {
        //hideProgress(context);
        if (response.statusCode == 200) {
          data = Map<String, dynamic>.from(json.decode(response.body));
          //print("GET DICT SUGGESTED WORDS: data = ${json.encode(data)}");
          if (data["SUCCESS"] == true) {
            try {
              dictSuggestions[inputListIndex]
                  .addAll(Map<String, String>.from(data["WORDS"]));
              myDictSuggestions.addAll(List<Map<String, String>>.from(
                  convertMapToListMap(
                      Map<String, String>.from(data["WORDS"]))));

              isWordLettersDictLoaded[inputListIndex] = true;
            } catch (e) {
              print("ERROR GET DICT SUGGS: ${e.toString()}");
            }
            return myDictSuggestions;
          } else {
            print("GET DICT SUGGESTED WORDS LFQ ERROR");
            return myDictSuggestions;
          }
        } else {
          print("GET DICT SUGGESTED WORDS NETWORK ERROR");
          return myDictSuggestions;
        }
      }
    }
  }

  Map<String, String> getDictEntriesFromLetter(String letter) {
    Map<String, String> dictEntries = {};
    return dictEntries;
  }

  doSelectWord(int i, String value) {
    print("doSelectWord called, selected value = $value");
    setState(() {
      inputControllers[i].text = getFormattedWord(value.toString());
      selectedAcrosticWords[i] = value!;
      print(
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
    print("IM HERE1");
    //print("filteredEntriesLetter = ${json.encode(filteredEntriesLetter)}");

    List<VisibilityDetector> adjGroups = [];
    for (int j = 0; j < selectedTypesAdjectives.length; j++) {
      wordsRadios = [];
      final fJ = j;
      final typeAdjStr =
          "${selectedTypesAdjectives[fJ]["type"]}: ${selectedTypesAdjectives[fJ]["adjective"]}";
      print(
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
      //print("filteredEntries = ${json.encode(filteredEntries)}");
      print(
          "letterList[fI] = ${letterList[fI]}, filteredEntriesAlp.length = ${filteredEntriesAlp.length}");
      final finalFilteredEntriesAlp = filteredEntriesAlp;
      for (int e = 0; e < finalFilteredEntriesAlp.length; e++) {
        final fE = e;
        //print("filteredEntries[e] = ${json.encode(filteredEntries[e]["Entry"])}");
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
                print(
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
      print(
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
                print(
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
            print(
                "$typeAdjStr visibilityInfo.visibleFraction = ${visibilityInfo.visibleFraction}, visibleHeight = $visibleHeight, stateCellHeight = $stateCellHeight");
            String nowVisibilityCondition = "WORD_${fI}_TYPE_$typeAdjStr";
            if (nowVisibilityCondition != visibilityCondition &&
                (visibilityInfo.visibleFraction == 1.0 ||
                    visibleHeight > (0.5 * stateCellHeight))) {
              print(
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

  @override
  Widget build(BuildContext context) {
    //PASSED DATA: ===================>
    String inputWord = widget.inputWord;

    //print("TablePage REBUILD, inputWord = $inputWord, selectedTypesAdjectives = ${json.encode(selectedTypesAdjectives)}, entries = ${json.encode(entries)}}");
    //================================>

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double cellHeight = MediaQuery.of(context).size.height - 175;
    stateCellHeight = cellHeight;

    var title = FlutterI18n.translate(context, "ACROSTICS_TABLE");

    double columnWidth = 250;
    double computedcolumnWidth = ((screenWidth - 20) / letterList.length);
    columnWidth = computedcolumnWidth > 250 ? computedcolumnWidth : 250;

    double tableWidth = (columnWidth * letterList.length);
    double copyButtonWidth =
        (tableWidth - 15) / 2 > 300 ? 300 : (tableWidth - 15) / 2;
    double shareButtonWidth =
        (tableWidth - 15) / 2 > 300 ? 300 : (tableWidth - 15) / 2;

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
      //print("suggestions[0] = ${suggestions[0]}");
      myColumnWidths[i] = FixedColumnWidth(columnWidth);
      if (selectedAcrosticWords.length <= i) {
        selectedAcrosticWords.add("");
      }
      if (inputControllers.length <= i) {
        inputControllers.add(TextEditingController());
      }
    }

    return Scaffold(
        key: scaffoldKey,
        appBar: AppBar(title: Text(title), toolbarHeight: 30, actions: <Widget>[
          Menu(context: context, page: 'table', updateParent: updateSelf)
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
                              Wrap(alignment: WrapAlignment.start, children: [
                                Text(
                                    "${FlutterI18n.translate(context, "YOUR_ACROSTIC_SENTENCE", translationParams: {
                                          "acrWor": inputWord.toUpperCase()
                                        })} ",
                                    textAlign: TextAlign.left,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
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
                                      child: Text(FlutterI18n.translate(
                                          context, "COPY_ACROSTIC"))),
                                ),
                                SizedBox(width: 15),
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
                                          MyHomeState().showPopup(
                                              context,
                                              FlutterI18n.translate(context,
                                                  "CREATE_ACROSTIC_TO_SHARE"));
                                        } else {
                                          print(
                                              "Sharing yourAcrostic = $yourAcrostic");
                                          Share.share(yourAcrostic);
                                        }
                                      },
                                      child: Text(
                                          FlutterI18n.translate(
                                              context, "SHARE"),
                                          style: TextStyle(
                                              color: Colors.black87,
                                              fontStyle: FontStyle.italic)),
                                    ))
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
                                                      isAcrosticDone == true)
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
                                                          (letterList.length -
                                                              1)) &&
                                                      isAcrosticDone == true)
                                                  ? Colors.green
                                                  : Colors.transparent,
                                              width: 5.0),
                                          bottom: BorderSide(
                                              color: isAcrosticDone == true
                                                  ? Colors.green
                                                  : Colors.transparent,
                                              width: 5.0),
                                        ),
                                        color:
                                            inputControllers[i].text.trim() ==
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
                                                inputControllers[i].text = "";
                                              } else {
                                                inputControllers[i].text =
                                                    getFormattedWord(value);
                                                selectedAcrosticWords[i] =
                                                    value;
                                                showAcrostic();
                                                print(
                                                    "selected value = $value, selectedAcrosticWords[$i] = ${selectedAcrosticWords[i]}");
                                              }
                                            });
                                          },
                                          onEditingComplete: () {
                                            //if (Platform.isAndroid) {
                                            //  focusNode.unfocus();
                                            //} else if (Platform.isIOS) {
                                            FocusScope.of(context).unfocus();
                                            //}
                                          }),
                                    )),
                                Container(
                                    height: 55,
                                    width: columnWidth,
                                    decoration: BoxDecoration(
                                        border:
                                            Border.all(color: Colors.black)),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          10, 2, 10, 2),
                                      child: Autocomplete<String>(
                                          fieldViewBuilder: ((context,
                                              textEditingController,
                                              focusNode,
                                              onFieldSubmitted) {
                                        autoFields[i] = textEditingController;
                                        focusNodes[i] = focusNode;
                                        return TextField(
                                            controller: autoFields[i],
                                            focusNode: focusNodes[i],
                                            onEditingComplete: onFieldSubmitted,
                                            cursorColor: Colors.black,
                                            onChanged: (value) =>
                                                (setState(() {})),
                                            decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.white,
                                                focusColor: Colors.amber[50],
                                                border: OutlineInputBorder(),
                                                hintText: FlutterI18n.translate(
                                                    context,
                                                    "SEARCH_DICTIONARY"),
                                                suffixIcon: Visibility(
                                                    visible: autoFields[i]
                                                        .text
                                                        .isNotEmpty,
                                                    child: IconButton(
                                                        icon: Icon(
                                                          Icons.clear,
                                                          color: Colors.black,
                                                        ),
                                                        onPressed: () =>
                                                            setState(() {
                                                              autoFields[i]
                                                                  .clear();
                                                            })))));
                                      }), optionsBuilder: (TextEditingValue
                                              textEditingValue) async {
                                        print(
                                            "autoComplete optionsBuilder$i: textEditingValue.text = ${textEditingValue.text}");
                                        if (textEditingValue.text == '') {
                                          return [];
                                        } else if (textEditingValue.text
                                                .trim() ==
                                            "") {
                                          autoFields[i].text = "";
                                          return [];
                                        } else {
                                          List<Map<String, String>> suggs = [];
                                          print(
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

                                            //print("dictWords = ${json.encode(dictWords)}");
                                            for (int d = 0;
                                                d < dictWords.length;
                                                d++) {
                                              if (dictWords[d].length >=
                                                      hintText.length &&
                                                  dictWords[d]
                                                      .toLowerCase()
                                                      .contains(hintText
                                                          .toLowerCase())) {
                                                Map<String, String> dictEntry =
                                                    {};
                                                dictEntry[dictWords[d]] =
                                                    dictSuggestions[i]
                                                        [dictWords[d]]!;
                                                myDictSuggestions.add(
                                                    Map<String, String>.from(
                                                        dictEntry));
                                              }
                                            }
                                            suggs = myDictSuggestions;
                                          } else {
                                            suggs = await loadDictSuggestions(
                                                context,
                                                i,
                                                textEditingValue.text);
                                          }
                                          for (int d = 0;
                                              d < suggs.length;
                                              d++) {
                                            options
                                                .add(suggs[d].keys.toList()[0]);
                                          }
                                          return options;
                                        }
                                      }, onSelected: (String selection) {
                                        debugPrint(
                                            'You just selected $selection');
                                        autoFields[i].text = "";
                                        doSelectWord(i, selection);
                                      }, optionsViewBuilder:
                                              (BuildContext context,
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
                                                      options.elementAt(index);
                                                  return Container(
                                                      width: columnWidth - 10,
                                                      child: InkWell(
                                                        onTap: () {
                                                          onSelected(option);
                                                        },
                                                        child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(option),
                                                              Visibility(
                                                                visible: dictSuggestions[i]
                                                                            [
                                                                            option] !=
                                                                        null &&
                                                                    dictSuggestions[i][option]!
                                                                            .trim() !=
                                                                        '',
                                                                child: Text(
                                                                    " -- ${dictSuggestions[i][option]}"),
                                                              ),
                                                              Divider(
                                                                color: Colors
                                                                    .black, // Color of the divider
                                                                height:
                                                                    1, // Space around the divider
                                                                thickness:
                                                                    1, // Thickness of the divider
                                                                indent:
                                                                    0, // Left indent
                                                                endIndent:
                                                                    0, // Right indent
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
                                            color: Colors.black, width: 2.0),
                                        top: BorderSide(
                                            color: Colors.black, width: 2.0),
                                        right: BorderSide(
                                            color: Colors.black, width: 2.0),
                                        bottom: BorderSide(
                                            color: Colors.black, width: 2.0),
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
                ))));
  }
}
