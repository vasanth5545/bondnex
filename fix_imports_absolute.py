import os
import re

base_dir = r"e:\bondnex\lib"

# Map of filename -> full package path
package_imports = {
    # services
    "auth_service.dart": "package:bondnex/services/auth/auth_service.dart",
    "database_helper.dart": "package:bondnex/services/database/database_helper.dart",
    "firestore_service.dart": "package:bondnex/services/database/firestore_service.dart",
    "firestore_service_dialer.dart": "package:bondnex/services/database/firestore_service_dialer.dart",
    "rtdb_service.dart": "package:bondnex/services/database/rtdb_service.dart",
    "cloudinary_service.dart": "package:bondnex/services/storage/cloudinary_service.dart",
    "storage_service.dart": "package:bondnex/services/storage/storage_service.dart",
    "api_keys.dart": "package:bondnex/services/core/api_keys.dart",
    "permissions_service.dart": "package:bondnex/services/core/permissions_service.dart",
    "shared_prefs_service.dart": "package:bondnex/services/core/shared_prefs_service.dart",

    # settings
    "account_settings_screen.dart": "package:bondnex/settings/profile/account_settings_screen.dart",
    "change_name_screen.dart": "package:bondnex/settings/profile/change_name_screen.dart",
    "crop_photo_screen.dart": "package:bondnex/settings/profile/crop_photo_screen.dart",
    "profile_photo_screen.dart": "package:bondnex/settings/profile/profile_photo_screen.dart",
    "app_lock_screen.dart": "package:bondnex/settings/security/app_lock_screen.dart",
    "panic_button_settings_screen.dart": "package:bondnex/settings/security/panic_button_settings_screen.dart",
    "password.dart": "package:bondnex/settings/security/password.dart",
    "uninstall_confirm_screen.dart": "package:bondnex/settings/security/uninstall_confirm_screen.dart",
    "permissions_screen.dart": "package:bondnex/settings/permissions/permissions_screen.dart",
    "usage_access_screen.dart": "package:bondnex/settings/permissions/usage_access_screen.dart",
    "settings_screen.dart": "package:bondnex/settings/general/settings_screen.dart",
    "merge_contacts_screen.dart": "package:bondnex/settings/general/merge_contacts_screen.dart",

    # phone
    "phone_screen.dart": "package:bondnex/phone/screens/phone_screen.dart",
    "dialer_screen.dart": "package:bondnex/phone/screens/dialer_screen.dart",
    "call_log_details_screen.dart": "package:bondnex/phone/screens/call_log_details_screen.dart",
    "contact_profile_screen.dart": "package:bondnex/phone/screens/contact_profile_screen.dart",
    "display_options_screen.dart": "package:bondnex/phone/screens/display_options_screen.dart",
    "phone_settings_screen.dart": "package:bondnex/phone/screens/phone_settings_screen.dart",
    "save_contact_screen.dart": "package:bondnex/phone/screens/save_contact_screen.dart",
    "incoming_call_screen.dart": "package:bondnex/phone/calls/incoming_call_screen.dart",
    "outgoing_call_screen.dart": "package:bondnex/phone/calls/outgoing_call_screen.dart",
    "partner_call_history_screen.dart": "package:bondnex/phone/partner/partner_call_history_screen.dart",
    "partner_contact_detail_screen.dart": "package:bondnex/phone/partner/partner_contact_detail_screen.dart",
    "message_screen.dart": "package:bondnex/phone/messaging/message_screen.dart",
}

# The previous script did this:
# import 'firestore_service.dart' -> import 'database/firestore_service.dart'
# And it did:
# import '../services/database/firestore_service.dart' -> import '../../services/database/firestore_service.dart'
# It's a mess. So let's use regex to find ANY import that ends with one of the filenames (like `firestore_service.dart` or `database/firestore_service.dart`)
# and replace the whole import path with the absolute `package:bondnex/...` path.

dart_files = []
for root, _, files in os.walk(base_dir):
    for f in files:
        if f.endswith(".dart"):
            dart_files.append(os.path.join(root, f))

for file_path in dart_files:
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    original_content = content
    
    for filename, pkg_path in package_imports.items():
        # Match `import 'something/filename';` or `import "something/filename";`
        # and replace with `import 'pkg_path';`
        pattern = rf"import\s+['\"][^'\"]*?{re.escape(filename)}['\"]"
        replacement = f"import '{pkg_path}'"
        content = re.sub(pattern, replacement, content)

    if content != original_content:
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Updated {file_path}")

print("Done")
