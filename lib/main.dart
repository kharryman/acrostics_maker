import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:acrostics_maker/acrostics_page.dart';
import 'package:acrostics_maker/globals.dart';
import 'package:acrostics_maker/services/ads.dart';
import 'package:acrostics_maker/services/helpers.dart';
import 'package:acrostics_maker/components/menu.dart';
import 'package:acrostics_maker/services/iap.dart';
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
import 'package:url_launcher/url_launcher.dart';

// ignore: library_prefixes
import 'table.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:multiselect/multiselect.dart';
//offline:
import 'data/alp.dart';
//to get reviews:
import 'package:advanced_in_app_review/advanced_in_app_review.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

const String testDevice = '974550CBC7D4EA4718A67165E2E3B868';
const String myIpad = '00008020-0014301102D1002E';
const String myIphone11 = 'A8EC231A-DCFC-405C-8A0D-62E9F5BA1918';

List<String> dropdownAdjectives = [];
dynamic allCategories = [];
dynamic selectedType;
String selectedAdjective = '';
bool isInitiated = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("main RETURNING $kIsWeb");
  if (kIsWeb == false) {
    var testDevices = <String>[];
    if (Platform.isAndroid) {
      testDevices = [testDevice];
      Globals.removeAdsProductId = "remove_ads";
    } else if (Platform.isIOS) {
      testDevices = [myIpad, myIphone11];
      Globals.removeAdsProductId = "remove_ads_acrostics_maker";
    }
    MobileAds.instance
      ..initialize()
      ..updateRequestConfiguration(RequestConfiguration(
        testDeviceIds: testDevices,
      ));
    InAppPurchase.instance.isAvailable().then((available) {
      if (!available) {
        debugPrint("In-app purchases not available on this device.");
      }
    });
  } else {
    debugPrint("main NOT SHOWING AD");
  }
  //String deviceId = await getDeviceId();
  //debugPrint('Device ID: $deviceId');
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (context) => AppData(), child: MyApp())
  ], child: MyApp()));
}

class AppData extends ChangeNotifier {
  void setIsAds(bool myIsAds) {
    debugPrint("AppData setIsAds called myIsAds = $myIsAds");
    Globals.isAds = myIsAds;
  }

  bool menuOpen = false;
  void setMenuOpen(bool isOpen) {
    menuOpen = isOpen;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static MyAppState? instance;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  List<BaseDecodeStrategy> decodeStrategies = [JsonDecodeStrategy()];
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  late StreamSubscription<List<ConnectivityResult>> connSubscription;
  final HelpersService helpers = HelpersService();
  Locale _locale = const Locale('en');

  @override
  void initState() {
    super.initState();
    instance = this;
    WidgetsBinding.instance.addObserver(this);

    Globals.selectedAcrosticsLanguage = Globals.languages.firstWhere(
        (dynamic lang) => lang["LID"] == Globals.defaultLanguage["LID"]);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setSavedLanguage();
    });
  }

  void setSavedLanguage() async {
    String savedLanguageCode =
        (await HelpersService.getData("LANGUAGE")) ?? "en";
    Globals.appLanguage = Globals.languages.firstWhere(
      (item) => item["value"] == savedLanguageCode,
    );
    Locale locale = HelpersService.getAppLocale(savedLanguageCode);
    debugPrint(
      "setSavedLanguage savedLanguageCode = $savedLanguageCode, locale = $locale",
    );
    //if (!mounted) return;
    setState(() {
      _locale = locale;
    });
  }

  Future<void> changeLanguage(String passedLanguageCode) async {
    debugPrint(
        "changeLanguage called, passedLanguageCode = $passedLanguageCode");
    await HelpersService.setData("LANGUAGE", passedLanguageCode);
    Globals.appLanguage = Globals.languages.firstWhere(
      (item) => item["value"] == passedLanguageCode,
    );
    Locale locale = HelpersService.getAppLocale(passedLanguageCode);
    if (!mounted) return;
    setState(() {
      _locale = locale;
    });
    if (mounted) {
      try {
        //await FlutterI18n.refresh(context, locale);
      } catch (e, st) {
        debugPrint("FlutterI18n refresh failed: $e\n$st");
      }
    }
  }

  static MyAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<MyAppState>();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AdService.disposeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _locale,
      title: 'Acrostics Maker',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      localizationsDelegates: [
        FlutterI18nDelegate(
          translationLoader: FileTranslationLoader(
            decodeStrategies: decodeStrategies,
            basePath: "assets/i18n",
            fallbackFile: "en",
            useCountryCode: false,
          ),
          missingTranslationHandler: (key, locale) {
            if (Globals.isAppStarted == true) {
              debugPrint(
                "--- Missing Key: $key, languageCode: ${locale?.languageCode}",
              );
            }
          },
        ),
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: const [
        Locale('af'),
        Locale('bs'),
        Locale('cs'),
        Locale('cy'),
        Locale('da'),
        Locale('de'),
        Locale('en'),
        Locale('es'),
        Locale('et'),
        Locale('eu'),
        Locale('fi'),
        Locale('fr'),
        Locale('ga'),
        Locale('hr'),
        Locale('hu'),
        Locale('id'),
        Locale('it'),
        Locale('lt'),
        Locale('ms'),
        Locale('pl'),
        Locale('pt'),
        Locale('ro'),
        Locale('sk'),
        Locale('sl'),
        Locale('sv')
      ],
      home: MyHome(),
    );
  }
}

