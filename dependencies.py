import yaml
import os
import shutil
import subprocess
import argparse
import sys

def print_blue(text):
    BLUE = '\x1b[34m'
    RESET = '\x1b[0m'
    print(f"{BLUE}{text}{RESET}")

def print_yellow(text):
    YELLOW = '\x1b[33m'
    RESET = '\x1b[0m'
    print(f"{YELLOW}{text}{RESET}")

def get_git_head(repo_path='.'):
    result = subprocess.run(
        ['git', 'rev-parse', 'HEAD'],
        cwd=repo_path,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False
    )
    if result.returncode != 0:
        raise RuntimeError(f"git error: {result.stderr.strip()}")
    return result.stdout.strip()

def get_default_branch(repo_path='.'):
    result = subprocess.run(
        ['git', 'symbolic-ref', 'refs/remotes/origin/HEAD'],
        cwd=repo_path,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False
    )
    if result.returncode == 0:
        return result.stdout.strip().split('/')[-1]
    return 'main'

def integrate_package(folder_name, data, cache_dir, out_dir):
    repo_url = data['git']
    keep_list = ["lib", "LICENSE", "pubspec.yaml", "android", "ios", "darwin"]
    if "keep" in data:
        keep_list += [item.rstrip('/') for item in data['keep']]
    
    print(f"Processing {folder_name}...")

    cache_path = os.path.join(cache_dir, folder_name)
    if not os.path.exists(cache_path):
        subprocess.run(["git", "clone", repo_url, cache_path], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    else:
        result = subprocess.run(["git", "fetch", "--all"], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, cwd=cache_path)
        if result.returncode != 0:
            print_yellow(f"Warning: Could not fetch updates for {folder_name}. You might be offline.")
    
    if "commit" in data:
        commit_hash = data["commit"]
        subprocess.run(["git", "checkout", commit_hash], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, cwd=cache_path)
    elif "tag" in data:
        tag_name = data["tag"]
        subprocess.run(["git", "checkout", tag_name], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, cwd=cache_path)
    else:
        print_yellow(f"Warning: No commit or tag specified for {folder_name}. Using default branch.")
        default_branch = get_default_branch(cache_path)
        subprocess.run(["git", "checkout", default_branch], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, cwd=cache_path)
        subprocess.run(["git", "pull"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, cwd=cache_path)
        last_commit_hash = get_git_head(cache_path)
        data["commit"] = last_commit_hash
        print_blue(f"Recorded commit {last_commit_hash} for {folder_name}")

    results = [] # List of (pkg_name, version)
    
    if "subpackages" in data:
        packages_to_extract = data["subpackages"]
    else:
        packages_to_extract = [{"name": folder_name, "path": data.get("path", "")}]

    for pkg in packages_to_extract:
        pkg_name = pkg["name"]
        subpath = pkg.get("path", "")
        
        out_path = os.path.join(out_dir, pkg_name)
        if os.path.exists(out_path):
            shutil.rmtree(out_path)
        os.makedirs(out_path)
        
        package_src_path = os.path.join(cache_path, subpath) if subpath else cache_path
    
        for item in keep_list:
            src_item = os.path.join(package_src_path, item)
            dst_item = os.path.join(out_path, item)
            
            if os.path.exists(src_item):
                os.makedirs(os.path.dirname(dst_item), exist_ok=True)
                if os.path.isdir(src_item):
                    shutil.copytree(src_item, dst_item, dirs_exist_ok=True)
                else:
                    shutil.copy2(src_item, dst_item)
                    
        version = "any"
        try:
            pubspec_path = os.path.join(package_src_path, "pubspec.yaml")
            if os.path.exists(pubspec_path):
                with open(pubspec_path, "r") as f:
                    ps = yaml.safe_load(f)
                    if ps and isinstance(ps, dict):
                        version = ps.get("version", "any")
        except Exception as e:
            print_yellow(f"Warning: Could not read version from {pkg_name}/pubspec.yaml")
            
        results.append((pkg_name, version))
        
    return results

def main():
    parser = argparse.ArgumentParser(description="Update specific or all repositories.")
    parser.add_argument('repo_name', nargs='?', default=None, help="Name of the repository to update (optional)")
    args = parser.parse_args()

    with open("dependencies.yaml", "r") as f:
        config = yaml.safe_load(f)

    cache_dir = config.get('cache', './.cache')
    out_dir = config.get('outdir', './dependencies')
    deps = config.get('dependencies', {})

    if not os.path.exists(cache_dir):
        os.makedirs(cache_dir)
    if not os.path.exists(out_dir):
        os.makedirs(out_dir)

    repos_to_update = [args.repo_name] if args.repo_name else list(deps.keys())
    
    pubspec_overrides = []
    pubspec_deps = []

    def process_deps_recursive(deps_dict, to_update=None):
        for name, data in deps_dict.items():
            if to_update is None or name in to_update:
                extracted_packages = integrate_package(name, data, cache_dir, out_dir)
                for pkg_name, version in extracted_packages:
                    pubspec_overrides.append(f"  {pkg_name}:\n    path: {out_dir}/{pkg_name}\n")
                    if version and version != "any":
                        pubspec_deps.append(f"  {pkg_name}: ^{version}\n")
                    else:
                        pubspec_deps.append(f"  {pkg_name}: any\n")
            if "dependencies" in data:
                # If we updated the parent, we should update children? Or if no args provided, update all.
                # Actually, the original logic updated children automatically if parent is updated.
                process_deps_recursive(data["dependencies"], None if (to_update is None or name in to_update) else [])

    process_deps_recursive(deps, repos_to_update if args.repo_name else None)

    def sort_dependencies(d):
        sorted_d = {k: d[k] for k in sorted(d.keys())}
        for k, v in sorted_d.items():
            if "dependencies" in v and isinstance(v["dependencies"], dict):
                v["dependencies"] = sort_dependencies(v["dependencies"])
        return sorted_d

    if "dependencies" in config:
        config["dependencies"] = sort_dependencies(config["dependencies"])

    with open("dependencies.yaml", "w") as f:
        yaml.safe_dump(config, f, sort_keys=False)
    
    # Update pubspec.yaml
    if not args.repo_name:
        with open("pubspec.yaml", "r") as f:
            pubspec_lines = f.readlines()
        
        start_marker_overrides = "## --- Start Managed Dependency Overrides ---"
        end_marker_overrides = "## --- End Managed Dependency Overrides ---"
        
        start_marker_deps = "## --- Start Managed Dependencies ---"
        end_marker_deps = "## --- End Managed Dependencies ---"
        
        try:
            start_idx_overrides = next(i for i, line in enumerate(pubspec_lines) if line.strip() == start_marker_overrides)
            end_idx_overrides = next(i for i, line in enumerate(pubspec_lines) if line.strip() == end_marker_overrides)
            
            # Update overrides section
            new_lines = pubspec_lines[:start_idx_overrides + 1] + pubspec_overrides + pubspec_lines[end_idx_overrides:]
            
            # Now find the deps markers in the updated lines
            start_idx_deps = next(i for i, line in enumerate(new_lines) if line.strip() == start_marker_deps)
            end_idx_deps = next(i for i, line in enumerate(new_lines) if line.strip() == end_marker_deps)
            
            # Update dependencies section
            final_lines = new_lines[:start_idx_deps + 1] + pubspec_deps + new_lines[end_idx_deps:]
            
            with open("pubspec.yaml", "w") as f:
                f.writelines(final_lines)
            print_blue("Updated pubspec.yaml successfully.")
        except ValueError as e:
            print_yellow("Error: Could not find professional markers in pubspec.yaml.")
            sys.exit(1)

if __name__ == "__main__":
    main()
