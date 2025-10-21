import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchLyrics() async {
    final response = await client.from('lyrics').select('*').order('id');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchBhajans() async {
    final response = await client.from('bhajans').select('*').order('id');
    return List<Map<String, dynamic>>.from(response);
  }

  // New helper method: fetch all rows for a specific bhajan name
  Future<List<Map<String, dynamic>>> fetchBhajansByName(String bhajanName) async {
    final response = await client
        .from('bhajans')
        .select('*')
        .eq('bhajan_name', bhajanName);
    return List<Map<String, dynamic>>.from(response);
  }

  // New helper method: delete all rows with a specific bhajan name
  Future<void> deleteBhajansByName(String bhajanName) async {
    await client.from('bhajans').delete().eq('bhajan_name', bhajanName);
  }

  Future<void> addLyric(String name, String url) async {
    await client.from('lyrics').insert({'lyricsName': name, 'lyricsUrl': url});
  }

  Future<void> updateLyric(int id, String name, String url) async {
    await client.from('lyrics').update({
      'lyricsName': name,
      'lyricsUrl': url,
    }).eq('id', id);
  }

  Future<void> deleteLyric(int id) async {
    await client.from('lyrics').delete().eq('id', id);
  }

  Future<void> addBhajan(String name, String artist, String category, String url) async {
    await client.from('bhajans').upsert({
      'bhajan_name': name,
      'artist_name': artist,
      'category': category,
      'audio_url': url,
    }, onConflict: 'bhajan_name,category');
  }

  Future<void> updateBhajan(int id, String name, String artist, String category, String url) async {
    await client.from('bhajans').update({
      'bhajan_name': name,
      'artist_name': artist,
      'category': category,
      'audio_url': url,
    }).eq('id', id);
  }

  Future<void> deleteBhajan(int id) async {
    await client.from('bhajans').delete().eq('id', id);
  }
}
