import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<Map<String, dynamic>> _albums = [];
  bool _loading = true;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService().get('/albums');
      setState(() {
        _albums = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _isConnected = true;
      });
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('커플이 연결되지')) {
        setState(() => _isConnected = false);
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  // Cloudinary URL이 file_path에 바로 저장됨
  String _photoUrl(String url) => url;

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddAlbumSheet(
        onSaved: () {
          Navigator.pop(context);
          _loadAlbums();
        },
      ),
    );
  }

  void _openDetail(Map<String, dynamic> album) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AlbumDetailScreen(
          album: album,
          photoUrl: _photoUrl,
          onDeleted: () {
            Navigator.pop(context);
            _loadAlbums();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.primary,
            title: const Text(
              '사진첩',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: Container(
              decoration: const BoxDecoration(gradient: AppColors.gradient),
            ),
          ),

          if (_loading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (!_isConnected)
            SliverFillRemaining(
              child: _EmptyState(
                icon: '💕',
                title: '아직 연결이 안 됐어요',
                subtitle: '설정에서 파트너와 연결하면\n함께 추억을 쌓을 수 있어요',
              ),
            )
          else if (_albums.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(
                icon: '📷',
                title: '첫 번째 추억을 남겨보세요',
                subtitle: '사진과 함께 소중한 순간을\n기록해보세요',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _AlbumCard(
                    album: _albums[i],
                    photoUrl: _photoUrl,
                    onTap: () => _openDetail(_albums[i]),
                  ),
                  childCount: _albums.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: (!_loading && _isConnected)
          ? FloatingActionButton(
              onPressed: _openAddSheet,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

// ── 앨범 카드 ────────────────────────────────────────────────────────────────

class _AlbumCard extends StatelessWidget {
  final Map<String, dynamic> album;
  final String Function(String) photoUrl;
  final VoidCallback onTap;

  const _AlbumCard({
    required this.album,
    required this.photoUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final photos = (album['album_photos'] as List?)
            ?.cast<Map<String, dynamic>>()
            .toList() ??
        [];
    photos.sort((a, b) =>
        (a['order_index'] as int).compareTo(b['order_index'] as int));

    final date = DateTime.tryParse(album['date'] ?? '');
    final dateStr = date != null
        ? DateFormat('yyyy년 M월 d일', 'ko').format(date)
        : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 사진 영역
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: _PhotoStrip(photos: photos, photoUrl: photoUrl),
            ),

            // 텍스트 영역
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 제목
                  Text(
                    album['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((album['content'] as String?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Text(
                      album['content']!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (photos.length > 1) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.photo_library_outlined,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '사진 ${photos.length}장',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  final List<Map<String, dynamic>> photos;
  final String Function(String) photoUrl;

  const _PhotoStrip({required this.photos, required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Container(
        height: 200,
        color: Colors.grey[100],
        child: const Center(
          child: Icon(Icons.photo_outlined, size: 48, color: Color(0xFFCCCCCC)),
        ),
      );
    }
    if (photos.length == 1) {
      return CachedNetworkImage(
        imageUrl: photoUrl(photos[0]['file_path']),
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(height: 220, color: Colors.grey[100]),
        errorWidget: (_, __, ___) =>
            Container(height: 220, color: Colors.grey[100]),
      );
    }
    // 2장 이상: 첫 번째 크게 + 나머지 오른쪽에 세로로
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: CachedNetworkImage(
            imageUrl: photoUrl(photos[0]['file_path']),
            height: 200,
            fit: BoxFit.cover,
            placeholder: (_, __) =>
                Container(height: 200, color: Colors.grey[100]),
            errorWidget: (_, __, ___) =>
                Container(height: 200, color: Colors.grey[100]),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              for (var i = 1; i < photos.length && i <= 3; i++) ...[
                if (i > 1) const SizedBox(height: 2),
                Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: photoUrl(photos[i]['file_path']),
                      height: (200 / (photos.length - 1).clamp(1, 3)).toDouble(),
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 65,
                        color: Colors.grey[100],
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 65,
                        color: Colors.grey[100],
                      ),
                    ),
                    if (i == 3 && photos.length > 4)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black45,
                          child: Center(
                            child: Text(
                              '+${photos.length - 3}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── 앨범 상세 ────────────────────────────────────────────────────────────────

class _AlbumDetailScreen extends StatelessWidget {
  final Map<String, dynamic> album;
  final String Function(String) photoUrl;
  final VoidCallback onDeleted;

  const _AlbumDetailScreen({
    required this.album,
    required this.photoUrl,
    required this.onDeleted,
  });

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('앨범 삭제'),
        content: const Text('이 앨범을 삭제하시겠어요?\n사진도 함께 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ApiService().delete('/albums/${album['id']}');
    onDeleted();
  }

  @override
  Widget build(BuildContext context) {
    final photos = (album['album_photos'] as List?)
            ?.cast<Map<String, dynamic>>()
            .toList() ??
        [];
    photos.sort((a, b) =>
        (a['order_index'] as int).compareTo(b['order_index'] as int));

    final date = DateTime.tryParse(album['date'] ?? '');
    final dateStr = date != null
        ? DateFormat('yyyy년 M월 d일 (E)', 'ko').format(date)
        : '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.black,
            leading: IconButton(
              icon:
                  const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: () => _delete(context),
              ),
            ],
          ),
          // 사진 풀스크린 페이지뷰
          if (photos.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.55,
                child: PageView.builder(
                  itemCount: photos.length,
                  itemBuilder: (_, i) => CachedNetworkImage(
                    imageUrl: photoUrl(photos[i]['file_path']),
                    fit: BoxFit.contain,
                    placeholder: (_, __) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.broken_image, color: Colors.white),
                  ),
                ),
              ),
            ),
          // 정보
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    album['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if ((album['content'] as String?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    Text(
                      album['content']!,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                  if (photos.length > 1) ...[
                    const SizedBox(height: 20),
                    const Text(
                      '모든 사진',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: photos.length,
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: photoUrl(photos[i]['file_path']),
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: Colors.grey[200]),
                          errorWidget: (_, __, ___) =>
                              Container(color: Colors.grey[200]),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 앨범 추가 시트 ────────────────────────────────────────────────────────────

class _AddAlbumSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddAlbumSheet({required this.onSaved});

  @override
  State<_AddAlbumSheet> createState() => _AddAlbumSheetState();
}

class _AddAlbumSheetState extends State<_AddAlbumSheet> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  List<XFile> _images = [];
  bool _saving = false;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final remaining = 10 - _images.length;
    if (remaining <= 0) return;
    final picked = await _picker.pickMultiImage(imageQuality: 80, limit: remaining);
    if (picked.isNotEmpty) {
      setState(() => _images = [..._images, ...picked]);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await ApiService().uploadFiles(
        '/albums',
        {
          'title': _titleCtrl.text.trim(),
          'content': _contentCtrl.text.trim(),
          'date': DateFormat('yyyy-MM-dd').format(_date),
        },
        _images.map((x) => File(x.path)).toList(),
      );
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottomInset + bottomPadding + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Row(
              children: [
                const Text(
                  '새 추억 기록',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close,
                      color: AppColors.textSecondary, size: 22),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 날짜 선택
            const Text(
              '날짜',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('yyyy년 M월 d일 (E)', 'ko').format(_date),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 사진 선택
            const Text(
              '사진',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            if (_images.isEmpty)
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.divider,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 32, color: AppColors.textSecondary),
                        SizedBox(height: 6),
                        Text(
                          '사진 선택 (최대 10장)',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 88,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length + 1,
                      itemBuilder: (_, i) {
                        if (i == _images.length) {
                          return GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: const Icon(Icons.add,
                                  color: AppColors.textSecondary),
                            ),
                          );
                        }
                        return Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(_images[i].path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 10,
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _images.removeAt(i)),
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 12),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // 제목
            const Text(
              '제목',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: '이 날을 한마디로 표현하면?',
                hintStyle: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 내용
            const Text(
              '내용',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: '그 날의 기억을 적어보세요 (선택)',
                hintStyle: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppColors.pinkShadow,
                ),
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          '저장하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 빈 상태 ───────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
