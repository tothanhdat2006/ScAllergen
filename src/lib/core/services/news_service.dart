// lib/core/services/news_service.dart
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:flutter/foundation.dart';

class NewsArticle {
  final String title;
  final String link;
  final String imageUrl;
  final String pubDate;

  NewsArticle({
    required this.title,
    required this.link,
    required this.imageUrl,
    required this.pubDate,
  });
}

class NewsService {
  static const String _rssUrl = 'https://vnexpress.net/rss/suc-khoe.rss';

  static Future<List<NewsArticle>> fetchHealthNews() async {
    try {
      final response = await http.get(Uri.parse(_rssUrl));

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final items = document.findAllElements('item');

        return items.map((element) {
          final title = element.findElements('title').first.innerText;
          final link = element.findElements('link').first.innerText;
          final pubDate = element.findElements('pubDate').first.innerText;

          final description = element.findElements('description').first.innerText;
          final imageRegex = RegExp(r'src="([^"]+)"');
          final match = imageRegex.firstMatch(description);
          final imageUrl = match?.group(1) ?? '';

          return NewsArticle(
            title: title,
            link: link,
            imageUrl: imageUrl,
            pubDate: pubDate,
          );
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint("Error fetching news: $e");
      return [];
    }
  }
}