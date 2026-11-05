import hashlib
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).parents[1] / "scripts/enroll.py"
TOOLS = ("age", "age-keygen", "agenix", "ssh-keygen", "git")


@unittest.skipUnless(all(shutil.which(tool) for tool in TOOLS), "crypto tools required")
class EnrollmentTests(unittest.TestCase):
    def command(self, *args, **kwargs):
        return subprocess.run(args, check=True, capture_output=True, **kwargs)

    def key(self, name):
        private = self.root / name
        self.command("ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-f", str(private))
        return private, Path(str(private) + ".pub")

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.repo = self.root / "repo"
        self.repo.mkdir()
        self.command("git", "init", "-q", str(self.repo))
        (self.repo / "secrets").mkdir()
        self.source = self.root / "old-secrets"
        self.source.mkdir()
        self.trusted, self.trusted_pub = self.key("trusted")
        self.compromised, compromised_pub = self.key("compromised")
        self.target, self.target_pub = self.key("target")
        self.files = ("user-password.age", "rclone-r2.conf.age")
        for name in self.files:
            self.command("age", "-r", " ".join(self.trusted_pub.read_text().split()[:2]),
                         "-r", " ".join(compromised_pub.read_text().split()[:2]),
                         "-o", str(self.source / name), input=b"disposable secret")

    def enroll(self, host, public, identity=None, initialize=False):
        args = [sys.executable, "-B", str(SCRIPT), str(self.repo), host, str(public),
                str(identity or self.trusted)]
        if initialize:
            args += ["--initialize-from", str(self.source)]
        return self.command(*args)

    def hashes(self):
        return {p.name: hashlib.sha256(p.read_bytes()).digest()
                for p in (self.repo / "secrets").iterdir()}

    def test_full_migration_enrollment_and_repeat(self):
        self.enroll("oregairu-yui", self.trusted_pub, initialize=True)
        for name in self.files:
            path = str(self.repo / "secrets" / name)
            self.assertEqual(self.command("age", "-d", "-i", str(self.trusted), path).stdout,
                             b"disposable secret")
            with self.assertRaises(subprocess.CalledProcessError):
                self.command("age", "-d", "-i", str(self.compromised), path)
        self.enroll("oregairu-yukino", self.target_pub)
        for name in self.files:
            self.assertEqual(self.command("age", "-d", "-i", str(self.target),
                                          str(self.repo / "secrets" / name)).stdout,
                             b"disposable secret")
        before = self.hashes()
        self.enroll("oregairu-yukino", self.target_pub)
        self.assertEqual(self.hashes(), before)
        # A registered key with stale ciphertext must trigger repair, not a skip.
        for name in self.files:
            shutil.copyfile(self.source / name, self.repo / "secrets" / name)
        self.enroll("oregairu-yukino", self.target_pub)
        for name in self.files:
            self.command("age", "-d", "-i", str(self.target),
                         str(self.repo / "secrets" / name))
        replacement, replacement_pub = self.key("replacement")
        self.enroll("oregairu-yukino", replacement_pub)
        for name in self.files:
            path = str(self.repo / "secrets" / name)
            self.command("age", "-d", "-i", str(replacement), path)
            with self.assertRaises(subprocess.CalledProcessError):
                self.command("age", "-d", "-i", str(self.target), path)

    def test_unavailable_identity_preserves_files(self):
        self.enroll("oregairu-yui", self.trusted_pub, initialize=True)
        before = self.hashes()
        with self.assertRaises(subprocess.CalledProcessError):
            self.enroll("oregairu-yukino", self.target_pub, self.compromised)
        self.assertEqual(self.hashes(), before)


if __name__ == "__main__":
    unittest.main()
