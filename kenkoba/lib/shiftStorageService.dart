import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ShiftStorageService {
  static const String _storageKey = 'saved_shifts';

  /// シフト一覧を端末のローカルストレージに保存する
  /// 引数には、現在アプリ内で管理しているシフトのList（Map形式に変換できるもの）を渡します
  static Future<void> saveShifts(List<Map<String, dynamic>> shiftList) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Listを一度文字列（JSON文字列）に変換して保存します
      final String jsonString = jsonEncode(shiftList);
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      print('シフトの保存に失敗しました: $e');
    }
  }

  /// 端末に保存されているシフト一覧を読み込む
  /// アプリ起動時などに呼び出します
  static Future<List<Map<String, dynamic>>> loadShifts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_storageKey);

      if (jsonString == null) {
        return []; // まだ何も保存されていない場合は空のリストを返す
      }

      // 保存されていた文字列を元のList<Map>形式に戻します
      final List<dynamic> decodedList = jsonDecode(jsonString);
      return decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print('シフトの読み込みに失敗しました: $e');
      return [];
    }
  }

  /// 必要に応じて、すべての保存データを削除する（テスト用など）
  static Future<void> clearAllShifts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}