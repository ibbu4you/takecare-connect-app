library;

/// One item of the website's header menu, as `/navigation` sends it.
///
/// The app's menu is the website's: read from the same tree the website's
/// header draws, so an edit in the admin's Content → Navigation reaches the
/// phone with no release. URLs are the website's own paths and go through
/// `openWebPath`, which turns each into a screen of the app's own and sends
/// anything it cannot show — another site — to the browser.
class NavItem {
  const NavItem({
    required this.label,
    this.url,
    this.external = false,
    this.children = const [],
  });

  final String label;

  /// Null on a heading that only opens a list, like "Our Programs".
  final String? url;

  final bool external;

  /// Up to two levels below this one: the menu is three deep at most.
  final List<NavItem> children;

  bool get hasChildren => children.isNotEmpty;

  factory NavItem.fromJson(Map<String, dynamic> json) => NavItem(
        label: (json['label'] ?? '') as String,
        url: json['url'] as String?,
        external: (json['external'] ?? false) as bool,
        children: ((json['children'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(NavItem.fromJson)
            .toList(),
      );
}
