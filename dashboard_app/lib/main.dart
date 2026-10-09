import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(
    const CupertinoApp(
      home: DashboardScreen(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _canGoBack = false;
  bool _canGoForward = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();

    if (!kIsWeb) {
      _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    }

    _controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (_) {
          if (!mounted) return;
          setState(() {
            _isLoading = true;
            _loadError = null;
          });
        },
        onPageFinished: (_) async {
          if (!mounted) return;
          setState(() => _isLoading = false);
          await _updateNavigationState();
        },
        onWebResourceError: (error) {
          if (error.isForMainFrame == false || !mounted) return;
          setState(() {
            _isLoading = false;
            _loadError = error.description;
          });
        },
      ),
    );

    _controller.loadRequest(Uri.parse('https://boxcloudirl.se/dashboard'));
  }

  Future<void> _retryLoading() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    await _controller.reload();
  }

  Future<void> _updateNavigationState() async {
    final canGoBack = await _controller.canGoBack();
    final canGoForward = await _controller.canGoForward();
    if (!mounted) return;
    setState(() {
      _canGoBack = canGoBack;
      _canGoForward = canGoForward;
    });
  }

  Future<void> _openDashboard() async {
    await _controller.loadRequest(
      Uri.parse('https://boxcloudirl.se/dashboard'),
    );
  }

  Future<void> _confirmLogout() async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need to sign in again to open the dashboard.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _logout();
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await _controller.runJavaScript(
        'window.localStorage.clear(); window.sessionStorage.clear();',
      );
    } catch (_) {}

    if (!kIsWeb) {
      await WebViewCookieManager().clearCookies();
      await _controller.clearCache();
    }

    await _controller.loadRequest(Uri.parse('https://boxcloudirl.se/login'));
  }

  Widget _toolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Expanded(
      child: CupertinoButton(
        onPressed: onPressed,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 21),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('BoxCloud'),
        trailing: CupertinoButton(
          onPressed: _confirmLogout,
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.square_arrow_right),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_isLoading && _loadError == null)
                    const Center(child: CupertinoActivityIndicator()),
                  if (_loadError != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('BoxCloud could not be loaded.'),
                            const SizedBox(height: 8),
                            Text(_loadError!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            CupertinoButton.filled(
                              onPressed: _retryLoading,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                border: Border(
                  top: BorderSide(
                    color: CupertinoColors.separator.resolveFrom(context),
                  ),
                ),
              ),
              child: Row(
                children: [
                  _toolbarButton(
                    icon: CupertinoIcons.house,
                    label: 'Dashboard',
                    onPressed: _openDashboard,
                  ),
                  _toolbarButton(
                    icon: CupertinoIcons.chevron_back,
                    label: 'Back',
                    onPressed: _canGoBack ? _controller.goBack : null,
                  ),
                  _toolbarButton(
                    icon: CupertinoIcons.chevron_forward,
                    label: 'Forward',
                    onPressed: _canGoForward ? _controller.goForward : null,
                  ),
                  _toolbarButton(
                    icon: CupertinoIcons.refresh,
                    label: 'Refresh',
                    onPressed: _retryLoading,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
