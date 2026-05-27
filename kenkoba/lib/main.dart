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
}

class Shift {
  final DateTime date;
  final String jobName;       
  final int weekdayWage;      
  final int holidayWage;      
  final int startHour;
  final int endHour;
  final int breakMinutes;
  final bool isCheckedOut; 

  Shift({
    required this.date,
    required this.jobName,
    required this.weekdayWage,
    required this.holidayWage,
    required this.startHour,
    required this.endHour,
    required this.breakMinutes,
    this.isCheckedOut = false,
  });

  int get workMinutes =>
      ((endHour - startHour) * 60) - breakMinutes;

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
  int index = 1; 
  DateTime selectedCalendarDate = DateTime.now();

  final List<Job> jobs = [
    Job(name: 'コンビニA', weekdayWage: 1100, holidayWage: 1200),
    Job(name: '居酒屋B', weekdayWage: 1200, holidayWage: 1400),
  ];

  final List<Shift> shifts = [];

  void addQuickCheckOutShift() {
    if (jobs.isEmpty) return;
    
    final today = DateTime.now();
    final defaultJob = jobs.first;

    const startHour = 10;       
    final endHour = today.hour;  
    final endMinutes = today.minute; 
    const breakMin = 0;          

    final realWorkMinutes = ((endHour - startHour) * 60) + endMinutes - breakMin;

    if (realWorkMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('出勤時間（10:00）を過ぎてから退勤を押してください')),
      );
      return;
    }

    setState(() {
      shifts.removeWhere((s) => s.date.day == today.day && s.date.month == today.month && s.date.year == today.year);

      shifts.add(
        Shift(
          date: today,
          jobName: defaultJob.name,
          weekdayWage: defaultJob.weekdayWage,
          holidayWage: defaultJob.holidayWage,
          startHour: startHour,
          endHour: endHour,
          breakMinutes: breakMin - endMinutes, 
          isCheckedOut: true, 
        ),
      );
    });

    final displayMinute = endMinutes.toString().padLeft(2, '0');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('退勤を完了しました！ ($startHour:00 〜 $endHour:$displayMinute)')),
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

  @override
  Widget build(BuildContext context) {
    // ★ 修正ポイント：ここにあった不要な「const」を徹底的に排除しました
    final screens = [
      HomeScreen(shifts: shifts, onQuickCheckOut: addQuickCheckOutShift),
      CalendarScreen(
        shifts: shifts,
        selectedDate: selectedCalendarDate,
        onDateSelected: (date) {
          setState(() {
            selectedCalendarDate = date; 
          });
        },
        onEditPressed: () => showShiftInputDialog(selectedCalendarDate), 
      ),
      AccountScreen(jobs: jobs, shifts: shifts),
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

/// ------------------------------
/// ホーム画面
/// ------------------------------
class HomeScreen extends StatelessWidget {
  final List<Shift> shifts;
  final VoidCallback onQuickCheckOut;

  const HomeScreen({required this.shifts, required this.onQuickCheckOut, super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthShifts =
        shifts.where((s) => s.date.month == now.month && s.date.year == now.year).toList();

    final earned = monthShifts.fold(0, (sum, s) => sum + s.salary);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ShiftCalc', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF689F38),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600), 
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('今月のシフト日数：${monthShifts.length}日', style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 16),
                      Text('今月の給料：¥$earned', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF689F38))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text('ワンタップ記録', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: onQuickCheckOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                icon: const Icon(Icons.logout, size: 24),
                label: const Text('今すぐ退勤を記録 (10:00〜現在)'),
              ),
              const SizedBox(height: 12),
              const Text(
                '※既存のデータがある場合は上書き修正され、「退勤済み」になります。',
                style: TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              )
            ],
          ),
        ),
      ),
    );
  }
}

/// ------------------------------
/// カレンダー画面（左右2カラム分割レイアウト）
/// ------------------------------
class CalendarScreen extends StatelessWidget {
  final List<Shift> shifts;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onEditPressed; 

