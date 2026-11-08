import 'package:flutter/material.dart';

import '../../../core/utils/byte_format.dart';
import '../../../data/services/sync_api_client.dart';

/// How much of the account's server quota is in use: a headline and a bar
/// that turns amber past 80% and red past 95%.
class RelayQuotaMeter extends StatelessWidget {
  final RelayUsage usage;

  const RelayQuotaMeter({super.key, required this.usage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = usage.quotaFraction;
    final color = fraction >= 0.95
        ? theme.colorScheme.error
        : fraction >= 0.8
            ? Colors.orange
            : theme.colorScheme.primary;
    final percent = (fraction * 100).clamp(0, 999).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${formatBytes(usage.usedBytes)} of ${formatBytes(usage.quotaBytes)} '
          'used ($percent%)',
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 6,
            color: color,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            semanticsLabel: 'Server storage used',
            // Semantics asserts 0..100; the headline carries an overshoot.
            semanticsValue: '${percent.clamp(0, 100)}%',
          ),
        ),
        if (fraction >= 0.8)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              fraction >= 1
                  ? 'Full: the server refuses new changes until you compact '
                      'or remove attachments.'
                  : 'Nearly full. Compacting usually frees most of it.',
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
      ],
    );
  }
}
