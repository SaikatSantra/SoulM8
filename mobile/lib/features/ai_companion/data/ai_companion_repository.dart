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
}
