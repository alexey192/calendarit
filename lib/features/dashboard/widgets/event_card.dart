import 'package:flutter/material.dart';

import '../../../app/styles.dart';

class EventCard extends StatelessWidget {
  final String title;
  final String description;
  final String location;
  final String date; // String like "July 23, 2025"
  final String status;
  final String source;
  final String tag;
  final bool seen;
  final VoidCallback onTap;

  const EventCard({
    super.key,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.status,
    required this.source,
    required this.tag,
    required this.seen,
    required this.onTap,
  });

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warningColor;
      case 'accepted':
        return AppColors.successColor;
      case 'rejected':
        return AppColors.errorColor;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: seen ? 1 : 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.surfaceColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!seen)
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.unreadIndicator,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              Text(title, style: AppTextStyles.title),
              const SizedBox(height: 6),
              Text(date, style: AppTextStyles.caption),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(child: Text(location, style: AppTextStyles.body)),
                ],
              ),
              const SizedBox(height: 8),
              Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.subtitle),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(tag, style: AppTextStyles.tag),
                    backgroundColor: AppColors.backgroundColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        source.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: AppTextStyles.status.copyWith(
                            color: _statusColor(status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
