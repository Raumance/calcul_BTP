import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({super.key, this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text ?? AppConstants.disclaimerText,
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
