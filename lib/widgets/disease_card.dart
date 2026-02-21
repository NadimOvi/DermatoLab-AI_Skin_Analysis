import 'package:flutter/material.dart';
import '../models/disease_info.dart';
import '../utils/constants.dart';

class DiseaseCard extends StatelessWidget {
  final DiseaseInfo disease;
  final VoidCallback onTap;

  const DiseaseCard({super.key, required this.disease, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DiseaseLabels.colors[disease.code]?.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  DiseaseLabels.icons[disease.code],
                  color: DiseaseLabels.colors[disease.code],
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      disease.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      disease.shortDescription,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: LegacyAppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: LegacyAppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
