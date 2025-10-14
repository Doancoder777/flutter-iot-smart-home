#!/usr/bin/env python3
"""Remove lines 279-464 from add_device_screen.dart"""

file_path = r'lib\screens\devices\add_device_screen.dart'

# Read all lines
with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Keep lines 1-278 and 465-end
new_lines = lines[:278] + lines[464:]

# Write back
with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print(f"✅ Removed lines 279-464 from {file_path}")
print(f"   Original: {len(lines)} lines")
print(f"   New: {len(new_lines)} lines")
print(f"   Deleted: {len(lines) - len(new_lines)} lines")
