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
  int index = 1; 
  DateTime selectedCalendarDate = DateTime.now();
  DateTime currentMonthView = DateTime.now(); 

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
    const startMinute = 0;
    
    final endHour = today.hour;     
    final endMinute = today.minute; 
    const breakMin = 0;          

    final startTotal = (startHour * 60) + startMinute;
    final endTotal = (endHour * 60) + endMinute;
    if ((endTotal - startTotal) <= 0) {
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

  void changeMonth(int offset) {
    setState(() {
      currentMonthView = DateTime(currentMonthView.year, currentMonthView.month + offset, 1);
      selectedCalendarDate = DateTime(currentMonthView.year, currentMonthView.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(shifts: shifts, onQuickCheckOut: addQuickCheckOutShift),
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
                '※既存のデータがある場合は自動で時間が上書きされ、「退勤済み」になります。',
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
/// カレンダー画面（★正確な曜日配置に修正）
/// ------------------------------
class CalendarScreen extends StatelessWidget {
  final List<Shift> shifts;
  final DateTime selectedDate;
  final DateTime currentMonth; 
  final Function(int) onMonthChange; 
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onEditPressed; 

  const CalendarScreen({
    required this.shifts,
    required this.selectedDate,
    required this.currentMonth,
    required this.onMonthChange,
    required this.onDateSelected,
    required this.onEditPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dayShifts = shifts.where((s) =>
        s.date.day == selectedDate.day &&
        s.date.month == selectedDate.month &&
        s.date.year == selectedDate.year).toList();
    final currentShift = dayShifts.isNotEmpty ? dayShifts.first : null;

    final weekDays = ['日', '月', '火', '水', '木', '金', '土'];

    // 💡 ★【重要】曜日を完全に合わせるための計算ロジック
    // 1. 表示している月の「1日」の曜日を取得 (DateTime.sunday=7, DateTime.monday=1...)
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    // 週の始まりを「日曜日（0）」にするため、Flutterの1(月)〜7(日)を変換
    final int startEmptySpaces = firstDayOfMonth.weekday == DateTime.sunday ? 0 : firstDayOfMonth.weekday;

    // 2. 当月の末日（日数）を取得
    final totalDaysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;

    // 3. グリッドに並べる総マス数（空白マス ＋ 当月の日数）
    final totalGridItems = startEmptySpaces + totalDaysInMonth;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.calendar_month, color: Colors.white),
            const SizedBox(width: 16),
            Text('${currentMonth.year}年 ${currentMonth.month}月', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
              onPressed: () => onMonthChange(-1),
            ),
            TextButton(
              onPressed: () => onMonthChange(-1),
              child: const Text('前月', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () => onMonthChange(1),
              child: const Text('次月', style: TextStyle(color: Colors.white)),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
              onPressed: () => onMonthChange(1),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF689F38),
        elevation: 2,
      ),
      body: Row( 
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // 【左カラム：カレンダー全体 2/3】
          Expanded(
            flex: 2, 
            child: Container(
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1)),
              ),
              padding: const EdgeInsets.all(24),
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
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: day == '日' ? Colors.red : (day == '土' ? Colors.blue : Colors.black54),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 1.4, 
                      ),
                      itemCount: totalGridItems, // ★ 空白を含めた総マス数に変更
                      itemBuilder: (context, index) {
                        // 1日の曜日より手前のマスは、前月の「空白マス」として描画する
                        if (index < startEmptySpaces) {
                          return const SizedBox(); // 何も表示しない空のマス
                        }

                        // 実際の「日にち」を割り出す
                        final day = index - startEmptySpaces + 1;
                        final targetDate = DateTime(currentMonth.year, currentMonth.month, day);
                        final isSelected = selectedDate.day == day && selectedDate.month == currentMonth.month && selectedDate.year == currentMonth.year;

                        final dayTargetShifts = shifts.where((s) =>
                            s.date.day == day && s.date.month == currentMonth.month && s.date.year == currentMonth.year).toList();
                        final hasShift = dayTargetShifts.isNotEmpty;
                        final isDayCheckedOut = hasShift && dayTargetShifts.first.isCheckedOut;

                        Color tileColor = Colors.white;
                        if (isSelected) {
                          tileColor = const Color(0xFFC8E6C9); 
                        } else if (hasShift) {
                          tileColor = isDayCheckedOut ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);
                        }

                        return GestureDetector(
                          onTap: () => onDateSelected(targetDate),
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: tileColor,
                              borderRadius: BorderRadius.circular(6),
                              border: isSelected 
                                  ? Border.all(color: const Color(0xFF689F38), width: 2) 
                                  : Border.all(color: hasShift ? (isDayCheckedOut ? Colors.green.shade200 : Colors.orange.shade200) : Colors.grey.shade100),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Text(
                                    '$day',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isSelected ? const Color(0xFF2E7D32) : (hasShift ? (isDayCheckedOut ? Colors.green.shade900 : Colors.orange.shade900) : Colors.black87),
                                      fontWeight: isSelected || hasShift ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (hasShift)
                                  Positioned(
                                    bottom: 8, left: 0, right: 0,
                                    child: Center(
                                      child: Container(
                                        width: 6, height: 6,
                                        decoration: BoxDecoration(
                                          color: isDayCheckedOut ? const Color(0xFF689F38) : Colors.orange, 
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 【右カラム：勤務詳細エリア 1/3】
          Expanded(
            flex: 1, 
            child: Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${selectedDate.month}月${selectedDate.day}日 勤務詳細',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  
                  Expanded(
                    child: currentShift == null
                        ? const Center(
                            child: Text('予定・勤務情報はありません', style: TextStyle(color: Colors.black45, fontSize: 14)),
                          )
                        : ListView(
                            children: [
                              Card(
                                elevation: 1,
                                color: Colors.white,
                                margin: EdgeInsets.zero,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(currentShift.jobName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: currentShift.isPaidHoliday 
                                                  ? Colors.blue.shade50 
                                                  : (currentShift.isCheckedOut ? Colors.green.shade50 : Colors.orange.shade50),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              currentShift.isPaidHoliday 
                                                  ? '有給休暇' 
                                                  : (currentShift.isCheckedOut ? '退勤済み' : 'シフト予定'),
                                              style: TextStyle(
                                                fontSize: 11, 
                                                color: currentShift.isPaidHoliday 
                                                    ? Colors.blue.shade800 
                                                    : (currentShift.isCheckedOut ? Colors.green.shade800 : Colors.orange.shade800), 
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      
                                      if (currentShift.isPaidHoliday) ...[
                                        const Row(
                                          children: [
                                            Icon(Icons.star, size: 18, color: Colors.blue),
                                            SizedBox(width: 8),
                                            Text('本日は有給休暇です', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        const Text('労働時間・見込給料は発生しません。', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                      ] else ...[
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time, size: 18, color: Colors.black54),
                                            const SizedBox(width: 8),
                                            Text(
                                              '時間: ${currentShift.startHour}:${currentShift.startMinute.toString().padLeft(2, '0')} 〜 ${currentShift.endHour}:${currentShift.endMinute.toString().padLeft(2, '0')}',
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.hourglass_bottom, size: 18, color: Colors.black54),
                                            const SizedBox(width: 8),
                                            Text('労働: ${(currentShift.workMinutes / 60).toStringAsFixed(2)}時間', style: const TextStyle(fontSize: 14)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.payments, size: 18, color: Color(0xFF689F38)),
                                            const SizedBox(width: 8),
                                            Text('見込給料: ¥${currentShift.salary}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF689F38))),
                                          ],
                                        ),
                                      ],
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
                      label: Text(currentShift == null ? '情報を新規追加' : '勤務情報を修正', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
  final startH = TextEditingController();
  final startM = TextEditingController();
  final endH = TextEditingController();
  final endM = TextEditingController();
  final rest = TextEditingController();
  
  bool isCheckedOut = false;    
  bool isPaidHoliday = false;   

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
      startH.text = s.startHour.toString();
      startM.text = s.startMinute.toString();
      endH.text = s.endHour.toString();
      endM.text = s.endMinute.toString();
      rest.text = s.breakMinutes.toString();
      isCheckedOut = s.isCheckedOut;
      isPaidHoliday = s.isPaidHoliday;
    } else {
      startH.text = '10';
      startM.text = '0';
      endH.text = '17';
      endM.text = '0';
      rest.text = '0';
      if (widget.jobs.isNotEmpty) {
        selectedJobName = widget.jobs.first.name;
        weekdayWageController.text = widget.jobs.first.weekdayWage.toString();
        holidayWageController.text = widget.jobs.first.holidayWage.toString();
      }
    }
  }

  void applyHistory(Shift h) {
    setState(() {
      selectedJobName = h.jobName;
      weekdayWageController.text = h.weekdayWage.toString();
      holidayWageController.text = h.holidayWage.toString();
      startH.text = h.startHour.toString();
      startM.text = h.startMinute.toString();
      endH.text = h.endHour.toString();
      endM.text = h.endMinute.toString();
      rest.text = h.breakMinutes.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${widget.initialDate.month}月${widget.initialDate.day}日';

    final Map<String, Shift> historyMap = {};
    for (var s in widget.shifts) {
      final key = '${s.startHour}-${s.startMinute}-${s.endHour}-${s.endMinute}-${s.jobName}';
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
              return ActionChip(
                label: Text('${h.startHour}:${h.startMinute.toString().padLeft(2,'0')}〜${h.endHour}:${h.endMinute.toString().padLeft(2,'0')} (${h.jobName})', style: const TextStyle(fontSize: 12)),
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
        
        Opacity(
          opacity: isPaidHoliday ? 0.4 : 1.0,
          child: AbsorbPointer(
            absorbing: isPaidHoliday,
            child: Column(
              children: [
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
                    Expanded(child: TextField(controller: startH, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '出勤（時）', border: OutlineInputBorder()))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: startM, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '出勤（分）', border: OutlineInputBorder()))),
                    const SizedBox(width: 16),
                    Expanded(child: TextField(controller: endH, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '退勤（時）', border: OutlineInputBorder()))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: endM, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '退勤（分）', border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: rest, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '休憩時間（分）', border: OutlineInputBorder())),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('この勤務は退勤済み（完了）にする', style: TextStyle(fontSize: 14)),
          value: isCheckedOut,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: const Color(0xFF689F38),
          onChanged: isPaidHoliday ? null : (val) { 
            setState(() {
              isCheckedOut = val ?? false;
            });
          },
        ),
        
        CheckboxListTile(
          title: Text(
            '有給休暇として記録する（給料計算は¥0になります）', 
            style: TextStyle(fontSize: 14, color: Colors.blue.shade700, fontWeight: FontWeight.w600),
          ),
          value: isPaidHoliday,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: Colors.blue,
          onChanged: (val) {
            setState(() {
              isPaidHoliday = val ?? false;
              if (isPaidHoliday) {
                isCheckedOut = false; 
              }
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
            if (selectedJobName == null || weekdayWageController.text.isEmpty || holidayWageController.text.isEmpty || startH.text.isEmpty || startM.text.isEmpty || endH.text.isEmpty || endM.text.isEmpty || rest.text.isEmpty) {
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
                startHour: int.parse(startH.text),
                startMinute: int.parse(startM.text),
                endHour: int.parse(endH.text),
                endMinute: int.parse(endM.text),
                breakMinutes: int.parse(rest.text),
                isCheckedOut: isCheckedOut,
                isPaidHoliday: isPaidHoliday, 
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