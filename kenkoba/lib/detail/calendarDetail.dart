import 'package:flutter/material.dart';
import '../main.dart'; // 親ディレクトリのモデル群を読み込み

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