import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'safe_network_image.dart';
import '../../models/network_story_model.dart';

class NetworkAvatar extends StatelessWidget {
  final NetworkStoryModel network;
  final VoidCallback onTap;
  final bool isSelected;

  const NetworkAvatar({
    super.key,
    required this.network,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                ),
                padding: EdgeInsets.all(isSelected ? 2.5 : 0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: !isSelected
                        ? Border.all(
                            color: AppTheme.outlineVariant.withValues(
                              alpha: 0.3,
                            ),
                          )
                        : null,
                    color: AppTheme.surface,
                  ),
                  padding: EdgeInsets.all(isSelected ? 2 : 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: network.imageUrl.trim().isNotEmpty
                        ? SafeNetworkImage(
                            url: network.imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorWidget: Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: AppTheme.surfaceContainerHighest,
                              alignment: Alignment.center,
                              child: Text(
                                network.acronym,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: AppTheme.surfaceContainerHighest,
                            alignment: Alignment.center,
                            child: Text(
                              network.acronym,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              if (!network.isJoined)
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.surface,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF001B3C),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            network.acronym,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
