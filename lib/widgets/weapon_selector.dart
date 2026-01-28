import 'package:flutter/material.dart';
import '../models/weapon.dart';
import '../theme/app_theme.dart';

class WeaponSelector extends StatelessWidget {
  final Weapon? selectedWeapon;
  final VoidCallback onTap;
  final bool enabled;

  const WeaponSelector({
    Key? key,
    this.selectedWeapon,
    required this.onTap,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: enabled ? AppTheme.surfaceColor : AppTheme.backgroundSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selectedWeapon != null
                ? AppTheme.accentPrimary.withOpacity(0.5)
                : AppTheme.borderColor,
            width: selectedWeapon != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selectedWeapon != null
                    ? AppTheme.accentPrimary.withOpacity(0.15)
                    : AppTheme.backgroundSecondary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.gps_fixed,
                size: 20,
                color: selectedWeapon != null
                    ? AppTheme.accentPrimary
                    : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: selectedWeapon != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedWeapon!.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedWeapon!.displayDetails,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    )
                  : Text(
                      'Sélectionner une arme',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
            ),
            Icon(
              selectedWeapon != null ? Icons.edit : Icons.arrow_forward_ios,
              size: 16,
              color: selectedWeapon != null
                  ? AppTheme.accentPrimary
                  : AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
