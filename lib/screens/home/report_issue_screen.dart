import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../db/db_helper.dart';
import '../../models/models.dart';
import '../../providers/session_provider.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});
  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _description = TextEditingController();
  final _picker = ImagePicker();
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  String _issueType = 'Bus breakdown';
  final _issueTypes = ['Bus breakdown', 'Overcrowding', 'Driver complaint', 'Dirty bus', 'Damaged bus stop', 'Other'];

  File? _photo;
  String? _audioPath;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _submitting = false;
  bool _submitted = false;

  Future<void> _capturePhoto() async {
    final img = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (img != null) setState(() => _photo = File(img.path));
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
        _audioPath = path;
      });
    } else {
      if (await _recorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/complaint_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(const RecordConfig(), path: path);
        setState(() => _isRecording = true);
      }
    }
  }

  Future<void> _playAudio() async {
    if (_audioPath == null) return;
    if (_isPlaying) {
      await _player.stop();
      setState(() => _isPlaying = false);
    } else {
      await _player.play(DeviceFileSource(_audioPath!));
      setState(() => _isPlaying = true);
      _player.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlaying = false);
      });
    }
  }

  Future<void> _submit() async {
    if (_description.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a description')));
      return;
    }
    setState(() => _submitting = true);
    double lat = 0, lng = 0;
    try {
      final pos = await Geolocator.getCurrentPosition();
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (_) {}

    final user = context.read<SessionProvider>().currentUser;
    final report = Report(
      userId: user?.id ?? 0,
      photoPath: _photo?.path,
      audioPath: _audioPath,
      description: _description.text.trim(),
      issueType: _issueType,
      lat: lat,
      lng: lng,
      reportTime: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
    );
    await DBHelper.instance.addReport(report);
    setState(() {
      _submitting = false;
      _submitted = true;
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report Issue')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const EmptyState(
                icon: Icons.check_circle_outline_rounded,
                title: 'Report submitted',
                subtitle: 'Thanks for helping us improve the service. Our team will review your report shortly.',
              ),
              const Spacer(),
              GradientButton(label: 'Done', onTap: () => Navigator.of(context).pop()),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Report an Issue')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Issue type', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _issueTypes
                  .map((t) => ChoiceChip(
                        label: Text(t),
                        selected: _issueType == t,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                            color: _issueType == t ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w600),
                        onSelected: (_) => setState(() => _issueType = t),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            const Text('Description', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            TextField(
              controller: _description,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Describe the issue in detail...'),
            ),
            const SizedBox(height: 20),
            const Text('Attach photo', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _capturePhoto,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: AppShadows.card,
                ),
                child: _photo == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 34),
                          SizedBox(height: 8),
                          Text('Tap to capture photo', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Image.file(_photo!, fit: BoxFit.cover, width: double.infinity),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Voice message', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            SoftCard(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _toggleRecording,
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        gradient: _isRecording
                            ? const LinearGradient(colors: [Color(0xFFFF5A6E), Color(0xFFFF8A65)])
                            : AppColors.cardGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_isRecording ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _isRecording
                          ? 'Recording...'
                          : (_audioPath != null ? 'Voice message recorded' : 'Tap mic to record complaint'),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  if (_audioPath != null && !_isRecording)
                    IconButton(
                      onPressed: _playAudio,
                      icon: Icon(_isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                          color: AppColors.primary, size: 32),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            GradientButton(
              label: 'Submit Report',
              icon: Icons.send_rounded,
              onTap: _submit,
              loading: _submitting,
              gradient: const LinearGradient(colors: [Color(0xFFFF5A6E), Color(0xFFFF8A65)]),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
