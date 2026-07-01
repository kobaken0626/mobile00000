import 'package:flutter/material.dart';
import 'main.dart'; // Job, Shiftモデルの読み込み用

class AccountScreen extends StatelessWidget {
  final List<Job> jobs;
  final List<Shift> shifts;
  final VoidCallback onJobsChanged; 

  const AccountScreen({required this.jobs, required this.shifts, required this.onJobsChanged, super.key});

  void _showJobEditDialog(BuildContext context, {Job? existingJob}) {
    final nameController = TextEditingController(text: existingJob?.name ?? '');
    final weekdayWageController = TextEditingController(text: existingJob?.weekdayWage.toString() ?? '');
    final holidayWageController = TextEditingController(text: existingJob?.holidayWage.toString() ?? '');
    final payDayController = TextEditingController(text: existingJob?.payDay.toString() ?? '25');
    final closingDayController = TextEditingController(text: existingJob?.closingDay.toString() ?? '30');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existingJob == null ? '新しいアルバイト情報を追加' : 'アルバイト情報を編集'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'アルバイト名', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: weekdayWageController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '平日時給', border: OutlineInputBorder()))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: holidayWageController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '休日時給', border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: payDayController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '給料日 (日)', border: OutlineInputBorder()))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: closingDayController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '締め日 (日)', border: OutlineInputBorder()))),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF689F38), foregroundColor: Colors.white),
              onPressed: () {
                if (nameController.text.isEmpty || weekdayWageController.text.isEmpty || holidayWageController.text.isEmpty) return;

                if (existingJob == null) {
                  jobs.add(Job(
                    name: nameController.text,
                    weekdayWage: int.parse(weekdayWageController.text),
                    holidayWage: int.parse(holidayWageController.text),
                    payDay: int.parse(payDayController.text),
                    closingDay: int.parse(closingDayController.text),
                  ));
                } else {
                  existingJob.name = nameController.text;
                  existingJob.weekdayWage = int.parse(weekdayWageController.text);
                  existingJob.holidayWage = int.parse(holidayWageController.text);
                  existingJob.payDay = int.parse(payDayController.text);
                  existingJob.closingDay = int.parse(closingDayController.text);
                }
                onJobsChanged(); 
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('登録中のアルバイト情報', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: () => _showJobEditDialog(context),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF689F38), foregroundColor: Colors.white),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('追加', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (jobs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('登録されているバイト先はありません。右上のボタンから追加してください。', style: TextStyle(color: Colors.grey)),
                  )
                else
                  ...jobs.map((j) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 1,
                        child: ListTile(
                          leading: const Icon(Icons.work, color: Color(0xFF689F38)),
                          title: Text(j.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('時給: 平日 ¥${j.weekdayWage} / 休日 ¥${j.holidayWage}'),
                              Text('締め日: 毎月 ${j.closingDay}日 / 給料日: 毎月 ${j.payDay}日', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                onPressed: () => _showJobEditDialog(context, existingJob: j),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                onPressed: () {
                                  jobs.remove(j);
                                  onJobsChanged();
                                },
                              ),
                            ],
                          ),
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