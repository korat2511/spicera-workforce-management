import '../../../core/network/api_client.dart';

class AuthApiService {
  const AuthApiService();

  Future<String> login({required String email, required String password}) async {
    final response = await ApiClient.postJson(
      path: '/auth/login',
      body: {'email': email, 'password': password},
    );

    final data = response['data'] as Map<String, dynamic>;
    return data['token'] as String;
  }

  Future<void> logout() async {
    await ApiClient.postJson(path: '/auth/logout', body: const {});
  }
}
