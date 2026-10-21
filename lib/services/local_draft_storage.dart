import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/collection_draft.dart';

class LocalDraftStorage {
  static const String _keyActiveDraft = 'active_collection_draft';

  static Future<void> saveDraft(CollectionDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(draft.toJson());
    await prefs.setString(_keyActiveDraft, jsonStr);
  }

  static Future<CollectionDraft?> loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keyActiveDraft);
      if (jsonStr == null || jsonStr.isEmpty) return null;

      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return CollectionDraft.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActiveDraft);
  }
}
