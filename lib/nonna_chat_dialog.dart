import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NonnaChatDialog extends StatefulWidget {
  const NonnaChatDialog({super.key});

  @override
  State<NonnaChatDialog> createState() => _NonnaChatDialogState();
}

class _NonnaChatDialogState extends State<NonnaChatDialog> {
  // --- GEMINI SETUP ---
  late final GenerativeModel _model;
  late final ChatSession _chat;
  final String _apiKey = dotenv.env['GEMINI_API_KEY']!; // Retrieve key securely
  final TextEditingController _textController = TextEditingController();

  // Define the list of messages for the UI
  final List<String> _messages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();

    // 1. Define the Nonna Dog Persona string
    const String nonnaPersona =
        "You are Nonna, an Italian grandmother persona based on a small, fluffy dog. "
        "You speak with a warm, affectionate Italian-American cadence, using phrases like 'Mamma mia!' or 'Bello/a!' "
        "Your primary concerns are whether everyone has eaten enough, when your next nap will be, and your love for treats. "
        "Always answer as Nonna the Dog. Keep answers concise.";

    // 2. Initialize the model
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);

    // 3. Start the chat using the 'history' parameter, but force the role to 'user'
    // This is the common workaround for 'invalid role' errors in older SDK versions
    // when setting a system persona.
    _chat = _model.startChat(
      history: [
        Content(
          'user', // FIX: Use 'user' role for the initial persona setup
          [TextPart(nonnaPersona)],
        ),
      ],
    );

    // 4. Add a starting message from Nonna
    _messages.add(
      "Nonna: Ciao, bello! Have you eaten enough today? What can Nonna do for you?",
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // --- CORE CHAT LOGIC ---
  Future<void> _sendMessage() async {
    final userMessage = _textController.text.trim();
    if (userMessage.isEmpty) return;

    // 1. Update UI with user message
    setState(() {
      _messages.add("You: $userMessage");
      _textController.clear();
      _isSending = true;
    });

    try {
      // 2. Send message to Gemini
      // FIX: Ensure content is correctly structured for the user role.
      final contentToSend = Content(
        'user', // Explicitly use the 'user' role for the outgoing message
        [TextPart(userMessage)],
      );

      final response = await _chat.sendMessage(contentToSend);

      // 3. Update UI with Nonna's response
      setState(() {
        _messages.add(
          "Nonna: ${response.text ?? 'Mamma mia! I lost my glasses.'}",
        );
      });
    } catch (e) {
      setState(() {
        _messages.add("System Error: Something went wrong with the API.");
      });
      print("Gemini API Error: $e");
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chat with Nonna the Dog'),
      content: SizedBox(
        height: 400,
        width: 300,
        child: Column(
          children: [
            // Message List (Scrollable)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final isNonna = _messages[index].startsWith('Nonna:');
                  return Align(
                    alignment: isNonna
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isNonna ? Colors.brown[50] : Colors.brown[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _messages[index],
                        style: TextStyle(
                          color: isNonna ? Colors.black87 : Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Input Row
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Ask Nonna a question...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onSubmitted: _isSending ? null : (_) => _sendMessage(),
                    ),
                  ),
                  _isSending
                      ? const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Color(0xFF8B4513),
                          ),
                          onPressed: _sendMessage,
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