// ignore: must_be_immutable
class MyHome extends StatefulWidget with WidgetsBindingObserver {
  @override
  MyHomeState createState() => MyHomeState();
}

class MyHomeState extends State<MyHome> with WidgetsBindingObserver {
  late StreamSubscription<ConnectivityResult> subscription;
  Locale _locale = const Locale('en');

  BannerAd? bannerAd;
  bool isBannerAdReady = false;

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

  bool isPushNavigationStack = true;
  bool isAndroid = kIsWeb == false ? false : false;
  bool isIOS = kIsWeb == false ? false : false;

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
  StreamSubscription<List<PurchaseDetails>>? purchaseSubscription;

  late final StreamSubscription<List<ConnectivityResult>>
      connectivitySubscription;

  @override
  initState() {
    super.initState();
    debugPrint(
        "MyHomeState initState:Globals.availLanguages = ${Globals.availLanguages}, selectedAcrosticsLanguage = ${Globals.selectedAcrosticsLanguage}");
    if (kIsWeb == false) {
      if (Platform.isIOS) {
        initializeInAppPurchase();
      }
      AdvancedInAppReview()
          .setMinDaysBeforeRemind(7)
          .setMinDaysAfterInstall(2)
          .setMinLaunchTimes(2)
          .setMinSecondsBeforeShowDialog(4)
          .monitor();
    }
    initConnectivityListener();

    if (kIsWeb == false && Globals.isAds == true) {
      AdService.loadInterstitial();
    }
    isInitiated = true;
  }

