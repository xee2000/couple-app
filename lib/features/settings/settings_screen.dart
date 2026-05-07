import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _myCode;
  String? _partnerNickname;
  bool _isConnected = false;
  bool _loadingCouple = true;
  final _codeController = TextEditingController();
  bool _joining = false;
  String _nickname = '';
  String _gender = '';

  @override
  void initState() {
    super.initState();
    _loadNickname();
    _loadCoupleInfo();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadNickname() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nickname = prefs.getString('nickname') ?? '';
      _gender = prefs.getString('gender') ?? '';
    });
  }

  Future<void> _loadCoupleInfo() async {
    setState(() => _loadingCouple = true);
    try {
      final res = await ApiService().get('/couples/me');
      final data = res['data'];
      if (data != null && data['user2_id'] != null) {
        setState(() {
          _isConnected = true;
          _partnerNickname = data['partner_nickname'] ?? '연인';
          _myCode = data['invite_code'];
        });
      } else {
        if (data != null) {
          setState(() => _myCode = data['invite_code']);
        } else {
          await _createMyCode();
        }
        setState(() => _isConnected = false);
      }
    } catch (_) {
      await _createMyCode();
      setState(() => _isConnected = false);
    }
    setState(() => _loadingCouple = false);
  }

  Future<void> _createMyCode() async {
    try {
      final res = await ApiService().post('/couples/create', {});
      setState(() => _myCode = res['data']['invite_code']);
    } catch (_) {}
  }

  Future<void> _joinCouple() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() => _joining = true);
    try {
      await ApiService().post('/couples/join', {'inviteCode': code});
      _codeController.clear();
      await _loadCoupleInfo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('💕 커플 연결 완료!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('연결 실패: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _disconnectCouple() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💔', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              const Text(
                '공유 끊기',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                '공유를 끊으면 함께 작성한\n캘린더와 기념일이 모두 삭제됩니다.\n\n계정은 그대로 유지되며\n새로운 연결을 시작할 수 있어요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      '끊기',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService().delete('/couples/disconnect');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('공유가 해제됐어요.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        // 커플 연결 화면으로 이동
        context.go('/couple-setup');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했어요: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👋', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              const Text('로그아웃',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('로그아웃 하시겠어요?',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('로그아웃', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              onPressed: () => context.pop(),
            ),
            title: const Text(
              '설정',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
            ),
            centerTitle: true,
            flexibleSpace: Container(
              decoration: const BoxDecoration(gradient: AppColors.gradient),
            ),
          ),

          // ── 내용 ──
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20, 20, 20,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 프로필 카드
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52, height: 52,
                          decoration: const BoxDecoration(
                            gradient: AppColors.gradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(child: Text('👤', style: TextStyle(fontSize: 26))),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nickname.isNotEmpty ? _nickname : '내 계정',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isConnected ? '커플 연결됨 💕' : '아직 연결 안 됨',
                              style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 커플 섹션
                  _SectionLabel(label: '커플 연결'),
                  const SizedBox(height: 10),
                  if (_loadingCouple)
                    const _LoadingCard()
                  else if (_isConnected)
                    _ConnectedCard(
                      partnerNickname: _partnerNickname ?? '연인',
                      onDisconnect: _disconnectCouple,
                    )
                  else
                    _DisconnectedCard(
                      myCode: _myCode,
                      codeController: _codeController,
                      joining: _joining,
                      onJoin: _joinCouple,
                    ),

                  const SizedBox(height: 28),

                  // 생리 주기 섹션 (여성만 표시)
                  if (_gender == 'female') ...[
                    _SectionLabel(label: '생리 주기'),
                    const SizedBox(height: 10),
                    const _CycleSection(),
                    const SizedBox(height: 28),
                  ],

                  // 계정 섹션
                  _SectionLabel(label: '계정'),
                  const SizedBox(height: 10),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.logout_rounded,
                        iconBg: Colors.red[50]!,
                        iconColor: Colors.red,
                        title: '로그아웃',
                        onTap: _logout,
                        showDivider: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 공통 위젯들 ────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700,
        color: AppColors.textSecondary, letterSpacing: 0.5,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  const _SettingsTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                        if (subtitle != null)
                          Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 66, color: AppColors.divider),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
      ),
    );
  }
}

