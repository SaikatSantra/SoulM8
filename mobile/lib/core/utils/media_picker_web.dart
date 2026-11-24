import 'dart:html' as html;
import 'dart:async';
import '../network/api_client.dart';

Future<String?> pickImageAndUpload({String folder = 'chat'}) async {
  final completer = Completer<String?>();
  final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
  uploadInput.click();

  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      final file = files[0];
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      reader.onLoadEnd.listen((e) async {
        try {
          final dataUrl = reader.result as String;
          final response = await ApiClient.client.post('/upload', data: {
            'image': dataUrl,
            'filename': file.name,
            'folder': folder,
          });
          if (response.statusCode == 200 && response.data != null) {
            completer.complete(response.data['url'] as String);
          } else {
            completer.complete(null);
          }
        } catch (err) {
          completer.complete(null);
        }
      });
    } else {
      completer.complete(null);
    }
  });

  return completer.future;
}
