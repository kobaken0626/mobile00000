import 'package:flutter/material.dart';
import 'home.dart';
import 'calendar.dart';
import 'account.dart';
import 'detail/calendarDetail.dart';

void main() {
  runApp(const MyApp());
}

/// ------------------------------
/// データモデル
/// ------------------------------
class Job {
  String name;
  int weekdayWage;
  int holidayWage;
  int payDay;       
  int closingDay;   

  Job({
    required this.name,
    required this.weekdayWage,
    required this.holidayWage,
    required this.payDay,
    required this.closingDay,
  });
}

class Shift {
  final DateTime date;
  final String jobName;       
  final int weekdayWage;      
  final int holidayWage;      
  final int startHour;
  final int startMinute; 
  final int endHour;
  final int endMinute;   
  final int breakMinutes;
  final bool isCheckedOut; 
  final bool isPaidHoliday; 

  Shift({
    required this.date,
    required this.jobName,
    required this.weekdayWage,
    required this.holidayWage,
    required this.startHour,
    this.startMinute = 0,
    required this.endHour,
    this.endMinute = 0,
    required this.breakMinutes,
    this.isCheckedOut = false,
    this.isPaidHoliday = false, 
  });

  int get workMinutes {
    final startTotal = (startHour * 60) + startMinute;
    final endTotal = (endHour * 60) + endMinute;
    return (endTotal - startTotal) - breakMinutes;
  }

  int get salary {
    if (isPaidHoliday) return 0; 
    final isHoliday =
        date.weekday == DateTime.saturday ||
        date.weekday == DateTime.sunday;
    final hourlyWage = isHoliday ? holidayWage : weekdayWage;
    return (workMinutes / 60 * hourlyWage).round();
  }
}

/// ------------------------------
/// アプリ全体の共通設定
/// ------------------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShiftCalc PC',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF689F38), 
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFF689F38),
          unselectedItemColor: Colors.black54,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

/// ------------------------------
/// メイン画面
/// ------------------------------
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int index = 0; 
  DateTime selectedCalendarDate = DateTime.now();
  DateTime currentMonthView = DateTime.now(); 

  final List<Job> jobs = [
    Job(name: 'コンビニA', weekdayWage: 1100, holidayWage: 1200, payDay: 25, closingDay: 31),
    Job(name: '居酒屋B', weekdayWage: 1200, holidayWage: 1400, payDay: 15, closingDay: 30),
  ];

  final List<Shift> shifts = [];

  bool hasTodayShiftScheduled() {
    final today = DateTime.now();
    return shifts.any((s) => s.date.day == today.day && s.date.month == today.month && s.date.year == today.year);
  }

  bool isTodayAlreadyCheckedOut() {
    final today = DateTime.now();
    final todayShifts = shifts.where((s) => s.date.day == today.day && s.date.month == today.month && s.date.year == today.year).toList();
    if (todayShifts.isEmpty) return false;
    return todayShifts.first.isCheckedOut;
  }

  void addQuickCheckOutShift() {
    if (jobs.isEmpty) return;
    final today = DateTime.now();
    if (!hasTodayShiftScheduled()) return;
    if (isTodayAlreadyCheckedOut()) return;

    final existingShift = shifts.firstWhere((s) => s.date.day == today.day && s.date.month == today.month && s.date.year == today.year);

    final startHour = existingShift.startHour;       
    final startMinute = existingShift.startMinute;
    final endHour = today.hour;     
    final endMinute = today.minute; 
    final breakMin = existingShift.breakMinutes;          

    final startTotal = (startHour * 60) + startMinute;
    final endTotal = (endHour * 60) + endMinute;
    if ((endTotal - startTotal) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('出勤時間を過ぎてから退勤を押してください')),
      );
      return;
    }

    setState(() {
      shifts.removeWhere((s) => s.date.day == today.day && s.date.month == today.month && s.date.year == today.year);
      shifts.add(
        Shift(
          date: today,
          jobName: existingShift.jobName,
          weekdayWage: existingShift.weekdayWage,
          holidayWage: existingShift.holidayWage,
          startHour: startHour,
          startMinute: startMinute,
          endHour: endHour,
          endMinute: endMinute, 
          breakMinutes: breakMin, 
          isCheckedOut: true, 
          isPaidHoliday: false,
        ),
      );
    });

    final displayMinute = endMinute.toString().padLeft(2, '0');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('退勤を完了しました！ ($startHour:${startMinute.toString().padLeft(2, '0')} 〜 $endHour:$displayMinute)')),
    );
  }

  void deleteShift(DateTime targetDate) {
    setState(() {
      shifts.removeWhere((s) =>
          s.date.day == targetDate.day &&
          s.date.month == targetDate.month &&
          s.date.year == targetDate.year);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('勤務情報を削除しました')),
    );
  }

  void showShiftInputDialog(DateTime targetDate) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 500, 
            padding: const EdgeInsets.all(24),
            child: ShiftInputSheet(
              jobs: jobs,
              shifts: shifts,
              initialDate: targetDate,
              onSave: () {
                setState(() {}); 
                Navigator.pop(context); 
              },
            ),
          ),
        );
      },
    );
  }

  void changeMonth(int offset) {
    setState(() {
      currentMonthView = DateTime(currentMonthView.year, currentMonthView.month + offset, 1);
      selectedCalendarDate = DateTime(currentMonthView.year, currentMonthView.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        shifts: shifts, 
        isButtonEnabled: hasTodayShiftScheduled() && !isTodayAlreadyCheckedOut(), 
        isAlreadyCheckedOut: isTodayAlreadyCheckedOut(), 
        onQuickCheckOut: addQuickCheckOutShift,
      ),
      CalendarScreen(
        shifts: shifts,
        selectedDate: selectedCalendarDate,
        currentMonth: currentMonthView, 
        onMonthChange: changeMonth,     
        onDateSelected: (date) {
          setState(() {
            selectedCalendarDate = date; 
          });
        },
        onEditPressed: () => showShiftInputDialog(selectedCalendarDate), 
        onDeletePressed: deleteShift, 
      ),
      AccountScreen(
        jobs: jobs, 
        shifts: shifts,
        onJobsChanged: () {
          setState(() {}); 
        },
      ),
    ];

    return Scaffold(
      body: screens[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          setState(() {
            index = i;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'カレンダー'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'アカウント'),
        ],
      ),
    );
  }
}