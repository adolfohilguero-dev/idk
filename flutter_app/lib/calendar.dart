import 'package:flutter/material.dart';
import 'data.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});
  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  late DateTime _month;
  late DateTime _sel;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    final t = dateOnly(DateTime.now());
    _month = DateTime(t.year, t.month);
    _sel = t;
  }

  bool _pastExam(Ev e) => e.exam && e.e.isBefore(dateOnly(DateTime.now()));

  bool _match(Ev e) => (_filter == 'all' || e.m == _filter) && !_pastExam(e);

  List<Ev> _forDay(DateTime d) =>
      Data.events.where((e) => _match(e) && e.coversDay(d)).toList();

  void _shift(int n) =>
      setState(() => _month = DateTime(_month.year, _month.month + n));

  Widget _cell(DateTime day) {
    final cs = Theme.of(context).colorScheme;
    final list = _forDay(day);
    final isToday = sameDay(day, DateTime.now());
    final isSel = sameDay(day, _sel);
    final exam = list.any((e) => e.isExamOn(day));
    final mods = <String>{for (final e in list) e.m}.toList();
    Color? bg;
    if (exam) {
      bg = const Color(0xFFDC2626).withOpacity(0.15);
    } else if (isToday) {
      bg = cs.primary.withOpacity(0.12);
    }
    return InkWell(
      onTap: () => setState(() => _sel = day),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSel
                ? cs.primary
                : (exam ? const Color(0xFFDC2626) : Colors.transparent),
            width: isSel ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final m in mods.take(3))
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: kMods[m]?.color ?? Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _evTile(Ev e, {bool showWhen = false}) {
    final cs = Theme.of(context).colorScheme;
    final isExam = e.exam;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isExam ? const Color(0xFFDC2626).withOpacity(0.08) : null,
        border: Border(left: BorderSide(color: e.color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${kKinds[e.k] ?? e.k} · ${e.modName.split(' · ').first}',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(e.s, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (e.o.isNotEmpty)
            Text(e.o, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          if (showWhen)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                e.w
                    ? 'Setmana del ${e.d.day}/${e.d.month} · ${whenText(e.d)}'
                    : '${fmtDate(e.d)} · ${whenText(e.d)}',
                style: TextStyle(
                    fontSize: 12.5,
                    color: cs.primary,
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(_month.year, _month.month, 1);
    final offset = first.weekday - 1;
    final total = DateTime(_month.year, _month.month + 1, 0).day;
    final cells = <Widget>[
      for (var i = 0; i < offset; i++) const SizedBox(),
      for (var d = 1; d <= total; d++)
        _cell(DateTime(_month.year, _month.month, d)),
    ];
    final dayEvents = _forDay(_sel);
    final today = dateOnly(DateTime.now());
    final upcoming = Data.events
        .where((e) => _match(e) && e.exam && !e.e.isBefore(today))
        .take(8)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendari'),
        actions: [
          TextButton(
            onPressed: () => setState(() {
              _month = DateTime(today.year, today.month);
              _sel = today;
            }),
            child: const Text('Avui'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in const ['all', 'elec', 'so', 'ipo'])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(f == 'all'
                          ? 'Tots'
                          : kMods[f]!.name.split(' · ').first),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  onPressed: () => _shift(-1),
                  icon: const Icon(Icons.chevron_left)),
              Text(
                '${kMonths[_month.month - 1][0].toUpperCase()}${kMonths[_month.month - 1].substring(1)} ${_month.year}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                  onPressed: () => _shift(1),
                  icon: const Icon(Icons.chevron_right)),
            ],
          ),
          Row(
            children: [
              for (final w in const ['Dl', 'Dt', 'Dc', 'Dj', 'Dv', 'Ds', 'Dg'])
                Expanded(
                  child: Center(
                    child: Text(w,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.95,
            children: cells,
          ),
          const SizedBox(height: 12),
          Text(fmtDate(_sel), style: Theme.of(context).textTheme.titleMedium),
          if (dayEvents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Cap activitat aquest dia.'),
            )
          else
            for (final e in dayEvents) _evTile(e),
          const Divider(height: 28),
          Text('🧪 Pròxims avaluables',
              style: Theme.of(context).textTheme.titleMedium),
          if (upcoming.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No hi ha avaluables pendents.'),
            )
          else
            for (final e in upcoming) _evTile(e, showWhen: true),
        ],
      ),
    );
  }
}