class _ConnectedCard extends StatelessWidget {
  final String partnerNickname;
  final VoidCallback onDisconnect;
  const _ConnectedCard({required this.partnerNickname, required this.onDisconnect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  shape: BoxShape.circle,
                ),
                child: const Center(child: Text('💑', style: TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('연결된 커플',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(
                      partnerNickname,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.primary, size: 14),
                    SizedBox(width: 4),
                    Text('연결됨', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onDisconnect,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.link_off_rounded, size: 15, color: Colors.red[300]),
                const SizedBox(width: 6),
                Text(
                  '공유 끊기',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red[300],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DisconnectedCard extends StatelessWidget {
  final String? myCode;
  final TextEditingController codeController;
  final bool joining;
  final VoidCallback onJoin;

  const _DisconnectedCard({
    required this.myCode,
    required this.codeController,
    required this.joining,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 내 초대코드
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.share, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('내 초대코드',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    myCode ?? '불러오는 중...',
                    style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w900,
                      color: AppColors.primary, letterSpacing: 5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (myCode != null)
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: myCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('코드가 복사됐어요!'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 18),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '이 코드를 연인에게 공유하세요',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),

          const SizedBox(height: 20),
          const Row(children: [
            Expanded(child: Divider(color: AppColors.divider)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('또는', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ),
            Expanded(child: Divider(color: AppColors.divider)),
          ]),
          const SizedBox(height: 20),

          // 연인 코드 입력
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.purple[50]!,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.favorite_border, color: Colors.purple[300], size: 18),
              ),
              const SizedBox(width: 12),
              const Text('연인 코드 입력',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: codeController,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    letterSpacing: 4, color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '코드 입력',
                    hintStyle: const TextStyle(fontSize: 13, letterSpacing: 1, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.gradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppColors.pinkShadow,
                  ),
                  child: ElevatedButton(
                    onPressed: joining ? null : onJoin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: joining
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('연결',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 생리 주기 관리 섹션 ──────────────────────────────────────────────────────

class _CycleSection extends StatefulWidget {
  const _CycleSection();
  @override
  State<_CycleSection> createState() => _CycleSectionState();
}

class _CycleSectionState extends State<_CycleSection> {
  List<Map<String, dynamic>> _myCycles = [];
  List<Map<String, dynamic>> _partnerCycles = [];
  String? _userId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('user_id');
      final res = await ApiService().get('/cycles');
      final all = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final sorted = [...all]
        ..sort((a, b) => (b['start_date'] as String).compareTo(a['start_date'] as String));
      setState(() {
        _myCycles = sorted.where((c) => c['user_id'] == _userId).toList();
        _partnerCycles = sorted.where((c) => c['user_id'] != _userId).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(String id) async {
    try {
      await ApiService().delete('/cycles/$id');
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _showAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddCycleSheet(onSaved: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.periodRed, strokeWidth: 2),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 내 생리 주기 ──
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            children: [
              if (_myCycles.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      const Text('🌸', style: TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),
                      const Text('등록된 생리 주기가 없어요',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 16),
                      SizedBox(width: double.infinity, child: _CycleAddButton(onTap: _showAdd)),
                    ],
                  ),
                )
              else ...[
                ...(_myCycles.take(5).toList().asMap().entries.map((entry) {
                  final i = entry.key;
                  final c = entry.value;
                  return _CycleTile(
                    cycle: c,
                    showDivider: i < (_myCycles.take(5).length - 1),
                    onDelete: () => _delete(c['id']),
                  );
                })),
                const Divider(height: 1, color: AppColors.divider),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: _CycleAddButton(onTap: _showAdd),
                ),
              ],
            ],
          ),
        ),

        // ── 파트너 생리 주기 (연결됐고 데이터 있을 때만) ──
        if (_partnerCycles.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Row(
              children: [
                const Text('🌸', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Text(
                  '파트너 생리 주기',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.periodRed.withValues(alpha: 0.8),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.periodRed.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.periodRed.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Column(
              children: _partnerCycles.take(5).toList().asMap().entries.map((entry) {
                final i = entry.key;
                final c = entry.value;
                return _CycleTile(
                  cycle: c,
                  showDivider: i < (_partnerCycles.take(5).length - 1),
                  onDelete: null, // 파트너 주기는 삭제 불가
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _CycleTile extends StatelessWidget {
  final Map<String, dynamic> cycle;
  final bool showDivider;
  final VoidCallback? onDelete; // null이면 파트너 주기 (삭제 불가)
  const _CycleTile({required this.cycle, required this.showDivider, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final start = DateTime.tryParse(cycle['start_date'] ?? '');
    final end = DateTime.tryParse(cycle['end_date'] ?? '');
    if (start == null) return const SizedBox.shrink();

    final startStr = DateFormat('yyyy.MM.dd').format(start);
    final endStr = end != null ? ' ~ ${DateFormat('MM.dd').format(end)}' : '';
    final days = end != null
        ? end.difference(start).inDays + 1
        : (cycle['period_length'] as int? ?? 5);
    final isPartner = onDelete == null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE57373).withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(child: Text('🌸', style: TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$startStr$endStr',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$days일간 · 주기 ${cycle['cycle_length'] ?? 28}일',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (isPartner)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.periodRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '파트너',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.periodRed.withValues(alpha: 0.8),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF9A9A)),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 64, color: AppColors.divider),
      ],
    );
  }
}

class _CycleAddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CycleAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add, size: 16, color: AppColors.periodRed),
      label: const Text('주기 추가',
          style: TextStyle(color: AppColors.periodRed, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0x66E57373)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}

// ── 생리 주기 추가 바텀시트 ──────────────────────────────────────────────────

class _AddCycleSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddCycleSheet({required this.onSaved});
  @override
  State<_AddCycleSheet> createState() => _AddCycleSheetState();
}

class _AddCycleSheetState extends State<_AddCycleSheet> {
  DateTime? _startDate;
  DateTime? _endDate;
  int _cycleLength = 28;
  bool _saving = false;

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_startDate ?? now)
        : (_endDate ?? (_startDate?.add(const Duration(days: 4)) ?? now));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.periodRed),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _save() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('시작일을 선택해주세요'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final periodLength = _endDate != null
          ? _endDate!.difference(_startDate!).inDays + 1
          : 5;
      await ApiService().post('/cycles', {
        'start_date': DateFormat('yyyy-MM-dd').format(_startDate!),
        if (_endDate != null) 'end_date': DateFormat('yyyy-MM-dd').format(_endDate!),
        'period_length': periodLength,
        'cycle_length': _cycleLength,
      });
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e'), behavior: SnackBarBehavior.floating),
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
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding + 16),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 20,
        bottom: bottomInset > 0 ? bottomInset + 16 : 24,
      ),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Text('🌸', style: TextStyle(fontSize: 22)),
              SizedBox(width: 8),
              Text('생리 주기 추가',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 24),

          // 시작일
          _CycleDateRow(label: '시작일', required: true, date: _startDate,
              onTap: () => _pickDate(isStart: true)),
          const SizedBox(height: 12),

          // 종료일
          _CycleDateRow(label: '종료일', required: false, date: _endDate,
              onTap: () => _pickDate(isStart: false)),
          const SizedBox(height: 20),

          // 주기 슬라이더
          Row(
            children: [
              const Text('다음 생리까지',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x1AE57373),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$_cycleLength일',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.periodRed, fontSize: 14)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.periodRed,
              thumbColor: AppColors.periodRed,
              inactiveTrackColor: const Color(0x26E57373),
              overlayColor: const Color(0x1AE57373),
              trackHeight: 3,
            ),
            child: Slider(
              value: _cycleLength.toDouble(),
              min: 21, max: 40, divisions: 19,
              onChanged: (v) => setState(() => _cycleLength = v.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('21일', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              Text('40일', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.periodRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('저장',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
        ), // Column
      ), // SingleChildScrollView
    );
  }
}

class _CycleDateRow extends StatelessWidget {
  final String label;
  final bool required;
  final DateTime? date;
  final VoidCallback onTap;
  const _CycleDateRow({required this.label, required this.required, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: date != null ? const Color(0x66E57373) : AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 16,
                color: date != null ? AppColors.periodRed : AppColors.textSecondary),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            if (required) const Text(' *', style: TextStyle(color: AppColors.periodRed, fontSize: 13)),
            const Spacer(),
            Text(
              date != null ? DateFormat('yyyy년 M월 d일').format(date!) : '선택',
              style: TextStyle(
                fontSize: 14,
                fontWeight: date != null ? FontWeight.w600 : FontWeight.w400,
                color: date != null ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
