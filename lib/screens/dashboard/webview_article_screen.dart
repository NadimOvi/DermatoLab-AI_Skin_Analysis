// ============================================================================
// WEBVIEW ARTICLE READER
// File: lib/screens/dashboard/webview_article_screen.dart
//
// Opens any URL inside the app with a full browser experience.
// Includes: progress bar, navigation controls, share button, refresh.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Shared dark colors ────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF0F0F14);
  static const surface = Color(0xFF1A1A24);
  static const surfaceAlt = Color(0xFF22222F);
  static const primary = Color(0xFF6366F1);
  static const accent = Color(0xFF8B5CF6);
  static const textHi = Color(0xFFF1F1F5);
  static const textMid = Color(0xFF8E8EA8);
  static const textLo = Color(0xFF4A4A60);
  static const border = Color(0xFF252535);
}

class WebViewArticleScreen extends StatefulWidget {
  final String url;
  final String title;
  final String? sourceName;

  const WebViewArticleScreen({
    Key? key,
    required this.url,
    required this.title,
    this.sourceName,
  }) : super(key: key);

  @override
  State<WebViewArticleScreen> createState() => _WebViewArticleScreenState();
}

class _WebViewArticleScreenState extends State<WebViewArticleScreen> {
  late final WebViewController _controller;
  double _loadingProgress = 0;
  bool _isLoading = true;
  bool _canGoBack = false;
  bool _canGoForward = false;
  String _currentTitle = '';

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.title;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(_C.bg)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            setState(() => _loadingProgress = progress / 100.0);
          },
          onPageStarted: (_) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) async {
            final title = await _controller.getTitle();
            final canBack = await _controller.canGoBack();
            final canFwd = await _controller.canGoForward();
            if (mounted) {
              setState(() {
                _isLoading = false;
                _loadingProgress = 1.0;
                if (title != null && title.isNotEmpty) _currentTitle = title;
                _canGoBack = canBack;
                _canGoForward = canFwd;
              });
            }
          },
          onWebResourceError: (error) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            // Allow all navigation within the webview
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _shareArticle() async {
    final url = await _controller.currentUrl() ?? widget.url;
    // Using url_launcher which is already in pubspec
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _openInBrowser() async {
    final url = await _controller.currentUrl() ?? widget.url;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          // ── Custom AppBar ─────────────────────────────────────────────────
          _buildAppBar(top),

          // ── Progress bar ──────────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _isLoading ? 2 : 0,
            child: LinearProgressIndicator(
              value: _loadingProgress < 1.0 ? _loadingProgress : null,
              backgroundColor: _C.surfaceAlt,
              valueColor: const AlwaysStoppedAnimation<Color>(_C.primary),
              minHeight: 2,
            ),
          ),

          // ── WebView ───────────────────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                // Initial loading overlay
                if (_isLoading && _loadingProgress < 0.1)
                  Container(
                    color: _C.bg,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: _C.primary,
                            strokeWidth: 2,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading article...',
                            style: TextStyle(color: _C.textMid, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Bottom navigation bar ─────────────────────────────────────────
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildAppBar(double top) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, top + 8, 8, 8),
      decoration: BoxDecoration(
        color: _C.surface,
        border: Border(bottom: BorderSide(color: _C.border, width: 1)),
      ),
      child: Row(
        children: [
          // Back button
          _NavBtn(
            icon: Icons.close_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),

          // Title + source
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentTitle,
                  style: const TextStyle(
                    color: _C.textHi,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.sourceName != null)
                  Text(
                    widget.sourceName!,
                    style: const TextStyle(color: _C.primary, fontSize: 11),
                  ),
              ],
            ),
          ),

          // Open in browser
          _NavBtn(
            icon: Icons.open_in_browser_rounded,
            onTap: _openInBrowser,
            tooltip: 'Open in browser',
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 8),
      decoration: BoxDecoration(
        color: _C.surface,
        border: Border(top: BorderSide(color: _C.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back
          _NavBtn(
            icon: Icons.arrow_back_rounded,
            onTap: _canGoBack ? () => _controller.goBack() : null,
            enabled: _canGoBack,
          ),
          // Forward
          _NavBtn(
            icon: Icons.arrow_forward_rounded,
            onTap: _canGoForward ? () => _controller.goForward() : null,
            enabled: _canGoForward,
          ),
          // Refresh
          _NavBtn(
            icon: Icons.refresh_rounded,
            onTap: () => _controller.reload(),
          ),
          // Share (open in external browser)
          _NavBtn(icon: Icons.share_rounded, onTap: _shareArticle),
          // Home (go back to original URL)
          _NavBtn(
            icon: Icons.home_rounded,
            onTap: () => _controller.loadRequest(Uri.parse(widget.url)),
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;
  final String? tooltip;

  const _NavBtn({
    required this.icon,
    this.onTap,
    this.enabled = true,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final color = (enabled && onTap != null) ? _C.textMid : _C.textLo;
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}
