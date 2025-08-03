import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SecureWebView extends StatefulWidget {
  @override
  _SecureWebViewState createState() => _SecureWebViewState();
}

class _SecureWebViewState extends State<SecureWebView> {
  late final WebViewController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(false)
      ..loadRequest(Uri.parse("https://example.com"))
      ..setNavigationDelegate(NavigationDelegate(
      ));

    // Listen for fullscreen events
    _enableFullscreenListener();
  }

  void _enableFullscreenListener() async {
    await _controller.runJavaScript("""
      document.addEventListener('fullscreenchange', function() {
        if (document.fullscreenElement) {
          window.flutter_inappwebview.callHandler('enterFullscreen');
        } else {
          window.flutter_inappwebview.callHandler('exitFullscreen');
        }
      });
    """);

    _controller.addJavaScriptChannel(
      'flutter_inappwebview',
      onMessageReceived: (message) {
        if (message.message == 'enterFullscreen') {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        } else if (message.message == 'exitFullscreen') {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]);
        }
      },
    );
  }


  void _searchWeb() {
    String query = _searchController.text.trim();
    if (query.isNotEmpty) {
      String searchUrl = Uri.encodeFull("https://www.google.com/search?q=$query");
      _controller.loadRequest(Uri.parse(searchUrl));
    }
  }

  Future<void> _goBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No previous page available.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search...",
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _searchWeb(),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
