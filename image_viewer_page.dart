import 'package:flutter/material.dart';

class ImageViewerPage extends StatelessWidget {
  final String imageUrl;

  const ImageViewerPage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Close the image viewer
          },
        ),
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.broken_image, size: 50, color: Colors.grey),
        ),
      ),
    );
  }
}