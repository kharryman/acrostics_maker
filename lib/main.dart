import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:acrostics_maker/menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_i18n/loaders/decoders/base_decode_strategy.dart';
import 'package:flutter_i18n/loaders/decoders/json_decode_strategy.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: library_prefixes
import 'table.dart';
import 'package:connectivity/connectivity.dart';
import 'package:multiselect/multiselect.dart';
//offline:
import 'dict_big.dart';
import 'alp.dart';
//to get reviews:
import 'package:advanced_in_app_review/advanced_in_app_review.dart';

const String testDevice = '974550CBC7D4EA4718A67165E2E3B868';
const String myIpad = '00008020-0014301102D1002E';
const String myIphone11 = 'A8EC231A-DCFC-405C-8A0D-62E9F5BA1918';
const int maxFailedLoadAttempts = 3;
InterstitialAd? interstitialAd;
int numInterstitialLoadAttempts = 0;
dynamic defaultLanguage = {
  "LID": "8",
  "name1": "English",
  "name2": "LANGUAGE_ENGLISH",
  "value": "en"
};
List<dynamic> availLanguages = [defaultLanguage];
dynamic selectedAcrosticsLanguage = defaultLanguage;
dynamic appLanguage = defaultLanguage;
List<dynamic> dropdownTypes = [];
List<dynamic> defaultTypes = [
  {"Type": "Colors", "Trans": "Colors"},
  {"Type": "Directions", "Trans": "Directions"},
  {"Type": "Nationalities", "Trans": "Nationalities"},
  {"Type": "Number", "Trans": "Number"},
  {"Type": "Opposites", "Trans": "Opposites"},
  {"Type": "Part_Speech", "Trans": "Part_Speech"},
  {"Type": "Themes", "Trans": "Themes"},
  {"Type": "Times", "Trans": "Times"}
];

