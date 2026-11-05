import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("enroll", Path(__file__).parents[1] / "scripts/enroll.py")
enroll = importlib.util.module_from_spec(spec)
spec.loader.exec_module(enroll)


class TransactionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name)
        self.destination = root / "secrets"
        self.stage = root / "stage"
        self.destination.mkdir()
        self.stage.mkdir()
        self.journal = root / "journal.json"
        self.names = (enroll.RULES, *enroll.FILES)
        for name in self.names:
            (self.destination / name).write_bytes(b"old")
            (self.stage / name).write_bytes(b"new")

    def assert_contents(self, expected):
        for name in self.names:
            self.assertEqual((self.destination / name).read_bytes(), expected)

    def test_commit(self):
        enroll.commit(self.stage, self.destination, self.journal)
        self.assert_contents(b"new")
        self.assertFalse(self.journal.exists())

    def test_second_file_failure_restores_all_files(self):
        original = enroll.atomic_write
        failed = False

        def fail_once(path, *args, **kwargs):
            nonlocal failed
            if path == self.destination / enroll.FILES[0] and not failed:
                failed = True
                raise OSError("injected write failure")
            return original(path, *args, **kwargs)

        with patch.object(enroll, "atomic_write", fail_once):
            with self.assertRaises(OSError):
                enroll.commit(self.stage, self.destination, self.journal)
        self.assert_contents(b"old")
        self.assertFalse(self.journal.exists())

    def test_power_loss_recovers_on_next_run(self):
        original = enroll.atomic_write

        def stop_after_journal(path, *args, **kwargs):
            if path.parent == self.destination:
                raise OSError("power loss")
            return original(path, *args, **kwargs)

        with patch.object(enroll, "atomic_write", stop_after_journal):
            with self.assertRaises(OSError):
                enroll.commit(self.stage, self.destination, self.journal)
        self.assertTrue(self.journal.exists())
        (self.destination / enroll.RULES).write_bytes(b"partial")
        enroll.recover(self.journal, self.destination)
        self.assert_contents(b"old")
        self.assertFalse(self.journal.exists())

    def test_unknown_rules_rejected(self):
        path = self.destination / enroll.RULES
        path.write_text('{ "secret.age".publicKeys = []; }')
        with self.assertRaises(ValueError):
            enroll.read_hosts(path)

    def test_initialization_failure_removes_new_files(self):
        for path in self.destination.iterdir():
            path.unlink()
        original = enroll.atomic_write
        failed = False

        def fail_once(path, *args, **kwargs):
            nonlocal failed
            if path == self.destination / enroll.FILES[0] and not failed:
                failed = True
                raise OSError("initialization failed")
            return original(path, *args, **kwargs)

        with patch.object(enroll, "atomic_write", fail_once):
            with self.assertRaises(OSError):
                enroll.commit(self.stage, self.destination, self.journal)
        self.assertEqual(list(self.destination.iterdir()), [])
        self.assertFalse(self.journal.exists())

    def test_recipient_roundtrip(self):
        hosts = {"oregairu-yui": "ssh-ed25519 AAAA"}
        path = self.destination / enroll.RULES
        path.write_text(enroll.render(hosts))
        self.assertEqual(enroll.read_hosts(path), hosts)


if __name__ == "__main__":
    unittest.main()
