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
import '../components/video_thumbnail_widget.dart';

class AddMediaScreen extends StatefulWidget {
  const AddMediaScreen({super.key});

  @override
  State<AddMediaScreen> createState() => _AddMediaScreenState();
}

class _AddMediaScreenState extends State<AddMediaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<File> _selectedFiles = [];
  Map<int, String> _customTitles = {};

  bool _isUploading = false;
  bool _isPickingFile = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = "";
  final MinioService _minioService = MinioService();

  Future<void> _pickVideo() async {
    if (_isPickingFile || _isUploading) return;

    if (Platform.isAndroid || Platform.isIOS) {
      if (await Permission.videos.request().isGranted ||
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
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mp3', 'mov', 'wav', 'm4a', 'mkv'],
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

  MediaModel _createMediaModel(
    String url,
    String title,
    String pathToCheck,
    int index,
  ) {
    String detectedCategory = 'Media';
    final extension = p.extension(pathToCheck).toLowerCase();

    if (extension == '.mp3' || extension == '.wav' || extension == '.m4a') {
      detectedCategory = 'Songs';
    } else if (extension == '.mp4' ||
        extension == '.mov' ||
        extension == '.mkv') {
      detectedCategory = 'Movies';
    }

    return MediaModel(
      id: '${DateTime.now().millisecondsSinceEpoch}_$index',
      title: title,
      url: url,
      description: _descriptionController.text,
      category: detectedCategory,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);
    final provider = Provider.of<MediaProvider>(context, listen: false);

    try {
      if (_selectedFiles.isNotEmpty) {
        for (int i = 0; i < _selectedFiles.length; i++) {
          final file = _selectedFiles[i];
          if (mounted) {
            setState(() {
              _uploadStatus = "Uploading ${i + 1} of ${_selectedFiles.length}";
              _uploadProgress = 0.0;
            });
          }

          final url = await _minioService.uploadVideo(
            file,
            onProgress: (p) {
              if (mounted) setState(() => _uploadProgress = p);
            },
          );

          final title =
              _selectedFiles.length == 1 && _titleController.text.isNotEmpty
              ? _titleController.text
              : (_customTitles[i] ?? p.basenameWithoutExtension(file.path));

          provider.addMedia(_createMediaModel(url, title, file.path, i));
        }
      } else {
        provider.addMedia(
          _createMediaModel(
            _urlController.text,
            _titleController.text,
            _urlController.text,
            0,
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Media', style: GoogleFonts.outfit()),
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
                    'Media Details',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: _pickVideo,
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
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _titleController,
                    label: 'Title',
                    hint: 'Enter title (optional for multiple)',
                    icon: Icons.title,
                    validator: (v) => (_selectedFiles.length <= 1 && v!.isEmpty)
                        ? 'Enter a title'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  if (_selectedFiles.isEmpty)
                    _buildTextField(
                      controller: _urlController,
                      label: 'Or Video URL',
                      hint: 'https://example.com/video.mp4',
                      icon: Icons.link,
                      validator: (v) => (_selectedFiles.isEmpty && v!.isEmpty)
                          ? 'Enter URL or pick files'
                          : null,
                    ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Short description...',
                    icon: Icons.description,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 50),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
          if (_isUploading) _buildUploadOverlay(),
        ],
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
              ? Icons.video_library
              : Icons.cloud_upload_outlined,
          size: 50,
          color: _selectedFiles.isNotEmpty ? Colors.redAccent : Colors.grey,
        ),
        const SizedBox(height: 10),
        Text(
          _selectedFiles.isNotEmpty
              ? '${_selectedFiles.length} Files Selected'
              : 'Tap to pick media (Multiple)',
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
          final extension = p.extension(file.path).toLowerCase();
          final isVideo = ['.mp4', '.mov', '.mkv'].contains(extension);

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
                    // Thumbnail / Icon
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 80,
                        height: 50,
                        color: Colors.black26,
                        child: isVideo
                            ? VideoThumbnailWidget(videoUrl: file.path)
                            : const Icon(
                                Icons.audiotrack_rounded,
                                color: Colors.redAccent,
                              ),
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
                        // Re-map titles
                        final newTitles = <int, String>{};
                        _customTitles.forEach((key, value) {
                          if (key > index)
                            newTitles[key - 1] = value;
                          else if (key < index)
                            newTitles[key] = value;
                        });
                        _customTitles = newTitles;
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Individual Title Edit
                TextField(
                  onChanged: (val) => _customTitles[index] = val,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Custom title for this file...',
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: Colors.white38,
                    ),
                  ),
                  controller: TextEditingController(text: _customTitles[index])
                    ..selection = TextSelection.fromPosition(
                      TextPosition(offset: (_customTitles[index] ?? "").length),
                    ),
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
          'Save & Upload',
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.grey),
        hintStyle: const TextStyle(color: Colors.white24),
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
