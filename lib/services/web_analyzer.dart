import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:fast_gbk/fast_gbk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_boilerplate/config/constants.dart';
import 'package:flutter_boilerplate/config/locator.dart';
import 'package:flutter_boilerplate/extensions/extensions.dart';
import 'package:flutter_boilerplate/models/models.dart';
import 'package:flutter_boilerplate/repositories/repositories.dart';
import 'package:html/dom.dart' hide Comment, Text;
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:logger/logger.dart';

abstract class InfoBase {
  late bool _shouldRetry;

  Map<String, dynamic> toJson();
}

/// Web Information
class WebInfo extends InfoBase {
  WebInfo({this.title, this.icon, this.description, this.image});

  WebInfo.fromJson(Map<String, dynamic> json)
      : title = json['title'] as String?,
        icon = json['icon'] as String?,
        description = json['description'] as String?,
        image = json['image'] as String?;

  final String? title;
  final String? icon;
  final String? description;
  final String? image;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'icon': icon,
      'description': description,
      'image': image,
    };
  }
}

/// Image Information
class WebImageInfo extends InfoBase {
  WebImageInfo({this.image});

  final String? image;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'image': image,
    };
  }
}

/// Video Information
class WebVideoInfo extends WebImageInfo {
  WebVideoInfo({super.image});
}

