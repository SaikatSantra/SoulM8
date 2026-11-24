import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';

class AuthRepository {
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await ApiClient.client.post(
        ApiConstants.login,
        data: {
          'identifier': identifier.trim(),
          'password': password,
        },
      );

      final data = Map<String, dynamic>.from(response.data as Map);
      final token = data['token'] as String;
      final user = Map<String, dynamic>.from(data['user'] as Map);

      await SecureStorageService.saveToken(token);
      await SecureStorageService.saveUserRaw(jsonEncode(user));

      return data;
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['error'] ?? 'Login failed. Please check your credentials.';
      throw Exception(errorMsg);
    }
  }

  Future<Map<String, dynamic>> register({
    String? email,
    String? phoneNumber,
    required String password,
    required String displayName,
    String? bio,
    String? companionName,
    String? companionGender,
  }) async {
    try {
      final response = await ApiClient.client.post(
        ApiConstants.register,
        data: {
          if (email != null && email.isNotEmpty) 'email': email.trim(),
          if (phoneNumber != null && phoneNumber.isNotEmpty) 'phoneNumber': phoneNumber.trim(),
          'password': password,
          'displayName': displayName.trim(),
          if (bio != null) 'bio': bio.trim(),
          'companionName': companionName ?? 'Soulie',
          'companionGender': companionGender ?? 'female',
        },
      );

      final data = Map<String, dynamic>.from(response.data as Map);
      final token = data['token'] as String;
      final user = Map<String, dynamic>.from(data['user'] as Map);

      await SecureStorageService.saveToken(token);
      await SecureStorageService.saveUserRaw(jsonEncode(user));

      return data;
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['error'] ?? 'Registration failed. Please try again.';
      throw Exception(errorMsg);
    }
  }

  Future<Map<String, dynamic>?> getMe() async {
    try {
      final response = await ApiClient.client.get(ApiConstants.me);
      final user = Map<String, dynamic>.from(response.data as Map);
      await SecureStorageService.saveUserRaw(jsonEncode(user));
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? phoneNumber,
  }) async {
    try {
      final response = await ApiClient.client.put(
        '/auth/profile',
        data: {
          if (displayName != null) 'displayName': displayName.trim(),
          if (bio != null) 'bio': bio.trim(),
          if (avatarUrl != null) 'avatarUrl': avatarUrl.trim(),
          if (phoneNumber != null) 'phoneNumber': phoneNumber.trim(),
        },
      );

      final updatedUser = Map<String, dynamic>.from(response.data as Map);
      await SecureStorageService.saveUserRaw(jsonEncode(updatedUser));
      return updatedUser;
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['error'] ?? 'Could not update profile.';
      throw Exception(errorMsg);
    }
  }

  Future<void> logout() async {
    await SecureStorageService.clearAll();
  }
}
