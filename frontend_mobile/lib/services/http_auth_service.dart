import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

Future<http.Response> httpGetConAuth(Uri url) async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('jwt_token');

  var res = await http.get(url, headers: {'Authorization': 'Bearer $token'});

  if (res.statusCode == 401) {
    final nuevoToken = await AuthService().refreshToken();
    if (nuevoToken != null) {
      res = await http.get(
        url,
        headers: {'Authorization': 'Bearer $nuevoToken'},
      );
    }
  }

  return res;
}

Future<http.Response> httpPostConAuth(
  Uri url,
  Map<String, dynamic> body,
) async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('jwt_token');

  var res = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(body),
  );

  if (res.statusCode == 401) {
    final nuevoToken = await AuthService().refreshToken();
    if (nuevoToken != null) {
      res = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $nuevoToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
    }
  }

  return res;
}

Future<http.Response?> httpMultipartPostConAuth({
  required Uri url,
  required String filePath,
  required String field,
  Map<String, String>? fields,
}) async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('jwt_token');

  var request =
      http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath(field, filePath));

  if (fields != null) {
    request.fields.addAll(fields);
  }

  var streamedResponse = await request.send();
  var response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode == 401) {
    final nuevoToken = await AuthService().refreshToken();
    if (nuevoToken != null) {
      request =
          http.MultipartRequest('POST', url)
            ..headers['Authorization'] = 'Bearer $nuevoToken'
            ..files.add(await http.MultipartFile.fromPath(field, filePath));
      if (fields != null) {
        request.fields.addAll(fields);
      }

      streamedResponse = await request.send();
      response = await http.Response.fromStream(streamedResponse);
    }
  }

  return response;
}

Future<http.Response> httpPutConAuth(Uri url, Map<String, dynamic> body) async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('jwt_token');

  var res = await http.put(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(body),
  );

  if (res.statusCode == 401) {
    final nuevoToken = await AuthService().refreshToken();
    if (nuevoToken != null) {
      res = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $nuevoToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
    }
  }

  return res;
}

Future<http.Response> httpDeleteConAuth(Uri url) async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('jwt_token');

  var res = await http.delete(url, headers: {'Authorization': 'Bearer $token'});

  if (res.statusCode == 401) {
    final nuevoToken = await AuthService().refreshToken();
    if (nuevoToken != null) {
      res = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $nuevoToken'},
      );
    }
  }

  return res;
}