  const CalendarScreen({
    required this.shifts,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onEditPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final dayShifts = shifts.where((s) =>
        s.date.day == selectedDate.day &&
        s.date.month == selectedDate.month &&
        s.date.year == selectedDate.year).toList();
    final currentShift = dayShifts.isNotEmpty ? dayShifts.first : null;

    final weekDays = ['日', '月', '火', '水', '木', '金', '土'];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.calendar_month, color: Colors.white),
            const SizedBox(width: 12),
            Text('${now.year}年 ${now.month}月', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: const Color(0xFF689F38),
        elevation: 2,
      ),
      body: Row( 
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // 【左カラム：コンパクトなカレンダー構造】
          Container(
            width: 450, 
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
              ),
            ),
            padding: const EdgeInsets.only(top: 16, left: 8, right: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: weekDays.map((day) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: day == '日' ? Colors.red : (day == '土' ? Colors.blue : Colors.black54),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1.2, 
                  ),
                  itemCount: 31,
                  itemBuilder: (context, index) {
                    final day = index + 1;
                    final targetDate = DateTime(now.year, now.month, day);
                    final isSelected = selectedDate.day == day;

                    final hasShift = shifts.any((s) =>
                        s.date.day == day && s.date.month == now.month && s.date.year == now.year);

                    return GestureDetector(
                      onTap: () => onDateSelected(targetDate),
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFC8E6C9) 
                              : (hasShift ? Colors.grey.shade50 : Colors.white),
                          borderRadius: BorderRadius.circular(4),
                          border: isSelected ? Border.all(color: const Color(0xFF689F38), width: 1.5) : null,
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isSelected ? const Color(0xFF2E7D32) : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (hasShift)
                              Positioned(
                                bottom: 6,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    width: 5, height: 5,
                                    decoration: const BoxDecoration(color: Color(0xFF689F38), shape: BoxShape.circle),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // 【右カラム：選択日の勤務詳細タイムライン風】
          Expanded(
            child: Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${selectedDate.year}年 ${selectedDate.month}月${selectedDate.day}日 勤務詳細',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  
                  Expanded(
                    child: currentShift == null
                        ? const Center(
                            child: Text('この日の予定・勤務情報はありません', style: TextStyle(color: Colors.black45, fontSize: 15)),
                          )
                        : ListView(
                            children: [
                              Card(
                                elevation: 1,
                                color: Colors.white,
                                margin: EdgeInsets.zero,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 4, height: 50,
                                        color: const Color(0xFF689F38),
                                      ),
                                      const SizedBox(width: 16),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${currentShift.startHour}:00', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                          Text(
                                            '${currentShift.endHour}:${((currentShift.workMinutes % 60) + currentShift.breakMinutes) > 0 ? ((currentShift.workMinutes % 60) + currentShift.breakMinutes).toString().padLeft(2, '0') : '00'}', 
                                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(currentShift.jobName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 4),
                                            Text('労働時間: ${(currentShift.workMinutes / 60).toStringAsFixed(2)}時間', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('¥${currentShift.salary}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF689F38))),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: currentShift.isCheckedOut ? Colors.green.shade50 : Colors.orange.shade50,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              currentShift.isCheckedOut ? '退勤済み' : 'シフト予定',
                                              style: TextStyle(fontSize: 11, color: currentShift.isCheckedOut ? Colors.green.shade800 : Colors.orange.shade800, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  
                  const Divider(),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton.icon(
                      onPressed: onEditPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF689F38),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.edit, size: 18),
                      label: Text(currentShift == null ? '勤務情報を新規追加する' : 'この日の勤務情報を修正する', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ------------------------------
/// シフト入力・修正フォーム
/// ------------------------------
class ShiftInputSheet extends StatefulWidget {
  final List<Job> jobs;
  final List<Shift> shifts;
  final DateTime initialDate;
  final VoidCallback onSave;

  const ShiftInputSheet({
    required this.jobs,
    required this.shifts,
    required this.initialDate,
    required this.onSave,
    super.key,
  });

  @override
  State<ShiftInputSheet> createState() => _ShiftInputSheetState();
}

class _ShiftInputSheetState extends State<ShiftInputSheet> {
  String? selectedJobName;
  final weekdayWageController = TextEditingController();
  final holidayWageController = TextEditingController();
  final start = TextEditingController();
  final end = TextEditingController();
  final rest = TextEditingController();
  bool isCheckedOut = true; 

  @override
  void initState() {
    super.initState();
    
    final dayShifts = widget.shifts.where((s) =>
        s.date.day == widget.initialDate.day &&
        s.date.month == widget.initialDate.month &&
        s.date.year == widget.initialDate.year).toList();

    if (dayShifts.isNotEmpty) {
      final s = dayShifts.first;
      selectedJobName = s.jobName;
      weekdayWageController.text = s.weekdayWage.toString();
      holidayWageController.text = s.holidayWage.toString();
      start.text = s.startHour.toString();
      end.text = s.endHour.toString();
      rest.text = s.breakMinutes < 0 ? '0' : s.breakMinutes.toString();
      isCheckedOut = s.isCheckedOut;
    } else if (widget.jobs.isNotEmpty) {
      selectedJobName = widget.jobs.first.name;
      weekdayWageController.text = widget.jobs.first.weekdayWage.toString();
      holidayWageController.text = widget.jobs.first.holidayWage.toString();
    }
  }

  void applyHistory(Shift historicalShift) {
    setState(() {
      selectedJobName = historicalShift.jobName;
      weekdayWageController.text = historicalShift.weekdayWage.toString();
      holidayWageController.text = historicalShift.holidayWage.toString();
      start.text = historicalShift.startHour.toString();
      end.text = historicalShift.endHour.toString();
      rest.text = historicalShift.breakMinutes < 0 ? '0' : historicalShift.breakMinutes.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${widget.initialDate.month}月${widget.initialDate.day}日';

    final Map<String, Shift> historyMap = {};
    for (var s in widget.shifts) {
      final key = '${s.startHour}-${s.endHour}-${s.jobName}';
      historyMap[key] = s;
    }
    final historyList = historyMap.values.toList().reversed.take(3).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$dateStr の勤務情報編集', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF689F38))),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
          ],
        ),
        const Divider(height: 24),

        if (historyList.isNotEmpty) ...[
          const Text('履歴からクイック入力：', style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8, runSpacing: 4,
            children: historyList.map((h) {
              final actMin = (h.workMinutes % 60) + h.breakMinutes;
              final dispMin = actMin > 0 ? actMin.toString().padLeft(2, '0') : '00';
              return ActionChip(
                label: Text('${h.startHour}:00〜${h.endHour}:$dispMin (${h.jobName})', style: const TextStyle(fontSize: 12)),
                onPressed: () => applyHistory(h),
                backgroundColor: Colors.green.shade50,
              );
            }).toList(),
          ),
          const Divider(height: 24),
        ],

        DropdownButtonFormField<String>(
          value: selectedJobName,
          decoration: const InputDecoration(labelText: 'アルバイト先', border: OutlineInputBorder()),
          items: widget.jobs.map((job) => DropdownMenuItem(value: job.name, child: Text(job.name))).toList(),
          onChanged: (value) {
            setState(() {
              selectedJobName = value;
              final selectedJob = widget.jobs.firstWhere((j) => j.name == value);
              weekdayWageController.text = selectedJob.weekdayWage.toString();
              holidayWageController.text = selectedJob.holidayWage.toString();
            });
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: TextField(controller: weekdayWageController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '平日時給（円）', border: OutlineInputBorder()))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: holidayWageController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '休日時給（円）', border: OutlineInputBorder()))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: TextField(controller: start, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '出勤（時）', border: OutlineInputBorder()))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: end, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '退勤（時）', border: OutlineInputBorder()))),
          ],
        ),
        const SizedBox(height: 12),
        TextField(controller: rest, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '休憩時間（分）', border: OutlineInputBorder())),
        
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('この勤務は退勤済み（完了）にする', style: TextStyle(fontSize: 14)),
          value: isCheckedOut,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: const Color(0xFF689F38),
          onChanged: (val) {
            setState(() {
              isCheckedOut = val ?? true;
            });
          },
        ),
        const SizedBox(height: 16),
        
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF689F38), 
            foregroundColor: Colors.white, 
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            if (selectedJobName == null || weekdayWageController.text.isEmpty || holidayWageController.text.isEmpty || start.text.isEmpty || end.text.isEmpty || rest.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('すべての項目を入力してください')));
              return;
            }

            widget.shifts.removeWhere((s) =>
                s.date.day == widget.initialDate.day &&
                s.date.month == widget.initialDate.month &&
                s.date.year == widget.initialDate.year);

            widget.shifts.add(
              Shift(
                date: widget.initialDate,
                jobName: selectedJobName!,
                weekdayWage: int.parse(weekdayWageController.text),
                holidayWage: int.parse(holidayWageController.text),
                startHour: int.parse(start.text),
                endHour: int.parse(end.text),
                breakMinutes: int.parse(rest.text),
                isCheckedOut: isCheckedOut,
              ),
            );
            widget.onSave();
          },
          child: const Text('勤務情報を保存する', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }
}

