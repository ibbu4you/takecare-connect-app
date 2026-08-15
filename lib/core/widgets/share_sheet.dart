import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../api/api_endpoints.dart';
import '../theme/app_colors.dart';
import 'app_snack.dart';

/// Share and copy-link, matching the `ShareBar` the website puts on every
/// story, craftsman and campaign.
///
/// The shared URL is the **website** URL, not an app route: a link is worth
/// sending only if the person receiving it can open it, and most of them will
/// not have the app.
class ShareAction extends StatelessWidget {
  const ShareAction({
    super.key,
    required this.path,
    required this.title,
    this.color,
  });

  /// Site-relative, e.g. `/stories/a-weaver-in-bhuj`.
  final String path;
  final String title;
  final Color? color;

  String get _url => Api.webUrl(path);

  Future<void> _open(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;

    await Shared.of(context, url: _url, title: title, origin: box);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _open(context),
      icon: const Icon(Icons.ios_share_rounded),
      color: color,
      tooltip: 'Share',
    );
  }
}

/// The share bar as a row of two buttons, for the foot of a detail screen.
class ShareBar extends StatelessWidget {
  const ShareBar({super.key, required this.path, required this.title});

  final String path;
  final String title;

  @override
  Widget build(BuildContext context) {
    final url = Api.webUrl(path);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Shared.of(context, url: url, title: title),
            icon: const Icon(Icons.ios_share_rounded, size: 18),
            label: const Text('Share'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Shared.copy(context, url),
            icon: const Icon(Icons.link_rounded, size: 18),
            label: const Text('Copy link'),
          ),
        ),
      ],
    );
  }
}

/// The two share primitives, so no screen talks to `share_plus` directly.
class Shared {
  Shared._();

  static Future<void> of(
    BuildContext context, {
    required String url,
    required String title,
    RenderBox? origin,
  }) async {
    // sharePositionOrigin is required on iPad — without it the popover has no
    // anchor and the share sheet throws rather than opening.
    final box = origin ?? context.findRenderObject() as RenderBox?;

    await Share.share(
      '$title\n$url',
      subject: title,
      sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    );
  }

  static Future<void> copy(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));

    if (context.mounted) {
      AppSnack.show(context, 'Link copied', icon: Icons.check_rounded, tone: AppColors.success);
    }
  }
}
