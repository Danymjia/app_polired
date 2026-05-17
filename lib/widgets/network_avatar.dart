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
                  gradient: isSelected
                      ? const LinearGradient(colors: [Colors.blue, Colors.red])
                      : null,
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
                    child: SafeNetworkImage(
                      url: network.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        color: AppTheme.surfaceContainerHighest,
                        child: const Icon(Icons.domain),
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
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.secondary,
                    ),
                    child: const Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Center(
                          child: Icon(
                            Icons.home,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: CircleAvatar(
                            radius: 6,
                            backgroundColor:
                                Colors.black, // Primary equivalent for plus bg
                            child: Icon(
                              Icons.add,
                              size: 8,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
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
