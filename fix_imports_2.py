import os

replacements = {
    r"E:\bondnex\lib\screens\auth\auth_wrapper.dart": {
        "import 'home_page.dart';": "import '../dashboard/home_page.dart';"
    },
    r"E:\bondnex\lib\screens\auth\email_verification_screen.dart": {
        "import 'home_page.dart';": "import '../dashboard/home_page.dart';"
    },
    r"E:\bondnex\lib\screens\auth\login_screen.dart": {
        "import 'home_page.dart';": "import '../dashboard/home_page.dart';"
    },
    r"E:\bondnex\lib\screens\communication\message_screen.dart": {
        "import 'public_profile_screen.dart';": "import '../profile/public_profile_screen.dart';"
    },
    r"E:\bondnex\lib\screens\communication\notification_screen.dart": {
        "import 'public_profile_screen.dart';": "import '../profile/public_profile_screen.dart';"
    },
    r"E:\bondnex\lib\screens\dashboard\dashboard_screen.dart": {
        "import 'notification_screen.dart';": "import '../communication/notification_screen.dart';",
        "import 'partner_profile_screen.dart';": "import '../profile/partner_profile_screen.dart';",
        "import 'public_profile_screen.dart';": "import '../profile/public_profile_screen.dart';"
    },
    r"E:\bondnex\lib\screens\dashboard\home_page.dart": {
        "import 'message_screen.dart';": "import '../communication/message_screen.dart';"
    },
    r"E:\bondnex\lib\screens\dashboard\intro_dashboard.dart": {
        "import 'login_screen.dart';": "import '../auth/login_screen.dart';",
        "import 'register_screen.dart';": "import '../auth/register_screen.dart';"
    },
    r"E:\bondnex\lib\screens\profile\partner_profile_screen.dart": {
        "import 'notification_screen.dart';": "import '../communication/notification_screen.dart';"
    }
}

for filepath, file_replacements in replacements.items():
    if not os.path.exists(filepath):
        print(f"File not found: {filepath}")
        continue
        
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        
    for old_str, new_str in file_replacements.items():
        content = content.replace(old_str, new_str)
        
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
        
    print(f"Updated {filepath}")
