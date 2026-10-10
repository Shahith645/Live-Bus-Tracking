import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../db/db_helper.dart';

/// Holds the currently logged-in user and exposes simple session helpers.
class SessionProvider extends ChangeNotifier {
  AppUser? currentUser;

  bool get isLoggedIn => currentUser != null;
  bool get isAdmin => currentUser?.isAdmin ?? false;

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('session_email');
    if (email != null) {
      currentUser = await DBHelper.instance.getUserByEmail(email);
      notifyListeners();
    }
  }

  Future<void> login(AppUser user) async {
    currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_email', user.email);
    notifyListeners();
  }

  Future<void> logout() async {
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_email');
    notifyListeners();
  }

  void refreshUser(AppUser user) {
    currentUser = user;
    notifyListeners();
  }
}
