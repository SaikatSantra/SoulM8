import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  // Allow overriding with --dart-define=BACKEND_HOST=192.168.1.6
  static const String _customHost = String.fromEnvironment('BACKEND_HOST', defaultValue: '');

  static String get host {
    if (_customHost.isNotEmpty) return _customHost;
    if (kIsWeb) return 'localhost:5000';
    if (Platform.isAndroid) {
      // Connects to local machine backend on same Wi-Fi network out-of-the-box.
      // Can be overridden via --dart-define=BACKEND_HOST=your_ip:5000
      return '192.168.1.8:5000';
    }
    return 'localhost:5000';
  }

  static String get baseUrl => 'http://$host/api';
  static String get socketUrl => 'http://$host';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';

  // Friends
  static const String searchFriends = '/friends/search';
  static const String addFriend = '/friends/add';
  static const String listFriends = '/friends/list';

  // Human Chat
  static const String humanChat = '/human-chat';

  // AI Companion
  static const String aiChat = '/ai/chat';
  static const String aiHistory = '/ai/history';
  static const String aiMode = '/ai/mode';
  static const String aiMemories = '/ai/memories';
  static const String aiPurge = '/ai/memories/purge';
  static const String aiTraining = '/ai/training-examples';
  static const String aiCompanion = '/ai/companion';

  // Upload
  static const String upload = '/upload';
}
