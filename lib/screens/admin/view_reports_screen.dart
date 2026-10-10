import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../db/db_helper.dart';
import '../../models/models.dart';

class ViewReportsScreen extends StatefulWidget {
  const ViewReportsScreen({super.key});
  @override
  State<ViewReportsScreen> createState() => _ViewReportsScreenState();
}

class _ViewReportsScreenState extends State<ViewReportsScreen> {
  List<Report> _reports = [];
  bool _loading = true;
  final _player = AudioPlayer();
  int? _playingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final reports = await DBHelper.instance.getReports();
    setState(() {
      _reports = reports;
      _loading = false;
    });
  }

  Future<void> _playAudio(Report r) async {
    if (r.audioPath == null) return;
    if (_playingId == r.id) {
      await _player.stop();
      setState(() => _playingId = null);
    } else {
      await _player.play(DeviceFileSource(r.audioPath!));
      setState(() => _playingId = r.id);
      _player.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playingId = null);
      });
    }
  }

  Future<void> _delete(Report r) async {
    await DBHelper.instance.deleteReport(r.id!);
    _load();
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'Bus breakdown':
        return AppColors.danger;
      case 'Overcrowding':
        return AppColors.accent;
      case 'Driver complaint':
        return const Color(0xFF7A5CFF);
      default:
        return AppColors.secondary;
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Passenger Reports')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? const EmptyState(icon: Icons.inbox_outlined, title: 'No reports', subtitle: 'Passenger issue reports will appear here.')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final r = _reports[i];
                    return SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              StatusChip(label: r.issueType, color: _colorFor(r.issueType)),
                              const Spacer(),
                              Text(r.reportTime, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                              IconButton(
                                onPressed: () => _delete(r),
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(r.description, style: const TextStyle(fontSize: 13)),
                          if (r.photoPath != null) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              child: Image.file(File(r.photoPath!), height: 140, width: double.infinity, fit: BoxFit.cover),
                            ),
                          ],
                          if (r.audioPath != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => _playAudio(r),
                                  icon: Icon(
                                    _playingId == r.id ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                                    color: AppColors.primary,
                                    size: 30,
                                  ),
                                ),
                                const Text('Voice message', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text('${r.lat.toStringAsFixed(4)}, ${r.lng.toStringAsFixed(4)}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
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
