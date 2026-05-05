import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

/// 로그인 후 커플 연결 화면
/// - 초대코드 생성 (상대방에게 공유)
/// - 상대방 초대코드 입력하여 연결
class CoupleSetupScreen extends StatefulWidget {
  const CoupleSetupScreen({super.key});

  @override
  State<CoupleSetupScreen> createState() => _CoupleSetupScreenState();
}

class _CoupleSetupScreenState extends State<CoupleSetupScreen> {
  String? _myCode;
  final _codeController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkExistingCouple();
  }

  Future<void> _checkExistingCouple() async {
    try {
      final res = await ApiService().get('/couples/me');
      if (res['data'] != null) {
        if (mounted) context.go('/calendar');
      } else {
        _createMyCode();
      }
    } catch (_) {
      _createMyCode();
    }
  }

  Future<void> _createMyCode() async {
    try {
      final res = await ApiService().post('/couples/create', {});
      setState(() => _myCode = res['data']['invite_code']);
    } catch (e) {
      debugPrint('code create error: $e');
    }
  }

  Future<void> _joinCouple() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ApiService().post('/couples/join', {'inviteCode': code});
      if (mounted) context.go('/calendar');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('커플 연결', style: TextStyle(color: Color(0xFFE91E8C), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text('💕', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 24),

            // 내 초대코드
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.1), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  const Text('내 초대코드', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _myCode ?? '불러오는 중...',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
                            color: Color(0xFFE91E8C), letterSpacing: 4),
                      ),
                      if (_myCode != null) ...[
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Color(0xFFE91E8C)),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _myCode!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('코드가 복사됐어요!')),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('이 코드를 연인에게 공유하세요', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Row(children: [
              Expanded(child: Divider()),
              Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('또는', style: TextStyle(color: Colors.grey))),
              Expanded(child: Divider()),
            ]),
            const SizedBox(height: 32),

            // 상대방 코드 입력
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 4),
              decoration: InputDecoration(
                hintText: '연인의 코드 입력',
                hintStyle: const TextStyle(fontSize: 16, letterSpacing: 1, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _joinCouple,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E8C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('연결하기', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
