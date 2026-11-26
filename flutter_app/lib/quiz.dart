import 'dart:math';
import 'package:flutter/material.dart';
import 'data.dart';

const _topics = <List<String>>[
  ['html', 'HTML'],
  ['css', 'CSS'],
  ['redes', 'Xarxes'],
  ['sost', 'Sostenibilitat'],
  ['so', 'Virtualització'],
  ['ipo', 'IPO'],
];

class QuizTab extends StatelessWidget {
  const QuizTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🧠 Mini tests')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Tria un tema: 5 preguntes aleatòries cada vegada.'),
          const SizedBox(height: 12),
          for (final t in _topics)
            Card(
              child: ListTile(
                title: Text(t[1]),
                trailing: const Icon(Icons.play_arrow),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => QuizPage(topic: t[0], title: t[1])),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class QuizPage extends StatefulWidget {
  final String topic;
  final String title;
  const QuizPage({super.key, required this.topic, required this.title});
  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late List<Map> _qs;
  int _i = 0;
  int _ok = 0;
  int? _picked;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    final all = Data.quiz
        .where((x) => x['tema'] == widget.topic)
        .map<Map>((x) => x as Map)
        .toList()
      ..shuffle(Random());
    _qs = all.take(5).toList();
    _i = 0;
    _ok = 0;
    _picked = null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget body;
    if (_qs.isEmpty) {
      body = const Center(child: Text('Encara no hi ha preguntes d\'aquest tema.'));
    } else if (_i >= _qs.length) {
      final msg = _ok == _qs.length
          ? '🎉 Perfecte!'
          : (_ok >= 3 ? '👍 Gairebé, repassa el que has fallat.' : '📖 Repassa els apunts i torna-ho a provar.');
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$_ok / ${_qs.length}',
                style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 8),
            Text(msg),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => setState(_start),
              child: const Text('Tornar a jugar'),
            ),
          ],
        ),
      );
    } else {
      final q = _qs[_i];
      final opts = (q['o'] as List).cast<String>();
      final answer = q['a'] as int;
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${_i + 1}/${_qs.length}',
              style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text(q['q'] as String,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          for (var k = 0; k < opts.length; k++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.all(14),
                  backgroundColor: _picked == null
                      ? null
                      : (k == answer
                          ? const Color(0xFF16A34A).withOpacity(0.18)
                          : (k == _picked
                              ? const Color(0xFFDC2626).withOpacity(0.18)
                              : null)),
                ),
                onPressed: _picked != null
                    ? null
                    : () => setState(() {
                          _picked = k;
                          if (k == answer) _ok++;
                        }),
                child: Text(opts[k]),
              ),
            ),
          if (_picked != null) ...[
            const SizedBox(height: 10),
            Text('${_picked == answer ? '✅' : '❌'} ${q['e']}'),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => setState(() {
                  _i++;
                  _picked = null;
                }),
                child: Text(_i + 1 < _qs.length ? 'Següent →' : 'Veure resultat'),
              ),
            ),
          ],
        ],
      );
    }
    return Scaffold(appBar: AppBar(title: Text(widget.title)), body: body);
  }
}
