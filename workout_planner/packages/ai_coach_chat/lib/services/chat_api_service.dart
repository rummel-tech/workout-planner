import 'dart:convert';
import 'dart:io';
import '../models/chat_models.dart';

/// Service for communicating with chat API
class ChatApiService {
  final String baseUrl;
  final HttpClient _client = HttpClient();

  ChatApiService({this.baseUrl = 'http://localhost:8000'});

  Future<List<ChatSession>> getSessions(String userId, {int limit = 20}) async {
    try {
      final uri = Uri.parse('$baseUrl/chat/sessions?user_id=$userId&limit=$limit');
      final request = await _client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final List<dynamic> data = json.decode(responseBody);
        return data.map((json) => ChatSession.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load sessions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching sessions: $e');
      rethrow;
    }
  }

  Future<ChatSession> createSession(String userId, {String? title}) async {
    try {
      final uri = Uri.parse('$baseUrl/chat/sessions');
      final request = await _client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');

      final body = json.encode({
        'user_id': userId,
        if (title != null) 'title': title,
      });
      request.write(body);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        return ChatSession.fromJson(json.decode(responseBody));
      } else {
        throw Exception('Failed to create session: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating session: $e');
      rethrow;
    }
  }

  Future<List<ChatMessage>> getMessages(int sessionId, String userId, {int limit = 50}) async {
    try {
      final uri = Uri.parse('$baseUrl/chat/messages/$sessionId?user_id=$userId&limit=$limit');
      final request = await _client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final List<dynamic> data = json.decode(responseBody);
        return data.map((json) => ChatMessage.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching messages: $e');
      rethrow;
    }
  }

  Future<SendMessageResponse> sendMessage(SendMessageRequest request) async {
    try {
      final uri = Uri.parse('$baseUrl/chat/messages');
      final httpRequest = await _client.postUrl(uri);
      httpRequest.headers.set('Content-Type', 'application/json');

      final body = json.encode(request.toJson());
      httpRequest.write(body);

      final response = await httpRequest.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        return SendMessageResponse.fromJson(json.decode(responseBody));
      } else {
        throw Exception('Failed to send message: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  Future<void> deleteSession(int sessionId, String userId) async {
    try {
      final uri = Uri.parse('$baseUrl/chat/sessions/$sessionId?user_id=$userId');
      final request = await _client.deleteUrl(uri);
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Failed to delete session: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting session: $e');
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}