dynamic defaultData = {
  "COMPLETED_TABLES": [
    {"Type": "Colors", "Table": "blue"},
    {"Type": "Colors", "Table": "brown"},
    {"Type": "Colors", "Table": "gray"},
    {"Type": "Colors", "Table": "green"},
    {"Type": "Colors", "Table": "orange"},
    {"Type": "Colors", "Table": "pink"},
    {"Type": "Colors", "Table": "purple"},
    {"Type": "Colors", "Table": "red"},
    {"Type": "Colors", "Table": "white"},
    {"Type": "Colors", "Table": "yellow"},
    {"Type": "Directions", "Table": "east"},
    {"Type": "Directions", "Table": "north"},
    {"Type": "Directions", "Table": "northwest"},
    {"Type": "Directions", "Table": "south"},
    {"Type": "Directions", "Table": "southeast"},
    {"Type": "Directions", "Table": "southwest"},
    {"Type": "Directions", "Table": "west"},
    {"Type": "Nationalities", "Table": "afghanistan"},
    {"Type": "Nationalities", "Table": "africa"},
    {"Type": "Nationalities", "Table": "asia"},
    {"Type": "Nationalities", "Table": "australia"},
    {"Type": "Nationalities", "Table": "belgium"},
    {"Type": "Nationalities", "Table": "canada"},
    {"Type": "Nationalities", "Table": "china"},
    {"Type": "Nationalities", "Table": "denmark"},
    {"Type": "Nationalities", "Table": "egypt"},
    {"Type": "Nationalities", "Table": "europe"},
    {"Type": "Nationalities", "Table": "finland"},
    {"Type": "Nationalities", "Table": "france"},
    {"Type": "Nationalities", "Table": "germany"},
    {"Type": "Nationalities", "Table": "greece"},
    {"Type": "Nationalities", "Table": "india"},
    {"Type": "Nationalities", "Table": "iraq"},
    {"Type": "Nationalities", "Table": "ireland"},
    {"Type": "Nationalities", "Table": "italy"},
    {"Type": "Nationalities", "Table": "japan"},
    {"Type": "Nationalities", "Table": "netherlandsdt"},
    {"Type": "Nationalities", "Table": "northamerica"},
    {"Type": "Nationalities", "Table": "norway"},
    {"Type": "Nationalities", "Table": "pakistan"},
    {"Type": "Nationalities", "Table": "portugal"},
    {"Type": "Nationalities", "Table": "rome"},
    {"Type": "Nationalities", "Table": "spain"},
    {"Type": "Nationalities", "Table": "sweden"},
    {"Type": "Nationalities", "Table": "uk"},
    {"Type": "Nationalities", "Table": "usa"},
    {"Type": "Nationalities", "Table": "vietnam"},
    {"Type": "Number", "Table": "eight"},
    {"Type": "Number", "Table": "five"},
    {"Type": "Number", "Table": "four"},
    {"Type": "Number", "Table": "nine"},
    {"Type": "Number", "Table": "one"},
    {"Type": "Number", "Table": "seven"},
    {"Type": "Number", "Table": "six"},
    {"Type": "Number", "Table": "ten"},
    {"Type": "Number", "Table": "three"},
    {"Type": "Number", "Table": "two"},
    {"Type": "Opposites", "Table": "above"},
    {"Type": "Opposites", "Table": "afraid"},
    {"Type": "Opposites", "Table": "alive"},
    {"Type": "Opposites", "Table": "bad"},
    {"Type": "Opposites", "Table": "behind"},
    {"Type": "Opposites", "Table": "below"},
    {"Type": "Opposites", "Table": "bent"},
    {"Type": "Opposites", "Table": "best"},
    {"Type": "Opposites", "Table": "big"},
    {"Type": "Opposites", "Table": "blurry"},
    {"Type": "Opposites", "Table": "bored"},
    {"Type": "Opposites", "Table": "brave"},
    {"Type": "Opposites", "Table": "bright"},
    {"Type": "Opposites", "Table": "buy"},
    {"Type": "Opposites", "Table": "chaos"},
    {"Type": "Opposites", "Table": "cheap"},
    {"Type": "Opposites", "Table": "clean"},
    {"Type": "Opposites", "Table": "clear"},
    {"Type": "Opposites", "Table": "closed"},
    {"Type": "Opposites", "Table": "cold"},
    {"Type": "Opposites", "Table": "complicated"},
    {"Type": "Opposites", "Table": "crazy"},
    {"Type": "Opposites", "Table": "cruel"},
    {"Type": "Opposites", "Table": "dark"},
    {"Type": "Opposites", "Table": "dead"},
    {"Type": "Opposites", "Table": "deep"},
    {"Type": "Opposites", "Table": "delicious"},
    {"Type": "Opposites", "Table": "different"},
    {"Type": "Opposites", "Table": "difficult"},
    {"Type": "Opposites", "Table": "dirty"},
    {"Type": "Opposites", "Table": "disgusting"},
    {"Type": "Opposites", "Table": "dry"},
    {"Type": "Opposites", "Table": "easy"},
    {"Type": "Opposites", "Table": "energetic"},
    {"Type": "Opposites", "Table": "excited"},
    {"Type": "Opposites", "Table": "expensive"},
    {"Type": "Opposites", "Table": "far"},
    {"Type": "Opposites", "Table": "fast"},
    {"Type": "Opposites", "Table": "fat"},
    {"Type": "Opposites", "Table": "female"},
    {"Type": "Opposites", "Table": "few"},
    {"Type": "Opposites", "Table": "fiction"},
    {"Type": "Opposites", "Table": "found"},
    {"Type": "Opposites", "Table": "fragrant"},
    {"Type": "Opposites", "Table": "go"},
    {"Type": "Opposites", "Table": "good"},
    {"Type": "Opposites", "Table": "hard"},
    {"Type": "Opposites", "Table": "heavy"},
    {"Type": "Opposites", "Table": "hot"},
    {"Type": "Opposites", "Table": "infrontof"},
    {"Type": "Opposites", "Table": "kind"},
    {"Type": "Opposites", "Table": "light"},
    {"Type": "Opposites", "Table": "loose"},
    {"Type": "Opposites", "Table": "lose"},
    {"Type": "Opposites", "Table": "lost"},
    {"Type": "Opposites", "Table": "loud"},
    {"Type": "Opposites", "Table": "male"},
    {"Type": "Opposites", "Table": "many"},
    {"Type": "Opposites", "Table": "narrow"},
    {"Type": "Opposites", "Table": "near"},
    {"Type": "Opposites", "Table": "normal"},
    {"Type": "Opposites", "Table": "old"},
    {"Type": "Opposites", "Table": "open"},
    {"Type": "Opposites", "Table": "organized"},
    {"Type": "Opposites", "Table": "poor"},
    {"Type": "Opposites", "Table": "pretty"},
    {"Type": "Opposites", "Table": "quiet"},
    {"Type": "Opposites", "Table": "recent"},
    {"Type": "Opposites", "Table": "rich"},
    {"Type": "Opposites", "Table": "rough"},
    {"Type": "Opposites", "Table": "same"},
    {"Type": "Opposites", "Table": "sane"},
    {"Type": "Opposites", "Table": "sell"},
    {"Type": "Opposites", "Table": "shallow"},
    {"Type": "Opposites", "Table": "short"},
    {"Type": "Opposites", "Table": "simple"},
    {"Type": "Opposites", "Table": "slow"},
    {"Type": "Opposites", "Table": "small"},
    {"Type": "Opposites", "Table": "smart"},
    {"Type": "Opposites", "Table": "smooth"},
    {"Type": "Opposites", "Table": "soft"},
    {"Type": "Opposites", "Table": "stinky"},
    {"Type": "Opposites", "Table": "stop"},
    {"Type": "Opposites", "Table": "straight"},
    {"Type": "Opposites", "Table": "strange"},
    {"Type": "Opposites", "Table": "strong"},
    {"Type": "Opposites", "Table": "tall"},
    {"Type": "Opposites", "Table": "thick"},
    {"Type": "Opposites", "Table": "thin"},
    {"Type": "Opposites", "Table": "tight"},
    {"Type": "Opposites", "Table": "tired"},
    {"Type": "Opposites", "Table": "truth"},
    {"Type": "Opposites", "Table": "ugly"},
    {"Type": "Opposites", "Table": "weak"},
    {"Type": "Opposites", "Table": "wet"},
    {"Type": "Opposites", "Table": "wide"},
    {"Type": "Opposites", "Table": "win"},
    {"Type": "Opposites", "Table": "worst"},
    {"Type": "Part_Speech", "Table": "adjective"},
    {"Type": "Part_Speech", "Table": "adjectiveage"},
    {"Type": "Part_Speech", "Table": "adjectivecolor"},
    {"Type": "Part_Speech", "Table": "adjectiveintensity"},
    {"Type": "Part_Speech", "Table": "adjectivematerial"},
    {"Type": "Part_Speech", "Table": "adjectivenationality"},
    {"Type": "Part_Speech", "Table": "adjectivenumber"},
    {"Type": "Part_Speech", "Table": "adjectivequality"},
    {"Type": "Part_Speech", "Table": "adjectivereligion"},
    {"Type": "Part_Speech", "Table": "adjectiveshape"},
    {"Type": "Part_Speech", "Table": "adjectivesize"},
    {"Type": "Part_Speech", "Table": "adjectivetexture"},
    {"Type": "Part_Speech", "Table": "adverb"},
    {"Type": "Part_Speech", "Table": "conjunction"},
    {"Type": "Part_Speech", "Table": "noun"},
    {"Type": "Part_Speech", "Table": "preposition"},
    {"Type": "Part_Speech", "Table": "verb"},
    {"Type": "Themes", "Table": "business"},
    {"Type": "Themes", "Table": "drama"},
    {"Type": "Themes", "Table": "entertainment"},
    {"Type": "Themes", "Table": "fashion"},
    {"Type": "Themes", "Table": "food"},
    {"Type": "Themes", "Table": "health"},
    {"Type": "Themes", "Table": "military"},
    {"Type": "Themes", "Table": "music"},
    {"Type": "Themes", "Table": "politics"},
    {"Type": "Themes", "Table": "religion"},
    {"Type": "Themes", "Table": "science"},
    {"Type": "Themes", "Table": "subject"},
    {"Type": "Themes", "Table": "technology"},
    {"Type": "Times", "Table": "after"},
    {"Type": "Times", "Table": "beginning"},
    {"Type": "Times", "Table": "early"},
    {"Type": "Times", "Table": "finish"},
    {"Type": "Times", "Table": "later"},
    {"Type": "Times", "Table": "now"},
    {"Type": "Times", "Table": "past"}
  ],
  "CATEGORIES": {
    "Colors": {
      "1": "Colors",
      "2": "Couleurs",
      "3": "Farben",
      "4": "Colori",
      "5": "Colores",
      "8": "Colors",
      "12": "Couleurs",
      "13": "Farben",
      "20": "Colori",
      "34": "Colores"
    },
    "Directions": {
      "1": "Directions",
      "2": "Directions",
      "3": "Richtungen",
      "4": "Indicazioni",
      "5": "Direcciones",
      "8": "Directions",
      "12": "Directions",
      "13": "Richtungen",
      "20": "Indicazioni",
      "34": "Direcciones"
    },
    "Materials": {
      "1": "Materials",
      "2": "Matériaux",
      "3": "Materialien",
      "4": "Materiali",
      "5": "Materiales",
      "8": "Materials",
      "12": "Matériaux",
      "13": "Materialien",
      "20": "Materiali",
      "34": "Materiales"
    },
    "Nationalities": {
      "1": "Nationalities",
      "2": "Nationalités",
      "3": "Nationalitäten",
      "4": "Nazionalità",
      "5": "Nacionalidades",
      "8": "Nationalities",
      "12": "Nationalités",
      "13": "Nationalitäten",
      "20": "Nazionalità",
      "34": "Nacionalidades"
    },
    "Number": {
      "1": "Number",
      "2": "Nombre",
      "3": "Nummer",
      "4": "Numero",
      "5": "Número",
      "8": "Number",
      "12": "Nombre",
      "13": "Nummer",
      "20": "Numero",
      "34": "Número"
    },
    "Opposites": {
      "1": "Opposites",
      "2": "Les contraires",
      "3": "Gegensätze",
      "4": "Gli opposti",
      "5": "Opuestos",
      "8": "Opposites",
      "12": "Les contraires",
      "13": "Gegensätze",
      "20": "Gli opposti",
      "34": "Opuestos"
    },
    "Part_Speech": {
      "1": "Part_Speech",
      "2": "Part_Speech",
      "3": "Teil_Rede",
      "4": "Parte_Discorso",
      "5": "Parte_discurso",
      "8": "Part_Speech",
      "12": "Part_Speech",
      "13": "Teil_Rede",
      "20": "Parte_Discorso",
      "34": "Parte_discurso"
    },
    "Religions": {
      "1": "Religions",
      "2": "Religions",
      "3": "Religionen",
      "4": "Religioni",
      "5": "Religiones",
      "8": "Religions",
      "12": "Religions",
      "13": "Religionen",
      "20": "Religioni",
      "34": "Religiones"
    },
    "Shapes": {
      "1": "Shapes",
      "2": "Formes",
      "3": "Formen",
      "4": "Forme",
      "5": "formas",
      "8": "Shapes",
      "12": "Formes",
      "13": "Formen",
      "20": "Forme",
      "34": "formas"
    },
    "Themes": {
      "1": "Themes",
      "2": "Thèmes",
      "3": "Themen",
      "4": "Temi",
      "5": "Temas",
      "8": "Themes",
      "12": "Thèmes",
      "13": "Themen",
      "20": "Temi",
      "34": "Temas"
    },
    "Times": {
      "1": "Times",
      "2": "Fois",
      "3": "Mal",
      "4": "Volte",
      "5": "Veces",
      "8": "Times",
      "12": "Fois",
      "13": "Mal",
      "20": "Volte",
      "34": "Veces"
    }
  }
};

