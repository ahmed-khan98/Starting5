import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AppWebView extends StatefulWidget {
  final String url;
  final String title;

  const AppWebView({super.key, required this.url, required this.title});

  @override
  State<AppWebView> createState() => _AppWebViewState();
}

class _AppWebViewState extends State<AppWebView> {
  WebViewController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            
            if (request.url.contains('/checkout') && !request.url.contains('ID=')) {
              String userId = "";
              if (widget.url.contains("ID=")) {
                userId = widget.url.split("ID=").last.split("&").first;
              }

              if (userId.isNotEmpty) {
                String separator = request.url.contains('?') ? '&' : '?';
                String forcedUrl = "${request.url}${separator}ID=$userId";
                debugPrint("KEEPING SESSION ALIVE: $forcedUrl");
                _controller?.loadRequest(Uri.parse(forcedUrl));
                return NavigationDecision.prevent;
              }
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (url) => setState(() => _isLoading = true),
          onPageFinished: (url) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    if (mounted) {
      setState(() {
        _controller = controller;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFF4500),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _controller == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF4500)))
          : Stack(
        children: [
          WebViewWidget(controller: _controller!),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFFFF4500))),
        ],
      ),
    );
  }
}