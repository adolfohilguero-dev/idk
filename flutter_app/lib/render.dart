import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

List<InlineSpan> buildSpans(BuildContext ctx, List sp) {
  final cs = Theme.of(ctx).colorScheme;
  return sp.map<InlineSpan>((e) {
    final t = e[0] as String;
    final s = e[1] as int;
    final code = (s & 4) != 0;
    return TextSpan(
      text: t,
      style: TextStyle(
        fontWeight: (s & 1) != 0 ? FontWeight.bold : null,
        fontStyle: (s & 2) != 0 ? FontStyle.italic : null,
        fontFamily: code ? 'monospace' : null,
        fontSize: code ? 13 : null,
        backgroundColor: code ? cs.primary.withOpacity(0.12) : null,
      ),
    );
  }).toList();
}

Widget richText(BuildContext ctx, List sp, {TextStyle? style}) =>
    Text.rich(TextSpan(children: buildSpans(ctx, sp)), style: style);

Widget codeBlock(BuildContext ctx, String code) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFF0F172A),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Stack(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 12, 44, 12),
          child: SelectableText(
            code,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              height: 1.4,
              color: Color(0xFFE2E8F0),
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            tooltip: 'Copiar',
            icon: const Icon(Icons.copy, size: 18, color: Colors.white70),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                content: Text('Copiat'),
                duration: Duration(seconds: 1),
              ));
            },
          ),
        ),
      ],
    ),
  );
}

Widget tableBlock(BuildContext ctx, List rows) {
  final cs = Theme.of(ctx).colorScheme;
  final cols = rows.map<int>((r) => (r as List).length).reduce(max);
  final width = max(MediaQuery.of(ctx).size.width - 32, cols * 150.0);
  final trs = <TableRow>[];
  for (final r in rows) {
    final cells = r as List;
    final allHead = cells.isNotEmpty && cells.every((c) => c['h'] == true);
    final children = <Widget>[];
    for (var i = 0; i < cols; i++) {
      if (i < cells.length) {
        final c = cells[i];
        final head = c['h'] == true;
        children.add(Padding(
          padding: const EdgeInsets.all(8),
          child: Text.rich(
            TextSpan(children: buildSpans(ctx, c['x'] as List)),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: head ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ));
      } else {
        children.add(const SizedBox());
      }
    }
    trs.add(TableRow(
      decoration:
          allHead ? BoxDecoration(color: cs.primary.withOpacity(0.12)) : null,
      children: children,
    ));
  }
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: width,
        child: Table(
          border: TableBorder.all(color: cs.outlineVariant),
          children: trs,
        ),
      ),
    ),
  );
}

Widget renderBlock(BuildContext ctx, Map b, {Key? key}) {
  final cs = Theme.of(ctx).colorScheme;
  final tt = Theme.of(ctx).textTheme;
  switch (b['t'] as String) {
    case 'h3':
      return Padding(
        key: key,
        padding: const EdgeInsets.only(top: 22, bottom: 6),
        child: richText(ctx, b['x'] as List,
            style: tt.titleLarge?.copyWith(
                fontWeight: FontWeight.bold, color: cs.primary)),
      );
    case 'h4':
      return Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 4),
        child: richText(ctx, b['x'] as List,
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      );
    case 'p':
      final mini = b['mini'] == 1;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: richText(ctx, b['x'] as List,
            style: mini
                ? tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)
                : tt.bodyMedium),
      );
    case 'ctitle':
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: richText(ctx, b['x'] as List,
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
      );
    case 'list':
      final ordered = b['ord'] == true;
      final items = b['items'] as List;
      final ws = <Widget>[];
      var n = 0;
      for (final it in items) {
        final lvl = it['l'] as int;
        if (lvl == 0) n++;
        ws.add(Padding(
          padding: EdgeInsets.only(left: 8.0 + lvl * 18, top: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                child: Text(ordered && lvl == 0 ? '$n.' : '•'),
              ),
              Expanded(child: richText(ctx, it['x'] as List)),
            ],
          ),
        ));
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: ws),
      );
    case 'table':
      return tableBlock(ctx, b['rows'] as List);
    case 'code':
      return codeBlock(ctx, b['x'] as String);
    case 'grid':
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final x in b['c'] as List) renderBlock(ctx, x as Map)],
      );
    case 'card':
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final x in b['c'] as List) renderBlock(ctx, x as Map)],
        ),
      );
    case 'callout':
      final good = b['k'] == 'good';
      final color = good ? const Color(0xFF16A34A) : const Color(0xFFD97706);
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final x in b['c'] as List) renderBlock(ctx, x as Map)],
        ),
      );
    default:
      return const SizedBox.shrink();
  }
}
