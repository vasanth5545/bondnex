import os
import re

screens_dir = r"E:\bondnex\lib\screens"

# Subdirectories we created
subdirs = ['auth', 'dashboard', 'profile', 'gallery', 'communication']

for subdir in subdirs:
    dir_path = os.path.join(screens_dir, subdir)
    if not os.path.exists(dir_path): continue
    
    for filename in os.listdir(dir_path):
        if not filename.endswith('.dart'): continue
        filepath = os.path.join(dir_path, filename)
        
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # We moved files one level deeper, so:
        # '../services/' -> '../../services/'
        # '../providers/' -> '../../providers/'
        # '../phone/' -> '../../phone/'
        # '../settings/' -> '../../settings/'
        # '../theme/' -> '../../theme/'
        # '../models/' -> '../../models/'
        
        content = re.sub(r"import '\.\./services/", "import '../../services/", content)
        content = re.sub(r"import '\.\./providers/", "import '../../providers/", content)
        content = re.sub(r"import '\.\./phone/", "import '../../phone/", content)
        content = re.sub(r"import '\.\./settings/", "import '../../settings/", content)
        content = re.sub(r"import '\.\./theme/", "import '../../theme/", content)
        content = re.sub(r"import '\.\./models/", "import '../../models/", content)
        
        # Intra-screens imports
        # 'login_screen.dart' (when it was in screens) -> if importing from another screen folder:
        # e.g., in auth_wrapper.dart, it might import 'login_screen.dart' -> now they are in same dir, so it's fine.
        # But if it imports 'dashboard_screen.dart' (which moved to dashboard/), we need '../dashboard/dashboard_screen.dart'
        
        # Let's handle the specific intra-screen imports manually below if needed,
        # but first let's run this auto-replace for the base level folders.
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed {filepath}")
