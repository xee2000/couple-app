import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  ApiService._();
  factory ApiService() => _instance;

  final String _base = AppConstants.serverUrl;

  Future<String?> get _token async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<Map<String, String>> get _headers async {
    final token = await _token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$_base$path'),
      headers: await _headers,
      body: jsonEncode(body),
    );
    return _parse(res);
  }

  Future<dynamic> get(String path) async {
    final res = await http.get(Uri.parse('$_base$path'), headers: await _headers);
    return _parse(res);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$_base$path'),
      headers: await _headers,
      body: jsonEncode(body),
    );
    return _parse(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await http.delete(Uri.parse('$_base$path'), headers: await _headers);
    return _parse(res);
  }

  dynamic _parse(http.Response res) {
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw Exception(data['message'] ?? '서버 오류');
    return data;
  }
}
