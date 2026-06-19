import os

def insert_import(file_path, import_stmt):
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()
    
    if import_stmt not in content:
        # Find the last import statement
        last_import_index = content.rfind("import ")
        if last_import_index != -1:
            end_of_line = content.find("\n", last_import_index)
            content = content[:end_of_line+1] + import_stmt + "\n" + content[end_of_line+1:]
        else:
            content = import_stmt + "\n" + content
            
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Added {import_stmt} to {file_path}")

insert_import(r"e:\bondnex\lib\main.dart", "import 'package:bondnex/settings/profile/account_settings_screen.dart';")
insert_import(r"e:\bondnex\lib\main.dart", "import 'package:bondnex/settings/security/panic_button_settings_screen.dart';")

insert_import(r"e:\bondnex\lib\phone\screens\phone_screen.dart", "import 'package:bondnex/phone/screens/phone_settings_screen.dart';")

print("Done")
