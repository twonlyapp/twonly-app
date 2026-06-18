#!/usr/bin/env python3
import os
import re
import sys

def parse_dependencies(pubspec_path):
    deps = []
    in_deps = False
    
    with open(pubspec_path, 'r', encoding='utf-8') as f:
        for line in f:
            stripped = line.strip()
            if not stripped or stripped.startswith('#'):
                continue
            
            # Detect starting of dependencies or ending
            if line[0].isalpha() or line.startswith('dev_dependencies') or line.startswith('dependency_overrides'):
                if stripped.startswith('dependencies:'):
                    in_deps = True
                else:
                    in_deps = False
                continue
                
            if in_deps:
                # Matches exactly 2 spaces indentation, followed by package name and colon
                match = re.match(r'^  ([a-zA-Z0-9_-]+):', line)
                if match:
                    dep = match.group(1)
                    # Ignore Flutter SDK built-ins and custom local rust bridge wrapper
                    if dep not in ['flutter', 'flutter_localizations', 'rust_lib_twonly']:
                        deps.append(dep)
    return deps

def find_used_packages(root_dir):
    used = set()
    # Matches: import 'package:package_name/...'; or export 'package:package_name/...';
    pattern = re.compile(r'(?:import|export)\s+[\'"]package:([a-zA-Z0-9_-]+)/')
    
    for dirpath, _, filenames in os.walk(root_dir):
        # Skip hidden directories (.git, .dart_tool, etc.)
        if any(part.startswith('.') for part in dirpath.split(os.sep)):
            continue
        for filename in filenames:
            if filename.endswith('.dart'):
                filepath = os.path.join(dirpath, filename)
                try:
                    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                        for line in f:
                            match = pattern.search(line)
                            if match:
                                used.add(match.group(1))
                except Exception:
                    pass
    return used

def main():
    # Locate project root (assuming script is in scripts/ or root/)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(script_dir, '..'))
    
    pubspec_path = os.path.join(project_root, 'pubspec.yaml')
    if not os.path.exists(pubspec_path):
        print(f"Error: pubspec.yaml not found at {pubspec_path}")
        sys.exit(1)
        
    print("Parsing dependencies from pubspec.yaml...")
    declared_deps = parse_dependencies(pubspec_path)
    print(f"Found {len(declared_deps)} runtime dependencies.")
    
    print("\nScanning codebase for imports/exports in lib/, test/, integration_test/...")
    used_in_code = set()
    for folder in ['lib', 'test', 'integration_test']:
        folder_path = os.path.join(project_root, folder)
        if os.path.exists(folder_path):
            used_in_code.update(find_used_packages(folder_path))
            
    unused_deps = []
    used_deps = []
    
    for dep in declared_deps:
        if dep in used_in_code:
            used_deps.append(dep)
        else:
            unused_deps.append(dep)
            
    print("\n" + "=" * 50)
    print("                   RESULTS")
    print("=" * 50)
    
    if unused_deps:
        print(f"\n❌ UNUSED DEPENDENCIES ({len(unused_deps)}):")
        for dep in sorted(unused_deps):
            print(f"  - {dep}")
    else:
        print("\n✅ All dependencies listed in pubspec.yaml are used in the codebase!")
        
    print(f"\n✨ USED DEPENDENCIES ({len(used_deps)}):")
    for dep in sorted(used_deps):
        print(f"  - {dep}")

if __name__ == '__main__':
    main()
