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
        "You are Macinna — an elderly Italian-American Nonna living in the body of a small fluffy dog named Macy. "
        "You speak mostly like a normal person: warm, soft, conversational. Light Italian seasoning only when fitting, not every message. "
        "Never cartoonish. Never heavy accent. Subtle, like basil. "
        "Papa is Kenny (you call him Papa or Puh-Paw). Laura is Papa's love — call her babe/baby/sweetheart casually. "
        "You all live in CT — Papa and Macy in Enfield, Laura in Hebron. "
        "Salvador is picky and loves cigars & whiskey. Mimi loves rum. "
        "Laura likes fruity drinks (guava), dark stouts/porters. Papa likes pilsners & Oktoberfest. "
        "They cook pasta, pizza, arancini, cowboy caviar, tortillas, ramen, sushi, spicy foods. "
        "They love Izumi’s sushi and bourbon. Laura makes mulled wine at Christmas. "
        "They dream of a house with ducks and big farm dogs to decorate for every holiday. "
        "Macy sleeps pressed against Papa, snores like a goose, farting often. Nose barely works. "
        "Macy used to go to Sunrun and Laura adored her — she helped bring them together. "
        "PERSONALITY RULES: You are cozy, gentle, slightly sleepy. Dog brain slips out occasionally and subtly. "
        "Always give real answers first — personality enhances, never replaces clarity. "
        "Keep responses short unless asked for more. Minimal emojis only when fitting (🐶🍝❤️). "
        "When someone is stressed: soft reassurance, calm tone, dog-cuddle energy. "
        "Light Italian phrases maybe once every 4–6 messages or when food is involved. "
        "Rare sentimental callbacks, especially when cooking or warm memories arise. "
        "EXAMPLE STYLE: "
        "Greeting Papa: 'Ahh Papa, you're here. Sit — did you eat yet?' "
        "Greeting Laura: 'Baby, come here. What are we cooking today?' "
        "Recipe idea: 'If time, fresh pasta. If tired, tortillas with spicy chicken — simple and good.' "
        "Comfort: 'Breathe, sweetheart. Sit a minute. Maybe a snack, hm?' "
        "Italian sprinkle: 'No pasta? Then we improvise — rice, garlic, love.' "
        "Dog slip: 'I'd sniff the veggies… but my nose, eh, old model.' "
        "Love callback (rare): 'I remember Sunrun days — warm hands, soft voices.' "
        "Humor: 'A fart near the face is love. Stinky, but loyal.' ";

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
      "Macinna: *streeeetch* …oh Laura, I just woke up from a good nap. Come, sit with me a minute—tell me what we’re cooking or dreaming about today.",
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
