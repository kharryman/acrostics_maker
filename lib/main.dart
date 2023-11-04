import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';

//import 'package:flutter_html/flutter_html.dart';
//import 'package:flutter/services.dart';
//import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// ignore: library_prefixes
import 'table.dart';
import 'package:connectivity/connectivity.dart';
import 'package:multiselect/multiselect.dart';

const String testDevice = '974550CBC7D4EA4718A67165E2E3B868';
const String myIpad = '00008020-0014301102D1002E';
const String myIphone11 = 'A8EC231A-DCFC-405C-8A0D-62E9F5BA1918';
const int maxFailedLoadAttempts = 3;
InterstitialAd? interstitialAd;
int numInterstitialLoadAttempts = 0;
List<String> dropdownTypes = [];
List<String> dropdownAdjectives = [];
String selectedType = '';
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
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  final int ofThousandShowAds = 425;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Acrostics Maker',
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

class MyHomeState extends State<MyHome> {
  late StreamSubscription<ConnectivityResult> subscription;
  String helpText =
      '<strong>The Acrostics Maker is a tool to help create a series of words or a sentence to memorize a word using its letters.</strong><br /><br /><strong>For example, to remember a "lemur", a 4-legged racoon-like mammmal from Madagascar, you can use this acrostic: <br /><strong><span style="font-style:italic">"Large Eyed Madagascaran Unmistakably Ringtailed"</span></strong><br /><br /><b><u><i>Help:</i></u></b><br />• The words are listed in columns under each letter of the acrostic word. <br />• They are ordered alphabetically by the chosen adjectives with dictionary entries listed underneath each adjective for each letter.<br />• Dictionary entries are chosen if the definition contains the adjective.<br /><br />• <u><i>To create the acrostic:</i></u> <br />  1)Select one word in each column for each letter<br />  2)Edit the word on the top as need.<br />  3)Click "Copy Acostic" on top to copy your acrostic.<br /><br /><br /><span style="color:purple">  Please ENJOY, and spread the good word how Acostics Maker has helped you remember special names in your life.</span>';
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

  bool isPushNavigationStack = true;
  bool isAndroid = kIsWeb == false ? false : false;
  bool isIOS = kIsWeb == false ? false : false;

