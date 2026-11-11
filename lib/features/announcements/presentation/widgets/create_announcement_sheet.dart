import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/enums/announcement_type.dart';
import 'announcement_card.dart';

typedef CreateAnnouncementCallback = Future<void> Function({
  required String title,
  required String content,
  required AnnouncementType type,
  required DateTime eventDate,
  required String targetCourse,
});

/// [CreateAnnouncementSheet] eğitmenin seminer / hackathon / tatil duyurusu yayınladığı form.
/// Anlık kriz bildirimi için [CrisisBroadcastBottomSheet] kullanılır.
class CreateAnnouncementSheet extends StatefulWidget {
  const CreateAnnouncementSheet({super.key, required this.targets, required this.onCreate});

  final List<String> targets;
  final CreateAnnouncementCallback onCreate;

  static Future<void> show(
    BuildContext context, {
    required List<String> targets,
    required CreateAnnouncementCallback onCreate,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: CreateAnnouncementSheet(targets: targets, onCreate: onCreate),
      ),
    );
  }

  @override
  State<CreateAnnouncementSheet> createState() => _CreateAnnouncementSheetState();
}

class _CreateAnnouncementSheetState extends State<CreateAnnouncementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  AnnouncementType _type = AnnouncementType.seminar;
  late String _target = widget.targets.first;
  DateTime _eventDate = DateTime.now().add(const Duration(days: 3));
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  static String _formatDateTime(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_eventDate));
    setState(() {
      _eventDate = DateTime(picked.year, picked.month, picked.day, time?.hour ?? 10, time?.minute ?? 0);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await widget.onCreate(
        title: _titleController.text,
        content: _contentController.text,
        type: _type,
        eventDate: _eventDate,
        targetCourse: _target,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: AppDimensions.paddingAll24,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.r24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: AppDimensions.radiusFull,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.p16),
              const Text('Yeni Duyuru / Etkinlik', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppDimensions.p16),
              Wrap(
                spacing: 8,
                children: [
                  for (final t in AnnouncementType.values.where((t) => t != AnnouncementType.crisis))
                    ChoiceChip(
                      avatar: Icon(announcementTypeIcon(t), size: 16, color: AppColors.forAnnouncementType(t)),
                      label: Text(AppStrings.announcementType(t)),
                      selected: _type == t,
                      onSelected: (_) => setState(() => _type = t),
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.p12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Başlık'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Başlık zorunludur' : null,
              ),
              const SizedBox(height: AppDimensions.p12),
              TextFormField(
                controller: _contentController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Açıklama'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Açıklama zorunludur' : null,
              ),
              const SizedBox(height: AppDimensions.p12),
              DropdownButtonFormField<String>(
                initialValue: _target,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Hedef Kitle'),
                items: [for (final t in widget.targets) DropdownMenuItem(value: t, child: Text(t))],
                onChanged: (v) {
                  if (v != null) setState(() => _target = v);
                },
              ),
              const SizedBox(height: AppDimensions.p12),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event_rounded),
                label: Text('Etkinlik tarihi: ${_formatDateTime(_eventDate)}'),
              ),
              const SizedBox(height: AppDimensions.p20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: Text(_isLoading ? 'Yayınlanıyor...' : 'Duyuruyu Yayınla'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
