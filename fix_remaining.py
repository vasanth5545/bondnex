import os
import shutil
import re

base_dir = r"e:\bondnex\lib"

moves = {
    # services
    r"services\auth_service.dart": r"services\auth\auth_service.dart",
    r"services\database_helper.dart": r"services\database\database_helper.dart",
    r"services\firestore_service.dart": r"services\database\firestore_service.dart",
    r"services\firestore_service_dialer.dart": r"services\database\firestore_service_dialer.dart",
    r"services\rtdb_service.dart": r"services\database\rtdb_service.dart",
    r"services\cloudinary_service.dart": r"services\storage\cloudinary_service.dart",
    r"services\storage_service.dart": r"services\storage\storage_service.dart",
    r"services\api_keys.dart": r"services\core\api_keys.dart",
    r"services\permissions_service.dart": r"services\core\permissions_service.dart",
    r"services\shared_prefs_service.dart": r"services\core\shared_prefs_service.dart",

    # settings
    r"settings\account_settings_screen.dart": r"settings\profile\account_settings_screen.dart",
    r"settings\change_name_screen.dart": r"settings\profile\change_name_screen.dart",
    r"settings\crop_photo_screen.dart": r"settings\profile\crop_photo_screen.dart",
    r"settings\profile_photo_screen.dart": r"settings\profile\profile_photo_screen.dart",
    r"settings\app_lock_screen.dart": r"settings\security\app_lock_screen.dart",
    r"settings\panic_button_settings_screen.dart": r"settings\security\panic_button_settings_screen.dart",
    r"settings\password.dart": r"settings\security\password.dart",
    r"settings\uninstall_confirm_screen.dart": r"settings\security\uninstall_confirm_screen.dart",
    r"settings\permissions_screen.dart": r"settings\permissions\permissions_screen.dart",
    r"settings\usage_access_screen.dart": r"settings\permissions\usage_access_screen.dart",
    r"settings\settings_screen.dart": r"settings\general\settings_screen.dart",
    r"settings\merge_contacts_screen.dart": r"settings\general\merge_contacts_screen.dart",

    # phone
    r"phone\phone_screen.dart": r"phone\screens\phone_screen.dart",
    r"phone\dialer_screen.dart": r"phone\screens\dialer_screen.dart",
    r"phone\call_log_details_screen.dart": r"phone\screens\call_log_details_screen.dart",
    r"phone\contact_profile_screen.dart": r"phone\screens\contact_profile_screen.dart",
    r"phone\display_options_screen.dart": r"phone\screens\display_options_screen.dart",
    r"phone\phone_settings_screen.dart": r"phone\screens\phone_settings_screen.dart",
    r"phone\save_contact_screen.dart": r"phone\screens\save_contact_screen.dart",
    r"phone\incoming_call_screen.dart": r"phone\calls\incoming_call_screen.dart",
    r"phone\outgoing_call_screen.dart": r"phone\calls\outgoing_call_screen.dart",
    r"phone\partner_call_history_screen.dart": r"phone\partner\partner_call_history_screen.dart",
    r"phone\partner_contact_detail_screen.dart": r"phone\partner\partner_contact_detail_screen.dart",
    r"phone\message_screen.dart": r"phone\messaging\message_screen.dart",
}

# Ensure destination directories exist
for src, dst in moves.items():
    dst_full = os.path.join(base_dir, dst)
    os.makedirs(os.path.dirname(dst_full), exist_ok=True)

# Move files
for src, dst in moves.items():
    src_full = os.path.join(base_dir, src)
    dst_full = os.path.join(base_dir, dst)
    if os.path.exists(src_full):
        shutil.move(src_full, dst_full)
        print(f"Moved {src} to {dst}")

# Fix imports in all .dart files
dart_files = []
for root, _, files in os.walk(base_dir):
    for f in files:
        if f.endswith(".dart"):
            dart_files.append(os.path.join(root, f))

# We will use regex to find and replace import paths.
# Since we moved them one directory deeper, we might need to adjust relative paths.
# To be completely safe and avoid calculating relative paths dynamically for everything,
# we will replace package:bondnex imports first if any, or do a targeted replace for filenames.

