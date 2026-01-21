import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

/// ------------------------------
/// データモデル
/// ------------------------------
class Job {
  final String name;
  final int weekdayWage;
  final int holidayWage;

  Job({
    required this.name,
    required this.weekdayWage,
    required this.holidayWage,
  });

  int wageForDate(DateTime date) {
    final isHoliday =
        date.weekday == DateTime.saturday ||
        date.weekday == DateTime.sunday;
    return isHoliday ? holidayWage : weekdayWage;
  }
}

class Shift {
  final DateTime date;
  final Job job;
  final int startHour;
  final int endHour;
  final int breakMinutes;

  Shift({
    required this.date,
    required this.job,
    required this.startHour,
    required this.endHour,
    required this.breakMinutes,
  });

  int get workMinutes =>
      ((endHour - startHour) * 60) - breakMinutes;

  int get salary =>
      (workMinutes / 60 * job.wageForDate(date)).round();
}

/// ------------------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShiftCalc',
      theme: ThemeData(
        useMaterial3: true,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Colors.black,
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

  final List<Job> jobs = [
    Job(name: 'コンビニA', weekdayWage: 1100, holidayWage: 1200),
    Job(name: '居酒屋B', weekdayWage: 1200, holidayWage: 1400),
  ];

  final List<Shift> shifts = [];

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(shifts),
      CalendarScreen(shifts),
      ShiftInputScreen(jobs, shifts, () => setState(() {})),
      JobListScreen(jobs),
    ];

    return Scaffold(
      body: screens[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'カレンダー'),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'シフト'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'バイト先'),
        ],
      ),
    );
  }
}

/// ------------------------------
/// ホーム画面
/// ------------------------------
class HomeScreen extends StatelessWidget {
  final List<Shift> shifts;
  const HomeScreen(this.shifts, {super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthShifts =
        shifts.where((s) => s.date.month == now.month).toList();

    final earned = monthShifts.fold(0, (sum, s) => sum + s.salary);

    return Scaffold(
      appBar: AppBar(title: const Text('ShiftCalc')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('今月のシフト日数：${monthShifts.length}日',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Text('今月の給料：¥$earned',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------
/// カレンダー
/// ------------------------------
class CalendarScreen extends StatelessWidget {
  final List<Shift> shifts;
  const CalendarScreen(this.shifts, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('カレンダー')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
        itemCount: 31,
        itemBuilder: (context, index) {
          final day = index + 1;
          final dayShifts =
              shifts.where((s) => s.date.day == day).toList();

          return GestureDetector(
            onTap: dayShifts.isEmpty
                ? null
                : () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text('$day日のシフト'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: dayShifts
                              .map((s) => Text(
                                  '${s.job.name} ¥${s.salary}'))
                              .toList(),
                        ),
                      ),
                    );
                  },
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: dayShifts.isNotEmpty
                    ? Colors.indigo.shade100
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(child: Text('$day')),
            ),
          );
        },
      ),
    );
  }
}

/// ------------------------------
/// シフト入力
/// ------------------------------
class ShiftInputScreen extends StatefulWidget {
  final List<Job> jobs;
  final List<Shift> shifts;
  final VoidCallback onSave;

  const ShiftInputScreen(this.jobs, this.shifts, this.onSave, {super.key});

  @override
  State<ShiftInputScreen> createState() => _ShiftInputScreenState();
}

class _ShiftInputScreenState extends State<ShiftInputScreen> {
  Job? selectedJob;
  final start = TextEditingController();
  final end = TextEditingController();
  final rest = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('シフト入力')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<Job>(
              decoration: const InputDecoration(labelText: 'バイト先'),
              items: widget.jobs
                  .map((j) =>
                      DropdownMenuItem(value: j, child: Text(j.name)))
                  .toList(),
              onChanged: (v) => selectedJob = v,
            ),
            TextField(
                controller: start,
                decoration: const InputDecoration(labelText: '出勤時間（時）')),
            TextField(
                controller: end,
                decoration: const InputDecoration(labelText: '退勤時間（時）')),
            TextField(
                controller: rest,
                decoration: const InputDecoration(labelText: '休憩（分）')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (selectedJob == null) return;

                widget.shifts.add(
                  Shift(
                    date: DateTime.now(),
                    job: selectedJob!,
                    startHour: int.parse(start.text),
                    endHour: int.parse(end.text),
                    breakMinutes: int.parse(rest.text),
                  ),
                );
                widget.onSave();
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------
/// バイト先一覧
/// ------------------------------
class JobListScreen extends StatelessWidget {
  final List<Job> jobs;
  const JobListScreen(this.jobs, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('バイト先一覧')),
      body: ListView(
        children: jobs
            .map(
              (j) => ListTile(
                title: Text(j.name),
                subtitle:
                    Text('平日 ¥${j.weekdayWage} / 休日 ¥${j.holidayWage}'),
              ),
            )
            .toList(),
      ),
    );
  }
}
