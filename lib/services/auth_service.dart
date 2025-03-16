import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService with ChangeNotifier {
  final PocketBase _pb = PocketBase('http://your.pocketbase.server:8090')

  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  Future<void> initialize() async {
    try {
      _isLoading = true;
      print('⚠️ Iniciando conexión con PocketBase');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final email = prefs.getString('user_email');
      final password = prefs.getString('user_password');

      if (token != null && email != null && password != null) {
        await login(email, password);
      }
    } catch (e) {
      print('⚠️ Error al restaurar sesión: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final authData = await _pb.collection('users').authWithPassword(email, password);

      if (authData.record == null) {
        print('⚠️ Error: authData.record es null');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _pb.authStore.token);
      await prefs.setString('user_email', email);
      await prefs.setString('user_password', password);

      _currentUser = User(
        id: authData.record!.id,
        email: authData.record!.data['email'] ?? '',
        username: authData.record!.data['username'] ?? '',
        m3uUrl: authData.record!.data['m3u_url'] ?? '',
      );

      print('⚠️ Usuario autenticado: ${_currentUser?.username}');

      notifyListeners();
      return true;

    } catch (e) {
      print('⚠️ Error de inicio de sesión: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password, String username, String m3uUrl) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userData = await _pb.collection('users').create(body: {
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'username': username,
        'm3u_url': m3uUrl,
      });

      return await login(email, password);

    } catch (e) {
      print('⚠️ Error de registro: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _pb.authStore.clear();
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_email');
    await prefs.remove('user_password');

    notifyListeners();
  }
}