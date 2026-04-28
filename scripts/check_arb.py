import os
import json
import re
import sys

ARB_DIR = 'lib/src/localization/translations'
LIB_DIR = 'lib'

def get_arb_data(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
        return {}

def save_arb_data(filepath, data):
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write('\n')

def get_keys(data):
    return {k for k in data.keys() if k and not k.startswith('@')}

def main():
    fix_mode = '--fix' in sys.argv

    en_file = os.path.join(ARB_DIR, 'en.arb')
    if not os.path.exists(en_file):
        print(f"Error: {en_file} not found. Please run this script from the project root.")
        return

    en_data = get_arb_data(en_file)
    en_keys = get_keys(en_data)
    print(f"Found {len(en_keys)} keys in en.arb")

    # 1. Check for unused keys in Dart files
    print("\n--- Checking for unused keys in Dart files ---")
    all_dart_text = ""
    for root, _, files in os.walk(LIB_DIR):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                if "generated" in str(filepath):
                    continue
                try:
                    with open(filepath, 'r', encoding='utf-8') as f:
                        all_dart_text += f.read() + "\n"
                except Exception as e:
                    print(f"Could not read {filepath}: {e}")

    unused_keys = set()
    for key in sorted(en_keys):
        # Using word boundary to avoid partial matches
        pattern = r'\b' + re.escape(key) + r'\b'
        if not re.search(pattern, all_dart_text):
            unused_keys.add(key)
            
    if unused_keys:
        print(f"Found {len(unused_keys)} keys in en.arb that do not appear to be used in the Dart code:")
        for k in sorted(unused_keys):
            print(f"  - {k}")
            
        if fix_mode:
            print("\n--fix is enabled. Deleting unused keys from all .arb files...")
            arb_files = [f for f in os.listdir(ARB_DIR) if f.endswith('.arb')]
            for arb_file in arb_files:
                filepath = os.path.join(ARB_DIR, arb_file)
                data = get_arb_data(filepath)
                deleted_count = 0
                for k in unused_keys:
                    if k in data:
                        del data[k]
                        # Also delete associated metadata if it exists
                        meta_k = f"@{k}"
                        if meta_k in data:
                            del data[meta_k]
                        deleted_count += 1
                
                if deleted_count > 0:
                    save_arb_data(filepath, data)
                    print(f"Deleted {deleted_count} unused keys from {arb_file}")
            
            # Remove deleted keys from our set so the comparison below is accurate
            en_keys = en_keys - unused_keys
        else:
            print("\nRun with --fix to automatically delete these unused keys.")
    else:
        print("All keys in en.arb seem to be used in the Dart files.")

    # 2. Compare other .arb files with en.arb
    print("\n--- Comparing other .arb files with en.arb ---")
    arb_files = [f for f in os.listdir(ARB_DIR) if f.endswith('.arb')]
    for arb_file in arb_files:
        if arb_file == 'en.arb':
            continue
            
        filepath = os.path.join(ARB_DIR, arb_file)
        data = get_arb_data(filepath)
        other_keys = get_keys(data)
        
        extra_keys = other_keys - en_keys
        missing_keys = en_keys - other_keys
        
        print(f"\n[{arb_file} vs en.arb]")
        if extra_keys:
            print(f"Keys in {arb_file} but NOT in en.arb ({len(extra_keys)}):")
            for k in sorted(extra_keys):
                print(f"  + {k}")
        else:
            print(f"No extra keys found in {arb_file} (all keys are in en.arb).")
            
        if missing_keys:
            print(f"Keys in en.arb but NOT in {arb_file} ({len(missing_keys)}):")
            for k in sorted(missing_keys):
                print(f"  - {k}")
        else:
            print(f"No missing keys in {arb_file} (it has all en.arb keys).")

if __name__ == "__main__":
    main()
