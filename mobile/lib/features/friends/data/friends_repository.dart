import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class FriendsRepository {
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final response = await ApiClient.client.get(
        ApiConstants.searchFriends,
        queryParameters: {'query': query},
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Search failed');
    }
  }

  Future<Map<String, dynamic>> addFriend(String friendId) async {
    try {
      final response = await ApiClient.client.post(
        ApiConstants.addFriend,
        data: {'friendId': friendId},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Could not add friend');
    }
  }

  Future<List<Map<String, dynamic>>> getFriendsList() async {
    try {
      final response = await ApiClient.client.get(ApiConstants.listFriends);
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Could not fetch friends');
    }
  }
}
