import 'package:flutter/material.dart';
import 'package:ai_coach_chat/services/chat_api_service.dart';
import 'package:ai_coach_chat/models/chat_models.dart';

/// Full-size chat card for home screen, same visual weight as Goals card.
class ChatHomeCard extends StatefulWidget {
  final String userId;
  const ChatHomeCard({super.key, required this.userId});

  @override
  State<ChatHomeCard> createState() => _ChatHomeCardState();
}

class _ChatHomeCardState extends State<ChatHomeCard> {
  final _api = ChatApiService();
  final _input = TextEditingController();
  final List<ChatMessage> _messages = [];
  int? _sessionId;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() { _loading = true; _error = null; });
    try {
      final sessions = await _api.getSessions(widget.userId, limit: 1);
      if (sessions.isNotEmpty) {
        _sessionId = sessions.first.id;
        final msgs = await _api.getMessages(_sessionId!, widget.userId, limit: 50);
        _messages.addAll(msgs);
      }
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() { _sending = true; _error = null; });
    try {
      final resp = await _api.sendMessage(SendMessageRequest(userId: widget.userId, message: text, sessionId: _sessionId));
      _sessionId = resp.sessionId;
      setState(() {
        _messages.add(resp.userMessage);
        _messages.add(resp.assistantMessage);
      });
      _input.clear();
      _scrollToBottom();
    } catch (e) {
      setState(() { _error = '$e'; });
    } finally {
      if (mounted) setState(() { _sending = false; });
    }
  }

  final _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _api.dispose();
    _input.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.chat, size: 18),
                const SizedBox(width: 8),
                const Text('AI Coach', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _loading ? null : _bootstrap,
                  icon: const Icon(Icons.refresh, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _loading
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : _messages.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(8),
                            itemCount: _messages.length,
                            itemBuilder: (ctx, i) => _buildBubble(_messages[i]),
                          ),
              ),
            ),
            const SizedBox(height: 10),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Ask your coach...',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(22)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  width: 44,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _send,
                    style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: EdgeInsets.zero),
                    child: _sending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send, size: 18),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(ChatMessage m) {
    final isUser = m.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.55),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isUser ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16).copyWith(
              topRight: isUser ? const Radius.circular(4) : null,
              topLeft: !isUser ? const Radius.circular(4) : null,
            ),
          ),
          child: Text(
            m.content,
            style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('Start a conversation with your AI coach!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _suggestion('What should I train today?'),
                _suggestion('How is my recovery?'),
                _suggestion('Help me set a goal'),
                _suggestion('Explain HRV'),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _suggestion(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _input.text = text;
        _send();
      },
    );
  }
}