List<String> dropdownAdjectives = [];
dynamic allCategories = [];
dynamic selectedType = {};
String selectedAdjective = '';
bool isInitiated = false;

class MyObject {
  String name;
  dynamic value;

  MyObject({required this.name, this.value});
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("main RETURNING $kIsWeb");
  if (kIsWeb == false) {
    var testDevices = <String>[];
    if (Platform.isAndroid) {
      testDevices = [testDevice];
    } else if (Platform.isIOS) {
      testDevices = [myIpad, myIphone11];
    }
    MobileAds.instance
      ..initialize()
      ..updateRequestConfiguration(RequestConfiguration(
        testDeviceIds: testDevices,
      ));
  } else {
    print("main NOT SHOWING AD");
  }
  //String deviceId = await getDeviceId();
  //print('Device ID: $deviceId');
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (context) => AppData(), child: MyApp())
  ], child: MyApp()));
}

class AppData extends ChangeNotifier {
  dynamic selectedLanguage = defaultLanguage;

  Future<void> setLanguage(dynamic myLanguage) async {
    selectedLanguage = myLanguage;
    appLanguage = selectedLanguage;
    await MyHomeState().setData("LANGUAGE", selectedLanguage["value"]);
    BuildContext? context = MyHomeState().scaffoldKey.currentContext;
    await MyHomeState().initiateTypesAdjectives(context, false);
    notifyListeners();
  }

  bool menuOpen = false;
  void setMenuOpen(bool isOpen) {
    menuOpen = isOpen;
  }
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  final int ofThousandShowAds = 425;
  List<BaseDecodeStrategy> decodeStrategies = [JsonDecodeStrategy()];
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  @override
  Widget build(BuildContext context) {
    String appTitle =
        "Acrostics Maker"; //FlutterI18n.translate(context, "APP_TITLE");
    return MaterialApp(
      navigatorKey: navigatorKey,
      localizationsDelegates: [
        FlutterI18nDelegate(
          translationLoader: FileTranslationLoader(
              decodeStrategies: decodeStrategies,
              basePath: "assets/i18n",
              fallbackFile: "en",
              useCountryCode: false),
          missingTranslationHandler: (key, locale) {
            print(
                "--- Missing Key: $key, languageCode: ${locale?.languageCode}");
          },
        ),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate
      ],
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: Color.fromRGBO(200, 255, 200, 1.0))),
      home: MyHome(),
    );
  }
}

// ignore: must_be_immutable
class MyHome extends StatefulWidget {
  @override
  MyHomeState createState() => MyHomeState();
}

bool isAppOnline = true;

class MyHomeState extends State<MyHome> {
  late StreamSubscription<ConnectivityResult> subscription;
  bool isLoading = false;
  final TextEditingController inputController = TextEditingController();
  String inputWord = "";
  List<String> inputList = [];
  String abcString = "abcdefghijklmnopqrstuvwxyz";
  List<dynamic> completedTables = [];
  List<String> selectedAdjectives = [];
  int selectedTypeIndex = 0;
  List<List<String>> selectedAllAdjectives = [[]];
  List<String> uniqueLetters = [];
  dynamic selectedDropdownAdjective;
  List<Widget> selectedDropdownItems = [];
  int countAllSelected = 0;
  bool isCancel = false;
  String selectedDropdownValue = "SOMETHING_SELECTED";
  Map<String, List<Map<String, String>>> myDic = {
    "A": [dicA1, dicA2],
    "B": [dicB1, dicB2],
    "C": [dicC1, dicC1, dicC3],
    "D": [dicD1, dicD2],
    "E": [dicE1],
    "F": [dicF1],
    "G": [dicG1],
    "H": [dicH1],
    "I": [dicI1],
    "J": [dicJ1],
    "K": [dicK1],
    "L": [dicL1],
    "M": [dicM1, dicM2],
    "N": [dicN1],
    "O": [dicO1],
    "P": [dicP1, dicP2],
    "Q": [dicQ1],
    "R": [dicR1, dicR2],
    "S": [dicS1, dicS2, dicS3],
    "T": [dicT1, dicT2],
    "U": [dicU1],
    "V": [dicV1],
    "W": [dicW1],
    "X": [dicX1],
    "Y": [dicY1],
    "Z": [dicZ1],
  };

  bool isPushNavigationStack = true;
  bool isAndroid = kIsWeb == false ? false : false;
  bool isIOS = kIsWeb == false ? false : false;

