import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testers/constants/icons.dart';
import 'package:testers/screen/auth/provider/auth_provider.dart';

class CoinDisplay extends StatefulWidget {
  const CoinDisplay({super.key});

  @override
  State<CoinDisplay> createState() => _CoinDisplayState();
}

class _CoinDisplayState extends State<CoinDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  late final Animation<double> _spinAnim;

  StreamSubscription<DocumentSnapshot>? _coinSub;
  int _coins = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(); 

    _spinAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _spinCtrl, curve: Curves.linear));

    
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribe());
  }

  void _subscribe() {
    final uid = context.read<AuthProvider>().uid;
    if (uid.isEmpty) return;

    _coinSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
          (snap) {
            if (!mounted) return;
            final fresh = (snap.data()?['coins'] as num?)?.toInt() ?? 0;
            setState(() {
              _coins = fresh;
              _loading = false;
            });
            
            context.read<AuthProvider>().refreshUserData();
          },
          onError: (_) {
            if (mounted) setState(() => _loading = false);
          },
        );
  }

  @override
  void dispose() {
    _coinSub?.cancel();
    _spinCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() => _loading = true);
    _spinCtrl.repeat();
    await context.read<AuthProvider>().refreshUserData();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      _spinCtrl.repeat();
    } else {
      _spinCtrl.stop();
    }

    return GestureDetector(
      onTap: _loading ? null : _refresh,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _loading
                ? RotationTransition(
                    key: const ValueKey('spin'),
                    turns: _spinAnim,
                    child: const Icon(
                      Icons.refresh_rounded,
                      size: 14,
                      color: Color(0xFFFFB800),
                    ),
                  )
                : Image.asset(coinIcon, width: 14, height: 14),
          ),
          const SizedBox(width: 5),

          
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: Text(
              key: ValueKey(_coins),
              '$_coins',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
