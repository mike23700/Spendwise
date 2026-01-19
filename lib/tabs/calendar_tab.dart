import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<UserProvider>();

    return Column(
      children: [
        TableCalendar(
          locale: 'fr_FR',
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          startingDayOfWeek: StartingDayOfWeek.sunday,
          headerVisible: false,
          daysOfWeekHeight: 30,
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: true,
            todayDecoration: BoxDecoration(),
            selectedDecoration: BoxDecoration(),
            tableBorder: TableBorder(
              horizontalInside: BorderSide(
                color: Color(0xFF2D6A4F),
                width: 0.5,
              ),
              verticalInside: BorderSide(color: Color(0xFF2D6A4F), width: 0.5),
            ),
          ),

          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              return _buildCellContent(day, store);
            },
            todayBuilder: (context, day, focusedDay) {
              return _buildCellContent(day, store, isToday: true);
            },
            outsideBuilder: (context, day, focusedDay) {
              return _buildCellContent(day, store, isOutside: true);
            },
          ),

          onFormatChanged: (format) {
            setState(() => _calendarFormat = format);
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
        ),
      ],
    );
  }

  Widget _buildCellContent(
    DateTime day,
    UserProvider store, {
    bool isToday = false,
    bool isOutside = false,
  }) {
    final String dateKey =
        "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
    final dayTransactions = store.groupedTransactions[dateKey] ?? [];

    double dayRev = 0;
    double dayDep = 0;

    for (var tx in dayTransactions) {
      double mnt = (tx['montant'] as num).toDouble();
      if (tx['type'] == 'revenu') {
        dayRev += mnt;
      } else {
        dayDep += mnt;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: isOutside ? Colors.grey[200] : Colors.white,
        border: Border.all(color: const Color(0xFF2D6A4F), width: 0.2),
      ),
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(2),
            child: Text(
              day.day.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isToday ? const Color(0xFF2D6A4F) : Colors.black,
              ),
            ),
          ),
          const Spacer(),
          if (dayRev > 0)
            Center(
              child: Text(
                dayRev.toInt().toString(),
                style: const TextStyle(color: Colors.indigo, fontSize: 8),
              ),
            ),
          if (dayDep > 0)
            Center(
              child: Text(
                dayDep.toInt().toString(),
                style: const TextStyle(color: Colors.redAccent, fontSize: 8),
              ),
            ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}