  List<dynamic> languages = [
    {
      "LID": "1",
      "name1": "Afrikaans",
      "name2": "LANGUAGE_AFRIKAANS",
      "value": "af"
    },
    {"LID": "2", "name1": "Euskara", "name2": "LANGUAGE_BASQUE", "value": "eu"},
    {
      "LID": "3",
      "name1": "Bosanski",
      "name2": "LANGUAGE_BOSNIAN",
      "value": "bs"
    },
    {
      "LID": "4",
      "name1": "Hrvatski",
      "name2": "LANGUAGE_CROATIAN",
      "value": "hr"
    },
    {"LID": "5", "name1": "čeština", "name2": "LANGUAGE_CZECH", "value": "cs"},
    {"LID": "6", "name1": "Dansk", "name2": "LANGUAGE_DANISH", "value": "da"},
    {
      "LID": "8",
      "name1": "English",
      "name2": "LANGUAGE_ENGLISH",
      "value": "en"
    },
    {
      "LID": "9",
      "name1": "Eesti keel",
      "name2": "LANGUAGE_ESTONIAN",
      "value": "et"
    },
    {
      "LID": "11",
      "name1": "Suomalainen",
      "name2": "LANGUAGE_FINNISH",
      "value": "fi"
    },
    {
      "LID": "12",
      "name1": "Français",
      "name2": "LANGUAGE_FRENCH",
      "value": "fr"
    },
    {
      "LID": "13",
      "name1": "Deutsch",
      "name2": "LANGUAGE_GERMAN",
      "value": "de"
    },
    {
      "LID": "14",
      "name1": "Kreyòl ayisyen",
      "name2": "LANGUAGE_HAITIAN_CREOLE",
      "value": "ht"
    },
    {
      "LID": "15",
      "name1": "ʻŌlelo Hawaiʻi",
      "name2": "LANGUAGE_HAWAIIAN",
      "value": "haw"
    },
    {"LID": "16", "name1": "Hmoob", "name2": "LANGUAGE_HMONG", "value": "hmn"},
    {
      "LID": "17",
      "name1": "Magyar",
      "name2": "LANGUAGE_HUNGARIAN",
      "value": "hu"
    },
    {
      "LID": "18",
      "name1": "Bahasa Indonesia",
      "name2": "LANGUAGE_INDONESIAN",
      "value": "id"
    },
    {"LID": "19", "name1": "Gaeilge", "name2": "LANGUAGE_IRISH", "value": "ga"},
    {
      "LID": "20",
      "name1": "Italiano",
      "name2": "LANGUAGE_ITALIAN",
      "value": "it"
    },
    {
      "LID": "22",
      "name1": "Lëtzebuergesch",
      "name2": "LANGUAGE_LUXEMBOURGISH",
      "value": "lb"
    },
    {"LID": "23", "name1": "Melayu", "name2": "LANGUAGE_MALAY", "value": "ms"},
    {"LID": "24", "name1": "Malti", "name2": "LANGUAGE_MALTESE", "value": "mt"},
    {"LID": "25", "name1": "Maori", "name2": "LANGUAGE_MAORI", "value": "mi"},
    {"LID": "27", "name1": "Polski", "name2": "LANGUAGE_POLISH", "value": "pl"},
    {
      "LID": "28",
      "name1": "Português",
      "name2": "LANGUAGE_PORTUGUESE",
      "value": "pt"
    },
    {
      "LID": "29",
      "name1": "Română",
      "name2": "LANGUAGE_ROMANIAN",
      "value": "ro"
    },
    {"LID": "30", "name1": "Samoa", "name2": "LANGUAGE_SAMOAN", "value": "sm"},
    {
      "LID": "31",
      "name1": "Slovensko",
      "name2": "LANGUAGE_SLOVAK",
      "value": "sk"
    },
    {
      "LID": "32",
      "name1": "Slovenščina",
      "name2": "LANGUAGE_SLOVENIAN",
      "value": "sl"
    },
    {
      "LID": "33",
      "name1": "Soomaali",
      "name2": "LANGUAGE_SOMALI",
      "value": "so"
    },
    {
      "LID": "34",
      "name1": "Español",
      "name2": "LANGUAGE_SPANISH",
      "value": "es"
    },
    {
      "LID": "35",
      "name1": "Svenska",
      "name2": "LANGUAGE_SWEDISH",
      "value": "sv"
    },
    {"LID": "39", "name1": "Cymraeg", "name2": "LANGUAGE_WELSH", "value": "cy"}
  ];

  bool isLanguagesLoading = false;
  bool isInitiatingTypesAdjectives = false;

  WidgetStateColor goButtonColor =
      WidgetStateColor.resolveWith((Set<WidgetState> states) {
    if (states.contains(WidgetState.pressed)) {
      return Color.fromARGB(
          255, 35, 239, 38); // Use a specific shade for the pressed state
    }
    return const Color.fromARGB(
        255, 194, 234, 149); // Use a default shade for other states
  });

  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  initState() {
    super.initState();
    if (kIsWeb == false) {
      AdvancedInAppReview()
          .setMinDaysBeforeRemind(7)
          .setMinDaysAfterInstall(2)
          .setMinLaunchTimes(2)
          .setMinSecondsBeforeShowDialog(4)
          .monitor();
    }
    BuildContext? context = scaffoldKey.currentContext;
    initiateAll(context);
    if (kIsWeb == false) {
      createInterstitialAd();
    }
    subscription = Connectivity().onConnectivityChanged.listen((result) async {
      isAppOnline = true;
      if (result == ConnectivityResult.none) {
        print("ACROSTICS MAKER NETWORK DISCONNECTED.");
        isAppOnline = false;
      }
      await doNetworkChange();
    });
  }

  doNetworkChange() async {
    if (isAppOnline == false) {
      setState(() {
        print("OFFLINE...");
        availLanguages = [defaultLanguage];
        isLanguagesLoading = false;
        dropdownTypes = List<dynamic>.from(defaultTypes);
        finishInitiateTypesAdjectives("8", defaultData);
        //myList = ["English(English)"];
      });
    } else {
      BuildContext? context = scaffoldKey.currentContext;
      await initiateAll(context);
      if (kIsWeb == false) {
        createInterstitialAd();
      }
    }
  }

  setAvailLanguages() async {
    //showProgress(
    //    context, FlutterI18n.translate(context, "PROGRESS_ADD_COMMENT"));
    dynamic data = {"SUCCESS": false};
    bool isSuccess = true;
    List<dynamic> gotLanguages = [];
    bool isRequestSuccess = true;
    Response response = http.Response("", 200);
    try {
      response = await http.get(Uri.parse(
          'https://www.learnfactsquick.com/lfq_app_php/get_dict_langs.php'));
    } catch (e) {
      isRequestSuccess = false;
      isAppOnline = false;
      await doNetworkChange();
    }
    if (isRequestSuccess == true) {
      //hideProgress(context);
      if (response.statusCode == 200) {
        data = Map<String, dynamic>.from(json.decode(response.body));
        print("GET AVAIL LANGUAGES data = ${json.encode(data)}");
        if (data["SUCCESS"] == true) {
          print("GOT LANGUAGES = ${json.encode(data)}");
          gotLanguages = data["LANGUAGES"];
        } else {
          print("GET LANGUAGES ERROR: ${data["ERROR"]}");
          isSuccess = false;
          await showPopup(context, data["ERROR"]);
          //showPopup(context, data["ERROR"]);
        }
      } else {
        isSuccess = false;
        await showPopup(
            context, FlutterI18n.translate(context, "NETWORK_ERROR"));
      }
      setState(() {
        isLanguagesLoading = false;
        if (isSuccess == false) {
          availLanguages = [defaultLanguage];
        } else {
          availLanguages = [];
          List<String> languageValues = [];
          List<dynamic> availLangs;
          for (int i = 0; i < gotLanguages.length; i++) {
            availLangs = (MyHomeState().languages.where((dynamic language) =>
                language["value"] == gotLanguages[i]["Code"])).toList();
            if (availLangs.isNotEmpty &&
                !languageValues.contains(availLangs[0]["value"])) {
              languageValues.add(availLangs[0]["value"]);
              availLanguages.add(availLangs[0]);
            }
          }
          resetMyList();
        }
      });
    }
  }

  setSavedLanguage(BuildContext? context) async {
    String savedLanguage = (await getData("LANGUAGE")) ?? "";
    print("savedLanguage = ${json.encode(savedLanguage)}");
    if (savedLanguage != "") {
      appLanguage = List<dynamic>.from(languages
          .where((dynamic lang) => lang["value"] == savedLanguage)
          .toList())[0];
      print("SET SAVED LANGUAGE, appLanguage = ${json.encode(appLanguage)}");
      try {
        if (context != null) {
          FlutterI18n.refresh(context, Locale(savedLanguage));
        }
      } catch (e) {
        print("Error refreshing saved language");
      }
    } else {
      //FlutterI18n.refresh(context, Locale('en'));
    }
    //setState((){});
  }

