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

  @override
  Widget build(BuildContext context) {
    // On écoute le provider pour réagir aux changements de date du Header
    final store = context.watch<UserProvider>();

    // Note : Pas de 'Expanded' ici, car il est déjà présent dans HomeScreen
    return Container(
      color: Colors.white,
      child: TableCalendar(
        locale: 'fr_FR',
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        
        // Synchronisation avec la date sélectionnée dans le Header
        focusedDay: store.selectedDate,
        calendarFormat: _calendarFormat,
        startingDayOfWeek: StartingDayOfWeek.monday,
        
        headerVisible: false, // Le Header personnalisé gère déjà l'affichage du mois
        daysOfWeekHeight: 25,
        rowHeight: 65, // Hauteur augmentée pour laisser de la place aux montants

        calendarStyle: const CalendarStyle(
          outsideDaysVisible: true,
          tablePadding: EdgeInsets.zero,
          todayDecoration: BoxDecoration(),
          selectedDecoration: BoxDecoration(),
        ),

        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) => _buildCell(day, store),
          todayBuilder: (context, day, focusedDay) => _buildCell(day, store, isToday: true),
          outsideBuilder: (context, day, focusedDay) => _buildCell(day, store, isOutside: true),
          // Style des noms de jours (L, M, M, J...)
          dowBuilder: (context, day) {
            final days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
            return Center(
              child: Text(
                days[day.weekday - 1],
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),

        onFormatChanged: (format) {
          setState(() => _calendarFormat = format);
        },
        
        // Quand on swipe le calendrier, on met à jour le mois dans le Header
        onPageChanged: (focusedDay) {
          store.updateSelectedDate(focusedDay);
        },
      ),
    );
  }

  Widget _buildCell(DateTime day, UserProvider store, {bool isToday = false, bool isOutside = false}) {
    // Clé formatée pour correspondre au mapping du provider (YYYY-MM-DD)
    final String dateKey = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
    final dayTransactions = store.groupedTransactions[dateKey] ?? [];

    double dayRev = 0;
    double dayDep = 0;

    for (var tx in dayTransactions) {
      if (tx.type == 'revenu') {
        dayRev += tx.amount;
      } else {
        dayDep += tx.amount;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: isOutside ? Colors.grey[50] : Colors.white,
        border: Border.all(color: Colors.grey[100]!, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Numéro du jour en haut à gauche
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              day.day.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? const Color(0xFF2D6A4F) : (isOutside ? Colors.grey : Colors.black87),
              ),
            ),
          ),
          const Spacer(),
          // Affichage compact des montants
          if (dayRev > 0) _amountLabel(dayRev, Colors.indigo),
          if (dayDep > 0) _amountLabel(dayDep, Colors.orange[800]!),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget _amountLabel(double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        amount.toInt().toString(),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}