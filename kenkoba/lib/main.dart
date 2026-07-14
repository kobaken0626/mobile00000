import 'package:flutter/material.dart';
import 'home.dart';
import 'calendar.dart';
import 'account.dart';
import 'detail/calendarDetail.dart';
import 'shiftStorageService.dart'; // ← 追加

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

  // --- Map変換ロジック（用意されていない場合はこちらを参考にしてください） ---
  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'jobName': jobName,
      'weekdayWage': weekdayWage,
      'holidayWage': holidayWage,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'breakMinutes': breakMinutes,
      'isCheckedOut': isCheckedOut,
      'isPaidHoliday': isPaidHoliday,
    };
  }

  factory Shift.fromMap(Map<String, dynamic> map) {
    return Shift(
      date: DateTime.parse(map['date']),
      jobName: map['jobName'],
      weekdayWage: map['weekdayWage'],
      holidayWage: map['holidayWage'],
      startHour: map['startHour'],
      startMinute: map['startMinute'],
      endHour: map['endHour'],
      endMinute: map['endMinute'],
      breakMinutes: map['breakMinutes'],
      isCheckedOut: map['isCheckedOut'] ?? false,
      isPaidHoliday: map['isPaidHoliday'] ?? false,
    );
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

  List<Shift> shifts = []; // lateではなく空リストで初期化

  @override
  void initState() {
    super.initState();
    _loadShiftsData(); // 起動時にデータを読み込む
  }

  // --- データの読み込み処理 ---
  Future<void> _loadShiftsData() async {
    try {
      final savedData = await ShiftStorageService.loadShifts();
      if (savedData.isNotEmpty) {
        setState(() {
          shifts = savedData.map((map) => Shift.fromMap(map)).toList();
        });
      }
    } catch (e) {
      debugPrint("データ読み込みエラー: $e");
    }
  }

  // --- データの保存処理 ---
  Future<void> _saveShiftsData() async {
    try {
      final mapList = shifts.map((shift) => shift.toMap()).toList();
      await ShiftStorageService.saveShifts(mapList);
    } catch (e) {
      debugPrint("データ保存エラー: $e");
    }
  }

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

  void addQuickCheckOutShift() async {
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
      // 本日のシフトを削除して、新しく退勤済みのシフトを追加（再生成）
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

    // データをローカルに保存
    await _saveShiftsData();

    final displayMinute = endMinute.toString().padLeft(2, '0');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('お疲れ様でした！退勤を記録しました。 ($startHour:${startMinute.toString().padLeft(2, '0')} 〜 $endHour:$displayMinute)'),
        backgroundColor: const Color(0xFF689F38),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void deleteShift(DateTime targetDate) async {
    setState(() {
      shifts.removeWhere((s) =>
          s.date.day == targetDate.day &&
          s.date.month == targetDate.month &&
          s.date.year == targetDate.year);
    });
    await _saveShiftsData(); // 削除時も保存
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
              onSave: () async {
                setState(() {}); 
                await _saveShiftsData(); // ダイアログでの追加・編集時も保存
                if (context.mounted) Navigator.pop(context); 
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