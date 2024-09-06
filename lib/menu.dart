// ignore_for_file: use_build_context_synchronously, must_be_immutable
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:provider/provider.dart';

import 'main.dart';

class Menu extends StatefulWidget {
  final BuildContext context;
  final String page;
  final Function updateParent;
  Menu({required this.context, required this.page, required this.updateParent});

  @override
  // ignore: library_private_types_in_public_api
  MenuState createState() => MenuState();
}

class MenuState extends State<Menu> {
  late BuildContext mainContext;
  String helpText = "";
  @override
  void initState() {
    mainContext = widget.context;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    MyHomeState().setSavedLanguage(context);
    return PopupMenuButton<dynamic>(
        padding: EdgeInsets.all(0),
        color: Colors.white,
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width,
        ),
        icon: Icon(Icons.menu),
        onSelected: (value) {
          print("menu selected value = $value");
          //focusNode.unfocus();
          FocusScope.of(context).unfocus();
          //MyHomePageState().showInterstitialAd((){});
        },
        onOpened: () {
          print("menu opened.");
          setState(() {
            context.read<AppData>().setMenuOpen(true);
          });
          widget.updateParent();
        },
        onCanceled: () {
          setState(() {
            context.read<AppData>().setMenuOpen(false);
          });
          widget.updateParent();
        },
        itemBuilder: (BuildContext context) {
          return [
            PopupMenuItem<dynamic>(
                value: 'MY POPUP',
                child: MenuList(
                    context: context,
                    page: widget.page,
                    updateParent: widget.updateParent)),
          ];
        });
  }
}

class MenuList extends StatefulWidget {
  BuildContext context;
  String page;
  Function updateParent;
  MenuList(
      {required this.context, required this.page, required this.updateParent});

  @override
  // ignore: library_private_types_in_public_api
  MenuListState createState() => MenuListState();
}

class MenuListState extends State<MenuList> {
  List<dynamic> languages = [];
  @override
  void initState() {
    super.initState();
    languages = MyHomeState().languages;
  }

  Future<void> changeLanguage(String languageCode) async {
    print("menu.changeLanguage called, languageCode = $languageCode");

    FlutterI18n.refresh(widget.context, Locale(languageCode));
    await Future.delayed(Duration(milliseconds: 400));
    //setState(() {
    //Future.delayed(Duration(milliseconds: 3000), () {
    dynamic myLanguage = (languages.where(
        (dynamic language) => language["value"] == languageCode)).toList()[0];
    context.read<AppData>().setLanguage(myLanguage!);
    print("menu.changeLanguage SELECTED LANGUAGE = $myLanguage");
    //});
    //widget.updateParent();
  }

  @override
  Widget build(BuildContext context) {
    MyHomeState().setSavedLanguage(context);
    double screenWidth = MediaQuery.of(context).size.width;
    double promptFontSize =
        (screenWidth * 0.05 - 3) > 15 ? 15 : (screenWidth * 0.05 - 3);
    String help1 = FlutterI18n.translate(context, "HELP1");
    String help2 = FlutterI18n.translate(context, "HELP2",
        translationParams: {"spcNm": "lemur"});
    String helpTrans = FlutterI18n.translate(context, "HELP");
    String help3 = FlutterI18n.translate(context, "HELP3");
    String help4 = FlutterI18n.translate(context, "HELP4");
    String help5 = FlutterI18n.translate(context, "HELP5");
    String help6 = FlutterI18n.translate(context, "HELP6");
    String help7 = FlutterI18n.translate(context, "HELP7");
    String help8 = FlutterI18n.translate(context, "HELP8");
    String help9 = FlutterI18n.translate(context, "HELP9");
    String help10 = FlutterI18n.translate(context, "HELP10");
    String helpText =
        '<strong>$help1</strong><br /><br /><strong>$help2<br /><strong><span style="font-style:italic">"Large Eyed Madagascaran Unmistakably Ringtailed"</span></strong><br /><br /><b><u><i>$helpTrans:</i></u></b><br />• $help3 <br />• $help4<br />• $help5<br /><br />• <u><i>$help6</i></u> <br />  1)$help7<br />  2)$help8<br />  3)$help9<br /><br /><br /><span style="color:purple">  $help10</span>';

    List<DropdownMenuItem<String>> languageItems =
        languages.map<DropdownMenuItem<String>>((dynamic lang) {
      return DropdownMenuItem<String>(
        value: lang["value"],
        child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.40,
            child: Text(
                "${lang["name1"]}(${FlutterI18n.translate(context, lang["name2"])})",
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: promptFontSize))),
      );
    }).toList();
    return widget.page == "main" && languages.isEmpty
        ? Center(child: CircularProgressIndicator())
        : SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Visibility(
                        visible: widget.page != "table",
                        child: Container(
                          width: screenWidth,
                          height: 50,
                          decoration: BoxDecoration(color: Colors.white),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(color: Colors.white),
                                width: screenWidth * 0.25,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 5, 0),
                                  child: Text(
                                      '${FlutterI18n.translate(context, "PROMPT_LANGUAGE")}:',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: promptFontSize)),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(color: Colors.white),
                                width: (screenWidth * 0.75) - 60,
                                child: DropdownButton<String>(
                                  alignment: Alignment.centerRight,
                                  isExpanded: true,
                                  value: Provider.of<AppData>(context)
                                      .selectedLanguage["value"],
                                  onChanged: (newLanguage) {
                                    changeLanguage(newLanguage!);
                                  },
                                  items: languageItems,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: Padding(
                              padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Html(data: helpText),
                                  ])))
                    ])));
  }
}
