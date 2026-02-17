import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:metadata_fetch/metadata_fetch.dart';

class MetadataService {
  static bool _isYouTube(String url) =>
      url.contains('youtube.com') || url.contains('youtu.be');

  static bool _isTwitter(String url) =>
      url.contains('twitter.com') || url.contains('x.com');

  static Future<Map<String, String?>> fetch(String url) async {
    try {
      if (_isYouTube(url)) return await _fetchYouTube(url);
      if (_isTwitter(url)) return await _fetchTwitter(url);
      return await _fetchGeneral(url);
    } catch (_) {
      return {};
    }
  }

  static Future<Map<String, String?>> _fetchYouTube(String url) async {
    try {
      final oembedUrl = Uri.parse(
        'https://www.youtube.com/oembed?url=${Uri.encodeComponent(url)}&format=json',
      );
      final response = await http.get(oembedUrl);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'title': json['title'] as String?,
          'description': json['author_name'] as String?,
          'image': json['thumbnail_url'] as String?,
          'favicon': 'https://www.youtube.com/favicon.ico',
        };
      }
    } catch (_) {}
    return {};
  }

  static Future<Map<String, String?>> _fetchTwitter(String url) async {
    try {
      final oembedUrl = Uri.parse(
        'https://publish.twitter.com/oembed?url=${Uri.encodeComponent(url)}&omit_script=true',
      );
      final response = await http.get(oembedUrl);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final html = json['html'] as String? ?? '';
        final authorName = json['author_name'] as String? ?? '';

        // Tweet metnini HTML'den çıkar (<p> içindeki metin)
        final textMatch =
            RegExp(r'<p[^>]*>(.*?)</p>', dotAll: true).firstMatch(html);
        String? tweetText = textMatch?.group(1);
        if (tweetText != null) {
          // HTML taglerini temizle
          tweetText = tweetText
              .replaceAll(RegExp(r'<[^>]+>'), '')
              .replaceAll('&amp;', '&')
              .replaceAll('&lt;', '<')
              .replaceAll('&gt;', '>')
              .replaceAll('&#39;', "'")
              .replaceAll('&quot;', '"')
              .trim();
        }

        return {
          'title': tweetText?.isNotEmpty == true
              ? '@$authorName: $tweetText'
              : '@$authorName',
          'description': authorName,
          'image': null,
          'favicon': 'https://abs.twimg.com/favicons/twitter.3.ico',
        };
      }
    } catch (_) {}
    return {};
  }

  static Future<Map<String, String?>> _fetchGeneral(String url) async {
    try {
      final data = await MetadataFetch.extract(url);
      if (data == null) return {};

      String? faviconUrl;
      try {
        final uri = Uri.parse(url);
        faviconUrl = '${uri.scheme}://${uri.host}/favicon.ico';
      } catch (_) {}

      return {
        'title': data.title,
        'description': data.description,
        'image': data.image,
        'favicon': faviconUrl,
      };
    } catch (_) {
      return {};
    }
  }
}
