import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Auth {
  static const _usersKey = 'smx_users';
  static const _sessionKey = 'smx_session';

  static String _hash(String salt, String pass) =>
      sha256.convert(utf8.encode('$salt:$pass')).toString();

  static String _salt() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
  }

  static Map<String, dynamic> _users(SharedPreferences p) =>
      jsonDecode(p.getString(_usersKey) ?? '{}') as Map<String, dynamic>;

  static Future<String?> session() async {
    final p = await SharedPreferences.getInstance();
    final u = p.getString(_sessionKey);
    if (u == null || u.isEmpty) return null;
    return _users(p).containsKey(u) ? u : null;
  }

  /// Devuelve un mensaje de error, o null si todo ha ido bien.
  static Future<String?> register(String user, String pass) async {
    final u = user.trim().toLowerCase();
    if (u.length < 3) return "L'usuari ha de tenir almenys 3 caràcters.";
    if (pass.length < 4) return 'La contrasenya ha de tenir almenys 4 caràcters.';
    final p = await SharedPreferences.getInstance();
    final users = _users(p);
    if (users.containsKey(u)) return 'Aquest usuari ja existeix.';
    final salt = _salt();
    users[u] = {'s': salt, 'h': _hash(salt, pass)};
    await p.setString(_usersKey, jsonEncode(users));
    await p.setString(_sessionKey, u);
    Counter.get(up: true); // suma 1 al comptador global (sense esperar)
    return null;
  }

  static Future<String?> login(String user, String pass) async {
    final u = user.trim().toLowerCase();
    final p = await SharedPreferences.getInstance();
    final rec = _users(p)[u];
    if (rec == null) return 'Usuari o contrasenya incorrectes.';
    if (_hash(rec['s'] as String, pass) != rec['h']) {
      return 'Usuari o contrasenya incorrectes.';
    }
    await p.setString(_sessionKey, u);
    return null;
  }

  static Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_sessionKey);
  }

  static Future<int> localCount() async {
    final p = await SharedPreferences.getInstance();
    return _users(p).length;
  }
}

/// Comptador global de persones registrades (counterapi.dev, sense clau).
class Counter {
  static const _base =
      'https://api.counterapi.dev/v1/smx-m1665-chuleta/registrados/';

  static Future<int?> get({bool up = false}) async {
    final c = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final req = await c.getUrl(Uri.parse(_base + (up ? 'up' : '')));
      final res = await req.close().timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final body = await res.transform(utf8.decoder).join();
      final j = jsonDecode(body);
      final n = j is Map ? j['count'] : null;
      return n is int ? n : null;
    } catch (_) {
      return null;
    } finally {
      c.close();
    }
  }
}
