import 'package:flutter/material.dart';
import 'package:ai_coach_chat/models/chat_models.dart';
import 'package:ai_coach_chat/services/chat_api_service.dart';

/// Lightweight embedded chat panel shown beside goals on the home screen.
/// Uses existing ChatApiService; keeps only a small recent history and an input box.
class EmbeddedChatPanel extends StatefulWidget {
  final String userId;
  const EmbeddedChatPanel({super.key, required this.userId});

  @override
  State<EmbeddedChatPanel> createState() => _EmbeddedChatPanelState();
}

class _EmbeddedChatPanelState extends State<EmbeddedChatPanel> {
  final _api = ChatApiService();
  final _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  int? _sessionId;
  bool _sending = false;
  bool _loadingHistory = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecentSession();
  }

  Future<void> _loadRecentSession() async {
    setState(() { _loadingHistory = true; _error = null; });
    try {
      final sessions = await _api.getSessions(widget.userId, limit: 1);
      if (sessions.isNotEmpty) {
        _sessionId = sessions.first.id;
        final msgs = await _api.getMessages(_sessionId!, widget.userId, limit: 20);
        setState(() { _messages.clear(); _messages.addAll(msgs); });
      }
    } catch (e) {
      setState(() { _error = '$e'; });
    } finally {
      setState(() { _loadingHistory = false; });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() { _sending = true; _error = null; });
    try {
      final resp = await _api.sendMessage(SendMessageRequest(userId: widget.userId, message: text, sessionId: _sessionId));
      _sessionId = resp.sessionId;
      setState(() {
        _messages.add(resp.userMessage);
        _messages.add(resp.assistantMessage);
      });
      _controller.clear();
    } catch (e) {
      setState(() { _error = '$e'; });
    } finally {
      setState(() { _sending = false; });
    }
  }

  @override
  void dispose() {
    _api.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.chat_bubble_outline, size: 16),
            const SizedBox(width: 6),
            const Text('AI Coach', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              tooltip: 'Reload',
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: _loadingHistory ? null : _loadRecentSession,
            ),
          ],
        ),
        Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _loadingHistory
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('Start a chat with your coach!', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _messages.length,
                      itemBuilder: (ctx, i) {
                        final m = _messages[i];
                        final isUser = m.isUser;
                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isUser ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12).copyWith(
                                topRight: isUser ? const Radius.circular(4) : null,
                                topLeft: !isUser ? const Radius.circular(4) : null,
                              ),
                            ),
                            child: Text(
                              m.content,
                              style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 12),
                            ),
                          ),
                        );
                      },
                    ),
        ),
        const SizedBox(height: 8),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 11)),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Ask something...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              height: 38,
              width: 38,
              child: ElevatedButton(
                onPressed: _sending ? null : _send,
                style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, shape: const CircleBorder()),
                child: _sending
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send, size: 16),
              ),
            ),
          ],
        )
      ],
    );
  }
}
