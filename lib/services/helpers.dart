import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class HelpersService {
  static bool isLoading = false;

  static isLinkPlayStore() {
    return (kIsWeb || Platform.isAndroid);
  }

  static isLinkAppStore() {
    return (kIsWeb || Platform.isIOS);
  }

  static void showProgress(BuildContext context, message) {
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

  static void hideProgress(BuildContext context) {
    debugPrint("hideProgress called");
    Navigator.of(context, rootNavigator: true).pop();
    isLoading = false;
  }

  static Future<void> showPopup(
    BuildContext context, {
    String? title,
    required String message,
  }) async {
    debugPrint("showPopup called");
    String myTitle = title ?? FlutterI18n.translate(context, "PROMPT_ALERT");
    return showDialog<void>(
      context: context,
      barrierDismissible:
          false, // Prevent dismissing by tapping outside the popup
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(textAlign: TextAlign.center, myTitle),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.70,
            child: SingleChildScrollView(child: Html(data: message)),
          ),
          actions: <Widget>[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(FlutterI18n.translate(context, "OK")),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<bool> showConfirm(
    BuildContext context,
    String title,
    String message,
    String cancelText,
    String okText,
  ) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Title
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  /// Message
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SingleChildScrollView(child: Html(data: message)),
                  ),

                  const SizedBox(height: 10),

                  IntrinsicHeight(
                    child: Row(
                      children: [
                        /// Cancel Button (Secondary)
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  249,
                                  208,
                                  208,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                              child: Text(cancelText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.black)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),

                        /// Confirm Button (Primary)
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  192,
                                  253,
                                  163,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                              child: Text(okText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.black)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((value) => value ?? false);
  }

  static Widget customButton(
    BuildContext context,
    double widthFactor,
    double promptFontSize,
    String labelKey,
    Widget icon,
    Color color,
    Color textColor,
    double roundness,
    VoidCallback? onPressed,
  ) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(roundness),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                softWrap: true,
                labelKey,
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor, fontSize: promptFontSize),
              ),
            ),
            const SizedBox(width: 12),
            icon,
          ],
        ),
      ),
    );
  }

  static bool isQueryValNull(dynamic val) {
    //RETURNS false if val is not null and string value is not 'null' or 'undefined'
    return (val == null ||
        ((val.runtimeType == String) &&
            (val.trim() == "" ||
                val.toUpperCase() == "NULL" ||
                val.toLowerCase() == "undefined")));
  }

  static Locale getAppLocale(String savedLanguageCode) {
    // Split into language and optional country
    List<String> parts = savedLanguageCode.split(RegExp(r"[-_]"));
    String languageCode = parts[0]; // zh
    String? countryCode =
        parts.length > 1 ? parts[1].toUpperCase() : null; // CN or TW
    Locale locale = countryCode != null
        ? Locale(languageCode, countryCode)
        : Locale(languageCode);
    return locale;
  }

  static bool isJSON(str) {
    try {
      json.decode(str);
    } catch (e) {
      return false;
    }
    return true;
  }

  static int getCurrentTimestamp() {
    DateTime now = DateTime.now();
    int currentTimeInSeconds = now.millisecondsSinceEpoch ~/ 1000;
    return currentTimeInSeconds;
  }

  // To save data
  static Future<void> setData(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
  }

