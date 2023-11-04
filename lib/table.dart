// results.dart

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import 'main.dart';
import 'dictionary.dart';
import 'package:share/share.dart';

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
  final myDic = {
    "a": dicList1,
    "b": dicList2,
    "c": dicList3,
    "d": dicList4,
    "e": dicList4,
    "f": dicList5,
    "g": dicList5,
    "h": dicList5,
    "i": dicList6,
    "j": dicList6,
    "k": dicList6,
    "l": dicList6,
    "m": dicList7,
    "n": dicList7,
    "o": dicList7,
    "p": dicList8,
    "q": dicList8,
    "r": dicList8,
    "s": dicList9,
    "t": dicList10,
    "u": dicList10,
    "v": dicList10,
    "w": dicList10,
    "x": dicList10,
    "y": dicList10,
    "z": dicList10,
  };
  List<String> selectedAcrosticWords = [];
  List<TextEditingController> inputControllers = [];
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  List<FocusNode> focusNodes = [];
  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.inputWord.length; i++) {
      inputControllers.add(TextEditingController());
      focusNodes.add(FocusNode());
    }
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

  getValueFromEntry(String value) {
    var valSplit = value.split("(");
    return valSplit[0];
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

  @override
  Widget build(BuildContext context) {
    //PASSED DATA: ===================>
    String inputWord = widget.inputWord;
    List<dynamic> selectedTypesAdjectives = widget.selectedTypesAdjectives;
    List<dynamic> entries = widget.entries;
    //print("TablePage REBUILD, inputWord = $inputWord, selectedTypesAdjectives = ${json.encode(selectedTypesAdjectives)}, entries = ${json.encode(entries)}}");
    //================================>
    List<String> letterList = inputWord.toUpperCase().split("");

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double cellHeight = MediaQuery.of(context).size.height - 175;

    var title = "Acrostics Table";
    List<TableRow> widgetTableRowList = [];
    List<Widget> widgetAcrosticList = [];
    List<Widget> widgetWordList = [];

    String wordText = "";
    double columnWidth = 250;
    Color myColor;
    Color colorLeft;
    Color colorRight;
    Color colorTopBottom;

    bool isAcrosticDone = true;
    bool isAcrosticStarted = false;
    Map<int, TableColumnWidth> myColumnWidths = {};

    List<Widget> widgetWordsList = [];
    List<Widget> wordsRadios = [];
    RadioListTile myRadio;
    Text myText;
    String inputTextSet = "";
    String inputText = "";

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
      dicEnt = Map<String, String>.from(
          myDic[letterList[i].toLowerCase()]!.cast<String, String>());
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
      myColor = inputControllers[i].text.trim() == ''
          ? Colors.pinkAccent
          : Colors.lightGreenAccent;
      colorLeft = (i == 0 && isAcrosticDone == true)
          ? Colors.green
          : Colors.transparent;
      colorRight = ((i == (letterList.length - 1)) && isAcrosticDone == true)
          ? Colors.green
          : Colors.transparent;
      colorTopBottom =
          isAcrosticDone == true ? Colors.green : Colors.transparent;

      widgetAcrosticList.add(TableCell(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              height: 55,
              padding: EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: colorLeft, width: 5.0),
                    top: BorderSide(color: colorTopBottom, width: 5.0),
                    right: BorderSide(color: colorRight, width: 5.0),
                    bottom: BorderSide(color: colorTopBottom, width: 5.0),
                  ),
                  color: myColor,
                  image: DecorationImage(
                      image: AssetImage('assets/images/transparent.png'),
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
                        print("selected value = $value");
                        selectedAcrosticWords[i] = getValueFromEntry(value);
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
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.black)),
              child: Autocomplete<String>(
                fieldViewBuilder: ((context, textEditingController, focusNode,
                    onFieldSubmitted) {
                  autoFields[i] = textEditingController;
                  focusNodes[i] = focusNode;
                  return TextFormField(
                      controller: autoFields[i],
                      focusNode: focusNode,
                      onEditingComplete: onFieldSubmitted,
                      decoration:
                          const InputDecoration(hintText: 'Search dictionary'));
                }),
                //displayStringForOption: (option) => option.split(":")[0],
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<String>.empty();
                  }
                  return suggestions[i].where((String option) {
                    return option
                        .split(":")[0]
                        .contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  debugPrint('You just selected $selection');
                  focusNodes[i].unfocus();
                  setState(() {
                    //print("letter= ${letterList[i]}, letterIndex=$i, inp cont length = ${inputControllers.length}");
                    String myWord = selection.split(":")[0];
                    autoFields[i].text = myWord;
                    String myVal = getFormattedWord(myWord);
                    inputControllers[i].text = myVal;
                    selectedAcrosticWords[i] = myVal;
                    showAcrostic();
                  });
                },
              ))
        ],
      )));
    }
    print(
        "TablePage TABLE ROW LENGTH widgetAcrosticList.length = ${widgetAcrosticList.length}");
    if (widgetAcrosticList.length == letterList.length) {
      widgetTableRowList.add(TableRow(children: widgetAcrosticList));
    }
    //FOR LETTERS LIST:
    for (int i = 0; i < letterList.length; i++) {
      wordText = letterList[i];
      widgetWordList.add(TableCell(
          child: Container(
              height: 50,
              padding: EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.black, width: 2.0),
                    top: BorderSide(color: Colors.black, width: 2.0),
                    right: BorderSide(color: Colors.black, width: 2.0),
                    bottom: BorderSide(color: Colors.black, width: 2.0),
                  ),
                  image: DecorationImage(
                      image: AssetImage('assets/images/transparent.png'),
                      fit: BoxFit.fill)),
              child: Center(
                  child: Text(wordText,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14))))));
    }
    print(
        "TablePage TABLE ROW LENGTH widgetWordList.length = ${widgetWordList.length}");
    widgetTableRowList.add(TableRow(children: widgetWordList));
    dynamic myWord = {};
    double textHeight = 1.1;
    List<dynamic> filteredEntriesLetter = [];
    List<dynamic> filteredEntriesAlp = [];
    List<dynamic> filteredEntriesDic = [];

    //FOR LETTERS WORDS LIST:
    for (int i = 0; i < letterList.length; i++) {
      filteredEntriesLetter = entries
          .where((dynamic entry) => entry["Letter"] == letterList[i])
          .toList();
      //print("filteredEntriesLetter = ${json.encode(filteredEntriesLetter)}");
      wordsRadios = [];
      for (int j = 0; j < selectedTypesAdjectives.length; j++) {
        //NOW GET entries HAVING inputList[i]=entry(Letter) AND adjective=selectedTypesAdjectives[j].Table=entry(Table_name):
        wordsRadios.add(Column(children: [
          Center(
            child: Text(
                selectedTypesAdjectives[j]["type"] +
                    ": " +
                    selectedTypesAdjectives[j]["adjective"],
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ]));
        //ADD ADJECTIVES:=========================================>
        filteredEntriesAlp = filteredEntriesLetter
            .where((dynamic entry) => entry["DICT"] == "0")
            .toList();
        filteredEntriesAlp = filteredEntriesAlp
            .where((dynamic entry) =>
                entry["Table_name"] == selectedTypesAdjectives[j]["adjective"])
            .toList();
        //print("filteredEntries = ${json.encode(filteredEntries)}");
        for (int e = 0; e < filteredEntriesAlp.length; e++) {
          //print("filteredEntries[e] = ${json.encode(filteredEntries[e]["Entry"])}");
          myRadio = RadioListTile<String>(
              dense: true,
              title: Text(filteredEntriesAlp[e]["Entry"]),
              value: getValueFromEntry(filteredEntriesAlp[e]["Entry"]),
              groupValue: selectedAcrosticWords[i],
              onChanged: (value) {
                setState(() {
                  print("selected value = $value");
                  String myVal = getFormattedWord(value.toString());
                  selectedAcrosticWords[i] = myVal;
                  inputControllers[i].text = myVal;
                  showAcrostic();
                });
              });
          wordsRadios.add(myRadio);
        }

        //ADD DICTIONARY:=========================================>
        wordsRadios.add(Column(children: [
          Center(
            child: Text("dictionary words:",
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
                entry["Table_name"] == selectedTypesAdjectives[j]["adjective"])
            .toList();
        for (int e = 0; e < filteredEntriesDic.length; e++) {
          myRadio = RadioListTile<String>(
              dense: true,
              title: getDicEntry(filteredEntriesDic[e]),
              value: filteredEntriesDic[e]["Word"],
              groupValue: selectedAcrosticWords[i],
              onChanged: (value) {
                setState(() {
                  print("selected value = $value");
                  String myVal = getFormattedWord(value.toString());
                  selectedAcrosticWords[i] = myVal;
                  inputControllers[i].text = myVal;
                  showAcrostic();
                });
              });
          wordsRadios.add(myRadio);
        }
      }
      widgetWordsList.add(TableCell(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
                color: Colors.black), // Set the border color to transparent
          ),
          height: cellHeight,
          width: columnWidth,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: wordsRadios,
            ),
          ),
        ),
      ));
    }

    if (widgetWordsList.length == letterList.length) {
      widgetTableRowList.add(TableRow(children: widgetWordsList));
    }

    return Scaffold(
        key: scaffoldKey,
        appBar: AppBar(title: Text(title), toolbarHeight: 30, actions: <Widget>[
          PopupMenuButton<String>(
              constraints: BoxConstraints(
                minWidth: 200,
                maxWidth: MediaQuery.of(context).size.width,
              ),
              icon: Icon(Icons.menu),
              onSelected: (value) {
                //focusNode.unfocus();
                FocusScope.of(context).unfocus();
                if (kIsWeb == false) {
                  Random random = Random();
                  var isShowAd =
                      random.nextInt(1000) < MyApp().ofThousandShowAds;
                  if (isShowAd) {
                    print(
                        "Selected Menu makeMajor showInterstitialAd CALLING...");
                    MyHomeState().showInterstitialAd();
                  }
                } else {
                  print("NOT SHOWING AD");
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                      value: 'Help',
                      child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: Padding(
                              padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Html(data: MyHomeState().helpText),
                                  ]))))
                ];
              })
        ]),
        body: Padding(
            padding: const EdgeInsets.all(1.0),
            child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          width: (columnWidth * letterList.length + 100),
                          child: Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                              child: Row(children: [
                                Text(
                                    ("Your Acrostic sentence, for (")
                                            .toString() +
                                        inputWord.toUpperCase() +
                                        ("): ").toString(),
                                    textAlign: TextAlign.left,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  yourAcrostic,
                                  style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.bold),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(15, 0, 15, 0),
                                  child: ElevatedButton(
                                      onPressed: () async {
                                        copyAcrostic(context);
                                      },
                                      child: Text("Copy Acrostic")),
                                ),
                                Container(
                                    width: 150.0, // Set the width of the button
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
                                        if (yourAcrostic.isEmpty) {
                                          MyHomeState().showPopup(context,
                                              "Please create an acrostic to share.");
                                        } else {
                                          Share.share(yourAcrostic);
                                        }
                                      },
                                      child: Text('SHARE',
                                          style: TextStyle(
                                              color: Colors.black87,
                                              fontStyle: FontStyle.italic)),
                                    ))
                              ]))),
                      Table(
                          columnWidths: myColumnWidths,
                          children: widgetTableRowList),
                    ],
                  ),
                ))));
  }
}
