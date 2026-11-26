import 'package:flutter/material.dart';
import 'auth.dart';
import 'calendar.dart';
import 'data.dart';
import 'notes.dart';
import 'notify.dart';
import 'quiz.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Data.load();
  await Notify.init();
  runApp(const SmxApp());
}

class SmxApp extends StatelessWidget {
  const SmxApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1E40AF);
    return MaterialApp(
      title: 'Chuleta SMX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: seed),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: seed,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const Gate(),
    );
  }
}

/// Decide si se muestra el login o la app según la sesión guardada.
class Gate extends StatefulWidget {
  const Gate({super.key});
  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> {
  bool _loading = true;
  String? _user;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final u = await Auth.session();
    if (!mounted) return;
    setState(() {
      _user = u;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_user == null) {
      return LoginPage(onDone: _check);
    }
    return HomePage(user: _user!, onLogout: () async {
      await Auth.logout();
      await _check();
    });
  }
}

class LoginPage extends StatefulWidget {
  final VoidCallback onDone;
  const LoginPage({super.key, required this.onDone});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _hide = true;
  String? _error;
  late Future<String> _count;

  @override
  void initState() {
    super.initState();
    _count = _loadCount();
  }

  Future<String> _loadCount() async {
    final n = await Counter.get();
    if (n != null) return '👥 $n ${n == 1 ? 'persona registrada' : 'persones registrades'}';
    final l = await Auth.localCount();
    return l > 0 ? '👥 $l en aquest dispositiu' : '';
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = _register
        ? await Auth.register(_user.text, _pass.text)
        : await Auth.login(_user.text, _pass.text);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _busy = false;
        _error = err;
      });
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.menu_book_rounded, size: 64, color: cs.primary),
                  const SizedBox(height: 8),
                  Text('Apunts SMX',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(_register ? 'Crea el teu compte' : 'Inicia sessió',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _user,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Usuari',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pass,
                    obscureText: _hide,
                    onSubmitted: (_) => _busy ? null : _submit(),
                    decoration: InputDecoration(
                      labelText: 'Contrasenya',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _hide = !_hide),
                      ),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(_error!, style: TextStyle(color: cs.error)),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(_register ? 'Registrar-me' : 'Entrar'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _register = !_register;
                      _error = null;
                    }),
                    child: Text(_register
                        ? 'Ja tinc compte'
                        : "No tinc compte · crear-ne un"),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<String>(
                    future: _count,
                    builder: (_, snap) => Text(
                      snap.data ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Els comptes es guarden només en aquest dispositiu.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String user;
  final VoidCallback onLogout;
  const HomePage({super.key, required this.user, required this.onLogout});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _i,
        children: [
          const NotesTab(),
          const CalendarTab(),
          const QuizTab(),
          ProfileTab(user: widget.user, onLogout: widget.onLogout),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Apunts'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Calendari'),
          NavigationDestination(
              icon: Icon(Icons.quiz_outlined),
              selectedIcon: Icon(Icons.quiz),
              label: 'Tests'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil'),
        ],
      ),
    );
  }
}

class ProfileTab extends StatefulWidget {
  final String user;
  final VoidCallback onLogout;
  const ProfileTab({super.key, required this.user, required this.onLogout});
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _notif = false;
  String _count = '…';

  @override
  void initState() {
    super.initState();
    Notify.isEnabled().then((v) {
      if (mounted) setState(() => _notif = v);
    });
    _loadCount();
  }

  Future<void> _loadCount() async {
    final n = await Counter.get();
    if (!mounted) return;
    setState(() => _count = n != null ? '$n' : 'no disponible (sense connexió)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(widget.user),
            subtitle: const Text('Sessió iniciada'),
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Avisos d\'avaluables'),
            subtitle: const Text('El dia abans (9:00) i el mateix dia (8:00).'),
            value: _notif,
            onChanged: (v) async {
              final r = await Notify.setEnabled(v);
              if (!mounted) return;
              setState(() => _notif = r);
              if (v && !r) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                      'No s\'han pogut activar. Revisa el permís de notificacions del mòbil.'),
                ));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.groups_outlined),
            title: const Text('Persones registrades'),
            trailing: Text(_count),
            onTap: _loadCount,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Tancar sessió'),
            onTap: widget.onLogout,
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Chuleta SMX · versió 1.0.0',
                textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}
