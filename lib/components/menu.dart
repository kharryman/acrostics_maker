// ignore_for_file: use_build_context_synchronously, must_be_immutable
import 'package:acrostics_maker/globals.dart';
import 'package:acrostics_maker/services/ads.dart';
import 'package:acrostics_maker/services/helpers.dart';
import 'package:acrostics_maker/services/iap.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:acrostics_maker/components/my_popup_menu_item.dart';

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

  Future<void> showSuccessThanksBuy() async {
    debugPrint("showSuccessThanksBuy called");
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          elevation: 10,
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              SizedBox(width: 10),
              Text(
                FlutterI18n.translate(context, "PROMPT_SUCCESS"),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  FlutterI18n.translate(context, "THANK_YOU_NO_ADS"),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ),
              SizedBox(height: 20),
              Icon(Icons.celebration, color: Colors.orange, size: 40),
            ],
          ),
          actions: <Widget>[
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: () async {
                  //await Future.delayed(Duration(milliseconds: 400));
                  setState(() {
                    Globals.isAds = false;
                    context.read<AppData>().setIsAds(false);
                  });
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text(
                  FlutterI18n.translate(context, "PROMPT_LETS_GO"),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 10),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double menuTitleFontSize =
        (screenWidth * 0.06) > 18 ? 18 : (screenWidth * 0.06);
    return PopupMenuButton<dynamic>(
        padding: EdgeInsets.all(0),
        color: Colors.white,
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width,
        ),
        icon: Icon(Icons.menu),
        onSelected: (value) {
          debugPrint("menu selected value = $value");
          //focusNode.unfocus();
          FocusScope.of(context).unfocus();
          if (value == "BUTTON_NO_ADS") {
            debugPrint("MENU LOSING FOCUS!!!");
            //FocusScope.of(context).unfocus();
            context.read<AppData>().setMenuOpen(true);
            //FocusScope.of(context).requestFocus(FocusNode());
          }
        },
        onOpened: () {
          debugPrint("menu opened.");
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
            NonDismissingPopupMenuItem<dynamic>(
              value: 'MY POPUP HEADER',
              child: Row(
                mainAxisSize: MainAxisSize.min, // Important! Let Row shrink
                children: [
                  Expanded(
                    child: Text(
                      "${FlutterI18n.translate(context, "HELP_MENU")}:",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color.fromARGB(255, 57, 19, 122),
                        fontSize: menuTitleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    color: Colors.black,
                    constraints: BoxConstraints(),
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
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
  bool isShowHelp = false;
  bool isRestoring = false;
  bool isFeatureRestoreButton = false;
  ProductDetails? productNoAds;

  @override
  void initState() {
    super.initState();
    if (kIsWeb == false) {
      loadInAppProducts();
    }
  }

  Future<void> loadInAppProducts() async {
    debugPrint("Menu.loadInAppProducts called");
    final InAppPurchase iapInstance = InAppPurchase.instance;
    final Set<String> productIds = {Globals.removeAdsProductId};
    final ProductDetailsResponse response =
        await iapInstance.queryProductDetails(productIds);

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint(
          "Menu.loadInAppProducts Product IDs not found: ${response.notFoundIDs}");
    } else {
      debugPrint("Menu.loadInAppProducts notFoundIDs EMPTY!");
      for (var product in response.productDetails) {
        debugPrint("Menu.loadInAppProducts Product ID: ${product.id}");
        debugPrint("Menu.loadInAppProducts Title: ${product.title}");
        debugPrint(
            "Menu.loadInAppProducts Description: ${product.description}");
        debugPrint("Menu.loadInAppProducts Price: ${product.price}");
        debugPrint("------------------------");
      }
      ProductDetails? tempProductNoAds = response.productDetails
          .firstWhere((product) => product.id == Globals.removeAdsProductId);
      // ignore: unnecessary_null_comparison
      if (tempProductNoAds != null) {
        setState(() {
          debugPrint(
              "Menu.loadInAppProducts tempProductNoAds NOT NULL! SETTING priceNoAds = $Globals.priceNoAds, productNoAds...");
          Globals.priceNoAds = tempProductNoAds.price;
          productNoAds = tempProductNoAds;
        });
      }
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    MyAppState.instance?.changeLanguage(languageCode);
  }

  Widget showHideButton({
    required bool isShowing,
    required VoidCallback onPressed,
    Color colorHide = Colors.grey,
    Color colorShow = Colors.lightBlueAccent,
    IconData icon = Icons.visibility,
    String labelOn = "Show",
    String labelOff = "Hide",
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 3, 0, 3),
      child: FractionallySizedBox(
        widthFactor: 0.95, // 80%
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white),
          label: Text(
            isShowing ? labelOff : labelOn,
            style: const TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isShowing ? colorHide : colorShow,
          ),
        ),
      ),
    );
  }

  watchAd() async {
    debugPrint("watchAd called");
    bool isWatch = await HelpersService.showConfirm(
      context,
      FlutterI18n.translate(context, "ENJOY_NO_ADS_24_HOURS"),
      FlutterI18n.translate(context, "PROMPT_WATCH_AD"),
      FlutterI18n.translate(context, "MAYBE_LATER"),
      "👉 ${FlutterI18n.translate(context, "GO_AD_FREE")}",
    );
    debugPrint("watchAd, user selected isWatch = $isWatch");
    if (isWatch == true) {
      AdService.showRewardedAd(() async {
        await AdService.enableAdRemoval();
        await AdService.setAdsDisabled();
        setState(() {});
        debugPrint("Ads disabled for 24 hours");
      });
    }
  }

  getNoAds() async {
    debugPrint("getNoAds called");
    String title = FlutterI18n.translate(context, "POPUP_NO_ADS_TITLE");
    //String message = FlutterI18n.translate(context, "POPUP_NO_ADS_MESSAGE",
    //    translationParams: {"mPr": getFormattedPrice, "mDev": myDevice});
    //"Enjoy an ad-free experience on **{mDev}** for just **{mPr}**!"
    String appTitle = FlutterI18n.translate(context, "APP_TITLE");
    String message = FlutterI18n.translate(context, "POPUP_NO_ADS_MESSAGE2",
        translationParams: {"mPr": Globals.priceNoAds, "mDev": appTitle});

    String cancelText = FlutterI18n.translate(context, "PROMPT_NO_THANK_YOU");
    String okText = FlutterI18n.translate(context, "PROMPT_YES_NOW");
    String supportUs = FlutterI18n.translate(context, "PROMPT_SUPPORT_US");
    String andOffline = FlutterI18n.translate(context, "PROMPT_AND_OFFLINE");

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // Rounded corners
          ),
          title: Row(
            children: [
              Icon(Icons.remove_circle_outline, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Expanded(
                child:
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.left,
              ),
              Text(
                "** $andOffline",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                textAlign: TextAlign.left,
              ),
              SizedBox(height: 10),
              Text(supportUs,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontStyle: FontStyle.italic)),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  backgroundColor: Color.fromARGB(255, 136, 122, 122),
                  foregroundColor: Colors.black),
              child: Text(cancelText),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                debugPrint("GETTING NO ADS!...");
                // ignore: unnecessary_null_comparison

                if (kIsWeb == true) {
                  await HelpersService.showPopup(context,
                      message: "Can't remove ads on web");
                } else if (productNoAds == null) {
                  await HelpersService.showPopup(context,
                      message: FlutterI18n.translate(
                          context, "PROMPT_NO_REMOVE_AD_PRODUCT"));
                } else {
                  ProductDetails finalProductNoAds = productNoAds!;
                  debugPrint("Menu getNoAds, BUYING NO ADS!");
                  final PurchaseParam purchaseParam =
                      PurchaseParam(productDetails: finalProductNoAds);

                  MyHomeState().purchaseSubscription?.cancel();
                  Navigator.pop(context);
                  await InAppPurchase.instance
                      .buyNonConsumable(purchaseParam: purchaseParam);
                  //if (isSuccess == true) {
                  debugPrint(
                      "Menu getNoAds, BUYING NO ADS, InAppPurchase.instance.buyNonConsumable DONE!");
                  //}
                }
              },
              icon: Icon(
                Icons.shopping_cart,
                size: 18,
                color: Colors.black,
              ),
              label: Text(
                okText,
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
        Globals.languages.map<DropdownMenuItem<String>>((dynamic lang) {
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
    return widget.page == "main" && Globals.languages.isEmpty
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
                                  value: Globals.appLanguage["value"],
                                  onChanged: (newLanguage) {
                                    if (newLanguage == null) return;
                                    final foundLanguage =
                                        Globals.languages.firstWhere(
                                      (item) => item["value"] == newLanguage,
                                    );
                                    setState(() {
                                      Globals.appLanguage = foundLanguage;
                                    });
                                    changeLanguage(newLanguage);
                                  },
                                  items: languageItems,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      showHideButton(
                        colorShow: Colors.lightBlue,
                        isShowing: isShowHelp,
                        labelOff: FlutterI18n.translate(context, "HIDE_HELP"),
                        labelOn: FlutterI18n.translate(context, "SHOW_HELP"),
                        onPressed: () {
                          setState(() {
                            isShowHelp = !isShowHelp;
                          });
                        },
                        icon: isShowHelp
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      if (isShowHelp == true)
                        SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: Padding(
                                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Html(data: helpText),
                                    ]))),
                      if (Globals.isAds == true)
                        NonDismissingPopupMenuItem<dynamic>(
                          value: 'BUTTON_NO_WATCH_AD',
                          onTap: () {
                            watchAd();
                          },
                          child: FractionallySizedBox(
                            widthFactor: 0.95,
                            child: ElevatedButton.icon(
                              onPressed: null,
                              label: Text(
                                FlutterI18n.translate(
                                  context,
                                  "PROMPT_NO_ADS_24_HOURS",
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green, // Red text
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.white, // White background
                                foregroundColor:
                                    Colors.green, // Red text/icon color
                                minimumSize: Size(double.infinity, 40),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: const BorderSide(
                                    color: Colors.grey,
                                    width: 2,
                                  ), // Red border
                                ),
                                elevation: 5, // Shadow effect
                              ),
                            ),
                          ),
                        ),
                      if (Globals.isAds == false)
                        PopupMenuItem(
                          value: "NO_ADS",
                          child: Container(
                            color: Colors
                                .lightGreen[100], // Light green background
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                Icon(
                                  Icons
                                      .check_circle_outline, // Cool check mark icon
                                  color: Colors.green,
                                ),
                                SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    FlutterI18n.translate(
                                        context, "PROMPT_ADS_FREE"),
                                    softWrap: true,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green, // Text color
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        )
                      else if (Globals.isAds == true)
                        NonDismissingPopupMenuItem<dynamic>(
                            value: 'BUTTON_NO_ADS',
                            onTap: () {
                              getNoAds();
                            },
                            child: FractionallySizedBox(
                                widthFactor: 0.95,
                                child: ElevatedButton.icon(
                                  onPressed: null,
                                  icon: const Icon(Icons.block,
                                      size: 20, color: Colors.red), // Red icon
                                  label: Text(
                                    "${FlutterI18n.translate(context, "REMOVE_ADS")} (${FlutterI18n.translate(context, "PROMPT_ONLY")} ${Globals.priceNoAds})",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red, // Red text
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.white, // White background
                                    foregroundColor:
                                        Colors.red, // Red text/icon color
                                    minimumSize: Size(double.infinity, 40),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: const BorderSide(
                                          color: Colors.grey,
                                          width: 2), // Red border
                                    ),
                                    elevation: 5, // Shadow effect
                                  ),
                                ))),
                      if (isFeatureRestoreButton == true)
                        NonDismissingPopupMenuItem(
                            value: "RESTORE_PURCHASES",
                            onTap: () {
                              IAP.restorePurchases();
                            },
                            child: FractionallySizedBox(
                                widthFactor: 0.95,
                                child: ElevatedButton.icon(
                                  onPressed: null,
                                  icon: const Icon(Icons.restore,
                                      color: Colors.blue),
                                  label: Text(
                                    isRestoring
                                        ? FlutterI18n.translate(
                                            context, "PROMPT_RESTORING")
                                        : FlutterI18n.translate(context,
                                            "PROMPT_RESTORE_PURCHASES"),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue, // Red text
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.white, // White background
                                    foregroundColor:
                                        Colors.blue, // Red text/icon color
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 2),
                                    minimumSize: Size(double.infinity, 40),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: const BorderSide(
                                          color: Colors.grey,
                                          width: 2), // Red border
                                    ),
                                    elevation: 5, // Shadow effect
                                  ),
                                ))),
                    ])));
  }
}
