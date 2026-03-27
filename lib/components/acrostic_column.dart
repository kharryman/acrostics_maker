import 'dart:convert';

import 'package:acrostics_maker/globals.dart';
import 'package:acrostics_maker/main.dart';
import 'package:acrostics_maker/services/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:http/http.dart' as http;
import 'package:visibility_detector/visibility_detector.dart';

String visibilityCondition = "";

class AcrosticColumn extends StatefulWidget {
  final int index;
  final String letter;
  final List<String> letterList;
  final bool isAcrosticDone;
  bool isWordLettersDictLoaded;
  final bool isWordStart;

  final TextEditingController inputController;
  final TextEditingController autoController;
  final FocusNode focusNode;

  final List<String> scrollTopics;
  Map<String, String> dictSuggestions;

  final Function(String) onMainChanged;
  final Function(String) onAutoSelected;
  final Function(int, String) doSelectWord;
  final Function() showAcrostic;
  final Function(List<String>) setSelectedAcrosticWords;

  final double columnWidth;
  final double cellHeight;

  final List<String> selectedAcrosticWords;
  final List<dynamic> selectedTypesAdjectives;
  final List<dynamic> entries;

  AcrosticColumn({
    super.key,
    required this.index,
    required this.letter,
    required this.letterList,
    required this.isAcrosticDone,
    required this.isWordLettersDictLoaded,
    required this.isWordStart,
    required this.inputController,
    required this.autoController,
    required this.focusNode,
    required this.scrollTopics,
    required this.dictSuggestions,
    required this.onMainChanged,
    required this.onAutoSelected,
    required this.doSelectWord,
    required this.showAcrostic,
    required this.setSelectedAcrosticWords,
    required this.columnWidth,
    required this.cellHeight,
    required this.selectedAcrosticWords,
    required this.selectedTypesAdjectives,
    required this.entries,
  });

  @override
  State<AcrosticColumn> createState() => _AcrosticColumnState();
}

class _AcrosticColumnState extends State<AcrosticColumn> {
  double stateCellHeight = 0.0;
  List<VisibilityDetector> adjGroups = [];

  @override
  void initState() {
    super.initState();
    setState(() {
      getWordRadios(widget.index);
    });
  }