// To read data
  static Future<String?> getData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static copyToClipboard(context, myText) {
    Clipboard.setData(ClipboardData(text: myText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ("Text, '").toString() +
              myText.toString() +
              ("' copied to clipboard").toString(),
        ),
      ),
    );
  }

  static convertDynamicDoubleListDynamic(myDynamic) {
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

  static removeParentheses(String text) {
    return text.replaceAll(RegExp(r'\([^)]*\)'), '');
  }

  static Map<String, String> splitAcrosticWord(String text) {
    final match = RegExp(r'^([A-Z]*)([a-z]*)([A-z]*)').firstMatch(text);

    return {
      "first": match?.group(1) ?? "",
      "lower": match?.group(2) ?? "",
      "remaining": match?.group(3) ?? "",
    };
  }

  static bool checkIsAcrostic(String name, String acrostic) {
    //debugPrint("checkIsAcrostic called with name: $name and acrostic: $acrostic");
    String cleanedName = name.replaceAll(RegExp(r'\s+'), '');
    String cleanedAcrostic = removeParentheses(acrostic);
    List<String> words = cleanedAcrostic.split(RegExp(r' +'));
    String buildAcrostic = "";
    for (String w in words) {
      Map<String, String> splitWord = splitAcrosticWord(w);
      //debugPrint("checkIsAcrostic splitWord for word '$w': ${splitWord.toString()}");
      buildAcrostic += splitWord["first"] ?? "";
    }
    //debugPrint("checkIsAcrostic buildAcrostic = ${buildAcrostic.toUpperCase()}, name = ${cleanedName.toUpperCase()}");
    if (buildAcrostic.toUpperCase() == cleanedName.toUpperCase()) {
      return true;
    } else {
      return false;
    }
  }

  static Widget getFormattedAcrostic(BuildContext context, String name,
      String acrostic, double promptFontSize) {
    String cleanedAcrostic = removeParentheses(acrostic);
    List<String> nameParts = name.toUpperCase().split(RegExp(r' +'));
    //debugPrint("getFormattedAcrostic nameParts: $nameParts");
    int nameIndex = 0;
    //List<String> words = cleanedAcrostic.split(RegExp(r' +'));
    List<String> words = cleanedAcrostic
        .split(RegExp(r' +'))
        .where((w) => w.isNotEmpty)
        .toList();
    words = words.map((w) => w.replaceAll(RegExp(r'[^A-Za-z]'), '')).toList();
    String buildWord = "";

    List<List<String>> wordsParts = [];
    List<String> wordPartsAdd = [];

    for (int i = 0; i < words.length; i++) {
      //debugPrint("getFormattedAcrostic word $i: ${words[i]}");
      Map<String, String> splitWord = splitAcrosticWord(words[i]);
      buildWord += splitWord["first"] ?? "";
      wordPartsAdd.add(words[i]);
      if (nameIndex < nameParts.length && buildWord == nameParts[nameIndex]) {
        buildWord = "";
        nameIndex++;
        wordsParts.add(wordPartsAdd);
        wordPartsAdd = [];
      }
    }

    //debugPrint("getFormattedAcrostic words & wordParts: words=$words, wordsParts: $wordsParts");

    return SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...wordsParts.asMap().entries.expand((entry) {
              int i = entry.key; // index of the word
              List<String> words = entry.value;
              List<Widget> nameSections = [];
              nameSections.add(Padding(
                padding: EdgeInsets.fromLTRB(5, 1, 5, 0),
                child: SizedBox(
                    width: double.infinity,
                    child: RichText(
                      text: TextSpan(
                        children: [
                          // Dynamically generated TextSpans
                          ...words.asMap().entries.expand((entry) {
                            int j = entry.key; // index of the word
                            String w = entry.value;
                            Map<String, String> splitWord =
                                splitAcrosticWord(w);
                            List<TextSpan> spans = [];
                            if (j == 0) {
                              spans.add(
                                TextSpan(
                                  text: "•",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              );
                            }
                            spans.add(
                              TextSpan(
                                text: "${splitWord["first"]}",
                                style: TextStyle(
                                  fontSize: promptFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: const Color.fromARGB(255, 57, 19, 122),
                                ),
                              ),
                            );

                            spans.add(
                              TextSpan(
                                text:
                                    "${splitWord["lower"]}${splitWord["remaining"]}",
                                style: TextStyle(
                                    fontSize: promptFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700]),
                              ),
                            );
                            if (j != words.length - 1) {
                              spans.add(
                                TextSpan(
                                  text: " ",
                                ),
                              );
                            }

                            return spans;
                          }),
                        ],
                      ),
                    )),
              ));
              return nameSections;
            })
          ],
        ));
  }

  static Widget buildBase64Image(String? base64OrDataUrl,
      {double? height, BoxFit fit = BoxFit.contain}) {
    if (base64OrDataUrl == null || base64OrDataUrl.isEmpty) {
      return const Icon(Icons.image_not_supported);
    }

    try {
      // Remove any data URL prefix if present
      String base64Str = base64OrDataUrl.contains(',')
          ? base64OrDataUrl.split(',').last
          : base64OrDataUrl;

      // Remove whitespace/newlines
      base64Str = base64Str.replaceAll(RegExp(r'\s+'), '');

      // Add padding if missing
      int remainder = base64Str.length % 4;
      if (remainder > 0) base64Str += '=' * (4 - remainder);

      // Decode to bytes
      Uint8List bytes = base64Decode(base64Str);

      // Display the image
      return Image.memory(
        bytes,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          // Fallback if decoding fails
          return const Icon(Icons.image_not_supported);
        },
      );
    } catch (e) {
      // Any decoding errors
      debugPrint("Base64 image decode error: $e");
      return const Icon(Icons.image_not_supported);
    }
  }

  static Widget buildImage(String? base64Str, {double? height}) {
    debugPrint("HelpersService.buildImage called");
    if (base64Str == null || base64Str.isEmpty) return const SizedBox();
    try {
      Uint8List bytes = base64Decode(base64Str);
      return Image.memory(
        bytes,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.image_not_supported),
      );
    } catch (e) {
      debugPrint("Image decode error: $e");
      return const Icon(Icons.image_not_supported);
    }
  }

  static Uint8List? decodeBase64Image(String img) {
    try {
      if (img.isEmpty) return null;

      // remove whitespace
      img = img.replaceAll(RegExp(r'\s+'), '');

      // remove data URI prefix if present
      img = img.replaceFirst(RegExp(r'data:image\/[a-zA-Z]+;base64,'), '');

      Uint8List? bytes = base64Decode(img);

      // detect double-encoded base64
      String decodedString = utf8.decode(bytes, allowMalformed: true);

      if (decodedString.startsWith('/9j/') || // jpeg
          decodedString.startsWith('iVBOR') || // png
          decodedString.startsWith('R0lG')) {
        // gif
        bytes = base64Decode(decodedString);
      } else {
        bytes = null;
      }

      return bytes;
    } catch (e) {
      debugPrint("Image decode error: $e");
      return null;
    }
  }

  static String prettify(String text) {
    String textSpaces = text.replaceAll('_', ' ');
    var words = textSpaces.split(" ");
    List<String> retArr = [];
    for (var i = 0; i < words.length; i++) {
      retArr.add(words[i].substring(0, 1).toUpperCase() +
          words[i].substring(1).toLowerCase());
    }
    return retArr.join(" ");
  }

  static String deprettify(String value) {
    value = value.toLowerCase().replaceAll(" ", '_');
    return value;
  }

  static int getEpochSeconds() {
    return DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  }

  static String getTimestamp(DateTime date) {
    String timestamp =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ";

    timestamp +=
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}";

    return timestamp;
  }

  static Future<Uint8List?> pickImage(ImageSource imageSource) async {
    debugPrint("pickImage called");
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: imageSource, // or ImageSource.camera
      imageQuality: 60, // compress
      maxWidth: 512,
      maxHeight: 512,
    );

    if (image == null) {
      debugPrint("pickImage image null!");
      return null;
    }
    Uint8List? imageBytes;
    debugPrint("pickImage got image");

    if (kIsWeb == false) {
      debugPrint("pickImage image.path = ${image.path}");
      final rawBytes = await File(image.path).readAsBytes();
      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) return null;
      final resized = img.copyResize(decoded, width: 1024, height: 1024);
      imageBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 70));
    } else {
      imageBytes = await image.readAsBytes();
    }
    debugPrint("pickImage return image as bytes. Length: ${imageBytes.length}");
    return imageBytes;
  }
}
