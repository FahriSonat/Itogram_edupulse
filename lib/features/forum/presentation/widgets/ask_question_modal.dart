import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Soru gönderme geri çağrısı — alanlar `ForumQuestionEntity` ile aynıdır.
typedef AskQuestionCallback = Future<void> Function({
  required String courseTag,
  required String topicTag,
  required String questionText,
  String? localPhotoPath,
});

/// Fotoğraf seçici: seçilen dosyanın yerel yolunu döndürür (iptalde null).
typedef PhotoPickCallback = Future<String?> Function();

/// [AskQuestionModal] **Kamera / Galeri fotoğraf seçicili** ve ders/konu etiketli
/// soru sorma penceresidir.
///
/// Fotoğraf seçimi [onPickFromCamera] / [onPickFromGallery] üzerinden
/// `FilePickerService`'e bağlanır; ikisi birden verilirse kullanıcıya kaynak sorulur.
class AskQuestionModal extends StatefulWidget {
  const AskQuestionModal({
    super.key,
    required this.courseTags,
    required this.onAskQuestion,
    this.onPickFromCamera,
    this.onPickFromGallery,
    this.topicSuggestions = const [],
  });

  final List<String> courseTags;
  final AskQuestionCallback onAskQuestion;
  final PhotoPickCallback? onPickFromCamera;
  final PhotoPickCallback? onPickFromGallery;

  /// Konu alanının altında dokunulabilir öneri çipleri.
  final List<String> topicSuggestions;

  static Future<void> show(
    BuildContext context, {
    required List<String> courseTags,
    required AskQuestionCallback onAskQuestion,
    PhotoPickCallback? onPickFromCamera,
    PhotoPickCallback? onPickFromGallery,
    List<String> topicSuggestions = const [],
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: AskQuestionModal(
          courseTags: courseTags,
          onAskQuestion: onAskQuestion,
          onPickFromCamera: onPickFromCamera,
          onPickFromGallery: onPickFromGallery,
          topicSuggestions: topicSuggestions,
        ),
      ),
    );
  }

  @override
  State<AskQuestionModal> createState() => _AskQuestionModalState();
}

enum _PhotoSource { camera, gallery }

class _AskQuestionModalState extends State<AskQuestionModal> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  final _questionController = TextEditingController();
  late String? _selectedCourse = widget.courseTags.isEmpty ? null : widget.courseTags.first;
  String? _selectedPhotoPath;
  bool _isLoading = false;

  bool get _canPickPhoto => widget.onPickFromCamera != null || widget.onPickFromGallery != null;

  @override
  void dispose() {
    _topicController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _handlePickPhoto() async {
    _PhotoSource? source;
    if (widget.onPickFromCamera != null && widget.onPickFromGallery != null) {
      source = await showModalBottomSheet<_PhotoSource>(
        context: context,
        // Zemin Material ile verilir; ListTile dalgalanması (ripple) görünür kalır.
        builder: (ctx) => Material(
          color: Theme.of(ctx).colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.r20)),
          ),
          child: SafeArea(
            minimum: const EdgeInsets.symmetric(vertical: AppDimensions.p8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Kamera ile Çek'),
                  onTap: () => Navigator.pop(ctx, _PhotoSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Galeriden Seç'),
                  onTap: () => Navigator.pop(ctx, _PhotoSource.gallery),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (widget.onPickFromCamera != null) {
      source = _PhotoSource.camera;
    } else if (widget.onPickFromGallery != null) {
      source = _PhotoSource.gallery;
    }
    if (source == null || !mounted) return;

    final picker = source == _PhotoSource.camera ? widget.onPickFromCamera : widget.onPickFromGallery;
    final path = await picker?.call();
    if (path != null && mounted) setState(() => _selectedPhotoPath = path);
  }

  Future<void> _handleSubmit() async {
    final course = _selectedCourse;
    if (course == null || !(_formKey.currentState?.validate() ?? false)) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _isLoading = true);
    try {
      await widget.onAskQuestion(
        courseTag: course,
        topicTag: _topicController.text.trim(),
        questionText: _questionController.text.trim(),
        localPhotoPath: _selectedPhotoPath,
      );
      if (mounted) navigator.pop();
    } catch (e) {
      if (mounted) messenger?.showSnackBar(SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                Text(
                  'Soru Sor & Danış',
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppDimensions.p16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCourse,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Ders Etiketi', prefixIcon: Icon(Icons.sell_outlined)),
                  validator: (v) => v == null ? 'Ders etiketi seçiniz' : null,
                  items: [
                    for (final c in widget.courseTags)
                      DropdownMenuItem(
                        value: c,
                        child: Text(c, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (val) => setState(() => _selectedCourse = val),
                ),
                const SizedBox(height: AppDimensions.p12),
                TextFormField(
                  key: const ValueKey('topic_field'),
                  controller: _topicController,
                  textInputAction: TextInputAction.next,
                  maxLength: 40,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Konu etiketi gerekli' : null,
                  decoration: const InputDecoration(
                    labelText: 'Konu Etiketi',
                    hintText: 'Örn: Bloc Pattern',
                    prefixIcon: Icon(Icons.tag_rounded),
                    counterText: '',
                  ),
                ),
                if (widget.topicSuggestions.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.p8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final t in widget.topicSuggestions)
                        ActionChip(
                          label: Text(t, style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => setState(() => _topicController.text = t),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppDimensions.p12),
                TextFormField(
                  key: const ValueKey('question_field'),
                  controller: _questionController,
                  maxLines: 4,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Soru açıklaması zorunludur' : null,
                  decoration: const InputDecoration(
                    labelText: 'Sorunuzu Detaylandırın',
                    hintText: 'Anlamadığınız satırı veya hatayı buraya yazınız...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppDimensions.p12),
                if (_selectedPhotoPath != null)
                  Container(
                    padding: AppDimensions.paddingAll8,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : const Color(0xFFF1F5F9),
                      borderRadius: AppDimensions.radius12,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.image_outlined, color: AppColors.secondaryLight, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedPhotoPath!.split(RegExp(r'[\\/]')).last,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          tooltip: 'Fotoğrafı kaldır',
                          onPressed: () => setState(() => _selectedPhotoPath = null),
                        ),
                      ],
                    ),
                  )
                else if (_canPickPhoto)
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handlePickPhoto,
                    icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                    label: const Text('Fotoğraf Ekle (Kamera / Galeri)'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(AppDimensions.buttonHeightSm)),
                  ),
                const SizedBox(height: AppDimensions.p20),
                ElevatedButton(
                  onPressed: _isLoading || _selectedCourse == null ? null : _handleSubmit,
                  child: Text(_isLoading ? 'Gönderiliyor...' : 'Soruyu Kampüs Forumuna Gönder'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
