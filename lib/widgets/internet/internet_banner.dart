import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import 'package:testers/utils/height_width.dart';

class InternetBanner extends StatefulWidget {
  const InternetBanner({super.key});

  @override
  State<InternetBanner> createState() => _InternetBannerState();
}

class _InternetBannerState extends State<InternetBanner> {
  bool _isOnline = true;
  bool _isRetrying = false;
  bool _retryFailed = false;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _checkAndUpdate();
    _subscription = _connectivity.onConnectivityChanged.listen(
          (results) {
        debugPrint('[InternetBanner] connectivity changed: $results');
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 300), _checkAndUpdate);
      },
      onError: (e) {
        debugPrint('[InternetBanner] stream error: $e');
        if (mounted) setState(() => _isOnline = false);
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  Future<bool> _hasRealInternet() async {
    const hosts = ['google.com', 'cloudflare.com', 'apple.com'];
    final completer = Completer<bool>();
    int failed = 0;

    for (final host in hosts) {
      InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 3))
          .then((result) {
        final ok = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
        debugPrint('[InternetBanner] host=$host ok=$ok');
        if (!completer.isCompleted && ok) completer.complete(true);
      }).catchError((e) {
        debugPrint('[InternetBanner] host=$host failed: $e');
        failed++;
        if (failed == hosts.length && !completer.isCompleted) {
          completer.complete(false);
        }
      });
    }

    final result = await completer.future;
    debugPrint('[InternetBanner] online=$result');
    return result;
  }

  Future<void> _checkAndUpdate() async {
    debugPrint('[InternetBanner] checking...');
    final online = await _hasRealInternet();
    if (!mounted) return;
    debugPrint('[InternetBanner] setState _isOnline=$online');
    setState(() {
      _isOnline = online;
      _retryFailed = false;
    });
  }

  Future<void> _onRetry() async {
    if (_isRetrying) return;
    setState(() {
      _isRetrying = true;
      _retryFailed = false;
    });
    final online = await _hasRealInternet();
    if (!mounted) return;
    setState(() {
      _isOnline = online;
      _isRetrying = false;
      _retryFailed = !online;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        heightFactor: _isOnline ? 0.0 : 1.0,
        child: _BannerContent(
          isRetrying: _isRetrying,
          retryFailed: _retryFailed,
          onRetry: _onRetry,
        ),
      ),
    );
  }
}

class _BannerContent extends StatelessWidget {
  const _BannerContent({
    required this.isRetrying,
    required this.retryFailed,
    required this.onRetry,
  });

  final bool isRetrying;
  final bool retryFailed;
  final VoidCallback onRetry;

  
  static  final Color _bg         = Colors.red.shade600;
  static final Color _iconCircle = Colors.red;

  @override
  Widget build(BuildContext context) {
    final TextTheme tt = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(listBorderRadius),
          border: Border.all(
            color: Colors.red.shade300,
            width: 1.5
          )
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconCircle,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text(
                    'No Internet Connection',
                    style: tt.titleSmall!.copyWith(
                      color: Colors.white
                    )
                  ),
                  const SizedBox(height: 2),
                  Text(
                    retryFailed
                        ? 'Still offline. Check your connection.'
                        : 'Please check your connection',
                    style: tt.bodySmall!.copyWith(
                      color: Colors.white,
                      fontSize: 11
                    )
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            
            GestureDetector(
              onTap: isRetrying ? null : onRetry,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _iconCircle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isRetrying
                          ? SizedBox(
                        key: const ValueKey('spinner'),
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(
                        key: ValueKey('icon'),
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isRetrying ? 'Checking' : 'Retry',
                      style:  tt.titleSmall!.copyWith(
                        color: Colors.white
                      )
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}