  Future<List<Map<String, String>>> loadDictSuggestions(
      BuildContext context, int inputListIndex, String hintText) async {
    debugPrint("loadDictSuggestions called, inputListIndex = $inputListIndex");
    bool isRequestSuccess = true;
    http.Response response = http.Response("", 200);
    String letter = widget.letterList[inputListIndex].toUpperCase();
    debugPrint("loadDictSuggestions: getting words from letter = $letter");
    List<Map<String, String>> myDictSuggestions = [];
    //return myDictSuggestions;
    if (MyHomeState().getIsUseOffline() == true) {
      try {
        widget.dictSuggestions = {};
        for (int i = 0; i < Globals.myDic[letter]!.length; i++) {
          widget.dictSuggestions
              .addAll(Map<String, String>.from(Globals.myDic[letter]![i]));
          myDictSuggestions.addAll(List<Map<String, String>>.from(
              HelpersService.convertMapToListMap(Globals.myDic[letter]![i])));
        }
      } catch (e) {
        debugPrint("Error getting dict suggs: $e");
      }
      debugPrint(
          "RETURNING myDictSuggestions = ${json.encode(myDictSuggestions)}");
      widget.isWordLettersDictLoaded = true;
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
                widget.dictSuggestions
                    .addAll(Map<String, String>.from(data["WORDS"]));
                myDictSuggestions.addAll(List<Map<String, String>>.from(
                    HelpersService.convertMapToListMap(
                        Map<String, String>.from(data["WORDS"]))));

                widget.isWordLettersDictLoaded = true;
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

  getWordRadios(i) {
    //print("AcrosticColumn getWordRadios called for index $i, letter = ${widget.letter}");
    final fI = widget.index;
    List<dynamic> entries = widget.entries;
    List<dynamic> selectedTypesAdjectives = widget.selectedTypesAdjectives;
    List<dynamic> filteredEntriesLetter = [];
    List<dynamic> filteredEntriesAlp = [];
    List<dynamic> filteredEntriesDic = [];
    List<Widget> wordsRadios = [];
    ListTile myRadio;
    filteredEntriesLetter = entries
        .where((dynamic entry) => entry["Letter"] == widget.letter)
        .toList();
    debugPrint("IM HERE1");
    //debugPrint("filteredEntriesLetter = ${json.encode(filteredEntriesLetter)}");

    adjGroups = [];
    for (int j = 0; j < selectedTypesAdjectives.length; j++) {
      wordsRadios = [];
      final fJ = j;
      final typeAdjStr =
          "${selectedTypesAdjectives[fJ]["type"]}: ${selectedTypesAdjectives[fJ]["adjective"]}";
      //debugPrint("getWordRadios ADDING RADIO FOR TYPE ${selectedTypesAdjectives[fJ]["adjective"]}");
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
          "letterList[fI] = ${widget.letter}, filteredEntriesAlp.length = ${filteredEntriesAlp.length}");
      final finalFilteredEntriesAlp = filteredEntriesAlp;
      for (int e = 0; e < finalFilteredEntriesAlp.length; e++) {
        final fE = e;
        //debugPrint("filteredEntries[e] = ${json.encode(filteredEntries[e]["Entry"])}");
        myRadio = ListTile(
            dense: true,
            title: Text(finalFilteredEntriesAlp[fE]["Entry"] ?? ""),
            tileColor: widget.selectedAcrosticWords[fI] ==
                    finalFilteredEntriesAlp[fE]["Word"]
                ? Colors.blue.withOpacity(0.2)
                : Colors.transparent,
            //value: finalFilteredEntriesAlp[e]["Word"] ?? "",
            //groupValue: selectedAcrosticWords[fI],
            onTap: () {
              setState(() {
                String value = finalFilteredEntriesAlp[fE]["Word"].toString();
                String myVal = HelpersService.getFormattedWord(value);
                widget.selectedAcrosticWords[fI] = value;
                widget.inputController.text = myVal;
                debugPrint(
                    "selected value alp = $value, selectedAcrosticWords[$fI] = ${widget.selectedAcrosticWords[fI]}");
                widget.setSelectedAcrosticWords(widget.selectedAcrosticWords);
                widget.showAcrostic();
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
          "letterList[fI] = ${widget.letter}, filteredEntriesDic.length = ${filteredEntriesDic.length}");
      final finalFilteredEntriesDic = filteredEntriesDic;
      for (int e = 0; e < finalFilteredEntriesDic.length; e++) {
        final fE = e;
        myRadio = ListTile(
            title: getDicEntry(finalFilteredEntriesDic[fE]),
            //value: finalFilteredEntriesDic[e]["Word"],
            //groupValue: selectedAcrosticWords[fI],
            tileColor: widget.selectedAcrosticWords[fI] ==
                    finalFilteredEntriesDic[fE]["Word"]
                ? Colors.blue.withOpacity(0.2)
                : Colors.transparent,
            onTap: () {
              setState(() {
                String value = finalFilteredEntriesDic[fE]["Word"].toString();
                String myVal = HelpersService.getFormattedWord(value);
                widget.selectedAcrosticWords[fI] = value;
                debugPrint(
                    "selected value dict = $value, selectedAcrosticWords[$fI] = ${widget.selectedAcrosticWords[fI]}");
                widget.inputController.text = myVal;
                widget.setSelectedAcrosticWords(widget.selectedAcrosticWords);
                widget.showAcrostic();
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
                widget.scrollTopics[fI] = typeAdjStr;
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
    stateCellHeight = widget.cellHeight;
    return Column(
      children: [
        // 🔹 TOP TEXTFIELD
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                height: 55,
                padding: EdgeInsets.all(2.0),
                decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                          color: widget.isWordStart
                              ? Colors.black
                              : ((widget.index == 0 &&
                                      widget.isAcrosticDone == true)
                                  ? Colors.green
                                  : Colors.transparent),
                          width: 5.0),
                      top: BorderSide(
                          color: widget.isAcrosticDone == true
                              ? Colors.green
                              : Colors.transparent,
                          width: 5.0),
                      right: BorderSide(
                          color: ((widget.index ==
                                      (widget.letterList.length - 1)) &&
                                  widget.isAcrosticDone == true)
                              ? Colors.green
                              : Colors.transparent,
                          width: 5.0),
                      bottom: BorderSide(
                          color: widget.isAcrosticDone == true
                              ? Colors.green
                              : Colors.transparent,
                          width: 5.0),
                    ),
                    color: widget.inputController.text.trim() == ''
                        ? Colors.pinkAccent
                        : Colors.lightGreenAccent,
                    image: DecorationImage(
                        image: AssetImage('assets/images/transparent.png'),
                        fit: BoxFit.fill)),
                child: SizedBox(
                  height: 50,
                  child: TextField(
                      controller: widget.inputController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '..',
                      ),
                      keyboardType: TextInputType.text,
                      onChanged: (value) {
                        setState(() {
                          if (widget.inputController.text.trim() != "" &&
                              widget.inputController.text
                                      .substring(0, 1)
                                      .toUpperCase() !=
                                  widget.letter.toUpperCase()) {
                            widget.inputController.text = "";
                          } else {
                            widget.inputController.text =
                                HelpersService.getFormattedWord(value);
                            widget.selectedAcrosticWords[widget.index] = value;
                            widget.setSelectedAcrosticWords(
                                widget.selectedAcrosticWords);
                            widget.showAcrostic();
                            //debugPrint("selected value = $value, selectedAcrosticWords[$i] = ${selectedAcrosticWords[i]}");
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
                width: widget.columnWidth,
                decoration: BoxDecoration(
                    border: Border(
                        left: BorderSide(
                            color: Colors.black,
                            width: widget.isWordStart ? 5.0 : 1.0),
                        top: BorderSide(color: Colors.black, width: 1.0),
                        right: BorderSide(color: Colors.black, width: 1.0),
                        bottom: BorderSide(color: Colors.black, width: 1.0))),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
                  child: Autocomplete<String>(fieldViewBuilder: ((context,
                      textEditingController, focusNode, onFieldSubmitted) {
                    //autoFields[i] = textEditingController;
                    //focusNodes[i] = focusNode;
                    return TextField(
                        controller: widget.autoController,
                        focusNode: widget.focusNode,
                        onEditingComplete: onFieldSubmitted,
                        cursorColor: Colors.black,
                        onChanged: (value) => (setState(() {})),
                        decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            focusColor: Colors.amber[50],
                            border: OutlineInputBorder(),
                            hintText: FlutterI18n.translate(
                                context, "SEARCH_DICTIONARY"),
                            suffixIcon: Visibility(
                                visible: widget.autoController.text.isNotEmpty,
                                child: IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: Colors.black,
                                    ),
                                    onPressed: () => setState(() {
                                          widget.autoController.clear();
                                        })))));
                  }), optionsBuilder:
                      (TextEditingValue textEditingValue) async {
                    debugPrint(
                        "autoComplete optionsBuilder${widget.index}: textEditingValue.text = ${textEditingValue.text}");
                    if (textEditingValue.text == '') {
                      return [];
                    } else if (textEditingValue.text.trim() == "") {
                      widget.autoController.text = "";
                      return [];
                    } else {
                      List<Map<String, String>> suggs = [];
                      debugPrint(
                          "dictSuggestions[${widget.index}].keys.toList().length = ${widget.dictSuggestions.keys.toList().length}");
                      List<String> options = [];
                      List<String> dictWords = widget.dictSuggestions.keys
                          .whereType<String>()
                          .toList();
                      if (widget.isWordLettersDictLoaded == true) {
                        List<Map<String, String>> myDictSuggestions = [];
                        String hintText = textEditingValue.text;

                        //debugPrint("dictWords = ${json.encode(dictWords)}");
                        for (int d = 0; d < dictWords.length; d++) {
                          if (dictWords[d].length >= hintText.length &&
                              dictWords[d]
                                  .toLowerCase()
                                  .contains(hintText.toLowerCase())) {
                            Map<String, String> dictEntry = {};
                            dictEntry[dictWords[d]] =
                                widget.dictSuggestions[dictWords[d]]!;
                            myDictSuggestions
                                .add(Map<String, String>.from(dictEntry));
                          }
                        }
                        suggs = myDictSuggestions;
                      } else {
                        suggs = await loadDictSuggestions(
                            context, widget.index, textEditingValue.text);
                      }
                      for (int d = 0; d < suggs.length; d++) {
                        options.add(suggs[d].keys.toList()[0]);
                      }
                      return options;
                    }
                  }, onSelected: (String selection) {
                    debugPrint('You just selected $selection');
                    widget.autoController.text = "";
                    widget.doSelectWord(widget.index, selection);
                  }, optionsViewBuilder: (BuildContext context,
                      AutocompleteOnSelected<String> onSelected,
                      Iterable<String> options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        child: Container(
                          height: widget.cellHeight * 0.8,
                          width: widget.columnWidth - 10,
                          margin: const EdgeInsets.only(top: 3.0),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.black)),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              return Container(
                                  width: widget.columnWidth - 10,
                                  child: InkWell(
                                    onTap: () {
                                      onSelected(option);
                                    },
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(option),
                                          Visibility(
                                            visible: widget.dictSuggestions[
                                                        option] !=
                                                    null &&
                                                widget.dictSuggestions[option]!
                                                        .trim() !=
                                                    '',
                                            child: Text(
                                                " -- ${widget.dictSuggestions[option]}"),
                                          ),
                                          Divider(
                                            color: Colors.black,
                                            height: 1,
                                            thickness: 1,
                                            indent: 0,
                                            endIndent: 0,
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
        ),
        Container(
            height: 50,
            padding: EdgeInsets.all(2.0),
            decoration: BoxDecoration(
              color: Color(0xFFDAC7FD),
              border: Border(
                left: BorderSide(
                    color: Colors.black, width: widget.isWordStart ? 5.0 : 2.0),
                top: BorderSide(color: Colors.black, width: 2.0),
                right: BorderSide(color: Colors.black, width: 2.0),
                bottom: BorderSide(color: Colors.black, width: 2.0),
              ),
            ),
            child: Center(
                child: Text(widget.letter,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)))),
        Container(
            decoration: BoxDecoration(
              border: Border(
                  left: BorderSide(
                      color: Colors.black,
                      width: widget.isWordStart ? 5.0 : 1.0),
                  top: BorderSide(color: Colors.black, width: 1.0),
                  right: BorderSide(color: Colors.black, width: 1.0),
                  bottom: BorderSide(color: Colors.black, width: 1.0)),
            ),
            height: widget.cellHeight,
            width: widget.columnWidth,
            child: Stack(children: [
              SingleChildScrollView(
                scrollDirection: Axis.vertical,
                //controller: scrollControllers[i],
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [SizedBox(height: 35), ...adjGroups]),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 35,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: Color.fromARGB(255, 253, 204, 55),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pink.shade200,
                          offset: Offset(0, 1),
                          blurRadius: 20.0,
                        ),
                      ],
                      border: Border.all(color: Colors.black26)),
                  child: Text(
                    widget.scrollTopics[widget.index],
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ])),
      ],
    );
  }
}
