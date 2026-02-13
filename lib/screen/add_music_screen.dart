import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/media_model.dart';
import '../services/media_provider.dart';
import '../services/minio_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

class AddMusicScreen extends StatefulWidget {
  const AddMusicScreen({super.key});

  @override
  State<AddMusicScreen> createState() => _AddMusicScreenState();
}

class _AddMusicScreenState extends State<AddMusicScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<File> _selectedFiles = [];
  Map<int, String> _customTitles = {};

  bool _isUploading = false;
  bool _isPickingFile = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = "";
  final MinioService _minioService = MinioService();

  Future<void> _pickMusic() async {
    if (_isPickingFile || _isUploading) return;

    if (Platform.isAndroid || Platform.isIOS) {
      if (await Permission.audio.request().isGranted ||
          await Permission.storage.request().isGranted) {
        _executePicker();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission is required')),
          );
        }
      }
    } else {
      _executePicker();
    }
  }

  Future<void> _executePicker() async {
    if (_isPickingFile) return;
    setState(() => _isPickingFile = true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          for (var path in result.paths.whereType<String>()) {
            final file = File(path);
            _selectedFiles.add(file);
            _customTitles[_selectedFiles.length - 1] = p
                .basenameWithoutExtension(path);
          }
          if (_selectedFiles.length == 1 && _titleController.text.isEmpty) {
            _titleController.text = _customTitles[0]!;
          }
        });
      }
    } catch (e) {
      debugPrint('File picker error: $e');
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select music files')),
      );
      return;
    }

    setState(() => _isUploading = true);
    final provider = Provider.of<MediaProvider>(context, listen: false);

    try {
      final totalSize = _selectedFiles.fold<int>(
        0,
        (sum, file) => sum + file.lengthSync(),
      );
      int totalUploadedSoFar = 0;

      for (int i = 0; i < _selectedFiles.length; i++) {
        final file = _selectedFiles[i];
        final fileName = p.basename(file.path);

        if (mounted) {
          setState(() {
            _uploadStatus =
                "Uploading $fileName (${i + 1}/${_selectedFiles.length})";
          });
        }

        DateTime lastUpdate = DateTime.now();
        final url = await _minioService.uploadVideo(
          // Reusing uploadVideo as it handles generic putObject
          file,
          onProgress: (p) {
            final now = DateTime.now();
            if (now.difference(lastUpdate).inMilliseconds > 100 || p == 1.0) {
              lastUpdate = now;
              if (mounted) {
                setState(() {
                  final currentFileProgress = (p * file.lengthSync()).toInt();
                  _uploadProgress =
                      (totalUploadedSoFar + currentFileProgress) / totalSize;
                });
              }
            }
          },
        );

        totalUploadedSoFar += file.lengthSync();

        final title =
            _selectedFiles.length == 1 && _titleController.text.isNotEmpty
            ? _titleController.text
            : (_customTitles[i] ?? p.basenameWithoutExtension(file.path));

        provider.addMedia(
          MediaModel(
            id: '${DateTime.now().millisecondsSinceEpoch}_$i',
            title: title,
            url: url,
            description: _descriptionController.text,
            category: 'Songs',
          ),
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Add New Music', style: GoogleFonts.outfit()),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Music Details',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 30),
                    GestureDetector(
                      onTap: _pickMusic,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: _selectedFiles.isNotEmpty
                                ? Colors.redAccent
                                : Colors.grey[700]!,
                            width: 2,
                          ),
                        ),
                        child: _isPickingFile
                            ? _buildPickerLoading()
                            : _buildPickerPlaceholder(),
                      ),
                    ),
                    if (_selectedFiles.isNotEmpty) _buildSelectedFilesList(),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _titleController,
                      label: 'Album/Playlist Name',
                      hint: 'Enter title (optional for multiple)',
                      icon: Icons.library_music_rounded,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Artist or Album details...',
                      icon: Icons.description,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 50),
                    _buildSubmitButton(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            if (_isUploading) _buildUploadOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerLoading() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: Colors.redAccent),
        const SizedBox(height: 15),
        Text('Processing...', style: GoogleFonts.outfit(color: Colors.white70)),
      ],
    );
  }

  Widget _buildPickerPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _selectedFiles.isNotEmpty
              ? Icons.audiotrack_rounded
              : Icons.music_note_rounded,
          size: 50,
          color: _selectedFiles.isNotEmpty ? Colors.redAccent : Colors.grey,
        ),
        const SizedBox(height: 10),
        Text(
          _selectedFiles.isNotEmpty
              ? '${_selectedFiles.length} Music Files Selected'
              : 'Tap to pick Music (Multiple)',
          style: GoogleFonts.outfit(
            color: _selectedFiles.isNotEmpty ? Colors.white : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedFilesList() {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _selectedFiles.length,
        itemBuilder: (context, index) {
          final file = _selectedFiles[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.music_note_rounded,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.basename(file.path),
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${(file.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB',
                            style: GoogleFonts.outfit(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 22,
                      ),
                      onPressed: () => setState(() {
                        _selectedFiles.removeAt(index);
                        _customTitles.remove(index);
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (val) => _customTitles[index] = val,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Song Title...',
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  controller: TextEditingController(text: _customTitles[index]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isUploading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          'Upload Music',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildUploadOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 120,
                  width: 120,
                  child: CircularProgressIndicator(
                    value: _uploadProgress,
                    color: Colors.redAccent,
                    strokeWidth: 10,
                    backgroundColor: Colors.white12,
                  ),
                ),
                Text(
                  "${(_uploadProgress * 100).toInt()}%",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              _uploadStatus,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.redAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    );
  }
}
