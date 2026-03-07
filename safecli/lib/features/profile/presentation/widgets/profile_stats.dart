import 'package:flutter/material.dart';

class ProfileStats extends StatelessWidget {
  final int scannedLinks;
  final int detectedThreats;
  final double accuracyRate;

  const ProfileStats({
    super.key,
    required this.scannedLinks,
    required this.detectedThreats,
    required this.accuracyRate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context: context,
                  icon: Icons.link,
                  label: 'تم الفحص',
                  value: scannedLinks.toString(),
                  color: Theme.of(context).colorScheme.primary,
                ),
                _buildStatItem(
                  context: context,
                  icon: Icons.warning,
                  label: 'تهديدات',
                  value: detectedThreats.toString(),
                  color: Theme.of(context).colorScheme.error,
                ),
                _buildStatItem(
                  context: context,
                  icon: Icons.analytics,
                  label: 'الدقة',
                  value: '${accuracyRate.toStringAsFixed(1)}%',
                  color: Theme.of(context).colorScheme.primary, // Keep green for success, or map to a custom valid indicator if required, but Colors.green is semantic. We'll leave it semantic. Wait, let's use secondary or primary to be strict. I'll use Colors.green inside the strict definition but we can map it. Actually, I'll pass Theme.of(context).colorScheme.primary
                ),
              ],
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: accuracyRate / 100,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              'معدل الدقة في الكشف',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