replacements = {
    # services
    "'auth_service.dart'": "'auth/auth_service.dart'",
    "'database_helper.dart'": "'database/database_helper.dart'",
    "'firestore_service.dart'": "'database/firestore_service.dart'",
    "'firestore_service_dialer.dart'": "'database/firestore_service_dialer.dart'",
    "'rtdb_service.dart'": "'database/rtdb_service.dart'",
    "'cloudinary_service.dart'": "'storage/cloudinary_service.dart'",
    "'storage_service.dart'": "'storage/storage_service.dart'",
    "'api_keys.dart'": "'core/api_keys.dart'",
    "'permissions_service.dart'": "'core/permissions_service.dart'",
    "'shared_prefs_service.dart'": "'core/shared_prefs_service.dart'",

    # settings
    "'account_settings_screen.dart'": "'profile/account_settings_screen.dart'",
    "'change_name_screen.dart'": "'profile/change_name_screen.dart'",
    "'crop_photo_screen.dart'": "'profile/crop_photo_screen.dart'",
    "'profile_photo_screen.dart'": "'profile/profile_photo_screen.dart'",
    "'app_lock_screen.dart'": "'security/app_lock_screen.dart'",
    "'panic_button_settings_screen.dart'": "'security/panic_button_settings_screen.dart'",
    "'password.dart'": "'security/password.dart'",
    "'uninstall_confirm_screen.dart'": "'security/uninstall_confirm_screen.dart'",
    "'permissions_screen.dart'": "'permissions/permissions_screen.dart'",
    "'usage_access_screen.dart'": "'permissions/usage_access_screen.dart'",
    "'settings_screen.dart'": "'general/settings_screen.dart'",
    "'merge_contacts_screen.dart'": "'general/merge_contacts_screen.dart'",

    # phone
    "'phone_screen.dart'": "'screens/phone_screen.dart'",
    "'dialer_screen.dart'": "'screens/dialer_screen.dart'",
    "'call_log_details_screen.dart'": "'screens/call_log_details_screen.dart'",
    "'contact_profile_screen.dart'": "'screens/contact_profile_screen.dart'",
    "'display_options_screen.dart'": "'screens/display_options_screen.dart'",
    "'phone_settings_screen.dart'": "'screens/phone_settings_screen.dart'",
    "'save_contact_screen.dart'": "'screens/save_contact_screen.dart'",
    "'incoming_call_screen.dart'": "'calls/incoming_call_screen.dart'",
    "'outgoing_call_screen.dart'": "'calls/outgoing_call_screen.dart'",
    "'partner_call_history_screen.dart'": "'partner/partner_call_history_screen.dart'",
    "'partner_contact_detail_screen.dart'": "'partner/partner_contact_detail_screen.dart'",
    "'message_screen.dart'": "'messaging/message_screen.dart'",
}

for file_path in dart_files:
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    original_content = content
    # First pass: replace simple filename occurrences. This works if they were in the same directory.
    # However, for relative paths like '../services/firestore_service.dart', 
    # replacing 'firestore_service.dart' with 'database/firestore_service.dart' results in '../services/database/firestore_service.dart', which is PERFECT!
    # Let's test this logic.
    for old, new in replacements.items():
        # Replace only within import statements to be safe
        content = re.sub(rf"(import\s+[^;]*){re.escape(old)}", rf"\1{new}", content)

    # BUT what about imports FROM within the moved directories?
    # e.g. a file in `services/database/firestore_service.dart` used to import `../models/user_model.dart`.
    # Now it's one directory deeper, so it needs `../../models/user_model.dart`.
    
    # Let's determine if this file was moved one level deeper.
    rel_path = os.path.relpath(file_path, base_dir)
    # Check if the file is inside one of the newly created subdirectories (depth 2 instead of depth 1 for phone/services/settings)
    parts = rel_path.split(os.sep)
    if len(parts) >= 3 and parts[0] in ["services", "settings", "phone"]:
        # If it's a file inside a subdirectory of these folders (e.g., services/database/file.dart)
        # We need to add one more '../' to any relative import that goes UP or parallel.
        # Specifically, imports starting with '../' should become '../../'
        
        # We'll use a regex to replace all import '../' with import '../../'
        content = re.sub(r"import\s+(['\"])\.\./", r"import \g<1>../../", content)

    if content != original_content:
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Updated {file_path}")

print("Done")
