import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Loading, error and empty — the three states every screen has and most apps
/// only design one of.

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? 240,
      child: const Center(
        child: SizedBox(
          height: 26,
          width: 26,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}

/// What the reader sees when a request fails.
///
/// The message comes from [ApiException], which already turns a `DioException`
/// into something a person can act on — "You appear to be offline" rather than
/// "SocketException: Failed host lookup". Retry is always offered, because
/// almost every failure on a phone is transient.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry, this.compact = false});

  final Object? error;
  final VoidCallback? onRetry;
  final bool compact;

  String get _message {
    final e = error;
    if (e is ApiException) return e.message;

    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: compact ? 20 : 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact)
            const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.mutedForeground),
          if (!compact) const SizedBox(height: 14),
          Text(_message, style: AppText.body, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }
}

/// A section that has nothing in it yet.
///
/// Written to read as a statement of fact rather than an apology — a charity
/// with no open campaigns this month is not an error condition.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_rounded,
    this.action,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 56),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 38, color: AppColors.border),
          const SizedBox(height: 14),
          Text(title, style: AppText.h3, textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: AppText.excerpt, textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    );
  }
}

/// The footer under an infinite list: a spinner, a retry, or the end.
class ListFooter extends StatelessWidget {
  const ListFooter({
    super.key,
    required this.loading,
    required this.endReached,
    this.error,
    this.onRetry,
    this.endLabel = "That's everything",
  });

  final bool loading;
  final bool endReached;
  final Object? error;
  final VoidCallback? onRetry;
  final String endLabel;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return ErrorView(error: error, onRetry: onRetry, compact: true);
    }

    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    if (endReached) {
      return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 32),
        child: Center(child: Text(endLabel, style: AppText.meta)),
      );
    }

    return const SizedBox(height: 24);
  }
}
