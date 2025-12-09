import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'dart:async';
import 'recipe_model.dart';

class CookModeScreen extends StatefulWidget {
  final Recipe recipe;

  const CookModeScreen({super.key, required this.recipe});

  @override
  State<CookModeScreen> createState() => _CookModeScreenState();
}

class _CookModeScreenState extends State<CookModeScreen> {
  int _currentStepIndex = 0;
  YoutubePlayerController? _videoController;
  final List<ActiveTimer> _activeTimers = [];

  RecipeStep get _currentStep => widget.recipe.steps[_currentStepIndex];

  @override
  void dispose() {
    _videoController?.close();
    for (var timer in _activeTimers) {
      timer.cancel();
    }
    super.dispose();
  }

  void _nextStep() {
    if (_currentStepIndex < widget.recipe.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
        _videoController?.close();
        _videoController = null;
      });
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
        _videoController?.close();
        _videoController = null;
      });
    }
  }

  void _startEndCheckPolling() async {
    final segment = _currentStep.videoSegment;
    if (_videoController == null || segment == null) return;

    final endTime = segment.endTimeSeconds.toDouble();

    // Only poll if the video is playing
    while (_videoController!.value.playerState == PlayerState.playing) {
      // Wait for a short interval before checking the position
      await Future.delayed(const Duration(milliseconds: 250));

      // Use the explicit method call to get position
      final currentPosition = (await _videoController!.currentTime) ?? 0.0;

      if (currentPosition >= endTime) {
        _videoController!.pauseVideo();

        // 🛑 REMOVED: Navigator.of(context).pop();

        return; // Stop the polling loop
      }
    }
  }

  void _resetSegmentPlayback() {
    final segment = _currentStep.videoSegment;
    if (_videoController == null || segment == null) return;

    final savedStartTime = segment.startTimeSeconds.toDouble();

    // Seek 1 second before the start time for a hard reset/buffer kick.
    final resetTime = (savedStartTime - 1.0) > 0.0
        ? (savedStartTime - 1.0)
        : 0.0;

    // 1. Stabilize by seeking back 1 second
    _videoController!.seekTo(seconds: resetTime, allowSeekAhead: true);

    // 2. Immediately seek forward to the correct start time
    _videoController!.seekTo(seconds: savedStartTime, allowSeekAhead: true);

    // 3. 🛑 CRITICAL CHANGE: Start the video playing!
    _videoController!.playVideo();
  }

  void _playVideoSegment() {
    final segment = _currentStep.videoSegment;
    if (segment == null) return;

    final videoId = YoutubePlayerController.convertUrlToId(segment.url);
    if (videoId == null) return;

    _videoController?.close();
    _videoController = null;

    final savedStartTime = segment.startTimeSeconds.toDouble();
    final initialLoadTime = savedStartTime + 1.0;

    // 1. Create controller: Load 1 second ahead, set autoPlay to false
    _videoController = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: false,
      startSeconds: initialLoadTime,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
      ),
    );

    setState(() {});

    // 2. Stabilization and Polling Sequence
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_videoController != null) {
        final stabilizeTime = (savedStartTime - 1.0) > 0.0
            ? (savedStartTime - 1.0)
            : 0.0;

        // Stabilization Seek Back -> Seek Forward
        _videoController!.seekTo(seconds: stabilizeTime);
        _videoController!.seekTo(seconds: savedStartTime);
        _videoController!.pauseVideo();
      }
    });

    // 3. Start polling when the user presses play.
    // We attach an action to the controller's main event stream to start polling when the state changes to playing.
    _videoController!.listen((event) {
      if (event.playerState == PlayerState.playing) {
        // 🛑 START THE POLLING LOOP WHEN THE USER PRESSES PLAY
        _startEndCheckPolling();
      }
    });

    // 4. Show dialog
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: YoutubePlayer(
                controller: _videoController!,
                aspectRatio: 16 / 9,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: _resetSegmentPlayback,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset/Fix Load'),
                ),
                TextButton(
                  onPressed: () {
                    // No need to remove a listener, only close the controller.
                    _videoController?.close();
                    _videoController = null;
                    Navigator.pop(context);
                  },
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startTimer(StepTimer timer) {
    final activeTimer = ActiveTimer(
      name: timer.name,
      totalSeconds: timer.durationSeconds,
      remainingSeconds: timer.durationSeconds,
    );

    setState(() => _activeTimers.add(activeTimer));

    activeTimer.timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        activeTimer.remainingSeconds--;
        if (activeTimer.remainingSeconds <= 0) {
          t.cancel();
          _showTimerComplete(activeTimer);
        }
      });
    });
  }

  void _showTimerComplete(ActiveTimer timer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Timer Complete!'),
        content: Text('${timer.name} is done'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _activeTimers.remove(timer));
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatTimerTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.name),
        backgroundColor: const Color(0xFF8B4513),
        bottom: _activeTimers.isNotEmpty
            ? PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: Container(
                  color: Colors.brown.shade200,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: _activeTimers.map((timer) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${timer.name}: ${_formatTimerTime(timer.remainingSeconds)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                timer.cancel();
                                setState(() => _activeTimers.remove(timer));
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              )
            : null,
      ),
      body: PageView.builder(
        controller: PageController(initialPage: _currentStepIndex),
        onPageChanged: (index) {
          setState(() {
            _currentStepIndex = index;
            _videoController?.close();
            _videoController = null;
          });
        },
        itemCount: widget.recipe.steps.length,
        itemBuilder: (context, index) {
          final step = widget.recipe.steps[index];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step number and title
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF8B4513),
                      child: Text('${step.stepNumber}'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Instructions
                if (step.instructions.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Instructions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            step.instructions,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Video segment
                if (step.videoSegment != null)
                  ElevatedButton.icon(
                    onPressed: _playVideoSegment,
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Watch Video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B4513),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Timers
                if (step.timers.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Timers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: step.timers.map((timer) {
                          return ElevatedButton.icon(
                            onPressed: () => _startTimer(timer),
                            icon: const Icon(Icons.timer, size: 18),
                            label: Text(
                              '${timer.name} (${_formatTimerTime(timer.durationSeconds)})',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown.shade100,
                              foregroundColor: Colors.black,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),

                // Pictures
                if (step.pictures.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pictures',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: step.pictures.length,
                          itemBuilder: (context, index) {
                            final pic = step.pictures[index];
                            return Container(
                              width: 200,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(pic.url),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                // Notes
                if (step.notes.isNotEmpty)
                  Card(
                    color: Colors.yellow.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.note, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Notes',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(step.notes),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // Navigation buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _currentStepIndex > 0 ? _previousStep : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B4513),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed:
                          _currentStepIndex < widget.recipe.steps.length - 1
                          ? _nextStep
                          : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B4513),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ActiveTimer {
  final String name;
  final int totalSeconds;
  int remainingSeconds;
  Timer? timer;

  ActiveTimer({
    required this.name,
    required this.totalSeconds,
    required this.remainingSeconds,
  });

  void cancel() {
    timer?.cancel();
  }
}
