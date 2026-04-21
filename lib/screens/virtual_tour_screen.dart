import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VirtualTourScreen extends StatefulWidget {
  final String imageUrl; // This will be your Pexels Living Room link
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

    // We define two scenes: 'livingRoom' and 'kitchen'
    // I found another Pexels 360 image for the kitchen so they match!
    final String kitchenUrl = 'https://images.pexels.com/photos/3457273/pexels-photo-3457273.jpeg';

    final String localHtml = '''
      <!DOCTYPE html>
      <html>
      <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/pannellum@2.5.6/build/pannellum.css"/>
          <script type="text/javascript" src="https://cdn.jsdelivr.net/npm/pannellum@2.5.6/build/pannellum.js"></script>
          <style>
              #panorama { width: 100vw; height: 100vh; background-color: black; }
              body { margin: 0; padding: 0; overflow: hidden; }
              .arrow-hotspot {
                  height: 60px; width: 60px;
                  background: url('https://img.icons8.com/ios-filled/100/ffffff/circled-up-2.png');
                  background-size: contain; cursor: pointer;
              }
          </style>
      </head>
      <body>
          <div id="panorama"></div>
          <script>
              pannellum.viewer('panorama', {
                  "default": { "firstScene": "livingRoom", "autoLoad": true },
                  "scenes": {
                      "livingRoom": {
                          "type": "equirectangular",
                          "panorama": "${widget.imageUrl}",
                          "hotSpots": [
                              {
                                  "pitch": -15, "yaw": 20,
                                  "type": "scene",
                                  "cssClass": "arrow-hotspot",
                                  "sceneId": "kitchen" // This moves you to the kitchen scene
                              }
                          ]
                      },
                      "kitchen": {
                          "type": "equirectangular",
                          "panorama": "$kitchenUrl",
                          "hotSpots": [
                              {
                                  "pitch": -15, "yaw": 160,
                                  "type": "scene",
                                  "cssClass": "arrow-hotspot",
                                  "sceneId": "livingRoom" // This moves you back to the living room
                              }
                          ]
                      }
                  }
              });
          </script>
      </body>
      </html>
    ''';

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => isLoading = false),
        ),
      )
      ..loadHtmlString(localHtml);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Property Walkthrough", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }
}