  void initConnectivityListener() {
    // Listen for connectivity changes
    final Connectivity connectivity = Connectivity();
    connectivitySubscription = connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final result =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      Globals.isAppOnline = result != ConnectivityResult.none;
      debugPrint(
          '🔌 Connectivity changed: $result  |  isOnline=${Globals.isAppOnline}');
      doNetworkChange();
    });

    // Check initial state
    connectivity.checkConnectivity().then((List<ConnectivityResult> results) {
      final result =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      Globals.isAppOnline = result != ConnectivityResult.none;
      debugPrint(
          '📶 Initial connectivity: $result  |  isOnline=${Globals.isAppOnline}');
      doNetworkChange();
    });
  }

  doNetworkChange() async {
    if (Globals.isAppOnline == false) {
      setState(() {
        debugPrint("OFFLINE...");
        Globals.availLanguages = Globals.languages
            .where(
                (dynamic lang) => lang["LID"] == Globals.defaultLanguage["LID"])
            .toList();
        Globals.selectedAcrosticsLanguage = Globals.languages.firstWhere(
            (dynamic lang) => lang["LID"] == Globals.defaultLanguage["LID"]);
        //debugPrint("selectedAcrosticsLanguage = ${jsonEncode(selectedAcrosticsLanguage)}");
        isLanguagesLoading = false;
        Globals.dropdownTypes = List<dynamic>.from(Globals.defaultTypes);
        finishInitiateTypesAdjectives("8", Globals.defaultData);
        //myList = ["English(English)"];
      });
    } else {
      BuildContext? context = scaffoldKey.currentContext;
      await initiateAll(context);
      if (kIsWeb == false) {
        await initializeInAppPurchase();
        AdService.checkAds();
        if (Globals.isAds == true) {
          bannerAd = await AdService.createBanner(
            onLoaded: () => setState(() {}),
          );
        }
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (kIsWeb == false) {
        if (Platform.isAndroid) {
          initializeInAppPurchase();
        }
        if (Globals.isAppOnline) {
          AdService.checkAds();
        }
      }
    }
  }

  Future<void> initializeInAppPurchase() async {
    final InAppPurchase iap = InAppPurchase.instance;
    final bool isAvailable = await iap.isAvailable();

    if (isAvailable) {
      if (purchaseSubscription != null) {
        await purchaseSubscription!.cancel();
      }

      purchaseSubscription =
          iap.purchaseStream.listen((List<PurchaseDetails> purchases) async {
        PurchaseDetails? purchaseRemoveAds = purchases.isNotEmpty
            ? purchases.firstWhere(
                (purchase) => purchase.productID == Globals.removeAdsProductId)
            : null;

        if (purchaseRemoveAds != null) {
          if (purchaseRemoveAds.status == PurchaseStatus.purchased ||
              purchaseRemoveAds.status == PurchaseStatus.restored) {
            debugPrint(
                "main initializeInAppPurchase ${Globals.removeAdsProductId} ${purchaseRemoveAds.status == PurchaseStatus.purchased ? "PURCHASED" : "RESTORED"}!");
            if (Globals.isForceAds == false) {
              setState(() {
                disposeAds();
                Globals.isAds = false;
              });
            }
            if (purchaseRemoveAds.pendingCompletePurchase) {
              debugPrint("Completing purchase...");
              await MenuState().showSuccessThanksBuy();
              await InAppPurchase.instance.completePurchase(purchaseRemoveAds);
            }
          } else if (purchaseRemoveAds.status == PurchaseStatus.pending) {
            debugPrint(
                "IAP.listen purchaseRemoveAds.status == PurchaseStatus.pending ...");
            //await InAppPurchase.instance.completePurchase(purchaseRemoveAds);
            await MenuState().showSuccessThanksBuy();
          } else if (purchaseRemoveAds.status == PurchaseStatus.error) {
            debugPrint(
                "main initializeInAppPurchase ${Globals.removeAdsProductId} Purchase error: ${purchaseRemoveAds.error}.");
            await HelpersService.showPopup(context,
                message:
                    "${FlutterI18n.translate(context, "PROMPT_PURCHASING_ERROR")}: ${purchaseRemoveAds.error}");
          }
        }
      }, onError: (error) {
        debugPrint("Purchase Error: $error");
      }, onDone: () {
        purchaseSubscription?.cancel(); // Clean up after use
      }, cancelOnError: true);
      await IAP.restorePurchases();
    }
  }

  setAvailLanguages() async {
    //showProgress(
    //    context, FlutterI18n.translate(context, "PROGRESS_ADD_COMMENT"));
    if (Globals.isAppOnline == false) {
      HelpersService.showPopup(context,
          message: FlutterI18n.translate(context, "NOT_ONLINE"));
    } else {
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
        Globals.isAppOnline = false;
        await doNetworkChange();
      }
      if (isRequestSuccess == true) {
        //hideProgress(context);
        if (response.statusCode == 200) {
          data = Map<String, dynamic>.from(json.decode(response.body));
          debugPrint("GET AVAIL LANGUAGES data = ${json.encode(data)}");
          if (data["SUCCESS"] == true) {
            debugPrint("GOT LANGUAGES = ${json.encode(data)}");
            gotLanguages = data["LANGUAGES"];
            Globals.DB_PREFIX = data["DB_PREFIX"];
          } else {
            debugPrint("GET LANGUAGES ERROR: ${data["ERROR"]}");
            isSuccess = false;
            await HelpersService.showPopup(context, message: data["ERROR"]);
            //showPopup(context, data["ERROR"]);
          }
        } else {
          isSuccess = false;
          await HelpersService.showPopup(context,
              message: FlutterI18n.translate(context, "NETWORK_ERROR"));
        }
        setState(() {
          isLanguagesLoading = false;
          if (isSuccess == false) {
            Globals.availLanguages = [Globals.defaultLanguage];
          } else {
            Globals.availLanguages = [];
            List<String> languageValues = [];
            List<dynamic> availLangs;
            for (int i = 0; i < gotLanguages.length; i++) {
              availLangs = Globals.languages
                  .where((dynamic language) =>
                      language["value"] == gotLanguages[i]["Code"])
                  .toList();
              if (availLangs.isNotEmpty &&
                  !languageValues.contains(availLangs[0]["value"])) {
                languageValues.add(availLangs[0]["value"]);
                Globals.availLanguages.add(availLangs[0]);
              }
            }
            if (Globals.availLanguages.isEmpty) {
              Globals.availLanguages = [Globals.defaultLanguage];
            }
            resetMyList();
          }
        });
      }
    }
  }

  static MyHomeState? of(BuildContext context) {
    return context.findAncestorStateOfType<MyHomeState>();
  }

  Future<bool> isNetworkAvailable() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      debugPrint("CONNECTED TO MOBILE DATA");
      return true;
    } else if (connectivityResult == ConnectivityResult.wifi) {
      debugPrint("CONNECTED TO WIFI");
      return true;
    }
    debugPrint("NOT CONNECTED");
    return false;
  }

  Future<void> initiateAll(context) async {
    await setAvailLanguages();
    await initiateTypesAdjectives(context, true);
  }

  Future<void> initiateTypesAdjectives(context, isSetState) async {
    if (Globals.isAppOnline == false) {
      HelpersService.showPopup(context,
          message: FlutterI18n.translate(context, "NOT_ONLINE"));
    } else {
      isInitiatingTypesAdjectives = true;
      String appLanguageId = Globals.appLanguage["LID"];
      debugPrint(
          "initiateTypesAdjectives called, isSetState = $isSetState, appLanguageId = $appLanguageId");
      List<String> availLIDs = List<String>.from(
          Globals.availLanguages.map((lang) => lang["LID"]).toList());
      debugPrint("initiateTypesAdjectives availLIDs = $availLIDs");
      if (!availLIDs.contains(Globals.appLanguage["LID"])) {
        appLanguageId = "8"; //ENGLISH
      }
      bool isRequestSuccess = true;
      Response response = http.Response("", 200);
      try {
        response = await http.get(Uri.parse(
            'https://www.learnfactsquick.com/lfq_app_php/get_alp_tabs_complete_app.php?language_id=${Globals.selectedAcrosticsLanguage["LID"]}&app_language_id=$appLanguageId'));
      } catch (e) {
        isRequestSuccess = false;
        Globals.isAppOnline = false;
        isInitiatingTypesAdjectives = false;
        await doNetworkChange();
      }
      if (isRequestSuccess == true) {
        if (response.statusCode == 200) {
          // If the server returns a 200 OK response, parse the JSON data
          final Map<String, dynamic> data = json.decode(response.body);
          debugPrint("initiateTypesAdjectives STATUS=200!!!");
          if (data["SUCCESS"] == true) {
            if (isSetState == true) {
              setState(() {
                debugPrint(
                    "setState TRUE, CALLING finishInitiateTypesAdjectives");
                finishInitiateTypesAdjectives(appLanguageId, data);
                isInitiatingTypesAdjectives = false;
              });
            } else {
              //setState(() {
              finishInitiateTypesAdjectives(appLanguageId, data);
              isInitiatingTypesAdjectives = false;
              //});
            }
            debugPrint("initiateTypesAdjectives DONE SUCCESSFULLY");
          } else {
            await HelpersService.showPopup(context, message: data["ERROR"]);
            setState(() {
              isInitiatingTypesAdjectives = false;
            });
          }
        } else {
          await HelpersService.showPopup(context,
              message: FlutterI18n.translate(context, "NETWORK_ERROR"));
          setState(() {
            isInitiatingTypesAdjectives = false;
          });
        }
      }
    }
  }

  finishInitiateTypesAdjectives(appLanguageId, data) {
    try {
      completedTables = List<dynamic>.from(data["COMPLETED_TABLES"]);
      allCategories = data["CATEGORIES"];
      selectedAllAdjectives = [];
      for (int i = 0; i < completedTables.length; i++) {
        selectedAllAdjectives.add([]);
      }
      if (Globals.dropdownTypes.isNotEmpty) {
        selectedType = Globals.dropdownTypes[0];
        dropdownAdjectives =
            getDropdownAdjectives(Globals.dropdownTypes[0]["Type"]);
        selectedAdjective = dropdownAdjectives[0];
        debugPrint(
            "finishInitiateTypesAdjectives DONE dropdownAdjectives = ${json.encode(dropdownAdjectives)}");
      }
    } catch (e) {
      debugPrint("ERROR FINISH initiateTypesAdjectives = $e");
    }
  }

  List<String> getDropdownAdjectives(String type) {
    debugPrint("getDropdownAdjectives type $type");
    List<String> myDropdownAdjectives = List<String>.from((List<dynamic>.from(
            completedTables
                .where((dynamic tableObj) => tableObj["Type"] == type)))
        .map((dynamic tableObj) => tableObj["Table"])
        .whereType<String>()
        .toSet()
        .toList());
    debugPrint(
        "getDropdownAdjectives RETURNING myDropdownAdjectives = ${json.encode(myDropdownAdjectives)}");
    return myDropdownAdjectives;
  }

  setType(type) {
    debugPrint("setType type = $type");
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
        selectedTypeIndex = Globals.dropdownTypes.indexOf(type);
      });
    }
  }

  setAdjective(adjective) {
    setState(() {
      selectedAdjective = adjective;
    });
  }

  String buildUrlString(params) {
    //debugPrint("buildUrlString called, params = $params");
    var ret = [];
    for (var p in params.keys) {
      ret.add("${Uri.encodeComponent(p)}=${Uri.encodeComponent(params[p])}");
    }
    //debugPrint("buildUrlString ret = {$ret}");
    return ret.join('&');
  }

  Future<void> doCreateAcrostics(context) async {
    if (validateCreate() == false) {
      return;
    } else {
      AdService.showInterstitialAd(() async {
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
    countAllSelected = 0;
    for (var i = 0; i < selectedAllAdjectives.length; i++) {
      for (var j = 0; j < selectedAllAdjectives[i].length; j++) {
        countAllSelected++;
      }
    }
    if (inputWord.trim() == '') {
      HelpersService.showPopup(context,
          message: FlutterI18n.translate(context, "INPUT_WORD_RETRY"));
      return false;
    } else if (countAllSelected == 0) {
      HelpersService.showPopup(context,
          message: FlutterI18n.translate(context, "PROMPT_SELECT_ADJECTIVES"));
      return false;
    }
    return true;
  }

  Future<void> createAcrosticsOld(context) async {
    debugPrint("createAcrosticsOld called");
    var progressMessage =
        FlutterI18n.translate(context, "LOAD_ACROSTICS_OFFLINE");
    HelpersService.showProgress(context, progressMessage);
    await Future.delayed(Duration(milliseconds: 200));
    dynamic response = {
      "SUCCESS": true,
      "ERROR": "",
      "RESULTS": "",
      "ENTRIES": [],
    };
    var inputSplit = inputWord.replaceAll(' ', '').toUpperCase().split("");
    uniqueLetters = List<String>.from(Set<String>.from(inputSplit));
    List<String> selectedSendAdjectives = [];
    List<dynamic> selectedTypesAdjectives = [];
    debugPrint(
        "createAcrostics selectedAllAdjectives = ${json.encode(selectedAllAdjectives)}");
    for (var i = 0; i < selectedAllAdjectives.length; i++) {
      for (var j = 0; j < selectedAllAdjectives[i].length; j++) {
        selectedSendAdjectives.add(selectedAllAdjectives[i][j]);
        selectedTypesAdjectives.add({
          "type": Globals.dropdownTypes[i]["Type"],
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
              "Word": getWordFromEntry(themeEntries[j][uniqueLetters[k]]![l]),
              "Entry": themeEntries[j][uniqueLetters[k]]![l]
            });
          }
        }
      }
    }

    List<Map<String, String>> dicVars = [];
    List<String> dicWords = [];
    for (int i = 0; i < uniqueLetters.length; i++) {
      dicVars =
          List<Map<String, String>>.from(Globals.myDic[uniqueLetters[i]]!);
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
    HelpersService.hideProgress(context);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => TablePage(
                inputWord: inputWord,
                selectedTypesAdjectives: selectedTypesAdjectives,
                entries: List<dynamic>.from(response["ENTRIES"]))));
  }

  String getWordFromEntry(String entry) {
    String word = entry.split("(")[0];
    return word;
  }

  Future<void> createAcrosticsNew(context) async {
    debugPrint("createAcrosticsNew called");
    if (Globals.isAppOnline == false) {
      HelpersService.showPopup(context,
          message: FlutterI18n.translate(context, "NOT_ONLINE"));
    } else {
      debugPrint("CREATING ACROSTICS!");
      inputWord = inputController.text;
      var progressMessage =
          FlutterI18n.translate(context, "LOAD_ACROSTICS_ONLINE");
      HelpersService.showProgress(context, progressMessage);
      var inputSplit = inputWord.replaceAll(' ', '').toUpperCase().split("");
      uniqueLetters = List<String>.from(Set<String>.from(inputSplit));
      List<String> selectedSendAdjectives = [];
      List<dynamic> selectedTypesAdjectives = [];
      debugPrint(
          "createAcrostics selectedAllAdjectives = ${json.encode(selectedAllAdjectives)}");
      for (var i = 0; i < selectedAllAdjectives.length; i++) {
        for (var j = 0; j < selectedAllAdjectives[i].length; j++) {
          selectedSendAdjectives.add(selectedAllAdjectives[i][j]);
          selectedTypesAdjectives.add({
            "type": Globals.dropdownTypes[i]["Type"],
            "adjective": selectedAllAdjectives[i][j]
          });
        }
      }

      String appLanguageId = Globals.appLanguage["LID"];
      debugPrint(
          "initiateTypesAdjectives called, appLanguageId = $appLanguageId");
      List<String> availLIDs = List<String>.from(
          Globals.availLanguages.map((lang) => lang["LID"]).toList());
      debugPrint("initiateTypesAdjectives availLIDs = $availLIDs");
      if (!availLIDs.contains(Globals.appLanguage["LID"])) {
        appLanguageId = "8"; //ENGLISH
      }
      Map<String, dynamic> params = {
        "selectedThemes": selectedSendAdjectives,
        "uniqueLetters": uniqueLetters,
        "languageId": Globals.selectedAcrosticsLanguage["LID"],
        "appLanguageId": appLanguageId
      };
      debugPrint(
          "createAcrostics NEXT CALLING get_alphabet_tables_completed_entries_app");
      bool isRequestSuccess = true;
      Response response = http.Response("", 200);
      try {
        response = await http.post(
            Uri.parse(
                'https://www.learnfactsquick.com/lfq_app_php/get_acrs.php'),
            body: json.encode(params));
      } catch (e) {
        HelpersService.hideProgress(context);
        isRequestSuccess = false;
        Globals.isAppOnline = false;
        await doNetworkChange();
      }
      if (isRequestSuccess == true) {
        //debugPrint("createAcrostics GENERATE_ALL RESPONSE = $response");
        if (response.statusCode == 200) {
          // If the server returns a 200 OK response, parse the JSON data
          final Map<String, dynamic> data = json.decode(response.body);
          //debugPrint("createAcrostics get_alphabet_tables_completed_entries_app DECODED data! = ${json.encode(data)}");
          if (data["SUCCESS"] == true) {
            HelpersService.hideProgress(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => TablePage(
                        inputWord: inputWord,
                        selectedTypesAdjectives: selectedTypesAdjectives,
                        entries: List<dynamic>.from(data["ENTRIES"]))));
          } else {
            debugPrint("createAcrostics SUCCESS=false");
            HelpersService.hideProgress(context);
            HelpersService.showPopup(context,
                message:
                    "${FlutterI18n.translate(context, "ERROR_MAKING_ACROSTICS")}: ${data["ERROR"]}");
          }
        } else {
          HelpersService.showPopup(context,
              message:
                  "${FlutterI18n.translate(context, "ERROR_MAKING_ACROSTICS")}: ${json.encode(e)}");
          HelpersService.hideProgress(context);
        }
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
      }
    }
  }

  cancelSelected(i, j) {
    selectedDropdownValue = "SOMETHING_SELECTED";
    setState(() {
      selectedAllAdjectives[i].removeAt(j);
      createSelectedDropdown();
      selectedDropdownValue = "NULL";
    });
  }

  getTransLangValue(dynamic value) {
    return "${value["name1"]}(${FlutterI18n.translate(context, value["name2"])})";
  }

  resetMyList() {
    debugPrint("resetMyList called");

    dynamic myLanguage = List<dynamic>.from(Globals.languages
        .where((dynamic lang) =>
            lang["value"] == Globals.selectedAcrosticsLanguage["value"])
        .toList())[0];
    List<dynamic> foundLangs = List<dynamic>.from(Globals.availLanguages
        .where((myEle) => myEle["value"] == myLanguage["value"])
        .toList());

    if (foundLangs.isNotEmpty) {
      dynamic myLang = foundLangs[0];
      Globals.selectedAcrosticsLanguage = Globals.languages
          .firstWhere((dynamic lang) => lang["LID"] == myLang["LID"]);
    } else {
      Globals.selectedAcrosticsLanguage = Globals.languages.firstWhere(
          (dynamic lang) => lang["LID"] == Globals.defaultLanguage["LID"]);
    }
  }

  setLanguage(BuildContext context, newLanguage) {
    debugPrint("setLanguage called, newLanguage = $newLanguage");
    Future.delayed(Duration(microseconds: 10), () {
      setState(() {
        Globals.selectedAcrosticsLanguage = Globals.languages
            .firstWhere((dynamic lang) => lang["LID"] == newLanguage["LID"]);
        for (var i = 0; i < selectedAllAdjectives.length; i++) {
          selectedAllAdjectives[i] = [];
        }
        createSelectedDropdown();
        debugPrint(
            "main.setLanguage calling initiateTypesAdjectives setState=true");
        initiateTypesAdjectives(context, true);
      });
    });
  }

  updateSelf() {
    debugPrint("MyHomeState updateSelf called");
    setState(() {});
  }

  bool getIsUseOffline() {
    debugPrint(
        "getIsUseOffline called, isOnline = ${Globals.isAppOnline}, isAds = $Globals.isAds");
    String appLanguageId = Globals.appLanguage["LID"];
    List<String> availLIDs = List<String>.from(
        Globals.availLanguages.map((lang) => lang["LID"]).toList());
    if (!availLIDs.contains(Globals.appLanguage["LID"])) {
      appLanguageId = "8"; //ENGLISH
    }
    String languageId = Globals.selectedAcrosticsLanguage["LID"];
    bool isUse = (Globals.isAds == false &&
        ((languageId == "8" && appLanguageId == "8")));
    return isUse;
  }

  void disposeAds() {
    AdService.disposeAll();
    bannerAd?.dispose();
  }

  @override
  void dispose() {
    super.dispose();
    subscription.cancel();
    if (kIsWeb == false) {
      debugPrint("DISPOSING interstitialAd !!!");
      bannerAd?.dispose();
    }
  }

  seeAcrostics(BuildContext context) async {
    debugPrint("seeAcrostics called");
    AdService.showInterstitialAd(() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AcrosticsPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        "Main build Widget called, selectedAcrosticLanguage = ${jsonEncode(Globals.selectedAcrosticsLanguage)}, availLanguages = ${jsonEncode(Globals.availLanguages)}");
    final TextStyle commonTextStyle = TextStyle(
      fontSize: 16.0,
      color: Colors.black,
      fontWeight: FontWeight.normal,
      fontFamily: 'Arial', // Specify the font family
    );
    double screenWidth = MediaQuery.of(context).size.width;
    double promptFontSize =
        (screenWidth * 0.016 + 4) < 11 ? 11 : (screenWidth * 0.016 + 4);
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
                centerTitle: true,
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
                          visible: Globals.isAppOnline == false,
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
                                  RegExp(r'[a-zA-Z ]')),
                              SingleSpaceFormatter(),
                            ],
                            controller: inputController,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: FlutterI18n.translate(
                                    context, "PROMPT_INPUT_WORD"),
                                hintStyle: TextStyle(fontSize: 12)),
                            keyboardType: TextInputType.text,
                            onEditingComplete: () {
                              debugPrint("INPUT WORD EDITTING COMPLETE");
                              //if (Platform.isAndroid) {
                              //  focusNode.unfocus();
                              //} else if (Platform.isIOS) {
                              inputController.text =
                                  inputController.text.trim();
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
                              visible: (Globals.dropdownTypes.isNotEmpty &&
                                  selectedType != null),
                              child: DropdownButtonHideUnderline(
                                  child: DropdownButton<dynamic>(
                                value: selectedType,
                                onChanged: (newValue) {
                                  setType(newValue);
                                  //appState.selectedType = newValue!;
                                  //});
                                },
                                items: Globals.dropdownTypes
                                    .map<DropdownMenuItem<dynamic>>(
                                        (dynamic value) {
                                  return DropdownMenuItem<dynamic>(
                                    value: value,
                                    child: SizedBox(
                                      width: screenWidth - 100,
                                      child: ListTile(
                                        title: Text(FlutterI18n.translate(
                                            context, value["Trans"])),
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
                                selectedType != null &&
                                isInitiatingTypesAdjectives == false,
                            child: DropDownMultiSelect(
                              separator: ", ",
                              decoration: InputDecoration(
                                labelText: "",
                                labelStyle: commonTextStyle,
                              ),
                              whenEmpty: selectedType != null &&
                                      selectedType["Type"] != null
                                  ? FlutterI18n.translate(
                                      context, "SELECT_TYPE_ADJECTIVES",
                                      translationParams: {
                                          "typeAdjs":
                                              "'${FlutterI18n.translate(context, selectedType["Trans"])}'"
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
                              Visibility(
                                visible: (Globals.availLanguages.isNotEmpty &&
                                    Globals.selectedAcrosticsLanguage != null),
                                child: DropdownButton<String>(
                                  value: Globals
                                      .selectedAcrosticsLanguage?["value"],
                                  onChanged: (newLanguage) {
                                    final foundLanguage =
                                        Globals.availLanguages.firstWhere(
                                      (item) => item["value"] == newLanguage,
                                    );
                                    if (foundLanguage != null) {
                                      setLanguage(context, foundLanguage);
                                    }
                                  },
                                  hint: Text(FlutterI18n.translate(
                                      context, "SELECT_LANGUAGE")),
                                  items: Globals.availLanguages
                                      .map<DropdownMenuItem<String>>((lang) {
                                    return DropdownMenuItem<String>(
                                      value: lang["value"], // ✅ string
                                      child: Text(
                                        getTransLangValue(lang),
                                        style:
                                            TextStyle(fontSize: linksFontSize),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ]),
                      ),
                      Center(
                        child: HelpersService.customButton(
                            context,
                            0.95,
                            promptFontSize,
                            FlutterI18n.translate(
                              context,
                              "CREATE_ACROSTICS",
                            ),
                            Icon(Icons.construction),
                            goButtonColor,
                            Colors.black,
                            5,
                            (isInitiated == true)
                                ? () async {
                                    doCreateAcrostics(context);
                                  }
                                : null),
                      ),
                      SizedBox(height: 15),
                      Center(
                        child: HelpersService.customButton(
                          context,
                          0.75,
                          promptFontSize,
                          FlutterI18n.translate(
                            context,
                            "SEE_ACROSTICS",
                          ),
                          Icon(Icons.visibility),
                          Colors.lightBlueAccent,
                          Colors.black,
                          5,
                          (Globals.isAppOnline == true)
                              ? () async {
                                  seeAcrostics(context);
                                }
                              : null,
                        ),
                      ),
                      SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                textAlign: TextAlign.left,
                                FlutterI18n.translate(
                                  context,
                                  "SEE_LFQ_WEBSITE_OTHER_APPS",
                                ),
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: promptFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                              HelpersService.customButton(
                                context,
                                0.80,
                                promptFontSize,
                                FlutterI18n.translate(
                                  context,
                                  "PROMPT_TOOLS_WEBSITE",
                                ),
                                Image.asset(
                                  'assets/images/lfq_icon.png',
                                  width: 20,
                                  height: 20,
                                ),
                                Color.fromARGB(255, 204, 159, 252),
                                Colors.white,
                                15,
                                () => launch('https://learnfactsquick.com'),
                              ),
                              if (HelpersService.isLinkPlayStore())
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: HelpersService.customButton(
                                    context,
                                    0.80,
                                    promptFontSize,
                                    FlutterI18n.translate(
                                      context,
                                      "PROMPT_APPS_PLAY_STORE",
                                    ),
                                    Icon(Icons.play_circle_fill),
                                    Colors.green,
                                    Colors.white,
                                    15,
                                    () => launch(
                                      'https://play.google.com/store/apps/dev?id=5263177578338103821',
                                    ),
                                  ),
                                ),
                              if (HelpersService.isLinkAppStore())
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: HelpersService.customButton(
                                    context,
                                    0.80,
                                    promptFontSize,
                                    FlutterI18n.translate(
                                      context,
                                      "PROMPT_APPS_APP_STORE",
                                    ),
                                    Icon(Icons.download_sharp),
                                    Colors.blue,
                                    Colors.white,
                                    15,
                                    () => launch(
                                      'https://apps.apple.com/us/developer/keith-harryman/id1693739510',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ]))),
            bottomNavigationBar: Globals.isAds
                ? AdService.bottomBanner(bannerAd: bannerAd)
                : null,
          );
  }
}
