import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class HumanChatRepository {
  Future<List<Map<String, dynamic>>> getMessages(String friendId) async {
    try {
      final response = await ApiClient.client.get('${ApiConstants.humanChat}/$friendId');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Could not load messages');
    }
  }

  Future<Map<String, dynamic>> sendMessage(String receiverId, String content, {String? mediaUrl}) async {
    try {
      final response = await ApiClient.client.post(
        '${ApiConstants.humanChat}/send',
        data: {
          'receiverId': receiverId,
          'content': content.trim(),
          if (mediaUrl != null && mediaUrl.isNotEmpty) 'mediaUrl': mediaUrl.trim(),
        },
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Could not send message');
    }
  }

  Future<void> markAsRead(String friendId) async {
    try {
      await ApiClient.client.post('${ApiConstants.humanChat}/$friendId/read');
    } catch (_) {}
  }
}
