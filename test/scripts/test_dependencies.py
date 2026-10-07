import importlib.util
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import yaml


SCRIPT_PATH = Path(__file__).resolve().parents[2] / "dependencies.py"
spec = importlib.util.spec_from_file_location("dependency_updater", SCRIPT_PATH)
updater = importlib.util.module_from_spec(spec)
spec.loader.exec_module(updater)


class CustomDependencyTests(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        self.root = Path(self.temp_dir.name)
        self.cache = self.root / "cache"
        self.output = self.root / "dependencies"

    def create_package(self, root, name, version, contents):
        package = root / name
        (package / "lib").mkdir(parents=True)
        (package / "pubspec.yaml").write_text(f"name: {name}\nversion: {version}\n")
        (package / "lib" / "camera.dart").write_text(contents)
        return package

    def test_custom_package_is_preserved_without_cache_or_git(self):
        package = self.create_package(self.output, "camera", "0.10.3", "custom code")
        for cache_only in (False, True):
            with self.subTest(cache_only=cache_only), patch.object(
                updater.subprocess, "run"
            ) as git:
                result = updater.integrate_package(
                    "camera", {"custom_changes": True},
                    self.cache, self.output, cache_only=cache_only,
                )
                self.assertEqual(result, [("camera", "0.10.3")])
                self.assertEqual((package / "lib" / "camera.dart").read_text(), "custom code")
                git.assert_not_called()

    def test_custom_subpackage_is_preserved_while_other_package_updates(self):
        custom = self.create_package(self.output, "camera", "0.7.4+6", "custom code")
        self.create_package(self.output, "video", "1.0.0", "old code")
        self.create_package(self.cache / "flutter_packages", "video", "2.0.0", "new code")
        # The protected camera source is deliberately absent from the cache.
        result = updater.integrate_package(
            "flutter_packages",
            {"subpackages": [
                {"name": "camera", "path": "camera", "custom_changes": True},
                {"name": "video", "path": "video"},
            ]},
            self.cache, self.output, cache_only=True,
        )
        self.assertEqual(result, [("camera", "0.7.4+6"), ("video", "2.0.0")])
        self.assertEqual((custom / "lib" / "camera.dart").read_text(), "custom code")
        self.assertEqual((self.output / "video" / "lib" / "camera.dart").read_text(), "new code")

    def test_all_custom_subpackages_need_no_cache_or_git(self):
        self.create_package(self.output, "camera", "0.7.4+6", "custom code")
        with patch.object(updater.subprocess, "run") as git:
            result = updater.integrate_package(
                "flutter_packages",
                {"subpackages": [{"name": "camera", "custom_changes": True}]},
                self.cache, self.output,
            )
            self.assertEqual(result, [("camera", "0.7.4+6")])
            git.assert_not_called()

    def test_missing_custom_package_fails_without_fetching_or_recreating_it(self):
        with patch.object(updater.subprocess, "run") as git:
            with self.assertRaisesRegex(FileNotFoundError, "Custom package not found"):
                updater.integrate_package(
                    "camera", {"custom_changes": True}, self.cache, self.output,
                )
            git.assert_not_called()
            self.assertFalse((self.output / "camera").exists())

    def test_full_update_retains_custom_flags_and_managed_pubspec_entries(self):
        self.create_package(self.output, "camera", "0.10.3", "custom code")
        config = {
            "cache": str(self.cache), "outdir": str(self.output),
            "dependencies": {"camera": {"custom_changes": True}},
        }
        (self.root / "dependencies.yaml").write_text(yaml.safe_dump(config))
        (self.root / "pubspec.yaml").write_text(
            "dependencies:\n"
            "## --- Start Managed Dependencies ---\n"
            "## --- End Managed Dependencies ---\n"
            "dependency_overrides:\n"
            "## --- Start Managed Dependency Overrides ---\n"
            "## --- End Managed Dependency Overrides ---\n"
        )
        previous_cwd = Path.cwd()
        try:
            os.chdir(self.root)
            with patch("sys.argv", ["dependencies.py"]), patch.object(
                updater.subprocess, "run"
            ) as git:
                updater.main()
                git.assert_not_called()
        finally:
            os.chdir(previous_cwd)
        pubspec = yaml.safe_load((self.root / "pubspec.yaml").read_text())
        self.assertEqual(pubspec["dependencies"]["camera"], "^0.10.3")
        self.assertEqual(pubspec["dependency_overrides"]["camera"]["path"], str(self.output / "camera"))
        saved_config = yaml.safe_load((self.root / "dependencies.yaml").read_text())
        self.assertTrue(saved_config["dependencies"]["camera"]["custom_changes"])
        self.assertEqual((self.output / "camera" / "lib" / "camera.dart").read_text(), "custom code")


if __name__ == "__main__":
    unittest.main()
