import 'package:flutter/material.dart';

import '../../core/models/business.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_image.dart';

/// Full-screen photographs, swipeable and pinch-zoomable.
///
/// Opened from a gallery, a workshop strip or a press cutting. Dark chrome
/// rather than the app's white — a photograph is the content here, and a white
/// surround changes how the colours in it read.
class PhotoViewer extends StatefulWidget {
  const PhotoViewer({super.key, required this.photos, this.initialIndex = 0, this.title});

  final List<Photo> photos;
  final int initialIndex;
  final String? title;

  static Future<void> open(
    BuildContext context, {
    required List<Photo> photos,
    int initialIndex = 0,
    String? title,
  }) {
    if (photos.isEmpty) return Future.value();

    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PhotoViewer(
          photos: photos,
          initialIndex: initialIndex,
          title: title,
        ),
      ),
    );
  }

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late final PageController _controller = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_index];

    return Scaffold(
      backgroundColor: AppColors.footerDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          widget.photos.length == 1
              ? (widget.title ?? '')
              : '${_index + 1} of ${widget.photos.length}',
          style: AppText.title.copyWith(color: Colors.white, fontSize: 15),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: AppImage(
                  url: widget.photos[i].url,
                  fit: BoxFit.contain,
                  semanticLabel: widget.photos[i].alt,
                ),
              ),
            ),
          ),
          if (photo.alt.trim().isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC0B1020)],
                  ),
                ),
                child: Text(
                  photo.alt,
                  style: AppText.excerpt.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
