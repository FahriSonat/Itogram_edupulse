import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';

/// Kriz yayını gönderim geri çağrısı.
///
/// [targetId] seçilen hedefin anahtarıdır (ör. `all_campus` veya bir `courseId`;
/// FCM topic adı buradan türetilir), [targetLabel] ise ekranda görünen adıdır.
typedef CrisisBroadcastCallback = Future<void> Function({
  required String targetId,
  required String targetLabel,
  required String title,
  required String message,
});

/// [CrisisBroadcastBottomSheet] eğitmenin **Duyuru / Anlık Kriz Yayını** kontrol panelidir.
///
/// Eğitmen hedef ders/sınıfı seçer, başlık ve mesajı yazar; tek tuşla anlık
/// FCM push bildirimi fırlatılır. Yazılan bildirim canlı önizlemede görünür.
class CrisisBroadcastBottomSheet extends StatefulWidget {
  const CrisisBroadcastBottomSheet({super.key, required this.targets, required this.onBroadcast});

  /// Hedef kimliği → görünen ad (ör. `{'all_campus': 'Tüm Kampüs', 'c101': 'Flutter'}`).
  /// İlk eleman varsayılan seçimdir.
  final Map<String, String> targets;
  final CrisisBroadcastCallback onBroadcast;

  static Future<void> show(
    BuildContext context, {
    required Map<String, String> targets,
    required CrisisBroadcastCallback onBroadcast,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: CrisisBroadcastBottomSheet(targets: targets, onBroadcast: onBroadcast),
      ),
    );
  }

  @override
  State<CrisisBroadcastBottomSheet> createState() => _CrisisBroadcastBottomSheetState();
}

class _CrisisBroadcastBottomSheetState extends State<CrisisBroadcastBottomSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  late String? _selectedTarget = widget.targets.isEmpty ? null : widget.targets.keys.first;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Önizleme yazdıkça güncellenir.
    _titleController.addListener(_onTextChanged);
    _messageController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleBroadcast() async {
    final target = _selectedTarget;
    if (target == null || !(_formKey.currentState?.validate() ?? false)) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _isLoading = true);
    try {
      await widget.onBroadcast(
        targetId: target,
        targetLabel: widget.targets[target] ?? target,
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
      );
      if (!mounted) return;
      navigator.pop();
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('Acil Kriz Bildirimi hedef kitleye fırlatıldı!'),
          backgroundColor: AppColors.criticalAbsenceRed,
        ),
      );
    } catch (e) {
      if (mounted) {
        messenger?.showSnackBar(SnackBar(content: Text(_readableError(e))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static String _readableError(Object e) {
    final text = e.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      padding: AppDimensions.paddingAll24,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.r24)),
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SheetHandle(),
                const SizedBox(height: AppDimensions.p16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.p10),
                      decoration: BoxDecoration(
                        color: AppColors.criticalAbsenceRed.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.campaign_rounded, color: AppColors.criticalAbsenceRed, size: 24),
                    ),
                    const SizedBox(width: AppDimensions.p12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Duyuru / Anlık Kriz Yayını',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 18),
                          ),
                          Text(
                            'Tek tuşla anlık FCM push bildirimi gönderin',
                            style: TextStyle(fontSize: 12, color: muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.p20),
                DropdownButtonFormField<String>(
                  initialValue: _selectedTarget,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Hedef Kitle / Ders'),
                  validator: (v) => v == null ? 'Hedef seçiniz' : null,
                  items: [
                    for (final entry in widget.targets.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (val) => setState(() => _selectedTarget = val),
                ),
                const SizedBox(height: AppDimensions.p12),
                TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  maxLength: 80,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Başlık zorunludur' : null,
                  decoration: const InputDecoration(
                    labelText: 'Kriz Başlığı',
                    hintText: 'Örn: Hava Muhalefeti Nedeniyle Ders İptali',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: AppDimensions.p12),
                TextFormField(
                  controller: _messageController,
                  maxLines: 3,
                  maxLength: 240,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Mesaj boş bırakılamaz' : null,
                  decoration: const InputDecoration(
                    labelText: 'Bildirim Metni',
                    hintText: 'Öğrencilere anında iletilecek bildirim metnini yazınız...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppDimensions.p12),
                _PushPreview(
                  title: _titleController.text.trim(),
                  message: _messageController.text.trim(),
                  target: _selectedTarget == null ? '' : (widget.targets[_selectedTarget] ?? ''),
                ),
                const SizedBox(height: AppDimensions.p20),
                ElevatedButton.icon(
                  onPressed: _isLoading || _selectedTarget == null ? null : _handleBroadcast,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                  label: Text(_isLoading ? 'Gönderiliyor...' : 'Anlık Kriz Bildirimini Fırlat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.criticalAbsenceRed,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Telefonda görünecek push bildiriminin canlı önizlemesi.
class _PushPreview extends StatelessWidget {
  const _PushPreview({required this.title, required this.message, required this.target});

  final String title;
  final String message;
  final String target;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      padding: AppDimensions.paddingAll12,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
        borderRadius: AppDimensions.radius16,
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.criticalAbsenceRed,
              borderRadius: BorderRadius.circular(AppDimensions.r8),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: AppDimensions.p10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppStrings.appName} • $target',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: muted),
                ),
                const SizedBox(height: 2),
                Text(
                  title.isEmpty ? 'Bildirim başlığı' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                Text(
                  message.isEmpty ? 'Bildirim metni burada görünecek.' : message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          borderRadius: AppDimensions.radiusFull,
        ),
      ),
    );
  }
}
