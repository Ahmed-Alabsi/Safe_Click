import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  final String scannedCount;
  final String maliciousCount;
  final String blockedCount;

  const StatsCard({
    super.key,
    required this.scannedCount,
    required this.maliciousCount,
    required this.blockedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'الإحصائيات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context: context,
                  icon: Icons.link,
                  label: 'تم الفحص',
                  value: scannedCount,
                  color: Theme.of(context).colorScheme.primary,
                ),
                _buildStatItem(
                  context: context,
                  icon: Icons.warning,
                  label: 'ضار',
                  value: maliciousCount,
                  color: Theme.of(context).colorScheme.error,
                ),
                _buildStatItem(
                  context: context,
                  icon: Icons.block,
                  label: 'تم الحظر',
                  value: blockedCount,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ],
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
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
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
