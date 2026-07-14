import 'package:flutter/material.dart';
import 'main.dart';

class CalendarScreen extends StatelessWidget {
  final List<Shift> shifts;
  final DateTime selectedDate;
  final DateTime currentMonth; 
  final Function(int) onMonthChange; 
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onEditPressed; 
  final Function(DateTime) onDeletePressed; 

  const CalendarScreen({
    required this.shifts,
    required this.selectedDate,
    required this.currentMonth,
    required this.onMonthChange,
    required this.onDateSelected,
    required this.onEditPressed,
    required this.onDeletePressed, 
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

    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final int startEmptySpaces = firstDayOfMonth.weekday == DateTime.sunday ? 0 : firstDayOfMonth.weekday;
    final totalDaysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
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
                      itemCount: totalGridItems, 
                      itemBuilder: (context, index) {
                        if (index < startEmptySpaces) {
                          return const SizedBox(); 
                        }

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: onEditPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF689F38),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('情報を新規追加・修正', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      if (currentShift != null) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: OutlinedButton.icon(
                            onPressed: () => onDeletePressed(selectedDate),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent, width: 1.5),
                              foregroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.delete_forever, size: 16),
                            label: const Text('この日の勤務情報を削除', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ],
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