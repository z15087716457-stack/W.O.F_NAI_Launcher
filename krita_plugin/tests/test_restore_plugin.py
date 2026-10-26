import json
import shutil
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from test_install_plugin import _load_install_plugin


class RestorePluginTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="krita_restore_")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.module = _load_install_plugin()
        self.profile = self.root / "pykrita"
        self.backup = self.root / "backup"
        self.kritarc = self.root / "kritarc"
        (self.profile / self.module.PLUGIN_NAME).mkdir(parents=True)
        (self.backup / self.module.PLUGIN_NAME).mkdir(parents=True)
        (self.profile / self.module.PLUGIN_NAME / "current.py").write_text("current plugin")
        (self.profile / self.module.DESKTOP_NAME).write_text("current desktop")
        self.kritarc.write_text("current config")
        (self.backup / self.module.PLUGIN_NAME / "original.py").write_text("original plugin")
        (self.backup / self.module.DESKTOP_NAME).write_text("original desktop")
        (self.backup / "kritarc").write_text("original config")
        self.manifest = {
            "plugin_name": self.module.PLUGIN_NAME,
            "desktop_name": self.module.DESKTOP_NAME,
            "had_desktop": True,
            "had_plugin_dir": True,
            "had_kritarc": True,
        }
        self.write_manifest()

    def write_manifest(self):
        (self.backup / self.module.MANIFEST_NAME).write_text(json.dumps(self.manifest))

    def restore(self):
        return self.module.restore_profile(
            pykrita_dir=self.profile,
            kritarc_path=self.kritarc,
            backup_dir=self.backup,
            apply=True,
            krita_running=False,
        )

    def snapshot(self):
        return {
            str(path.relative_to(self.root)): path.read_bytes()
            for path in self.root.rglob("*") if path.is_file()
        }

    def test_each_missing_backup_preserves_the_entire_current_profile(self):
        for name in [self.module.DESKTOP_NAME, self.module.PLUGIN_NAME, "kritarc"]:
            with self.subTest(name=name):
                backup = self.backup / name
                parked = self.root / "parked"
                backup.rename(parked)
                before = self.snapshot()
                with self.assertRaises(FileNotFoundError):
                    self.restore()
                self.assertEqual(before, self.snapshot())
                parked.rename(backup)

    def test_wrong_backup_types_preserve_the_current_profile(self):
        for name in [self.module.DESKTOP_NAME, self.module.PLUGIN_NAME, "kritarc"]:
            with self.subTest(name=name):
                backup = self.backup / name
                parked = self.root / "parked"
                backup.rename(parked)
                if parked.is_dir():
                    backup.write_text("not a directory")
                else:
                    backup.mkdir()
                before = self.snapshot()
                with self.assertRaises(FileNotFoundError):
                    self.restore()
                self.assertEqual(before, self.snapshot())
                if backup.is_dir():
                    backup.rmdir()
                else:
                    backup.unlink()
                parked.rename(backup)

    def test_incomplete_or_invalid_manifest_never_removes_current_files(self):
        original = dict(self.manifest)
        variants = [{}, [], dict(original, had_desktop="true"),
                    dict(original, plugin_name="other"), dict(original, desktop_name="other")]
        for key in ["had_desktop", "had_plugin_dir", "had_kritarc"]:
            missing = dict(original)
            del missing[key]
            variants.append(missing)
        for manifest in variants:
            with self.subTest(manifest=manifest):
                self.manifest = manifest
                self.write_manifest()
                before = self.snapshot()
                with self.assertRaises(ValueError):
                    self.restore()
                self.assertEqual(before, self.snapshot())

    def test_partial_staging_copy_failure_keeps_current_and_backup_files(self):
        before = self.snapshot()
        copytree = shutil.copytree

        def fail_copy(source, destination, *args, **kwargs):
            if Path(source) == self.backup / self.module.PLUGIN_NAME:
                Path(destination).mkdir()
                (Path(destination) / "partial.py").write_text("partial")
                raise OSError("copy interrupted")
            return copytree(source, destination, *args, **kwargs)

        with patch.object(self.module.shutil, "copytree", side_effect=fail_copy):
            with self.assertRaisesRegex(OSError, "copy interrupted"):
                self.restore()
        self.assertEqual(before, self.snapshot())

    def test_publish_failure_restores_all_three_current_paths(self):
        before = self.snapshot()
        rename = Path.rename

        def fail_publish(source, target):
            if Path(source).name == "replacement" and Path(target) == self.kritarc:
                raise OSError("publish interrupted")
            return rename(source, target)

        with patch.object(Path, "rename", new=fail_publish):
            with self.assertRaisesRegex(OSError, "publish interrupted"):
                self.restore()
        self.assertEqual(before, self.snapshot())

    def test_failed_rollback_preserves_stashed_current_files_and_reports_paths(self):
        rename = Path.rename

        def fail_rename(source, target):
            source, target = Path(source), Path(target)
            if source.name == "replacement" and target == self.kritarc:
                raise OSError("publish interrupted")
            if source.name == "current" and target == self.profile / self.module.DESKTOP_NAME:
                raise OSError("rollback interrupted")
            return rename(source, target)

        with patch.object(Path, "rename", new=fail_rename):
            with self.assertRaisesRegex(RuntimeError, "preserved at") as error:
                self.restore()
        stashed = list(self.root.rglob("current"))
        self.assertTrue(any(path.is_file() and path.read_text() == "current desktop"
                            for path in stashed))
        self.assertTrue(any(str(path.parent) in str(error.exception) for path in stashed))
        self.assertEqual("original desktop", (self.backup / self.module.DESKTOP_NAME).read_text())
        self.assertEqual("original plugin", (self.backup / self.module.PLUGIN_NAME / "original.py").read_text())

    def test_success_restores_all_paths_and_keeps_the_backup(self):
        self.assertTrue(self.restore().applied)
        self.assertEqual("original desktop", (self.profile / self.module.DESKTOP_NAME).read_text())
        self.assertEqual("original plugin", (self.profile / self.module.PLUGIN_NAME / "original.py").read_text())
        self.assertFalse((self.profile / self.module.PLUGIN_NAME / "current.py").exists())
        self.assertEqual("original config", self.kritarc.read_text())
        self.assertFalse(list(self.root.rglob(".restore-*")))
        self.assertTrue((self.backup / self.module.PLUGIN_NAME / "original.py").exists())
