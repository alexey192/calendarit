import 'package:flutter/material.dart';
import '../../../app/styles.dart';
import '../../../models/connected_account.dart';

class IconCard extends StatelessWidget {
  final ConnectedAccount account;

  const IconCard({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    final String providerLabel = switch (account.type) {
      AccountType.gmail => "Gmail",
    };

    final String assetPath = switch (account.type) {
      AccountType.gmail => 'assets/icons/gmail.png',
    };

    return Container(
      width: 180,
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // TODO: handle click
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Image.asset(assetPath, width: 32, height: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(providerLabel, style: AppTextStyles.caption),
                    const SizedBox(height: 2),
                    Text(
                      account.email,
                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
