#!/usr/bin/env python3
import os
import subprocess
from textwrap import dedent

REPO_ROOT = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(REPO_ROOT, os.pardir))

# Default environment file expected by the project
DEFAULT_ENV_FILE = os.path.join(REPO_ROOT, ".env.local")

REQUIRED_VARS = [
    "POSTGRES_PASSWORD",
    "GITHUB_LOGIN_APP_ID",
    "GITHUB_LOGIN_APP_INSTALLATION_ID",
    "GITHUB_LOGIN_KEY",
    "GITHUB_LOGIN_SYSTEM_USER_NAME",
    "GITHUB_LOGIN_SYSTEM_USER_PERSONALACCESSTOKEN",
]

README_LINK = os.path.join(REPO_ROOT, "README.md")


def prompt_env_path() -> str:
    """Ask the user to confirm or provide the environment file."""
    print("\nStep 1: Specify environment file")
    print(f"Default location: {os.path.relpath(DEFAULT_ENV_FILE, REPO_ROOT)}")
    custom = input("Press Enter to accept or provide custom path relative to repo: ").strip()
    path = DEFAULT_ENV_FILE if not custom else os.path.join(REPO_ROOT, custom)
    if not os.path.exists(path):
        print(f"Warning: {path} does not exist.\n")
    else:
        print(f"Using {path} for environment configuration.\n")
    return path


def run(cmd):
    """Run a shell command and stream output."""
    print(f"\n$ {' '.join(cmd)}")
    process = subprocess.Popen(cmd)
    process.communicate()


def check_docker():
    try:
        subprocess.run(["docker", "version"], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("Docker is not installed or not running.\n")
        return False


def get_images():
    try:
        res = subprocess.run(["docker", "compose", "config", "--images"],
                             check=True, capture_output=True, text=True)
        return [img.strip() for img in res.stdout.splitlines() if img.strip()]
    except subprocess.CalledProcessError:
        return []


def check_images():
    print("\nStep 2: Checking required images...")
    images = get_images()
    missing = []
    for img in images:
        res = subprocess.run(["docker", "images", "-q", img], capture_output=True, text=True)
        if not res.stdout.strip():
            missing.append(img)
    if missing:
        print("Images missing and need build: " + ", ".join(missing))
    else:
        print("All service images are available.")


def load_env(path: str) -> dict:
    env = {}
    if os.path.exists(path):
        with open(path) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#') or '=' not in line:
                    continue
                key, val = line.split('=', 1)
                env[key] = val
    return env


def check_env(env_path: str):
    print("\nStep 3: Checking environment configuration...")
    env = load_env(env_path)
    missing = [var for var in REQUIRED_VARS if not env.get(var)]
    if missing:
        print("Missing variables: " + ", ".join(missing))
        print(f"See README for setup instructions: {README_LINK}\n")
    else:
        print("All required environment variables are set.")


def detect_platform():
    print("\nStep 4: Detecting Docker build platform...")
    try:
        res = subprocess.run(["docker", "version", "--format", "{{.Server.Os}}/{{.Server.Arch}}"],
                             check=True, capture_output=True, text=True)
        platform = res.stdout.strip()
    except subprocess.CalledProcessError:
        platform = "unknown"
    print(f"Docker build platform detected: {platform}\n")


def build_images():
    print("\nStep 5: Building images...")
    run(["docker", "compose", "build"])


def start_containers(build: bool = False):
    cmd = ["docker", "compose", "up", "-d"]
    if build:
        cmd.append("--build")
    run(cmd)


def restart_containers():
    run(["docker", "compose", "restart"])


def reboot_clean():
    run(["docker", "compose", "up", "-d", "--build", "--force-recreate"])


def nuclear_rebuild():
    run(["docker", "compose", "down", "-v"])
    run(["docker", "compose", "up", "-d", "--build"])


def stop_containers():
    run(["docker", "compose", "down"])


MENU = dedent("""
    Select an action:
    1) Start containers
    2) Respring APIs
    3) Reboot APIs with clean build
    4) Rebuild all APIs and restart Postgres (destructive)
    5) Stop containers
    6) Exit
""")


def interactive_loop():
    print("\nStep 6: Manage running containers")
    while True:
        print(MENU)
        choice = input("Choice: ").strip()
        if choice == "1":
            start_containers()
        elif choice == "2":
            restart_containers()
        elif choice == "3":
            reboot_clean()
        elif choice == "4":
            nuclear_rebuild()
        elif choice == "5":
            stop_containers()
        elif choice == "6":
            break


def main():
    if not check_docker():
        return
    env_path = prompt_env_path()
    check_images()
    check_env(env_path)
    detect_platform()
    build = input("Build images now? [y/N] ").strip().lower() == 'y'
    if build:
        build_images()
    interactive_loop()


if __name__ == "__main__":
    main()

