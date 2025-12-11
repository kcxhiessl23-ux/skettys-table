import 'package:flutter/material.dart';
import 'media_model.dart';
import 'firestore_service.dart';

class UploadMediaScreen extends StatefulWidget {
  final String mediaType; // 'photo' or 'video'

  const UploadMediaScreen({super.key, required this.mediaType});

  @override
  State<UploadMediaScreen> createState() => _UploadMediaScreenState();
}

class _UploadMediaScreenState extends State<UploadMediaScreen> {
  final _firestoreService = FirestoreService();
  final _nameController = TextEditingController();
  final _tagsController = TextEditingController();

  String? _fileUrl;
  bool _isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    // For web testing, use placeholder
    setState(() {
      _fileUrl = widget.mediaType == 'video'
          ? 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'
          : 'https://picsum.photos/400/300?random=${DateTime.now().millisecondsSinceEpoch}';
    });
  }

  Future<void> _saveMedia() async {
    if (_fileUrl == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a file')));
      return;
    }

    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a name')));
      return;
    }

    setState(() => _isUploading = true);

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final media = MediaItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: _fileUrl!,
      type: widget.mediaType,
      name: _nameController.text,
      tags: tags,
      uploadedAt: DateTime.now(),
    );

    await _firestoreService.saveMedia(media);

    setState(() => _isUploading = false);

    if (mounted) {
      Navigator.pop(context, true); // Return true to indicate success
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Upload ${widget.mediaType == 'video' ? 'Video' : 'Photo'}',
        ),
        backgroundColor: const Color(0xFF8B4513),
      ),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // File preview
                  if (_fileUrl != null)
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade200,
                      ),
                      child: widget.mediaType == 'photo'
                          ? Image.network(_fileUrl!, fit: BoxFit.cover)
                          : const Center(
                              child: Icon(
                                Icons.videocam,
                                size: 80,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  const SizedBox(height: 20),

                  // Pick file button
                  ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: Icon(
                      widget.mediaType == 'video'
                          ? Icons.videocam
                          : Icons.photo,
                    ),
                    label: Text(
                      _fileUrl == null ? 'Select File' : 'Change File',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B4513),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Name field
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'e.g., Pasta Making Technique',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tags field
                  TextField(
                    controller: _tagsController,
                    decoration: const InputDecoration(
                      labelText: 'Tags (comma separated)',
                      hintText: 'e.g., italian, pasta, technique',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  ElevatedButton(
                    onPressed: _saveMedia,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B4513),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
    );
  }
}
