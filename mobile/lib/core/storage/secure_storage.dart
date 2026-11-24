import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'soulm8_jwt_token';
  static const _userKey = 'soulm8_user_data';
  static const _companionModeKey = 'soulm8_companion_mode';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> saveUserRaw(String jsonStr) async {
    await _storage.write(key: _userKey, value: jsonStr);
  }

  static Future<String?> getUserRaw() async {
    return await _storage.read(key: _userKey);
  }

  static Future<void> saveCompanionMode(String mode) async {
    await _storage.write(key: _companionModeKey, value: mode);
  }

  static Future<String> getCompanionMode() async {
    return await _storage.read(key: _companionModeKey) ?? 'ROMANTIC';
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
