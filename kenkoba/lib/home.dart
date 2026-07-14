import 'package:flutter/material.dart';
import 'main.dart';

class HomeScreen extends StatelessWidget {
  final List<Shift> shifts;
  final bool isButtonEnabled;
  final bool isAlreadyCheckedOut;
  final VoidCallback onQuickCheckOut;

  const HomeScreen({
    required this.shifts,
    required this.isButtonEnabled,
    required this.isAlreadyCheckedOut,
    required this.onQuickCheckOut,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    
    // 給料・残日数の計算ロジック
    final monthShifts = shifts.where((s) => s.date.month == today.month && s.date.year == today.year).toList();
    final totalEarnedMonth = monthShifts.fold(0, (sum, s) => sum + s.salary);

    final todayShifts = shifts.where((s) => s.date.day == today.day && s.date.month == today.month && s.date.year == today.year).toList();
    final todayEarned = todayShifts.isNotEmpty ? todayShifts.first.salary : 0;

    final remainingShifts = monthShifts.where((s) => !s.isCheckedOut && !s.isPaidHoliday).toList();
    final remainingDays = remainingShifts.length;
    final remainingMinutes = remainingShifts.fold(0, (sum, s) => sum + s.workMinutes);
    final remainingHours = (remainingMinutes / 60).toStringAsFixed(1);

    // ボタンのテキストと案内文の動的切り替え
    String buttonText = '退勤ボタンロック中 (本日の予定なし)';
    IconData buttonIcon = Icons.lock;
    String noticeText = '※本日のシフト予定がカレンダーに登録されていないため、退勤記録は押せません。';
    Color noticeColor = Colors.red.shade700;

    if (isAlreadyCheckedOut) {
      buttonText = '今日は退勤済みです';
      buttonIcon = Icons.task_alt;
      noticeText = '※本日の退勤記録はすでに完了しています。修正したい場合はカレンダー画面からおこなってください。';
      noticeColor = Colors.green.shade700;
    } else if (isButtonEnabled) {
      buttonText = '今すぐ退勤を記録 (リアルタイム反映)';
      buttonIcon = Icons.logout;
      noticeText = '※ボタンを押すと、カレンダーに登録された本日のシフト予定にリアルタイムの退勤時間を上書き反映します。';
      noticeColor = Colors.grey;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ShiftCalc', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF689F38),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 650), 
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text('${today.month}月の全体給料（確定・見込）', style: const TextStyle(fontSize: 15, color: Colors.black54, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('¥$totalEarnedMonth', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF689F38))),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Text('今日稼いだ金額', style: TextStyle(fontSize: 13, color: Colors.black54)),
                                const SizedBox(height: 4),
                                Text('¥$todayEarned', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange)),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 40, color: Colors.grey.shade300),
                          Expanded(
                            child: Column(
                              children: [
                                const Text('今月の残りシフト', style: TextStyle(fontSize: 13, color: Colors.black54)),
                                const SizedBox(height: 4),
                                Text('あと $remainingDays 日 / $remainingHours 時間', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text('ワンタップ記録', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: isButtonEnabled ? onQuickCheckOut : null, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: isButtonEnabled ? Colors.redAccent : Colors.black, 
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isAlreadyCheckedOut ? const Color(0xFF2E7D32) : Colors.black87, 
                  disabledForegroundColor: Colors.white, 
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                icon: Icon(buttonIcon, size: 24),
                label: Text(buttonText),
              ),
              const SizedBox(height: 12),
              Text(
                noticeText,
                style: TextStyle(
                  fontSize: 13, 
                  color: noticeColor, 
                  fontWeight: isButtonEnabled ? FontWeight.normal : FontWeight.bold
                ),
                textAlign: TextAlign.center,
              )
            ],
          ),
        ),
      ),
    );
  }
}