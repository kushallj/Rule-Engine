import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/docflow_api.dart';

/// Signed-in state: which DocFlow server, and the API token for it.
class Session extends ChangeNotifier {
  static const _kUrl = 'docflow.url';
  static const _kToken = 'docflow.token';
  static const _kUser = 'docflow.user';
  static const defaultUrl = 'http://localhost:8000';

  String serverUrl = defaultUrl;
  String? username;
  DocflowApi? api;

  bool get signedIn => api?.token != null;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    serverUrl = prefs.getString(_kUrl) ?? defaultUrl;
    final token = prefs.getString(_kToken);
    username = prefs.getString(_kUser);
    if (token != null) api = DocflowApi(serverUrl, token: token);
    notifyListeners();
  }

  Future<void> signIn(String url, String user, String password) async {
    final token = await DocflowApi(url).login(user, password);
    serverUrl = url;
    username = user;
    api = DocflowApi(url, token: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUrl, url);
    await prefs.setString(_kToken, token);
    await prefs.setString(_kUser, user);
    notifyListeners();
  }

  Future<void> signOut() async {
    api = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    notifyListeners();
  }
}