  // To save data
  Future<void> setData(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
  }

// To read data
  Future<String?> getData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<bool> isNetworkAvailable() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      print("CONNECTED TO MOBILE DATA");
      return true;
    } else if (connectivityResult == ConnectivityResult.wifi) {
      print("CONNECTED TO WIFI");
      return true;
    }
    print("NOT CONNECTED");
    return false;
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

  Future<void> initiateAll(context) async {
    //var isOnline = await isNetworkAvailable();
    //if (isOnline == true) {
    await setAvailLanguages();
    await initiateTypesAdjectives(context, true);
    //}
    isInitiated = true;
  }

  Future<void> initiateTypesAdjectives(context, isSetState) async {
    isInitiatingTypesAdjectives = true;
    String appLanguageId = appLanguage["LID"];
    print("initiateTypesAdjectives called, appLanguageId = $appLanguageId");
    List<String> availLIDs =
        List<String>.from(availLanguages.map((lang) => lang["LID"]).toList());
    print("initiateTypesAdjectives availLIDs = $availLIDs");
    if (!availLIDs.contains(appLanguage["LID"])) {
      appLanguageId = "8"; //ENGLISH
    }
    bool isRequestSuccess = true;
    Response response = http.Response("", 200);
    try {
      response = await http.get(Uri.parse(
          'https://www.learnfactsquick.com/lfq_app_php/get_alp_tabs_complete_app.php?language_id=${selectedAcrosticsLanguage["LID"]}&app_language_id=$appLanguageId'));
    } catch (e) {
      isRequestSuccess = false;
      isAppOnline = false;
      await doNetworkChange();
      setState(() {
        isInitiatingTypesAdjectives = false;
      });
    }
    if (isRequestSuccess == true) {
      if (response.statusCode == 200) {
        // If the server returns a 200 OK response, parse the JSON data
        final Map<String, dynamic> data = json.decode(response.body);
        print("initiateTypesAdjectives STATUS=200!!!");
        if (data["SUCCESS"] == true) {
          if (isSetState == true) {
            setState(() {
              finishInitiateTypesAdjectives(appLanguageId, data);
              isInitiatingTypesAdjectives = false;
            });
          } else {
            setState(() {
              finishInitiateTypesAdjectives(appLanguageId, data);
              isInitiatingTypesAdjectives = false;
            });
          }
          print("initiateTypesAdjectives DONE SUCCESSFULLY");
        } else {
          await showPopup(context, data["ERROR"]);
          setState(() {
            isInitiatingTypesAdjectives = false;
          });
        }
      } else {
        await showPopup(
            context, FlutterI18n.translate(context, "NETWORK_ERROR"));
        setState(() {
          isInitiatingTypesAdjectives = false;
        });
      }
    }
  }

  finishInitiateTypesAdjectives(appLanguageId, data) {
    try {
      completedTables = List<dynamic>.from(data["COMPLETED_TABLES"]);
      allCategories = data["CATEGORIES"];
      List<String> uniqueTypes = List<String>.from(Set.from(completedTables
          .map((tbl) => tbl["Type"])
          .whereType<String>()
          .toSet()));
      dropdownTypes = [];
      print("initiateTypesAdjectives appLanguageId = $appLanguageId");
      for (int u = 0; u < uniqueTypes.length; u++) {
        dropdownTypes.add({
          "Type": uniqueTypes[u],
          "Trans": allCategories[uniqueTypes[u]][appLanguageId]
        });
      }
      //dropdownTypes = List<dynamic>.from(completedTables);
      print("dropdownTypes = ${json.encode(dropdownTypes)}");
      selectedAllAdjectives = [];
      for (int i = 0; i < completedTables.length; i++) {
        selectedAllAdjectives.add([]);
      }
      if (dropdownTypes.isNotEmpty) {
        selectedType = dropdownTypes[0];
        dropdownAdjectives = getDropdownAdjectives(dropdownTypes[0]["Type"]);
        selectedAdjective = dropdownAdjectives[0];
      }
    } catch (e) {
      print("ERROR FINISH initiateTypesAdjectives = $e");
    }
  }

  List<String> getDropdownAdjectives(String type) {
    print("getDropdownAdjectives type $type");
    List<String> myDropdownAdjectives = List<String>.from((List<dynamic>.from(
            completedTables
                .where((dynamic tableObj) => tableObj["Type"] == type)))
        .map((dynamic tableObj) => tableObj["Table"])
        .whereType<String>()
        .toSet()
        .toList());
    print(
        "getDropdownAdjectives RETURNING myDropdownAdjectives = ${json.encode(myDropdownAdjectives)}");
    return myDropdownAdjectives;
  }

  setType(type) {
    print("setType type = $type");
    if (selectedType != type) {
      setState(() {
        selectedType = type;
        List<String> gotDropdownAdjectives =
            getDropdownAdjectives(type["Type"]);
        if (gotDropdownAdjectives.isNotEmpty) {
          dropdownAdjectives = List<String>.from(gotDropdownAdjectives);
        }
        if (dropdownAdjectives.isNotEmpty) {
          selectedAdjective = dropdownAdjectives[0];
        }
        selectedTypeIndex = dropdownTypes.indexOf(type);
      });
    }
  }

  setAdjective(adjective) {
    setState(() {
      selectedAdjective = adjective;
    });
  }

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

  String buildUrlString(params) {
    //print("buildUrlString called, params = $params");
    var ret = [];
    for (var p in params.keys) {
      ret.add("${Uri.encodeComponent(p)}=${Uri.encodeComponent(params[p])}");
    }
    //print("buildUrlString ret = {$ret}");
    return ret.join('&');
  }

  Future<void> doCreateAcrostics(context) async {
    if (validateCreate() == false) {
      return;
    } else {
      showInterstitialAd(() async {
        if (getIsUseOffline() == true) {
          await createAcrosticsOld(context);
        } else {
          await createAcrosticsNew(context);
        }
      });
    }
  }

  bool validateCreate() {
    inputWord = inputController.text;
    if (inputWord.trim() == '') {
      showPopup(context, FlutterI18n.translate(context, "INPUT_WORD_RETRY"));
      return false;
    } else if (countAllSelected == 0) {
      showPopup(
          context, FlutterI18n.translate(context, "PROMPT_SELECT_ADJECTIVES"));
      return false;
    }
    return true;
  }

  Future<void> createAcrosticsOld(context) async {
    print("createAcrosticsOld called");
    var progressMessage =
        FlutterI18n.translate(context, "LOAD_ACROSTICS_OFFLINE");
    showProgress(context, progressMessage);
    await Future.delayed(Duration(milliseconds: 200));
    dynamic response = {
      "SUCCESS": true,
      "ERROR": "",
      "RESULTS": "",
      "ENTRIES": [],
    };
    var inputSplit = inputWord.toUpperCase().split("");
    uniqueLetters = List<String>.from(Set<String>.from(inputSplit));
    List<String> selectedSendAdjectives = [];
    List<dynamic> selectedTypesAdjectives = [];
    print(
        "createAcrostics selectedAllAdjectives = ${json.encode(selectedAllAdjectives)}");
    for (var i = 0; i < selectedAllAdjectives.length; i++) {
      for (var j = 0; j < selectedAllAdjectives[i].length; j++) {
        selectedSendAdjectives.add(selectedAllAdjectives[i][j]);
        selectedTypesAdjectives.add({
          "type": dropdownTypes[i]["Type"],
          "adjective": selectedAllAdjectives[i][j]
        });
      }
    }
    List<Map<String, List<dynamic>>> themeEntries = [];
    for (int i = 0; i < selectedSendAdjectives.length; i++) {
      themeEntries = List<Map<String, List<dynamic>>>.from(
          allEntries[selectedSendAdjectives[i]]!);
      for (int j = 0; j < themeEntries.length; j++) {
        for (int k = 0; k < uniqueLetters.length; k++) {
          for (int l = 0; l < themeEntries[j][uniqueLetters[k]]!.length; l++) {
            response["ENTRIES"].add({
              "DICT": "0",
              "Table_name": selectedSendAdjectives[i],
              "Letter": uniqueLetters[k],
              "Entry": themeEntries[j][uniqueLetters[k]]![l]
            });
          }
        }
      }
    }

    List<Map<String, String>> dicVars = [];
    List<String> dicWords = [];
    for (int i = 0; i < uniqueLetters.length; i++) {
      dicVars = List<Map<String, String>>.from(myDic[uniqueLetters[i]]!);
      for (int j = 0; j < dicVars.length; j++) {
        dicWords = dicVars[j].keys.toList();
        for (int k = 0; k < dicWords.length; k++) {
          for (int l = 0; l < selectedSendAdjectives.length; l++) {
            if (dicVars[j][dicWords[k]]!.contains(selectedSendAdjectives[l])) {
              response["ENTRIES"].add({
                "DICT": "1",
                "Table_name": selectedSendAdjectives[l],
                "Letter": uniqueLetters[i],
                "Word": dicWords[k],
                "Entry": dicVars[j][dicWords[k]]
              });
            }
          }
        }
      }
    }
    hideProgress(context);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => TablePage(
                inputWord: inputWord,
                selectedTypesAdjectives: selectedTypesAdjectives,
                entries: List<dynamic>.from(response["ENTRIES"]))));
  }

  Future<void> createAcrosticsNew(context) async {
    print("createAcrosticsNew called");

    print("CREATING ACROSTICS!");
    inputWord = inputController.text;
    var progressMessage =
        FlutterI18n.translate(context, "LOAD_ACROSTICS_ONLINE");
    showProgress(context, progressMessage);
    var inputSplit = inputWord.split("");
    uniqueLetters = List<String>.from(Set<String>.from(inputSplit));
    List<String> selectedSendAdjectives = [];
    List<dynamic> selectedTypesAdjectives = [];
    print(
        "createAcrostics selectedAllAdjectives = ${json.encode(selectedAllAdjectives)}");
    for (var i = 0; i < selectedAllAdjectives.length; i++) {
      for (var j = 0; j < selectedAllAdjectives[i].length; j++) {
        selectedSendAdjectives.add(selectedAllAdjectives[i][j]);
        selectedTypesAdjectives.add({
          "type": dropdownTypes[i]["Type"],
          "adjective": selectedAllAdjectives[i][j]
        });
      }
    }
    String appLanguageId = appLanguage["LID"];
    print("initiateTypesAdjectives called, appLanguageId = $appLanguageId");
    List<String> availLIDs =
        List<String>.from(availLanguages.map((lang) => lang["LID"]).toList());
    print("initiateTypesAdjectives availLIDs = $availLIDs");
    if (!availLIDs.contains(appLanguage["LID"])) {
      appLanguageId = "8"; //ENGLISH
    }
    Map<String, dynamic> params = {
      "selectedThemes": selectedSendAdjectives,
      "uniqueLetters": uniqueLetters,
      "languageId": selectedAcrosticsLanguage["LID"],
      "appLanguageId": appLanguageId
    };
    print(
        "createAcrostics NEXT CALLING get_alphabet_tables_completed_entries_app");
    bool isRequestSuccess = true;
    Response response = http.Response("", 200);
    try {
      response = await http.post(
          Uri.parse('https://www.learnfactsquick.com/lfq_app_php/get_acrs.php'),
          body: json.encode(params));
    } catch (e) {
      hideProgress(context);
      isRequestSuccess = false;
      isAppOnline = false;
      await doNetworkChange();
    }
    if (isRequestSuccess == true) {
      //print("createAcrostics GENERATE_ALL RESPONSE = $response");
      if (response.statusCode == 200) {
        // If the server returns a 200 OK response, parse the JSON data
        final Map<String, dynamic> data = json.decode(response.body);
        print(
            "createAcrostics get_alphabet_tables_completed_entries_app DECODED data! = ${json.encode(data)}");
        if (data["SUCCESS"] == true) {
          hideProgress(context);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => TablePage(
                      inputWord: inputWord,
                      selectedTypesAdjectives: selectedTypesAdjectives,
                      entries: List<dynamic>.from(data["ENTRIES"]))));
        } else {
          print("createAcrostics SUCCESS=false");
          hideProgress(context);
          showPopup(context,
              "${FlutterI18n.translate(context, "ERROR_MAKING_ACROSTICS")}: ${data["ERROR"]}");
        }
      } else {
        showPopup(context,
            "${FlutterI18n.translate(context, "ERROR_MAKING_ACROSTICS")}: ${json.encode(e)}");
        hideProgress(context);
      }
    }
  }

  createSelectedDropdown() {
    selectedDropdownItems = [];
    countAllSelected = 0;
    for (var i = 0; i < selectedAllAdjectives.length; i++) {
      for (var j = 0; j < selectedAllAdjectives[i].length; j++) {
        countAllSelected++;
        selectedDropdownItems.add(Padding(
          padding: const EdgeInsets.all(2.0),
          child: Container(
              width: 120,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.horizontal(), // Apply a border radius
                color: Colors.transparent,
              ),
              child: ElevatedButton(
                  style: ButtonStyle(),
                  onPressed: () => cancelSelected(i, j),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            maxLines: null,
                            selectedAllAdjectives[i][j],
                            overflow: TextOverflow.clip,
                            style: TextStyle(height: 1.0),
                          ),
                        ),
                        Icon(Icons.delete)
                      ]))),
        ));
        /*selectedDropdownItems.add(DropdownMenuItem(
          value: selectedAllAdjectives[i][j],
          child: Container(
            decoration: BoxDecoration(color: Colors.white),
            child: Row(
              children: <Widget>[
                Text(dropdownTypes[i] +
                    (": ").toString() +
                    selectedAllAdjectives[i][j]),
                SizedBox(width: 8),
                InkWell(
                    onTap: () => {cancelSelected(i, j)},
                    child: Icon(FontAwesomeIcons.ban)),
              ],
            ),
          ),
        ));
        */
      }
    }
    //return selectedDropdownItems;
  }

  cancelSelected(i, j) {
    selectedDropdownValue = "SOMETHING_SELECTED";
    setState(() {
      selectedAllAdjectives[i].removeAt(j);
      createSelectedDropdown();
      selectedDropdownValue = "NULL";
    });
  }

  convertDynamicDoubleListDynamic(myDynamic) {
    List<List<dynamic>> myList = [];
    if (myDynamic is List<dynamic>) {
      // Loop through the dynamic data and check if each element is a List<dynamic>
      for (dynamic item in myDynamic) {
        if (item is List<dynamic>) {
          // Cast the inner list to List<dynamic> and add it to the result
          myList.add(item);
        } else {
          //JUST ADD EMPTY LIST AS PLACEHOLDER:
          myList.add([]);
        }
      }
    }
    return myList;
  }

  copyToClipboard(context, myText) {
    Clipboard.setData(ClipboardData(text: myText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              "${FlutterI18n.translate(context, "TEXT")}, '$myText', ${FlutterI18n.translate(context, "COPIED_TO_CLIPBOARD")}.")),
    );
  }

  static final AdRequest request = AdRequest(
    keywords: <String>[
      'acrostics generator',
      'memorize lists',
      'improve memory',
      'remember words',
      'define words',
      'study tool',
      'learning tool'
    ],
    contentUrl: 'https://learnfactsquick.com/#/alphabet_acrostics_generator',
    nonPersonalizedAds: true,
  );

  void createInterstitialAd() {
    print("createInterstitialAd interstitialAd CALLED.");
    //setState(() {
    //  isMakeMajor = false;
    //});
    var adUnitId = Platform.isAndroid
        ? 'ca-app-pub-8514966468184377/1433817858'
        : 'ca-app-pub-8514966468184377/1586501727';
    print("Using appId: $adUnitId kDebugMode = $kDebugMode");
    InterstitialAd.load(
        adUnitId: adUnitId,
        request: request,
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            print('My InterstitialAd $ad loaded');
            interstitialAd = ad;
            numInterstitialLoadAttempts = 0;
            interstitialAd!.setImmersiveMode(true);
            print("interstitialAd == null ? : ${interstitialAd == null}");
            //setState(() {
            //  isMakeMajor = true;
            //});
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('interstitialAd failed to load: $error.');
            numInterstitialLoadAttempts += 1;
            interstitialAd = null;
            //setState(() {
            //  isMakeMajor = false;
            //});
            if (numInterstitialLoadAttempts < maxFailedLoadAttempts) {
              createInterstitialAd();
            }
          },
        ));
  }

  void showInterstitialAd(Function callback) {
    print("showInterstitialAd called");
    if (interstitialAd == null) {
      print('Warning: attempt to show interstitialAd before loaded.');
      callback();
    } else {
      Random random = Random();
      var isShowAd =
          (kIsWeb == false && random.nextInt(1000) < MyApp().ofThousandShowAds);
      if (isShowAd != true) {
        callback();
      } else {
        interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdShowedFullScreenContent: (InterstitialAd ad) =>
              debugPrint('interstitialAd onAdShowedFullScreenContent.'),
          onAdDismissedFullScreenContent: (InterstitialAd ad) {
            ad.dispose();
            createInterstitialAd();
            callback();
          },
          onAdFailedToShowFullScreenContent:
              (InterstitialAd ad, AdError error) {
            ad.dispose();
            createInterstitialAd();
            callback();
          },
        );
        interstitialAd!.show();
        interstitialAd = null;
      }
    }
  }

  getTransLangValue(dynamic value) {
    return "${value["name1"]}(${FlutterI18n.translate(context, value["name2"])})";
  }

  resetMyList() {
    print("resetMyList called");

    dynamic myLanguage = List<dynamic>.from(languages
        .where((dynamic lang) =>
            lang["value"] == selectedAcrosticsLanguage["value"])
        .toList())[0];
    List<dynamic> foundLangs = List<dynamic>.from(availLanguages
        .where((myEle) => myEle["value"] == myLanguage["value"])
        .toList());

    if (foundLangs.isNotEmpty) {
      dynamic myLang = foundLangs[0];
      selectedAcrosticsLanguage = myLang;
    } else {
      selectedAcrosticsLanguage = null;
    }
  }

  setLanguage(BuildContext context, newLanguage) {
    print("setLanguage called, newLanguage = $newLanguage");
    Future.delayed(Duration(microseconds: 10), () {
      setState(() {
        selectedAcrosticsLanguage = newLanguage;
        for (var i = 0; i < selectedAllAdjectives.length; i++) {
          selectedAllAdjectives[i] = [];
        }
        createSelectedDropdown();
        initiateTypesAdjectives(context, true);
      });
    });
  }

  isLinkPlayStore() {
    return (kIsWeb || Platform.isAndroid);
  }

  isLinkAppStore() {
    return (kIsWeb || Platform.isIOS);
  }

  updateSelf() {
    print("MyHomeState updateSelf called");
    setState(() {});
  }

  bool getIsUseOffline() {
    String appLanguageId = appLanguage["LID"];
    List<String> availLIDs =
        List<String>.from(availLanguages.map((lang) => lang["LID"]).toList());
    if (!availLIDs.contains(appLanguage["LID"])) {
      appLanguageId = "8"; //ENGLISH
    }
    String languageId = selectedAcrosticsLanguage["LID"];
    bool isUse =
        ((languageId == "8" && appLanguageId == "8") || isAppOnline == false);
    return isUse;
  }

  @override
  void dispose() {
    super.dispose();
    subscription.cancel();
    if (kIsWeb == false) {
      print("DISPOSING interstitialAd !!!");
      interstitialAd?.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle commonTextStyle = TextStyle(
      fontSize: 16.0,
      fontWeight: FontWeight.normal,
      fontFamily: 'Arial', // Specify the font family
    );
    double screenWidth = MediaQuery.of(context).size.width;
    double linkButtonSize = screenWidth * 0.7 > 275 ? screenWidth * 0.7 : 275;
    double linksFontSize =
        (screenWidth * 0.014 + 4) < 10 ? 10 : (screenWidth * 0.014 + 4);
    return isInitiated == false
        ? Center(
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
                    "${FlutterI18n.translate(context, "LOADING")}...",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ],
              ),
            ),
          )
        : Scaffold(
            key: scaffoldKey,
            appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                title: Text(FlutterI18n.translate(context, "APP_TITLE")),
                actions: <Widget>[
                  Menu(context: context, page: 'main', updateParent: updateSelf)
                ]),
            body: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Center(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                      Visibility(
                          visible: isAppOnline == false,
                          child: Container(
                              height: linksFontSize + 3,
                              width: double.infinity,
                              color: Colors.yellow,
                              child: Center(
                                child: Text(
                                    FlutterI18n.translate(
                                        context, "APP_OFFLINE"),
                                    style: TextStyle(fontSize: linksFontSize)),
                              ))),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                        child: Text(
                            FlutterI18n.translate(
                                context, "PROMPT_INPUT_ACRONYM"),
                            style: TextStyle(fontSize: 12)),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                        child: TextField(
                            enabled: isInitiated,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-Z]')),
                            ],
                            controller: inputController,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: FlutterI18n.translate(
                                    context, "PROMPT_INPUT_WORD"),
                                hintStyle: TextStyle(fontSize: 12)),
                            keyboardType: TextInputType.text,
                            onEditingComplete: () {
                              //if (Platform.isAndroid) {
                              //  focusNode.unfocus();
                              //} else if (Platform.isIOS) {
                              FocusScope.of(context).unfocus();
                              //}
                              doCreateAcrostics(context);
                            }),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                        child: Text(
                            "${FlutterI18n.translate(context, "CHOOSE_TYPE")}:",
                            style: TextStyle(fontSize: 12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                        child: Container(
                            width: screenWidth - 50,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors
                                      .black), // Set the border color to transparent
                            ),
                            child: Visibility(
                              visible: dropdownTypes.isNotEmpty,
                              child: DropdownButtonHideUnderline(
                                  child: DropdownButton<dynamic>(
                                value: selectedType,
                                onChanged: (newValue) {
                                  setType(newValue);
                                  //appState.selectedType = newValue!;
                                  //});
                                },
                                items: dropdownTypes
                                    .map<DropdownMenuItem<dynamic>>(
                                        (dynamic value) {
                                  return DropdownMenuItem<dynamic>(
                                    value: value,
                                    child: SizedBox(
                                      width: screenWidth - 100,
                                      child: ListTile(
                                        title: Text(value["Trans"]),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              )),
                            )),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                        child: Text(
                            "${FlutterI18n.translate(context, "CHOOSE_ADJECTIVE")}:",
                            style: TextStyle(fontSize: 12)),
                      ),
                      Visibility(
                        visible: selectedTypeIndex >= 0 &&
                            selectedAllAdjectives.length > selectedTypeIndex &&
                            dropdownAdjectives.isNotEmpty,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                          child: Visibility(
                            visible: dropdownAdjectives.isNotEmpty &&
                                isInitiatingTypesAdjectives == false,
                            child: DropDownMultiSelect(
                              separator: ", ",
                              decoration: InputDecoration(
                                labelText: "",
                                labelStyle: commonTextStyle,
                              ),
                              whenEmpty: selectedType["Type"] != null
                                  ? FlutterI18n.translate(
                                      context, "SELECT_TYPE_ADJECTIVES",
                                      translationParams: {
                                          "typeAdjs":
                                              "'${selectedType["Trans"]}'"
                                        })
                                  : "",
                              hintStyle: commonTextStyle,
                              isDense: true,
                              onChanged: (List<String> x) {
                                setState(() {
                                  if (selectedTypeIndex >= 0 &&
                                      selectedAllAdjectives.length >
                                          selectedTypeIndex) {
                                    selectedAllAdjectives[selectedTypeIndex] =
                                        x;
                                  }
                                  createSelectedDropdown();
                                });
                              },
                              options: dropdownAdjectives,
                              selectedValues:
                                  selectedAllAdjectives[selectedTypeIndex],
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                          visible: countAllSelected == 0,
                          child: Padding(
                              padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                              child: Text(FlutterI18n.translate(
                                  context, "NOTHING_SELECTED")))),
                      Visibility(
                          visible: countAllSelected > 0,
                          child: Padding(
                              padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                              child: Text(countAllSelected.toString() +
                                  (" ${FlutterI18n.translate(context, "SELECTED")}.")
                                      .toString()))),
                      Visibility(
                        visible: countAllSelected > 0,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                          child: Container(
                              width: MediaQuery.of(context).size.width,
                              constraints: BoxConstraints(maxHeight: 100),
                              child: SingleChildScrollView(
                                  child: Wrap(
                                      direction: Axis.horizontal,
                                      children: selectedDropdownItems))),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 10, 0),
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.25,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                          "${FlutterI18n.translate(context, "CHOOSE_ACROSTICS_LANGUAGE")}:",
                                          style: TextStyle(
                                              fontSize: linksFontSize)),
                                    ),
                                  )),
                              DropdownButton<dynamic>(
                                value: selectedAcrosticsLanguage,
                                onChanged: (newLanguage) {
                                  setLanguage(context, newLanguage);
                                },
                                hint: Text(FlutterI18n.translate(
                                    context, "SELECT_LANGUAGE")),
                                items: availLanguages
                                    .map<DropdownMenuItem<dynamic>>(
                                        (dynamic value) {
                                  return DropdownMenuItem<dynamic>(
                                    value: value,
                                    child: Text(getTransLangValue(value),
                                        style:
                                            TextStyle(fontSize: linksFontSize)),
                                  );
                                }).toList(),
                              ),
                            ]),
                      ),
                      Row(
                        children: [
                          Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.9,
                                child: ElevatedButton(
                                    style: ButtonStyle(
                                        shape: WidgetStateProperty.all(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                5.0), // Adjust the radius as needed
                                          ),
                                        ),
                                        backgroundColor: goButtonColor),
                                    onPressed: (isInitiated == true)
                                        ? () async {
                                            doCreateAcrostics(context);
                                          }
                                        : null,
                                    child: Text(
                                        FlutterI18n.translate(
                                            context, "CREATE_ACROSTICS"),
                                        style: TextStyle(fontSize: 12))),
                              )),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.all(10.0),
                        child: SizedBox(
                            width: linkButtonSize,
                            child: ElevatedButton(
                              onPressed: () {
                                launchUrl(
                                    Uri.parse('https://learnfactsquick.com'));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                    255,
                                    204,
                                    159,
                                    252), // Change the button's background color
                                foregroundColor:
                                    Colors.white, // Change the text color
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Image.asset(
                                    'assets/images/lfq_icon.png',
                                    width: 25, // Set the desired width
                                    height: 25, // Set the desired height
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                      FlutterI18n.translate(
                                          context, "PROMPT_TOOLS_WEBSITE"),
                                      style: TextStyle(
                                          fontSize: linksFontSize)), // Text
                                ],
                              ),
                            )),
                      ),
                      Visibility(
                        visible: isLinkPlayStore(),
                        child: Padding(
                          padding: EdgeInsets.all(10.0),
                          child: SizedBox(
                              width: linkButtonSize,
                              child: ElevatedButton(
                                onPressed: () {
                                  launchUrl(Uri.parse(
                                      'https://play.google.com/store/apps/dev?id=5263177578338103821'));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors
                                      .green, // Change the button's background color
                                  foregroundColor:
                                      Colors.white, // Change the text color
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(Icons
                                        .play_circle_fill), // Google Play icon
                                    SizedBox(
                                        width:
                                            8), // Add some space between the icon and text
                                    Text(
                                        FlutterI18n.translate(
                                            context, "PROMPT_APPS_PLAY_STORE"),
                                        style: TextStyle(
                                            fontSize: linksFontSize)), // Text
                                  ],
                                ),
                              )),
                        ),
                      ),
                      Visibility(
                        visible: isLinkAppStore(),
                        child: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: SizedBox(
                                width: linkButtonSize,
                                child: ElevatedButton(
                                  onPressed: () {
                                    launchUrl(Uri.parse(
                                        'https://apps.apple.com/us/developer/keith-harryman/id1693739510'));
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors
                                        .blue, // Change the button's background color
                                    foregroundColor:
                                        Colors.white, // Change the text color
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Icon(Icons
                                          .download_sharp), // Google Play icon
                                      SizedBox(
                                          width:
                                              8), // Add some space between the icon and text
                                      Text(
                                          FlutterI18n.translate(
                                              context, "PROMPT_APPS_APP_STORE"),
                                          style: TextStyle(
                                              fontSize: linksFontSize)), // Text
                                    ],
                                  ),
                                ))),
                      ),
                    ]))),
          );
  }
}
