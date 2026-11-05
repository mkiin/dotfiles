#!/usr/bin/env python3
"""Rekey on a trusted host. Private keys never become repository contents."""
import argparse
import base64
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import tempfile

FILES = ("user-password.age", "rclone-r2.conf.age")
RULES = "agenix-rules.nix"
PREFIX = "let\n  hosts = builtins.fromJSON ''\n"
SUFFIX = "\n  '';\n  recipients = builtins.attrValues hosts;\nin\n{\n" + "".join(
    f'  "{name}".publicKeys = recipients;\n' for name in FILES
) + "}\n"


def run(args, **kwargs):
    return subprocess.run(args, check=True, **kwargs)


def public_key(path):
    # Ignore comments when comparing keys, but validate the actual SSH encoding.
    key = path.read_text().strip().split()
    if len(key) < 2 or key[0] != "ssh-ed25519":
        raise ValueError("An Ed25519 public key is required")
    run(["ssh-keygen", "-lf", str(path)], stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL)
    return " ".join(key[:2])


def render(hosts):
    return PREFIX + json.dumps(hosts, sort_keys=True, indent=2) + SUFFIX


def read_hosts(path):
    text = path.read_text()
    if not text.startswith(PREFIX) or not text.endswith(SUFFIX):
        raise ValueError("Unknown rules format; refusing to discard existing recipients")
    hosts = json.loads(text[len(PREFIX):-len(SUFFIX)])
    if not isinstance(hosts, dict) or not hosts:
        raise ValueError("Empty recipient list")
    for name, key in hosts.items():
        if not re.fullmatch(r"[a-z0-9][a-z0-9-]*", name):
            raise ValueError("Invalid host name")
        if not re.fullmatch(r"ssh-ed25519 [A-Za-z0-9+/=]+", key):
            raise ValueError("Invalid recipient")
    return hosts


def digest(path, identity):
    # Drain the stream even on authentication failure; only return a verified hash.
    with subprocess.Popen(["age", "-d", "-i", str(identity), str(path)],
                          stdout=subprocess.PIPE, stderr=subprocess.DEVNULL) as proc:
        value = hashlib.file_digest(proc.stdout, "sha256").digest()
        if proc.wait() != 0:
            raise ValueError(f"Cannot decrypt {path.name} with the supplied identity")
    return value


def sync_dir(path):
    fd = os.open(path, os.O_RDONLY | os.O_DIRECTORY)
    try:
        os.fsync(fd)
    finally:
        os.close(fd)


def atomic_write(path, data, mode=0o600, owner=None):
    fd, temp = tempfile.mkstemp(prefix=".enroll-", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(data)
            os.fchmod(stream.fileno(), mode)
            if owner is not None:
                os.fchown(stream.fileno(), *owner)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temp, path)
        sync_dir(path.parent)
    finally:
        Path(temp).unlink(missing_ok=True)


def recover(journal, destination):
    if not journal.exists():
        return
    records = json.loads(journal.read_text())
    if set(records) != {RULES, *FILES}:
        raise ValueError("Invalid transaction journal; manual recovery required")
    for name, record in records.items():
        path = destination / name
        if path.is_symlink():
            raise ValueError("Refusing to restore through a symlink")
        if record is None:
            path.unlink(missing_ok=True)
        else:
            atomic_write(path, base64.b64decode(record["data"]), record["mode"],
                         (record["uid"], record["gid"]))
    sync_dir(destination)
    journal.unlink()
    sync_dir(journal.parent)