/// ------------------------------
/// アカウント画面
/// ------------------------------
class AccountScreen extends StatelessWidget {
  final List<Job> jobs;
  final List<Shift> shifts;

  const AccountScreen({required this.jobs, required this.shifts, super.key});

  @override
  Widget build(BuildContext context) {
    final totalEarned = shifts.fold(0, (sum, s) => sum + s.salary);

    return Scaffold(
      appBar: AppBar(
        title: const Text('アカウント詳細', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF689F38),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: Color(0xFF689F38),
                        child: Icon(Icons.person, size: 55, color: Colors.white),
                      ),
                      SizedBox(height: 12),
                      Text('シフト太郎', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('ユーザーID: 123456', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                const Divider(height: 40),
                const Text('統計データ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.monetization_on, color: Colors.orange, size: 28),
                  title: const Text('今までの総獲得金額', style: TextStyle(fontSize: 16)),
                  trailing: Text('¥$totalEarned', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: const Icon(Icons.assignment, color: Colors.blue, size: 28),
                  title: const Text('登録済みの総シフト数', style: TextStyle(fontSize: 16)),
                  trailing: Text('${shifts.length} 回', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 40),
                const Text('登録中のアルバイト情報', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (jobs.isEmpty)
                  const Text('登録されているバイト先はありません。')
                else
                  ...jobs.map((j) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.work, color: Color(0xFF689F38)),
                          title: Text(j.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('平日: ¥${j.weekdayWage} / 休日: ¥${j.holidayWage}'),
                        ),
                      )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}