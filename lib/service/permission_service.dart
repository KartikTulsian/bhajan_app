import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionService {
  static Future<bool> requestNotificationPermission(BuildContext context) async {
    // Check if Android 13+
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();

      if (status.isDenied) {
        // Show dialog explaining why permission is needed
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Notification Permission Required'),
              content: const Text(
                'To control playback from the notification, please allow notifications in your device settings.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
        }
        return false;
      }

      if (status.isPermanentlyDenied) {
        // Open app settings
        await openAppSettings();
        return false;
      }

      return status.isGranted;
    }

    return true;
  }
}