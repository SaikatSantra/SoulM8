import 'media_picker_io.dart' if (dart.library.html) 'media_picker_web.dart';

class MediaPickerHelper {
  static Future<String?> pickAndUploadImage({String folder = 'chat'}) async {
    return pickImageAndUpload(folder: folder);
  }
}
