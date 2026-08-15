import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The office on a map, as the website shows it.
///
/// Renders the same Google Maps embed the site does — the URL comes from
/// settings, so whoever moves the pin in the admin moves it in both places.
///
/// **The map does not pan, and that is deliberate.** It sits inside a scrolling
/// contact screen, and a live map there is the classic trap: drag to scroll
/// past it and the map swallows the gesture, so the page appears stuck. Passing
/// no gesture recognizers leaves every drag to the parent scroll view, and a
/// tap anywhere opens the address in the phone's own maps app — which is where
/// somebody wants it anyway, because that is the thing that can navigate.
class MapCard extends StatefulWidget {
  const MapCard({super.key, required this.embedUrl, required this.address});

  final String embedUrl;
  final String address;

  @override
  State<MapCard> createState() => _MapCardState();
}

class _MapCardState extends State<MapCard> {
  WebViewController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Builds the controller, or gives up quietly.
  ///
  /// Wrapped because `WebViewController()` throws outright when no platform
  /// implementation is registered — on Flutter web, on desktop, and in a widget
  /// test, where the plugin registrant never runs. Unwrapped, that exception
  /// propagates during build and Flutter replaces the whole screen with its red
  /// error box: the contact details, the map and the form all gone because a
  /// decorative map could not load.
  void _load() {
    try {
      _create();
    } catch (_) {
      _failed = true;
    }
  }

  void _create() {
    final uri = Uri.tryParse(widget.embedUrl);

    if (uri == null) {
      _failed = true;

      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // The page behind the embed is transparent at the edges; without this it
      // flashes black on Android before the tiles arrive.
      ..setBackgroundColor(AppColors.surface)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (_) {
            if (mounted) setState(() => _failed = true);
          },
          // Nothing inside the map may navigate the WebView somewhere else. A
          // tap is handled by the overlay below and goes to the maps app.
          onNavigationRequest: (request) => request.url == widget.embedUrl
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
        ),
      )
      ..loadRequest(uri);
  }

  Future<void> _openInMaps() async {
    final uri = Uri.parse(
      'https://maps.google.com/?q=${Uri.encodeComponent(widget.address)}',
    );

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_controller != null && !_failed)
                      // No gestureRecognizers: every drag belongs to the page.
                      WebViewWidget(controller: _controller!)
                    else
                      const _MapUnavailable(),

                    // Transparent, over the whole map, so a tap anywhere hands
                    // off rather than doing nothing.
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _openInMaps,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _openInMaps,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Get directions',
                          style: AppText.metaStrong.copyWith(
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.open_in_new_rounded,
                        size: 15,
                        color: AppColors.mutedForeground,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What shows when the embed will not load — offline, or a bad URL in settings.
///
/// Still tappable, because the address is what somebody actually needs and the
/// maps app can find it without this map ever rendering.
class _MapUnavailable extends StatelessWidget {
  const _MapUnavailable();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_outlined, size: 30, color: AppColors.border),
          const SizedBox(height: 8),
          Text('Tap to open in Maps', style: AppText.meta),
        ],
      ),
    );
  }
}
