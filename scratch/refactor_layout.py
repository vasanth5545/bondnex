import os
import re
import subprocess

# List of screen files to move from lib/ to lib/screens/
screens_to_move = [
    "activity_screen.dart",
    "app_lock_screen.dart",
    "auth_wrapper.dart",
    "dashboard_screen.dart",
    "edit_profile_screen.dart",
    "email_verification_screen.dart",
    "home_page.dart",
    "intro_dashboard.dart",
    "login_screen.dart",
    "notification_screen.dart",
    "partner_call_history_screen.dart",
    "partner_contact_detail_screen.dart",
    "permissions_screen.dart",
    "photo_view_screen.dart",
    "private_gallery_screen.dart",
    "public_photo_picker_screen.dart",
    "register_screen.dart",
    "settings_screen.dart",
    "splash_screen.dart",
    "update_status_screen.dart"
]

project_root = r"e:\bondnex"
lib_dir = os.path.join(project_root, "lib")
screens_dir = os.path.join(lib_dir, "screens")

# Ensure the screens directory exists
os.makedirs(screens_dir, exist_ok=True)

# 1. Move files using git mv (or standard move if git mv fails)
print("Moving files...")
for filename in screens_to_move:
    src = os.path.join(lib_dir, filename)
    dst = os.path.join(screens_dir, filename)
    if os.path.exists(src):
        try:
            # Try git mv to keep history
            subprocess.run(["git", "mv", src, dst], check=True, cwd=project_root)
            print(f"Git moved: {filename}")
        except Exception as e:
            # Fallback to standard move
            os.rename(src, dst)
            print(f"Moved (fallback): {filename}")
    else:
        print(f"Warning: {filename} not found at {src}")

# 2. Function to update imports inside a given file
def update_imports(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    modified = False

    # Get the directory level relative to lib
    rel_path = os.path.relpath(file_path, lib_dir)
    parts = rel_path.split(os.sep)
    # Number of directories below lib/
    # e.g., if rel_path is "screens/home_page.dart", parts = ["screens", "home_page.dart"], level = 1
    # if rel_path is "phone/widgets/call_log_tile.dart", parts = ["phone", "widgets", "call_log_tile.dart"], level = 2
    # if rel_path is "main.dart", parts = ["main.dart"], level = 0
    level = len(parts) - 1

    # Update imports of the moved screens in other files
    for screen in screens_to_move:
        # A. Replace package imports:
        # package:bondnex/screen.dart -> package:bondnex/screens/screen.dart
        pkg_pattern = f"package:bondnex/{screen}"
        pkg_replace = f"package:bondnex/screens/{screen}"
        if pkg_pattern in content:
            content = content.replace(pkg_pattern, pkg_replace)
            modified = True

        # B. Replace relative imports targeting the moved screen files
        # Depending on the level of the file we are editing:
        if level == 0:
            # File is in lib/ (like main.dart)
            # import 'screen.dart'; -> import 'screens/screen.dart';
            rel_pattern = f"import '{screen}'"
            rel_replace = f"import 'screens/{screen}'"
            if rel_pattern in content:
                content = content.replace(rel_pattern, rel_replace)
                modified = True
            
            # Double quotes variant
            rel_pattern_dq = f'import "{screen}"'
            rel_replace_dq = f'import "screens/{screen}"'
            if rel_pattern_dq in content:
                content = content.replace(rel_pattern_dq, rel_replace_dq)
                modified = True

        elif level == 1:
            # File is in a subdirectory like lib/phone/ or lib/screens/ or lib/settings/
            if parts[0] == "screens":
                # Inside lib/screens/, imports to other screens in same directory remain relative
                # e.g., import 'screen.dart'; is still correct.
                # But if it had import '../screen.dart'; (which might happen if it was in subdirectory before),
                # we change it to import 'screen.dart';
                rel_pattern = f"import '../{screen}'"
                rel_replace = f"import '{screen}'"
                if rel_pattern in content:
                    content = content.replace(rel_pattern, rel_replace)
                    modified = True
                
                rel_pattern_dq = f'import "../{screen}"'
                rel_replace_dq = f'import "{screen}"'
                if rel_pattern_dq in content:
                    content = content.replace(rel_pattern_dq, rel_replace_dq)
                    modified = True
            else:
                # File is in lib/phone/ or lib/settings/ or lib/providers/
                # import '../screen.dart'; -> import '../screens/screen.dart';
                rel_pattern = f"import '../{screen}'"
                rel_replace = f"import '../screens/{screen}'"
                if rel_pattern in content:
                    content = content.replace(rel_pattern, rel_replace)
                    modified = True

                rel_pattern_dq = f'import "../{screen}"'
                rel_replace_dq = f'import "../screens/{screen}"'
                if rel_pattern_dq in content:
                    content = content.replace(rel_pattern_dq, rel_replace_dq)
                    modified = True

        elif level == 2:
            # File is in a sub-sub-directory like lib/phone/widgets/
            # import '../../screen.dart'; -> import '../../screens/screen.dart';
            rel_pattern = f"import '../../{screen}'"
            rel_replace = f"import '../../screens/{screen}'"
            if rel_pattern in content:
                content = content.replace(rel_pattern, rel_replace)
                modified = True

            rel_pattern_dq = f'import "../../{screen}"'
            rel_replace_dq = f'import "../../screens/{screen}"'
            if rel_pattern_dq in content:
                content = content.replace(rel_pattern_dq, rel_replace_dq)
                modified = True

    # C. If we are editing one of the moved screen files, we also need to adjust
    # its relative imports to other files (like providers, services, settings, phone)
    # that did not move.
    if level == 1 and parts[0] == "screens":
        # Any relative import to providers, services, settings, phone needs to go up one directory.
        # e.g., import 'providers/user_provider.dart'; -> import '../providers/user_provider.dart';
        # e.g., import 'services/auth_service.dart'; -> import '../services/auth_service.dart';
        # e.g., import 'phone/...'; -> import '../phone/...';
        # e.g., import 'settings/...'; -> import '../settings/...';
        
        # Let's use regex to find relative imports that don't start with package: or dart: or ../
        # Match pattern: import 'dir/
        # where dir is one of: providers, services, phone, settings
        for folder in ["providers", "services", "phone", "settings"]:
            # Single quote imports
            sq_pattern = rf"import\s+'{folder}/"
            sq_replace = f"import '../{folder}/"
            new_content = re.sub(sq_pattern, sq_replace, content)
            if new_content != content:
                content = new_content
                modified = True

            # Double quote imports
            dq_pattern = rf'import\s+"{folder}/'
            dq_replace = f'import "../{folder}/'
            new_content = re.sub(dq_pattern, dq_replace, content)
            if new_content != content:
                content = new_content
                modified = True

    if modified:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated imports in: {rel_path}")

# Walk through all dart files and update imports
print("Updating imports in Dart files...")
for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith(".dart"):
            update_imports(os.path.join(root, file))

print("Done refactoring layout!")
