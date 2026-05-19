import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VirtualTourScreen extends StatefulWidget {
  final String imageUrl; // Supports Kuula, Matterport, Pannellum, etc.
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

    // --- FIX: AUTOMATIC SCHEME CHECK ---
    // If the user pastes "my.matterport.com...", this adds "https://" automatically
    String finalUrl = widget.imageUrl.trim();
    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
      finalUrl = 'https://$finalUrl';
    }

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)

    // UNIVERSAL USER AGENT
    // Matterport requires this to enable the 3D 'Dollhouse' and smooth navigation
      ..setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36")

      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("Virtual Tour Error: ${error.description}");
          },
        ),
      )
      ..loadRequest(Uri.parse(finalUrl)); // Uses the corrected URL
  }

  @override
  Widget build(BuildContext context) {
    // UI 100% PRESERVED
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("EstateTech 360° Explorer",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w400)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // THE 360 VIEWER
          WebViewWidget(controller: controller),

          // LOADING OVERLAY
          if (isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 15),
                  Text("Initializing 360° Environment...",
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}