import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCoupleInfo();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadCoupleInfo() async {
    setState(() => _loadingCouple = true);
    try {
      final res = await ApiService().get('/couples/me');
      final data = res['data'];
      if (data != null && data['user2_id'] != null) {
        // 연결된 커플
        setState(() {
          _isConnected = true;
          _partnerNickname = data['partner_nickname'] ?? '연인';
          _myCode = data['invite_code'];
        });
      } else {
        // 연결 안 됨 - 초대코드만 있거나 없음
        if (data != null) {
          setState(() => _myCode = data['invite_code']);
        } else {
          // 코드 생성
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
          const SnackBar(content: Text('💕 커플 연결 완료!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('연결 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠어요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
          ),
        ],
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
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('설정', style: TextStyle(color: Color(0xFFE91E8C), fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFE91E8C)),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 커플 연결 섹션
          _SectionTitle(title: '커플 연결'),
          const SizedBox(height: 12),

          if (_loadingCouple)
            const Center(child: CircularProgressIndicator(color: Color(0xFFE91E8C)))
          else if (_isConnected)
            _ConnectedCard(partnerNickname: _partnerNickname ?? '연인')
          else
            _DisconnectedCard(
              myCode: _myCode,
              codeController: _codeController,
              joining: _joining,
              onJoin: _joinCouple,
            ),

          const SizedBox(height: 32),

          // 계정 섹션
          _SectionTitle(title: '계정'),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.logout,
            iconColor: Colors.red,
            title: '로그아웃',
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
    );
  }
}

class _ConnectedCard extends StatelessWidget {
  final String partnerNickname;
  const _ConnectedCard({required this.partnerNickname});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.08), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE91E8C).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite, color: Color(0xFFE91E8C)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('연결됨', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text(
                partnerNickname,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFE91E8C)),
              ),
            ]),
          ),
          const Icon(Icons.check_circle, color: Color(0xFFE91E8C)),
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
        boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.08), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 내 초대코드
          const Text('내 초대코드', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  myCode ?? '불러오는 중...',
                  style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w900,
                    color: Color(0xFFE91E8C), letterSpacing: 4,
                  ),
                ),
              ),
              if (myCode != null)
                IconButton(
                  icon: const Icon(Icons.copy, color: Color(0xFFE91E8C)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: myCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('코드가 복사됐어요!')),
                    );
                  },
                ),
            ],
          ),
          const Text('이 코드를 연인에게 공유하세요', style: TextStyle(color: Colors.grey, fontSize: 12)),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // 연인 코드 입력
          const Text('연인 코드 입력', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: codeController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 3),
                  decoration: InputDecoration(
                    hintText: '코드 8자리',
                    hintStyle: const TextStyle(fontSize: 14, letterSpacing: 1, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFFFF0F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: joining ? null : onJoin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E8C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: joining
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('연결', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.05), blurRadius: 6)],
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
