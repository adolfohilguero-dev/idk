import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class ModInfo {
  final String name;
  final Color color;
  const ModInfo(this.name, this.color);
}

const Map<String, ModInfo> kMods = {
  'elec': ModInfo('Electricitat · M1 BA1', Color(0xFF2563EB)),
  'so': ModInfo('Sistemes Operatius · M2 RA1', Color(0xFF059669)),
  'ipo': ModInfo('IPO · M1709', Color(0xFFD97706)),
};

const Map<String, String> kKinds = {
  't': '📖 Teoria',
  'a': '📝 Pràctica',
  'e': '🧪 Avaluable',
};

const List<String> kMonths = [
  'gener', 'febrer', 'març', 'abril', 'maig', 'juny',
  'juliol', 'agost', 'setembre', 'octubre', 'novembre', 'desembre'
];
const List<String> kWeekdays = [
  'Dilluns', 'Dimarts', 'Dimecres', 'Dijous', 'Divendres', 'Dissabte', 'Diumenge'
];

DateTime dateOnly(DateTime x) => DateTime(x.year, x.month, x.day);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

int daysBetween(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day)
        .difference(DateTime.utc(a.year, a.month, a.day))
        .inDays;

DateTime parseIso(String s) {
  final p = s.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

String fmtDate(DateTime d) {
  final m = kMonths[d.month - 1];
  final de = 'aeiou'.contains(m[0]) ? "d'" : 'de ';
  return '${kWeekdays[d.weekday - 1]} ${d.day} $de$m';
}

String whenText(DateTime d) {
  final n = daysBetween(dateOnly(DateTime.now()), d);
  if (n < 0) return 'fa ${-n} dies';
  if (n == 0) return 'avui';
  if (n == 1) return 'demà';
  return "d'aquí a $n dies";
}

class Ev {
  final DateTime d;
  final DateTime e;
  final bool w;
  final String m, k, s, o;

  Ev({
    required this.d,
    required this.e,
    required this.w,
    required this.m,
    required this.k,
    required this.s,
    required this.o,
  });

  bool get exam => k == 'e';

  bool coversDay(DateTime x) {
    final v = dateOnly(x);
    return !v.isBefore(d) && !v.isAfter(e);
  }

  /// Las semanas evaluables solo se marcan como examen el primer día.
  bool isExamOn(DateTime x) => exam && (!w || sameDay(x, d));

  Color get color => kMods[m]?.color ?? Colors.grey;
  String get modName => kMods[m]?.name ?? m;
}

String spansText(List sp) => sp.map((e) => e[0] as String).join();

void collectText(List blocks, List<String> out) {
  for (final b in blocks) {
    final t = b['t'];
    if (t == 'p' || t == 'h3' || t == 'h4' || t == 'ctitle') {
      out.add(spansText(b['x'] as List));
    } else if (t == 'code') {
      out.add(b['x'] as String);
    } else if (t == 'list') {
      for (final it in b['items'] as List) {
        out.add(spansText(it['x'] as List));
      }
    } else if (t == 'table') {
      for (final r in b['rows'] as List) {
        for (final c in r as List) {
          out.add(spansText(c['x'] as List));
        }
      }
    } else if (b['c'] != null) {
      collectText(b['c'] as List, out);
    }
  }
}

class Data {
  static late List<dynamic> sections;
  static late List<dynamic> quiz;
  static late List<Ev> events;
  static late List<List<String>> parts;

  static Future<void> load() async {
    sections = jsonDecode(await rootBundle.loadString('assets/content.json'));
    quiz = jsonDecode(await rootBundle.loadString('assets/quiz.json'));
    final raw = jsonDecode(await rootBundle.loadString('assets/events.json'))
        as List;
    events = raw.map<Ev>((x) {
      final d = parseIso(x['d'] as String);
      final w = x['w'] == true;
      return Ev(
        d: d,
        e: DateTime(d.year, d.month, d.day + (w ? 4 : 0)),
        w: w,
        m: x['m'] as String,
        k: x['k'] as String,
        s: x['s'] as String,
        o: (x['o'] ?? '') as String,
      );
    }).toList()
      ..sort((a, b) => a.d.compareTo(b.d));
    parts = sections.map<List<String>>((s) {
      final out = <String>[];
      collectText(s['blocks'] as List, out);
      return out;
    }).toList();
  }
}
