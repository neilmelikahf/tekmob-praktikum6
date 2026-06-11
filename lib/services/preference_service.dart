import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static const _keyDraftJudul = 'draft_judul';
  static const _keyDraftDeskripsi = 'draft_deskripsi';
  static const _keyLastSavedAt = 'draft_last_saved_at';

  Future<void> saveDraft({String? judul, String? deskripsi}) async {
    final prefs = await SharedPreferences.getInstance();
    if (judul != null) {
      await prefs.setString(_keyDraftJudul, judul);
    }
    if (deskripsi != null) {
      await prefs.setString(_keyDraftDeskripsi, deskripsi);
    }
    await prefs.setString(_keyLastSavedAt, DateTime.now().toIso8601String());
  }

  Future<Map<String, String?>> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'judul': prefs.getString(_keyDraftJudul),
      'deskripsi': prefs.getString(_keyDraftDeskripsi),
      'savedAt': prefs.getString(_keyLastSavedAt),
    };
  }

  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDraftJudul);
    await prefs.remove(_keyDraftDeskripsi);
    await prefs.remove(_keyLastSavedAt);
  }
}