  MaterialStateColor goButtonColor =
      MaterialStateColor.resolveWith((Set<MaterialState> states) {
    if (states.contains(MaterialState.pressed)) {
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
    BuildContext? context = scaffoldKey.currentContext;
    if (isInitiated == false) {
      initiateAll(context);
      if (kIsWeb == false) {
        createInterstitialAd();
      }
    }
    subscription = Connectivity().onConnectivityChanged.listen((result) async {
      if (result == ConnectivityResult.none) {
        print("ACROSTICS MAKER NETWORK DISCONNECTED.");
      } else {
        if (isInitiated == false) {
          print(
              "ACROSTICS MAKER NOT INITIATED, NETWORK CONNECTED, CALLING initiateTypesAdjectives..");
          BuildContext? context = scaffoldKey.currentContext;
          await initiateTypesAdjectives(context);
          if (kIsWeb == false) {
            createInterstitialAd();
          }
        }
      }
    });
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

  Future<void> initiateAll(context) async {
    var isOnline = await isNetworkAvailable();
    if (isOnline == true) {
      await initiateTypesAdjectives(context);
    }
  }

  Future<void> initiateTypesAdjectives(context) async {
    print("initiateTypesAdjectives called");
    try {
      final response = await http.get(Uri.parse(
          'https://www.learnfactsquick.com/lfq_app_php/get_alphabet_tables_completed_app.php'));

      if (response.statusCode == 200) {
        // If the server returns a 200 OK response, parse the JSON data
        final Map<String, dynamic> data = json.decode(response.body);
        print("initiateTypesAdjectives STATUS=200!!!");
        if (data["SUCCESS"] == true) {
          setState(() {
            completedTables = List<dynamic>.from(data["COMPLETED_TABLES"]);
            dropdownTypes = List<String>.from(Set<String>.from(
                completedTables.map((dynamic tableObj) => tableObj["Type"])));
            selectedAllAdjectives = [];
            for (int i = 0; i < dropdownTypes.length; i++) {
              selectedAllAdjectives.add([]);
            }
            selectedType = dropdownTypes[0];
            dropdownAdjectives = getDropdownAdjectives(dropdownTypes[0]);
            selectedAdjective = dropdownAdjectives[0];
            isInitiated = true;
          });
          print("initiateTypesAdjectives DONE SUCCESSFULLY");
        } else {
          print(
              "initiateTypesAdjectives FAILED data['SUCCESS'] = ${data['SUCCESS']}");
        }
      } else {
        // If the server did not return a 200 OK response,
        // throw an exception or handle the error as needed
        print('initiateTypesAdjectives Failed to load data');
      }
    } catch (e) {
      showPopup(
          context, ("Error initiating app: ").toString() + json.encode(e));
    }
  }

  getDropdownAdjectives(String type) {
    print("getDropdownAdjectives type $type");
    List<String> myDropdownAdjectives = List<String>.from((List<dynamic>.from(
            completedTables
                .where((dynamic tableObj) => tableObj["Type"] == type)))
        .map((dynamic tableObj) => tableObj["Table"])
        .toList());
    return myDropdownAdjectives;
  }

  setType(type) {
    print("setType type = $type");
    setState(() {
      selectedType = type;
      dropdownAdjectives = getDropdownAdjectives(type);
      if (dropdownAdjectives.isNotEmpty) {
        selectedAdjective = dropdownAdjectives[0];
      }
      selectedTypeIndex = dropdownTypes.indexOf(type);
    });
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

  Future<void> createAcrostics(context) async {
    print("createAcrostics called");
    Random random = Random();
    var isShowAd = random.nextInt(1000) >= 500; //EXACTLY HALF.
    if (kIsWeb == false && isShowAd == true) {
      print("createAcrostics showInterstitialAd CALLING...");
      MyHomeState().showInterstitialAd();
    } else {
      print("NOT SHOWING AD, CREATING ACROSTICS!");
      var isOnline = await isNetworkAvailable();
      if (isOnline == false) {
        showPopup(context, "Not online. Please connect and retry.");
      } else {
        inputWord = inputController.text;
        if (inputWord.trim() == '') {
          showPopup(context, "Please input a word and try again.");
        } else if (countAllSelected == 0) {
          showPopup(context,
              "Please select one or more adjectives to describe your word.");
        } else {
          var progressMessage = "Loading acrostic words, please wait...";
          showProgress(context, progressMessage);
          var inputSplit = inputWord.split("");
          uniqueLetters = List<String>.from(Set<String>.from(inputSplit));
          List<String> selectedSendAdjectives = [];
          List<dynamic> selectedTypesAdjectives = [];
          for (var i = 0; i < selectedAllAdjectives.length; i++) {
            for (var j = 0; j < selectedAllAdjectives[i].length; j++) {
              selectedSendAdjectives.add(selectedAllAdjectives[i][j]);
              selectedTypesAdjectives.add({
                "type": dropdownTypes[i],
                "adjective": selectedAllAdjectives[i][j]
              });
            }
          }
          Map<String, dynamic> params = {
            "selectedThemes": selectedSendAdjectives,
            "uniqueLetters": uniqueLetters
          };
          print(
              "createAcrostics NEXT CALLING get_alphabet_tables_completed_entries_app");
          try {
            final response = await http.post(
                Uri.parse(
                    'https://www.learnfactsquick.com/lfq_app_php/get_alphabet_tables_completed_entries_app.php'),
                body: json.encode(params));
            //print("createAcrostics GENERATE_ALL RESPONSE = $response");
            if (response.statusCode == 200) {
              // If the server returns a 200 OK response, parse the JSON data
              final Map<String, dynamic> data = json.decode(response.body);
              //print("createAcrostics get_alphabet_tables_completed_entries_app DECODED data! = ${json.encode(data)}");
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
                hideProgress(context);
              }
            } else {
              hideProgress(context);
            }
          } catch (e) {
            showPopup(context,
                ("Error making acrostics: ").toString() + json.encode(e));
            hideProgress(context);
          }
        }
      } //END IS ONLINE.
    } //END NOT SHOW ADD, CREATE ACROSTICS
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
                color: Colors.black,
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

  Future<void> showPopup(BuildContext context, String message) async {
    print("showPopup called");
    return showDialog<void>(
      context: context,
      barrierDismissible:
          false, // Prevent dismissing by tapping outside the popup
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alert'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the popup
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
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
          content: Text(("Text, '").toString() +
              myText.toString() +
              ("' copied to clipboard").toString())),
    );
  }

  static final AdRequest request = AdRequest(
    keywords: <String>[
      'acrostics generator',
      'memorize lists',
      'improve memory',
      'remember words',
      'define words'
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

  void showInterstitialAd() {
    print("showInterstitialAd called");
    if (interstitialAd == null) {
      print('Warning: attempt to show interstitialAd before loaded.');
      return;
    }
    print(
        "showInterstitialAd called, CALLING interstitialAd!.fullScreenContentCallback!!!");
    interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          print('interstitialAd onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        print('$ad interstitialAd onAdDismissedFullScreenContent.');
        ad.dispose();
        print(
            'interstitialAd onAdDismissedFullScreenContent Calling createInterstitialAd again');
        createInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('$ad interstitialAd onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        print(
            'interstitialAd onAdFailedToShowFullScreenContent Calling createInterstitialAd again');
        createInterstitialAd();
      },
    );
    interstitialAd!.show();
    print("SETTING interstitialAd = null!!");
    interstitialAd = null;
  }

  isLinkPlayStore() {
    return (kIsWeb || Platform.isAndroid);
  }

  isLinkAppStore() {
    return (kIsWeb || Platform.isIOS);
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
    return Visibility(
      visible: isInitiated == true,
      child: Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text("Acrostics Maker"),
            actions: <Widget>[
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
                        showInterstitialAd();
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
                                  padding:
                                      const EdgeInsets.fromLTRB(5, 0, 0, 0),
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Html(data: helpText),
                                      ]))))
                    ];
                  })
            ]),
        body: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Center(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                    child: Text(
                        'Enter one word only(only letters): Then press ENTER',
                        style: TextStyle(fontSize: 12)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: TextField(
                        enabled: isInitiated,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z]')),
                        ],
                        controller: inputController,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'one word(letters no spaces)',
                            hintStyle: TextStyle(fontSize: 12)),
                        keyboardType: TextInputType.text,
                        onEditingComplete: () {
                          //if (Platform.isAndroid) {
                          //  focusNode.unfocus();
                          //} else if (Platform.isIOS) {
                          FocusScope.of(context).unfocus();
                          //}
                          createAcrostics(context);
                        }),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                    child: Text('Choose type:', style: TextStyle(fontSize: 12)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors
                                .black), // Set the border color to transparent
                      ),
                      child: DropdownButton<String>(
                        value: selectedType,
                        onChanged: (newValue) {
                          setType(newValue);
                          //appState.selectedType = newValue!;
                          //});
                        },
                        items: dropdownTypes
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                    child: Text('Choose adjective:',
                        style: TextStyle(fontSize: 12)),
                  ),
                  Visibility(
                    visible: selectedTypeIndex >= 0 &&
                        selectedAllAdjectives.length > selectedTypeIndex &&
                        dropdownAdjectives.isNotEmpty,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                      child: DropDownMultiSelect(
                        isDense: true,
                        onChanged: (List<String> x) {
                          setState(() {
                            if (selectedTypeIndex >= 0 &&
                                selectedAllAdjectives.length >
                                    selectedTypeIndex) {
                              selectedAllAdjectives[selectedTypeIndex] = x;
                            }
                            createSelectedDropdown();
                          });
                        },
                        options: dropdownAdjectives,
                        selectedValues:
                            selectedAllAdjectives[selectedTypeIndex],
                        whenEmpty: ('Select ').toString() +
                            selectedType +
                            (' Adjectives').toString(),
                      ),
                    ),
                  ),
                  Visibility(
                      visible: countAllSelected == 0,
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                          child: Text("Nothing selected."))),
                  Visibility(
                      visible: countAllSelected > 0,
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                          child: Text(countAllSelected.toString() +
                              (" selected.").toString()))),
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
                  Row(
                    children: [
                      Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.9,
                            child: ElevatedButton(
                                style: ButtonStyle(
                                    shape: MaterialStateProperty.all(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            5.0), // Adjust the radius as needed
                                      ),
                                    ),
                                    backgroundColor: goButtonColor),
                                onPressed: (isInitiated == true)
                                    ? () async {
                                        createAcrostics(context);
                                      }
                                    : null,
                                child: Text('Create Acrostics!',
                                    style: TextStyle(fontSize: 12))),
                          )),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.all(10.0),
                    child: SizedBox(
                        width: 250,
                        child: ElevatedButton(
                          onPressed: () {
                            launch('https://learnfactsquick.com');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 204, 159,
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
                              Text('See other tools from the website',
                                  style: TextStyle(fontSize: 10)), // Text
                            ],
                          ),
                        )),
                  ),
                  Visibility(
                    visible: isLinkPlayStore(),
                    child: Padding(
                      padding: EdgeInsets.all(10.0),
                      child: SizedBox(
                          width: 250,
                          child: ElevatedButton(
                            onPressed: () {
                              launch(
                                  'https://play.google.com/store/apps/dev?id=5263177578338103821');
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
                                Icon(
                                    Icons.play_circle_fill), // Google Play icon
                                SizedBox(
                                    width:
                                        8), // Add some space between the icon and text
                                Text('See other apps from Play Store',
                                    style: TextStyle(fontSize: 10)), // Text
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
                            width: 250,
                            child: ElevatedButton(
                              onPressed: () {
                                launch(
                                    'https://apps.apple.com/us/developer/keith-harryman/id1693739510');
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
                                  Icon(
                                      Icons.download_sharp), // Google Play icon
                                  SizedBox(
                                      width:
                                          8), // Add some space between the icon and text
                                  Text('See other apps from App Store',
                                      style: TextStyle(fontSize: 10)), // Text
                                ],
                              ),
                            ))),
                  ),
                ]))),
      ),
    );
  }
}
