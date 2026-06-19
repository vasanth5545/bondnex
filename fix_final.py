import os
import re

base_dir = r"e:\bondnex\lib"

# Targeted replacements for the files that are throwing errors
replacements = {
    # main.dart
    r"import\s+['\"]screens/profile/edit_profile_screen.dart['\"]": r"import 'package:bondnex/screens/profile/edit_profile_screen.dart'",
    r"import\s+['\"]screens/profile/update_status_screen.dart['\"]": r"import 'package:bondnex/screens/profile/update_status_screen.dart'",
    
    # phone_screen.dart and contact_profile_screen.dart
    r"import\s+['\"]widgets/call_log_tile.dart['\"]": r"import 'package:bondnex/phone/widgets/call_log_tile.dart'",
    r"import\s+['\"]widgets/swipeable_contact_tile.dart['\"]": r"import 'package:bondnex/phone/widgets/swipeable_contact_tile.dart'",
    r"import\s+['\"]screens/save_contact_screen.dart['\"]": r"import 'package:bondnex/phone/screens/save_contact_screen.dart'",
    r"import\s+['\"]screens/phone_settings_screen.dart['\"]": r"import 'package:bondnex/phone/screens/phone_settings_screen.dart'",
    r"import\s+['\"]messaging/message_screen.dart['\"]": r"import 'package:bondnex/phone/messaging/message_screen.dart'",
    r"import\s+['\"]calls/outgoing_call_screen.dart['\"]": r"import 'package:bondnex/phone/calls/outgoing_call_screen.dart'",
    r"import\s+['\"]calls/incoming_call_screen.dart['\"]": r"import 'package:bondnex/phone/calls/incoming_call_screen.dart'",

    # partner_call_history_screen.dart
    r"import\s+['\"]partner/partner_contact_detail_screen.dart['\"]": r"import 'package:bondnex/phone/partner/partner_contact_detail_screen.dart'",
    r"import\s+['\"]partner_contact_detail_screen.dart['\"]": r"import 'package:bondnex/phone/partner/partner_contact_detail_screen.dart'",
}

dart_files = []
for root, _, files in os.walk(base_dir):
    for f in files:
        if f.endswith(".dart"):
            dart_files.append(os.path.join(root, f))

for file_path in dart_files:
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()

        original_content = content
        
        for pattern, replacement in replacements.items():
            content = re.sub(pattern, replacement, content)

        if content != original_content:
            with open(file_path, "w", encoding="utf-8") as f:
                f.write(content)
            print(f"Fixed {file_path}")
    except Exception as e:
        pass

print("Done fixing remaining imports")