/// Web analyzer
class WebAnalyzer {
  static final Map<String?, InfoBase> cacheMap = <String?, InfoBase>{};
  static final RegExp _bodyReg =
      RegExp(r'<body[^>]*>([\s\S]*?)<\/body>', caseSensitive: false);
  static final RegExp _htmlReg = RegExp(
    r'(<head[^>]*>([\s\S]*?)<\/head>)|(<script[^>]*>([\s\S]*?)<\/script>)|(<style[^>]*>([\s\S]*?)<\/style>)|(<[^>]+>)|(<link[^>]*>([\s\S]*?)<\/link>)|(<[^>]+>)',
    caseSensitive: false,
  );
  static final RegExp _metaReg = RegExp(
    r'<(meta|link)(.*?)\/?>|<title(.*?)</title>',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _titleReg =
      RegExp('(title|icon|description|image)', caseSensitive: false);
  static final RegExp _lineReg = RegExp(r'[\n\r]|&nbsp;|&gt;');
  static final RegExp _spaceReg = RegExp(r'\s+');

  static bool isEmpty(String? str) {
    return !isNotEmpty(str);
  }

  static bool isNotEmpty(String? str) {
    return str != null && str.isNotEmpty && str.trim().isNotEmpty;
  }

  /// Get web information
  /// return [InfoBase]
  static InfoBase? getInfoFromCache(String? cacheKey) {
    if (cacheKey == null) return null;

    final InfoBase? info = cacheMap[cacheKey];

    return info;
  }

  static Future<InfoBase?> _getInfo(String url, bool? multimedia) async {
    final Response? response = await _requestUrl(url);

    if (response == null) return null;

    if (multimedia!) {
      final String? contentType = response.headers['content-type'];
      if (contentType != null) {
        if (contentType.contains('image/')) {
          return WebImageInfo(image: url);
        } else if (contentType.contains('video/')) {
          return WebVideoInfo(image: url);
        }
      }
    }

    return _getWebInfo(response, url, multimedia);
  }

  static Future<List<dynamic>?> _fetchInfoFromUrl(dynamic message) async {
    try {
      // ignore: avoid_dynamic_calls
      final String url = message[0] as String;
      // ignore: avoid_dynamic_calls
      final bool multimedia = message[1] as bool;

      final InfoBase? info = await _getInfo(url, multimedia);

      if (info is WebInfo) {
        return <dynamic>[
          '0',
          info.title,
          info.description,
          info.icon,
          info.image,
        ];
      } else if (info is WebVideoInfo) {
        return <dynamic>['1', info.image];
      } else if (info is WebImageInfo) {
        return <dynamic>['2', info.image];
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  static bool _certificateCheck(X509Certificate cert, String host, int port) =>
      true;

  static Future<Response?> _requestUrl(
    String url, {
    int count = 0,
    String? cookie,
  }) async {
    Response? res;
    final Uri uri = Uri.parse(url);
    final HttpClient ioClient = HttpClient()
      ..badCertificateCallback = _certificateCheck
      ..connectionTimeout = AppDurations.tenSeconds;
    final IOClient client = IOClient(ioClient);
    final BaseRequest request = Request('GET', uri)
      ..followRedirects = true
      ..maxRedirects = 3
      ..persistentConnection = true
      ..headers['accept-encoding'] = 'gzip, deflate'
      ..headers['User-Agent'] = url.contains('twitter.com')
          ? 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'
          : 'Mozilla/5.0'
      ..headers['cache-control'] = 'no-cache'
      ..headers['accept'] =
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9';

    try {
      final IOStreamedResponse stream =
          await client.send(request).timeout(AppDurations.tenSeconds);

      if (stream.statusCode == HttpStatus.movedTemporarily ||
          stream.statusCode == HttpStatus.movedPermanently) {
        if (stream.isRedirect && count < 6) {
          final String? location = stream.headers['location'];
          if (location != null) {
            url = location;
            if (location.startsWith('/')) {
              url = uri.origin + location;
            }
          }
          if (stream.headers['set-cookie'] != null) {
            cookie = stream.headers['set-cookie'];
          }
          count++;
          client.close();
          return _requestUrl(url, count: count, cookie: cookie);
        }
      } else if (stream.statusCode == HttpStatus.ok) {
        res = await Response.fromStream(stream);
        if (uri.host == 'm.tb.cn') {
          final RegExpMatch? match =
              RegExp(r"var url = \'(.*)\'").firstMatch(res.body);
          if (match != null) {
            final String? newUrl = match.group(1);
            if (newUrl != null) {
              return _requestUrl(newUrl, count: count, cookie: cookie);
            }
          }
        }
      }
      client.close();
      return res;
    } catch (_) {
      return null;
    }
  }

  static Future<InfoBase?> _getWebInfo(
    Response response,
    String url,
    bool? multimedia,
  ) async {
    if (response.statusCode == HttpStatus.ok) {
      String? html;
      try {
        html = const Utf8Decoder().convert(response.bodyBytes);
        if (url.contains('twitter.com')) {
          String temp = html.replaceAll(r'\', '');
          temp = temp.replaceAll('u003C', '<');
          temp = temp.replaceAll('u003E', '>');
        }
      } catch (e) {
        try {
          html = gbk.decode(response.bodyBytes);
        } catch (e) {
          locator
              .get<Logger>()
              .e('''web page resolution failure from:$url Error:$e''');
        }
      }

      if (html == null) return null;

      final String headHtml = _getHeadHtml(html);
      final Document document = parser.parse(headHtml);
      final Uri uri = Uri.parse(url);

      // get image or video
      if (multimedia!) {
        final InfoBase? gif = _analyzeGif(document, uri);
        if (gif != null) return gif;

        final InfoBase? video = _analyzeVideo(document, uri);
        if (video != null) return video;
      }

      final WebInfo info = WebInfo(
        title: _analyzeTitle(document),
        icon: _analyzeIcon(document, uri),
        description: _analyzeDescription(document, html),
        image: _analyzeImage(document, uri),
      );
      return info;
    }
    return null;
  }

  static String _getHeadHtml(String html) {
    html = html.replaceFirst(_bodyReg, '<body></body>');
    final Iterable<RegExpMatch> matches = _metaReg.allMatches(html);
    final StringBuffer head = StringBuffer('<html><head>');
    for (final RegExpMatch element in matches) {
      final String str = element.group(0)!;
      if (str.contains(_titleReg)) head.writeln(str);
    }
    head.writeln('</head></html>');
    return head.toString();
  }

  static String? _getMetaContent(
    Document document,
    String property,
    String propertyValue,
  ) {
    final List<Element> meta = document.head!.getElementsByTagName('meta');
    final Element? ele = meta.firstWhereOrNull(
      (Element e) => e.attributes[property] == propertyValue,
    );
    if (ele != null) return ele.attributes['content']?.trim();
    return null;
  }

  static InfoBase? _analyzeGif(Document document, Uri uri) {
    if (_getMetaContent(document, 'property', 'og:image:type') == 'image/gif') {
      final String? gif = _getMetaContent(document, 'property', 'og:image');
      if (gif != null) return WebImageInfo(image: _handleUrl(uri, gif));
    }
    return null;
  }

  static InfoBase? _analyzeVideo(Document document, Uri uri) {
    final String? video = _getMetaContent(document, 'property', 'og:video');
    if (video != null) return WebVideoInfo(image: _handleUrl(uri, video));
    return null;
  }

  static String _analyzeTitle(Document document, {bool isTwitter = false}) {
    if (isTwitter) return '';
    final String? title = _getMetaContent(document, 'property', 'og:title');

    if (title != null) return title;
    final List<Element> list = document.head!.getElementsByTagName('title');
    if (list.isNotEmpty) {
      final String tagTitle = list.first.text;
      return tagTitle.trim();
    }
    return '';
  }

  static String? _analyzeDescription(Document document, String html) {
    final String? desc =
        _getMetaContent(document, 'property', 'og:description');
    if (desc != null &&
        !desc.contains('JavaScript is disabled in your browser')) return desc;

    final String? description =
        _getMetaContent(document, 'name', 'description') ??
            _getMetaContent(document, 'name', 'Description');

    if (isEmpty(description)) {
      String body = html.replaceAll(_htmlReg, '');
      body = body.trim().replaceAll(_lineReg, ' ').replaceAll(_spaceReg, ' ');
      if (body.length > 300) {
        body = body.substring(0, 300);
      }
      if (body.contains('JavaScript is disabled in your browser')) return '';
      return body;
    }

    if (description!.contains('JavaScript is disabled in your browser')) {
      return '';
    }
    return description;
  }

  static String? _analyzeIcon(Document document, Uri uri) {
    final List<Element> meta = document.head!.getElementsByTagName('link');
    String? icon = '';
    // get icon first
    Element? metaIcon = meta.firstWhereOrNull((Element e) {
      final String rel = (e.attributes['rel'] ?? '').toLowerCase();
      if (rel == 'icon') {
        icon = e.attributes['href'];
        if (icon != null && !icon!.toLowerCase().contains('.svg')) {
          return true;
        }
      }
      return false;
    });

    metaIcon ??= meta.firstWhereOrNull((Element e) {
      final String rel = (e.attributes['rel'] ?? '').toLowerCase();
      if (rel == 'shortcut icon') {
        icon = e.attributes['href'];
        if (icon != null && !icon!.toLowerCase().contains('.svg')) {
          return true;
        }
      }
      return false;
    });

    if (metaIcon != null) {
      icon = metaIcon.attributes['href'];
    } else {
      return '${uri.origin}/favicon.ico';
    }

    return _handleUrl(uri, icon);
  }

  static String? _analyzeImage(Document document, Uri uri) {
    final String? image = _getMetaContent(document, 'property', 'og:image');
    return _handleUrl(uri, image);
  }

  static String? _handleUrl(Uri uri, String? source) {
    if (isNotEmpty(source) && !source!.startsWith('http')) {
      if (source.startsWith('//')) {
        source = '${uri.scheme}:$source';
      } else {
        if (source.startsWith('/')) {
          source = '${uri.origin}$source';
        } else {
          source = '${uri.origin}/$source';
        }
      }
    }
    return source;
  }
}
