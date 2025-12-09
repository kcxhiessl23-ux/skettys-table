import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'recipe_model.dart';
import 'video_segment_picker.dart';

class StepEditorScreen extends StatefulWidget {
  final RecipeStep step;
  final int stepIndex;

  const StepEditorScreen({
    super.key,
    required this.step,
    required this.stepIndex,
  });

  @override
  State<StepEditorScreen> createState() => _StepEditorScreenState();
}

class _StepEditorScreenState extends State<StepEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _instructionsController;
  late TextEditingController _notesController;

  late List<StepPicture> _pictures;
  VideoSegment? _videoSegment;
  late List<StepTimer> _timers;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.step.title);
    _instructionsController = TextEditingController(
      text: widget.step.instructions,
    );
    _notesController = TextEditingController(text: widget.step.notes);
    _pictures = List.from(widget.step.pictures);
    _videoSegment = widget.step.videoSegment;
    _timers = List.from(widget.step.timers);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addPicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _isLoading = true);

      final ref = FirebaseStorage.instance
          .ref()
          .child('stepImages')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      await ref.putFile(File(pickedFile.path));
      final url = await ref.getDownloadURL();

      setState(() {
        _pictures.add(StepPicture(url: url, caption: ''));
        _isLoading = false;
      });
    }
  }

  Future<void> _addVideoSegment() async {
    final segment = await Navigator.push<VideoSegment>(
      context,
      MaterialPageRoute(
        builder: (_) => VideoSegmentPicker(existingSegment: _videoSegment),
      ),
    );

    if (segment != null) {
      setState(() => _videoSegment = segment);
    }
  }

  void _addTimer() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final durationController = TextEditingController();

        return AlertDialog(
          title: const Text('Add Timer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Timer Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (seconds)',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    durationController.text.isNotEmpty) {
                  setState(() {
                    _timers.add(
                      StepTimer(
                        name: nameController.text,
                        durationSeconds: int.parse(durationController.text),
                      ),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _saveStep() {
    final updatedStep = RecipeStep(
      stepNumber: widget.stepIndex + 1,
      title: _titleController.text,
      instructions: _instructionsController.text,
      notes: _notesController.text,
      pictures: _pictures,
      videoSegment: _videoSegment,
      timers: _timers,
    );

    Navigator.pop(context, updatedStep);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Step ${widget.stepIndex + 1}'),
        backgroundColor: const Color(0xFF8B4513),
        actions: [
          TextButton(
            onPressed: _saveStep,
            child: const Text(
              'Done',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Title
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Step Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Instructions
                TextField(
                  controller: _instructionsController,
                  decoration: const InputDecoration(
                    labelText: 'Instructions',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),

                // Notes
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Pictures Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pictures',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _addPicture,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B4513),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_pictures.isNotEmpty)
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _pictures.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(_pictures[index].url),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 12,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: () =>
                                    setState(() => _pictures.removeAt(index)),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.all(4),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 24),

                // Video Segment Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Video Segment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _addVideoSegment,
                      icon: const Icon(Icons.videocam),
                      label: Text(_videoSegment == null ? 'Add' : 'Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B4513),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                if (_videoSegment != null)
                  Card(
                    margin: const EdgeInsets.only(top: 8),
                    child: ListTile(
                      leading: const Icon(Icons.play_circle_outline),
                      title: Text(
                        '${_videoSegment!.startTimeSeconds}s - ${_videoSegment!.endTimeSeconds}s',
                      ),
                      subtitle: Text(_videoSegment!.url),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => setState(() => _videoSegment = null),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Timers Section
                // Notes for the Time Section - Kenny
                //  Add hh/mm/ss in wheel style picker for smooth tablet interface
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Timers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _addTimer,
                      icon: const Icon(Icons.timer),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B4513),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._timers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final timer = entry.value;
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.timer),
                      title: Text(timer.name),
                      subtitle: Text(
                        '${timer.durationSeconds ~/ 60}:${(timer.durationSeconds % 60).toString().padLeft(2, '0')}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            setState(() => _timers.removeAt(index)),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
    );
  }
}
