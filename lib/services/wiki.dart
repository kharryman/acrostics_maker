import 'dart:convert';

import 'package:acrostics_maker/services/helpers.dart';
import 'package:http/http.dart' as http;

class WikiService {
  static Future<String?> getSummaryFromText(String text) async {
    List<String> searchResults = await searchWikipedia(text);
    if (searchResults.isNotEmpty) {
      String title = searchResults.first;
      return await fetchWikipediaSummary(title);
    }
    return null;
  }

  static Future<List<String>> searchWikipedia(String query) async {
    if (query.trim().isEmpty) return [];
    //String? gotLanguageCode = await HelpersService.getData("LANGUAGE");
    //String languageCode = gotLanguageCode ?? "en";
    String languageCode = "en";
    final url = Uri.parse(
      'https://${languageCode}.wikipedia.org/w/api.php'
      '?action=opensearch'
      '&format=json'
      '&search=$query'
      '&limit=1'
      '&origin=*',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<String>.from(data[1]); // titles
    } else {
      throw Exception('Failed to load Wikipedia results');
    }
  }

  static Future<String?> fetchWikipediaSummary(String title) async {
    final encodedTitle = Uri.encodeComponent(title);
    //String? gotLanguageCode = await HelpersService.getData("LANGUAGE");
    //String languageCode = gotLanguageCode ?? "en";
    String languageCode = "en";
    final url = Uri.parse(
      'https://$languageCode.wikipedia.org/api/rest_v1/page/summary/$encodedTitle',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['extract']; // short summary
    } else {
      return null;
    }
  }
}
