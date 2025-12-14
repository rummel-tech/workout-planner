import 'package:supabase_flutter/supabase_flutter.dart';

class UserSyncService {
  final _client = Supabase.instance.client;

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final u = _client.auth.currentUser;
    if (u == null) return null;
    return await _client.from("profiles").select().eq("id", u.id).maybeSingle();
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final u = _client.auth.currentUser;
    if (u == null) return;
    await _client.from("profiles").upsert({...data, "id": u.id});
  }

  Future<Map<String, dynamic>?> fetchSettings() async {
    final u = _client.auth.currentUser;
    if (u == null) return null;
    return await _client.from("settings").select().eq("user_id", u.id).maybeSingle();
  }

  Future<void> updateSettings(Map<String, dynamic> data) async {
    final u = _client.auth.currentUser;
    if (u == null) return;
    await _client.from("settings").upsert({...data, "user_id": u.id});
  }
}
