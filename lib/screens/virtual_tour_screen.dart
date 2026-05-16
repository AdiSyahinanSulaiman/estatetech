import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VirtualTourScreen extends StatefulWidget {
  final String imageUrl; // This will now accept your Kuula link
  const VirtualTourScreen({super.key, required this.imageUrl});

  @override
  State<VirtualTourScreen> createState() => _VirtualTourScreenState();
}

class _VirtualTourScreenState extends State<VirtualTourScreen> {
  late final WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    // 1. Initialize the controller
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // This allows hotspots to work
      ..setBackgroundColor(Colors.black)

    // --- THE FIX ---
    // Removed .setDomStorageEnabled because it's automatic in this version

      ..setUserAgent("Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1")
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("Tour Error: ${error.description}");
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.imageUrl.trim()));
  }

  @override
  Widget build(BuildContext context) {
    // UI is 100% PRESERVED from your original code
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Property Walkthrough", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // The 360 Viewer
          WebViewWidget(controller: controller),

          // Loading Indicator
          if (isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 10),
                  Text("Opening Virtual Tour...", style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}