import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_database.dart';

class AICompanionRepository {
  Future<Map<String, dynamic>> sendChatMessage(
    String message,
    String mode, [
    String? photoUrl,
  ]) async {
    try {
      final response = await ApiClient.client.post(
        ApiConstants.aiChat,
        data: {
          'message': message.trim(),
          'mode': mode,
          if (photoUrl != null && photoUrl.isNotEmpty) 'photoUrl': photoUrl,
        },
      );

      final data = Map<String, dynamic>.from(response.data as Map);

      // Cache into local SQLite (fire & forget, don't let DB failure block chat)
      LocalDatabaseHelper.insertAIMessage(
        id: (data['messageId'] ?? 'ai_${DateTime.now().millisecondsSinceEpoch}') as String,
        isUser: false,
        content: (data['reply'] ?? '') as String,
        activeMode: mode,
        photoUrl: data['photoUrl'] as String?,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ).catchError((e) => debugPrint('Safe insertAIMessage error: $e'));

      return data;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'AI connection timeout');
    } catch (e) {
      throw Exception('AI error: $e');
    }
  }

  Future<Map<String, dynamic>> getCompanionProfile() async {
    try {
      final response = await ApiClient.client.get(ApiConstants.aiCompanion);
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      debugPrint('getCompanionProfile fallback: $e');
      return {'name': 'Mira', 'gender': 'female'};
    }
  }

  Future<Map<String, dynamic>> updateCompanionProfile({
    String? name,
    String? gender,
    String? avatarUrl,
    String? languageStyle,
  }) async {
    try {
      final response = await ApiClient.client.put(
        ApiConstants.aiCompanion,
        data: {
          if (name != null) 'name': name,
          if (gender != null) 'gender': gender,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
          if (languageStyle != null) 'languageStyle': languageStyle,
        },
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Failed to update companion');
    } catch (e) {
      throw Exception('Update companion error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final response = await ApiClient.client.get(ApiConstants.aiHistory);
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('⚠️ getHistory fallback: $e');
      return await LocalDatabaseHelper.getAIMessages();
    }
  }

  Future<void> switchMode(String newMode) async {
    try {
      await ApiClient.client.put(
        ApiConstants.aiMode,
        data: {'mode': newMode},
      );
    } catch (_) {}
  }

  Future<Map<String, dynamic>> getMemories() async {
    try {
      final response = await ApiClient.client.get(ApiConstants.aiMemories);
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Failed to load memories');
    } catch (e) {
      throw Exception('Memories error: $e');
    }
  }

  Future<void> deleteMemory(String id) async {
    try {
      await ApiClient.client.delete('${ApiConstants.aiMemories}/$id');
    } catch (e) {
      throw Exception('Could not delete memory');
    }
  }

  Future<void> purgeAllMemories() async {
    try {
      await ApiClient.client.post(ApiConstants.aiPurge);
      await LocalDatabaseHelper.wipeAllLocalData();
    } catch (e) {
      throw Exception('Could not purge memories');
    }
  }

  Future<List<Map<String, dynamic>>> getGallery() async {
    try {
      final response = await ApiClient.client.get(ApiConstants.aiGallery);
      if (response.data?['photos'] is List) {
        return (response.data['photos'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('getGallery error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getPulse() async {
    try {
      final response = await ApiClient.client.get(ApiConstants.aiPulse);
      return Map<String, dynamic>.from(response.data?['pulse'] ?? {});
    } catch (e) {
      debugPrint('getPulse error: $e');
      return {
        'closenessScore': 20,
        'levelNumber': 1,
        'levelTitle': 'Acquaintance',
        'currentMood': 'Warm & curious',
        'nextMilestone': 'Close Friend (Level 2 at 30%)',
      };
    }
  }

  Future<Map<String, dynamic>?> checkProactive() async {
    try {
      final response = await ApiClient.client.post(ApiConstants.aiProactive);
      if (response.data?['sent'] == true) {
        return Map<String, dynamic>.from(response.data['message'] ?? {});
      }
      return null;
    } catch (e) {
      debugPrint('checkProactive error: $e');
      return null;
    }
  }

  Future<void> addMemory(String category, String factKey, String factValue) async {
    try {
      await ApiClient.client.post(
        ApiConstants.aiMemories,
        data: {
          'category': category,
          'factKey': factKey,
          'factValue': factValue,
        },
      );
    } catch (e) {
      throw Exception('Could not add memory');
    }
  }

  Future<void> updateMemory(String id, {String? factKey, String? factValue, String? category}) async {
    try {
      await ApiClient.client.put(
        '${ApiConstants.aiMemories}/$id',
        data: {
          if (factKey != null) 'factKey': factKey,
          if (factValue != null) 'factValue': factValue,
          if (category != null) 'category': category,
        },
      );
    } catch (e) {
      throw Exception('Could not update memory');
    }
  }
}
