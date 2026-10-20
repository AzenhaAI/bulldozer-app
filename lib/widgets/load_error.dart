import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../theme.dart';

/// What a failed load says to a person, and a way to try again.
///
/// Exists because a tester on a weak 5G signal was shown
/// "ClientException with SocketException: Failed host lookup: 'azenha.ai'
/// (OS Error: nodename nor servname provided, or not known, errno = 8)" —
/// the exception's own toString, which names nothing a person can act on.
/// The cause was the phone's DNS; the app's fault was the wording and the
/// missing Retry.
String friendlyError(Object e) {
  final s = e.toString();
  if (e is SocketException ||
      s.contains('SocketException') ||
      s.contains('Failed host lookup') ||
      s.contains('Connection refused') ||
      s.contains('Network is unreachable')) {
    return 'No connection. Check the internet and try again.';
  }
  if (e is TimeoutException || s.contains('TimeoutException')) {
    return 'The connection is too slow right now. Try again.';
  }
  final m = RegExp(r'HTTP (\d{3})').firstMatch(s);
  if (m != null) return 'The data service answered with an error (${m.group(1)}). Try again later.';
  if (s.contains('FormatException')) return 'The data arrived damaged. Try again.';
  return 'Could not load this. Try again.';
}

class LoadError extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  /// What failed, in the page's words: "the quiz", "countries", "this story".
  final String what;

  const LoadError({super.key, required this.error, required this.what, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 36, color: kTextDim),
            const SizedBox(height: 12),
            Text("Couldn't load $what.",
                textAlign: TextAlign.center,
                style: TextStyle(color: kText, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(friendlyError(error),
                textAlign: TextAlign.center, style: TextStyle(color: kTextDim, height: 1.4)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
