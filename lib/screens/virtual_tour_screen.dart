import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VirtualTourScreen extends StatefulWidget {
  final String imageUrl;
  const VirtualTourScreen({super.key, required this.imageUrl});

  @override
  State<VirtualTourScreen> createState() => _VirtualTourScreenState();
}

class _VirtualTourScreenState extends State<VirtualTourScreen> {
  late final WebViewController controller;
  bool isLoading = true; // Added a loading spinner

  @override
  void initState() {
    super.initState();

    // This is the most stable 360 viewer URL
    final String tourUrl = 'https://pannellum.org/standalone/standalone.html?panorama=${widget.imageUrl}';

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              isLoading = false; // Hide spinner when room is ready
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(tourUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("360° Virtual Tour", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
    );
  }
}