import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/detection_result.dart';
import '../screens/result_screen.dart';
import '../utils/constants.dart';

class HistoryItem extends StatelessWidget {
  final DetectionResult result;
  final VoidCallback onDelete;

  const HistoryItem({super.key, required this.result, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(result.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: LegacyAppColors.errorColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResultScreen(result: result),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(result.imagePath),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.diseaseName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(result.confidence * 100).toStringAsFixed(1)}% confidence',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat(
                          'MMM dd, yyyy - HH:mm',
                        ).format(result.timestamp),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: LegacyAppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  DiseaseLabels.icons[result.diseaseCode],
                  color: DiseaseLabels.colors[result.diseaseCode],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