def commit(stage, destination, journal):
    records = {}
    for name in (RULES, *FILES):
        path = destination / name
        if path.is_symlink():
            raise ValueError("Refusing to overwrite a symlink")
        if path.exists():
            info = path.stat()
            records[name] = dict(data=base64.b64encode(path.read_bytes()).decode(),
                                 mode=info.st_mode & 0o777, uid=info.st_uid, gid=info.st_gid)
        else:
            records[name] = None
    atomic_write(journal, json.dumps(records).encode())
    try:
        owner = destination.stat()
        for name in (RULES, *FILES):
            previous = records[name]
            atomic_write(destination / name, (stage / name).read_bytes(),
                         previous["mode"] if previous else 0o644,
                         (previous["uid"], previous["gid"]) if previous else
                         (owner.st_uid, owner.st_gid))
        journal.unlink()
        sync_dir(journal.parent)
    except BaseException:
        recover(journal, destination)
        raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repo", type=Path)
    parser.add_argument("host")
    parser.add_argument("public_key", type=Path)
    parser.add_argument("identity", type=Path, help="Trusted host private key, kept outside Git")
    parser.add_argument("--initialize-from", type=Path,
                        help="One-time migration: drop compromised recipients and retain only this host")
    args = parser.parse_args()
    os.umask(0o077)
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]*", args.host):
        raise ValueError("Invalid host name")
    repo = args.repo.resolve(strict=True)
    destination = repo / "secrets"
    if destination.is_symlink() or not destination.is_dir():
        raise ValueError("Expected a real secrets directory")
    identity = args.identity.resolve(strict=True)
    if identity.is_relative_to(repo):
        raise ValueError("Private identity must be outside the repository")
    git_dir = Path(run(["git", "-c", f"safe.directory={repo}", "-C", str(repo),
                        "rev-parse", "--absolute-git-dir"],
                       capture_output=True, text=True).stdout.strip())
    with (git_dir / "enroll.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        journal = git_dir / "enroll-transaction.json"
        recover(journal, destination)
        key = public_key(args.public_key.resolve(strict=True))
        source = args.initialize_from.resolve(strict=True) if args.initialize_from else destination
        if args.initialize_from:
            if any((destination / name).exists() for name in (RULES, *FILES)):
                raise ValueError("Initialization requires absent rules and encrypted files")
            own_key = run(["ssh-keygen", "-y", "-f", str(identity)],
                          capture_output=True, text=True).stdout.strip().split()
            if " ".join(own_key[:2]) != key:
                raise ValueError("Initialization key must match the supplied trusted identity")
            hosts = {args.host: key}
        else:
            hosts = read_hosts(destination / RULES)
        before = {name: digest(source / name, identity) for name in FILES}
        if not args.initialize_from and hosts.get(args.host) == key:
            check = subprocess.run(["agenix", "-c"], cwd=destination,
                                   env=dict(os.environ, AGENIX_RULES=str(destination / RULES)),
                                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if check.returncode == 0:
                print("Already enrolled; encrypted files unchanged.")
                return
        hosts[args.host] = key
        # agenix writes temporary plaintext: keep its temporary files in RAM.
        # This does not protect against an untrusted host or unencrypted swap.
        with tempfile.TemporaryDirectory(prefix="enroll-", dir="/dev/shm") as temporary:
            stage = Path(temporary)
            for name in FILES:
                (stage / name).write_bytes((source / name).read_bytes())
            (stage / RULES).write_text(render(hosts))
            env = dict(os.environ, AGENIX_RULES=str(stage / RULES), TMPDIR=str(stage))
            run(["agenix", "-r", "-i", str(identity)], cwd=stage, env=env,
                stdout=subprocess.DEVNULL)
            run(["agenix", "-c"], cwd=stage, env=env, stdout=subprocess.DEVNULL)
            for name in FILES:
                if digest(stage / name, identity) != before[name]:
                    raise ValueError("Rekey changed secret content")
            commit(stage, destination, journal)
        print("Rekey committed. Verify decryption on the new host before switching.")


if __name__ == "__main__":
    def interrupted(signum, frame):
        raise InterruptedError(f"Interrupted by signal {signum}")
    signal.signal(signal.SIGTERM, interrupted)
    signal.signal(signal.SIGHUP, interrupted)
    main()
