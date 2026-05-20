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
  final String jobName;       // ★ 変更：直接テキストでバイト名を持つ
  final int weekdayWage;      // ★ 追加：そのシフトの平日時給
  final int holidayWage;      // ★ 追加：そのシフトの休日時給
  final int startHour;
  final int endHour;
  final int breakMinutes;

  Shift({
    required this.date,
    required this.jobName,
    required this.weekdayWage,
    required this.holidayWage,
    required this.startHour,
    required this.endHour,
    required this.breakMinutes,
  });

  int get workMinutes =>
      ((endHour - startHour) * 60) - breakMinutes;

  // ★ 変更：入力されたその日の時給（平日/休日）を判定して計算
  int get salary {
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
      title: 'ShiftCalc',
      debugShowCheckedModeBanner: false, // デバッグ帯を非表示にする
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
/// メイン画面（画面切り替えと状態の管理）
/// ------------------------------
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int index = 0;
  
  // ★ 追加：カレンダーでタップされた日付を保存する変数（初期値は今日）
  DateTime selectedDateFromCalendar = DateTime.now();

  // サンプル用の初期マスターデータ（一覧表示用）
  final List<Job> jobs = [
    Job(name: 'コンビニA', weekdayWage: 1100, holidayWage: 1200),
    Job(name: '居酒屋B', weekdayWage: 1200, holidayWage: 1400),
  ];

  final List<Shift> shifts = [];

  // ★ 追加：カレンダーから日付を受け取ってシフト入力画面へ切り替える関数
  void jumpToShiftInput(DateTime date) {
    setState(() {
      selectedDateFromCalendar = date;
      index = 2; // シフト入力画面（インデックス2）へ切り替え
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(shifts),
      CalendarScreen(shifts, onSelectDate: jumpToShiftInput), // ★ 変更：関数を渡す
      ShiftInputScreen(
        jobs, 
        shifts, 
        selectedDateFromCalendar, // ★ 変更：選択された日付を渡す
        () {
          setState(() {
            index = 1; // 保存したらカレンダー画面に自動で戻る
          });
        },
      ),
      JobListScreen(jobs),
    ];

    return Scaffold(
      body: screens[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) {
          setState(() {
            index = i;
            // 下のタブから直接「シフト」を押したときは、日付を「今日」にする
            if (i == 2) {
              selectedDateFromCalendar = DateTime.now();
            }
          });
        },
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
/// カレンダー（タップで入力画面へ・長押しで詳細表示）
/// ------------------------------
class CalendarScreen extends StatelessWidget {
  final List<Shift> shifts;
  final Function(DateTime) onSelectDate; // ★ 追加：日付選択時のイベント

  const CalendarScreen(this.shifts, {required this.onSelectDate, super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('カレンダー')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
        itemCount: 31,
        itemBuilder: (context, index) {
          final day = index + 1;
          final targetDate = DateTime(now.year, now.month, day); // このマスの日付

          final dayShifts =
              shifts.where((s) => s.date.day == day && s.date.month == now.month).toList();

          return GestureDetector(
            onTap: () {
              // ★ 変更：タップしたらその日の日付をセットして入力画面にジャンプ
              onSelectDate(targetDate);
            },
            onLongPress: () {
              // ★ 変更：今までの詳細ポップアップは長押しで表示
              if (dayShifts.isEmpty) return;
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text('$day日のシフト詳細'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: dayShifts
                        .map((s) => Text('${s.jobName} ¥${s.salary}')) // ★ s.jobName に変更
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
              child: Stack(
                children: [
                  Center(child: Text('$day')),
                  // シフトがある日は右上にインジケーター（青い丸）を表示
                  if (dayShifts.isNotEmpty)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.indigo,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ------------------------------
/// シフト入力（完全入力タイプに変更）
/// ------------------------------
class ShiftInputScreen extends StatefulWidget {
  final List<Job> jobs;
  final List<Shift> shifts;
  final DateTime initialDate; // ★ 追加：カレンダーから渡された日付
  final VoidCallback onSave;

  const ShiftInputScreen(this.jobs, this.shifts, this.initialDate, this.onSave, {super.key});

  @override
  State<ShiftInputScreen> createState() => _ShiftInputScreenState();
}

class _ShiftInputScreenState extends State<ShiftInputScreen> {
  // ★ 変更：ドロップダウンを廃止し、すべての入力欄をテキストコントローラーにする
  final nameController = TextEditingController();
  final weekdayWageController = TextEditingController();
  final holidayWageController = TextEditingController();
  final start = TextEditingController();
  final end = TextEditingController();
  final rest = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final dateStr = '${widget.initialDate.month}月${widget.initialDate.day}日';

    return Scaffold(
      appBar: AppBar(title: const Text('シフト入力')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // どの日付を編集しているか分かりやすくするヘッダー
              Card(
                color: Colors.indigo.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.indigo),
                      const SizedBox(width: 12),
                      Text(
                        '対象日: $dateStr のシフトを追加',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // ★ 変更：自由に名前を打ち込めるテキストフィールド
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'アルバイト名',
                  hintText: '例: コンビニA、マクドナルド',
                ),
              ),
              
              // ★ 追加：平日時給入力
              TextField(
                controller: weekdayWageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '平日時給（円）'),
              ),
              
              // ★ 追加：休日時給入力
              TextField(
                controller: holidayWageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '休日時給（円）'),
              ),
              
              TextField(
                  controller: start,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '出勤時間（時） 例: 9')),
              TextField(
                  controller: end,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '退勤時間（時） 例: 17')),
              TextField(
                  controller: rest,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '休憩時間（分） 例: 60')),
              const SizedBox(height: 20),
              
              ElevatedButton(
                onPressed: () {
                  // すべての入力項目が埋まっているかチェック（バリデーション）
                  if (nameController.text.isEmpty ||
                      weekdayWageController.text.isEmpty ||
                      holidayWageController.text.isEmpty ||
                      start.text.isEmpty ||
                      end.text.isEmpty ||
                      rest.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('すべての項目を入力してください')),
                    );
                    return;
                  }

                  // シフト配列にデータを新規追加
                  widget.shifts.add(
                    Shift(
                      date: widget.initialDate,
                      jobName: nameController.text,
                      weekdayWage: int.parse(weekdayWageController.text),
                      holidayWage: int.parse(holidayWageController.text),
                      startHour: int.parse(start.text),
                      endHour: int.parse(end.text),
                      breakMinutes: int.parse(rest.text),
                    ),
                  );
                  
                  // 保存成功後の後処理（入力欄のクリアと画面戻り）
                  nameController.clear();
                  weekdayWageController.clear();
                  holidayWageController.clear();
                  start.clear();
                  end.clear();
                  rest.clear();
                  
                  widget.onSave();
                },
                child: const Text('保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ------------------------------
/// バイト先一覧（参考用マスターデータ）
/// ------------------------------
class JobListScreen extends StatelessWidget {
  final List<Job> jobs;
  const JobListScreen(this.jobs, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('バイト先一覧（既定）')),
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