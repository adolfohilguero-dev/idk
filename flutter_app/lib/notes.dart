import 'package:flutter/material.dart';
import 'data.dart';
import 'render.dart';

class NotesTab extends StatefulWidget {
  const NotesTab({super.key});
  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  final _ctl = TextEditingController();
  String _q = '';

  String? _snippet(int i, String q) {
    for (final p in Data.parts[i]) {
      final at = p.toLowerCase().indexOf(q);
      if (at >= 0) {
        final from = at - 30 < 0 ? 0 : at - 30;
        final to = at + 70 > p.length ? p.length : at + 70;
        return (from > 0 ? '…' : '') +
            p.substring(from, to).replaceAll('\n', ' ') +
            (to < p.length ? '…' : '');
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final rows = <Widget>[];
    for (var i = 0; i < Data.sections.length; i++) {
      final s = Data.sections[i] as Map;
      final title = s['title'] as String;
      String? sub;
      if (q.isNotEmpty) {
        if (!title.toLowerCase().contains(q)) {
          sub = _snippet(i, q);
          if (sub == null) continue;
        }
      }
      rows.add(ListTile(
        title: Text(title),
        subtitle: sub != null ? Text(sub, maxLines: 2) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SectionPage(section: s)),
        ),
      ));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Apunts SMX')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _ctl,
              decoration: InputDecoration(
                hintText: 'Cerca una etiqueta, propietat o concepte…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _q.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _ctl.clear();
                          setState(() => _q = '');
                        },
                      ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          Expanded(
            child: rows.isEmpty
                ? const Center(child: Text('Cap resultat.'))
                : ListView(children: rows),
          ),
        ],
      ),
    );
  }
}

class SectionPage extends StatefulWidget {
  final Map section;
  const SectionPage({super.key, required this.section});
  @override
  State<SectionPage> createState() => _SectionPageState();
}

class _SectionPageState extends State<SectionPage> {
  final Map<int, GlobalKey> _keys = {};

  @override
  Widget build(BuildContext context) {
    final blocks = widget.section['blocks'] as List;
    final heads = <int>[
      for (var i = 0; i < blocks.length; i++)
        if (blocks[i]['t'] == 'h3') i
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          (widget.section['title'] as String),
          style: const TextStyle(fontSize: 16),
          maxLines: 2,
        ),
        actions: [
          if (heads.isNotEmpty)
            PopupMenuButton<int>(
              icon: const Icon(Icons.list),
              tooltip: 'Índex',
              onSelected: (i) {
                final ctx = _keys[i]?.currentContext;
                if (ctx != null) {
                  Scrollable.ensureVisible(ctx,
                      duration: const Duration(milliseconds: 300),
                      alignment: 0.02);
                }
              },
              itemBuilder: (_) => [
                for (final i in heads)
                  PopupMenuItem<int>(
                    value: i,
                    child: Text(
                      spansText(blocks[i]['x'] as List),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < blocks.length; i++)
              renderBlock(
                context,
                blocks[i] as Map,
                key: blocks[i]['t'] == 'h3'
                    ? _keys.putIfAbsent(i, () => GlobalKey())
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}
