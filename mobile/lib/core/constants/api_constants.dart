import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  // Allow overriding with --dart-define=BACKEND_HOST=soulm8-iota.vercel.app
  static const String _customHost = String.fromEnvironment('BACKEND_HOST', defaultValue: '');

  static String get host {
    if (_customHost.isNotEmpty) {
      return _customHost.replaceFirst(RegExp(r'^https?:\/\/'), '');
    }
    if (kIsWeb) {
      // In web debug mode, use localhost:5000; in production, use the live Vercel domain
      return kDebugMode ? 'localhost:5000' : 'soulm8-iota.vercel.app';
    }
    if (Platform.isAndroid) {
      // In Android release mode, connect to public Vercel production domain; in debug, LAN IP
      return kReleaseMode ? 'soulm8-iota.vercel.app' : '192.168.1.8:5000';
    }
    return 'soulm8-iota.vercel.app';
  }

  static bool get isSecure {
    if (_customHost.startsWith('https://')) return true;
    if (_customHost.startsWith('http://')) return false;
    if (host.contains('vercel.app') || host.contains('.com') || host.contains('.org')) return true;
    if (kIsWeb && !kDebugMode) return true;
    return false;
  }

  static String get baseUrl {
    final scheme = isSecure ? 'https' : 'http';
    return '$scheme://$host/api';
  }

  static String get socketUrl {
    final scheme = isSecure ? 'https' : 'http';
    return '$scheme://$host';
  }

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
