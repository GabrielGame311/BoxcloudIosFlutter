import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MaterialApp(
    home: DashboardScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
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
        onPageFinished: (_) {
          if (!mounted) return;
          setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading && _loadError == null)
              const Center(child: CircularProgressIndicator()),
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
                      FilledButton.icon(
                        onPressed: _retryLoading,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
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