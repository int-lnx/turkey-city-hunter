import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Conditionally import dart:html for Web only without breaking non-web platforms/tests
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

class FileHelper {
  /// Harita JSON verisini dosya olarak indirir (.json)
  static Future<void> downloadJsonFile({
    required String jsonContent,
    required String fileName,
  }) async {
    if (kIsWeb) {
      final bytes = utf8.encode(jsonContent);
      final blob = html.Blob([bytes], 'application/json');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..style.display = 'none';
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } else {
      // Web dışı ortamda Clipboard yedekleme olanağı
      await Clipboard.setData(ClipboardData(text: jsonContent));
    }
  }

  /// Web ortamında kullanıcının JSON dosyası seçmesini sağlar ve dosya içeriğini döndürür.
  static Future<String?> pickJsonFile() async {
    if (!kIsWeb) return null;

    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = '.json,application/json';
    uploadInput.click();

    await uploadInput.onChange.first;
    if (uploadInput.files == null || uploadInput.files!.isEmpty) {
      return null;
    }

    final file = uploadInput.files!.first;
    final reader = html.FileReader();
    reader.readAsText(file);

    await reader.onLoadEnd.first;
    return reader.result as String?;
  }
}
