import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_constants.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient._();

  static Future<Map<String, dynamic>> get(String path) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');

    final http.Response response;
    try {
      response = await http.get(uri, headers: {'Accept': 'application/json'});
    } on SocketException {
      throw ApiException('No internet connection. Please try again.');
    } catch (_) {
      throw ApiException('Could not reach the server. Please try again.');
    }

    return _parse(response);
  }

  static Future<Map<String, dynamic>> patchJson({
    required String path,
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');

    final http.Response response;
    try {
      response = await http.patch(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
    } on SocketException {
      throw ApiException('No internet connection. Please try again.');
    } catch (_) {
      throw ApiException('Could not reach the server. Please try again.');
    }

    return _parse(response);
  }

  static Future<Map<String, dynamic>> postJson({
    required String path,
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');

    final http.Response response;
    try {
      response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
    } on SocketException {
      throw ApiException('No internet connection. Please try again.');
    } catch (_) {
      throw ApiException('Could not reach the server. Please try again.');
    }

    return _parse(response);
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');

    final http.Response response;
    try {
      response = await http.delete(
        uri,
        headers: {'Accept': 'application/json'},
      );
    } on SocketException {
      throw ApiException('No internet connection. Please try again.');
    } catch (_) {
      throw ApiException('Could not reach the server. Please try again.');
    }

    return _parse(response);
  }

  static Future<Map<String, dynamic>> postMultipart({
    required String path,
    required Map<String, String> fields,
    File? file,
    String fileFieldName = 'profile_photo',
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..fields.addAll(fields);

    if (file != null) {
      request.files.add(
        await http.MultipartFile.fromPath(fileFieldName, file.path),
      );
    }

    final http.Response response;
    try {
      final streamedResponse = await request.send();
      response = await http.Response.fromStream(streamedResponse);
    } on SocketException {
      throw ApiException('No internet connection. Please try again.');
    } catch (_) {
      throw ApiException('Could not reach the server. Please try again.');
    }

    return _parse(response);
  }

  static Map<String, dynamic> _parse(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected response from the server.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = body['message'] as String? ?? 'Request failed.';

    if (response.statusCode == 422 && body['errors'] is Map) {
      final rawErrors = body['errors'] as Map;
      throw ApiValidationException(
        message,
        rawErrors.map(
          (key, value) =>
              MapEntry(key as String, List<String>.from(value as List)),
        ),
      );
    }

    throw ApiException(message, statusCode: response.statusCode);
  }
}
