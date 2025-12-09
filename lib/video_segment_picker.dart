import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'recipe_model.dart';

class VideoSegmentPicker extends StatefulWidget {
  final VideoSegment? existingSegment;

  const VideoSegmentPicker({super.key, this.existingSegment});

  @override
  State<VideoSegmentPicker> createState() => _VideoSegmentPickerState();
}

class _VideoSegmentPickerState extends State<VideoSegmentPicker> {
  final _urlController = TextEditingController();
  YoutubePlayerController? _playerController;

  int? _startTime;
  int? _endTime;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingSegment != null) {
      _urlController.text = widget.existingSegment!.url;
      _startTime = widget.existingSegment!.startTimeSeconds;
      _endTime = widget.existingSegment!.endTimeSeconds;
      // 🛑 REMOVED: Initializing the player here caused the issue
      // because it ran before the UI was fully set up.
      // We now rely on the user tapping "Load" or the controller's onReady state.
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _playerController?.close();
    super.dispose();
  }

  void _initializePlayer(String url) {
    final videoId = YoutubePlayerController.convertUrlToId(url);
    if (videoId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid YouTube URL')));
      _playerController?.close();
      setState(() => _isPlayerReady = false);
      return;
    }

    // 🛑 RULE #1 IMPLEMENTATION: Always start at 0 seconds (0.0).
    const initialStartSeconds = 0.0;

    // 1. Create the controller
    final controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: false,
      startSeconds: initialStartSeconds, // Set to 0.0
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
      ),
    );

    // 2. Set the controller and ready state
    setState(() {
      _playerController = controller;
      _isPlayerReady = true;
    });

    // 3. Keep the stability hack: Pause after 500ms to clear the initial buffer stall.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_playerController != null) {
        _playerController!.pauseVideo();
      }
    });

    // 4. Load saved times into state (if available) for the Mark buttons to display.
    if (widget.existingSegment != null) {
      _startTime = widget.existingSegment!.startTimeSeconds;
      _endTime = widget.existingSegment!.endTimeSeconds;
    }
  }

  Future<void> _markStart() async {
    if (_playerController == null) return;
    final currentTime = await _playerController!.currentTime;
    setState(() => _startTime = currentTime.toInt());
  }

  Future<void> _markEnd() async {
    if (_playerController == null) return;
    final currentTime = await _playerController!.currentTime;
    setState(() => _endTime = currentTime.toInt());
  }

  void _saveSegment() {
    if (_urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a YouTube URL')),
      );
      return;
    }
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please mark start and end times')),
      );
      return;
    }
    if (_endTime! <= _startTime!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    final segment = VideoSegment(
      url: _urlController.text,
      startTimeSeconds: _startTime!,
      endTimeSeconds: _endTime!,
    );

    Navigator.pop(context, segment);
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Segment'),
        backgroundColor: const Color(0xFF8B4513),
        actions: [
          TextButton(
            onPressed: _saveSegment,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'YouTube URL',
                      hintText: 'https://www.youtube.com/watch?v=...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _initializePlayer(_urlController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Load'),
                ),
              ],
            ),
          ),

          if (_isPlayerReady && _playerController != null)
            Expanded(
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: YoutubePlayer(
                      controller: _playerController!,
                      aspectRatio: 16 / 9,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mark buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _markStart,
                          icon: const Icon(Icons.start),
                          label: const Text('Mark Start'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9BE79D),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        ElevatedButton.icon(
                          onPressed: _markEnd,
                          icon: const Icon(Icons.stop),
                          label: const Text('Mark End'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF7A8A8),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Time display
                  if (_startTime != null || _endTime != null)
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text(
                                  'Start',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _startTime != null
                                      ? _formatTime(_startTime!)
                                      : '--:--',
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ],
                            ),
                            const Icon(Icons.arrow_forward, size: 32),
                            Column(
                              children: [
                                const Text(
                                  'End',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _endTime != null
                                      ? _formatTime(_endTime!)
                                      : '--:--',
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
