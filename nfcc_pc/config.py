import json
import os
import uuid

CONFIG_DIR = os.path.join(os.path.expanduser("~"), ".nfcc")
CONFIG_FILE = os.path.join(CONFIG_DIR, "config.json")
LOG_FILE = os.path.join(CONFIG_DIR, "nfcc.log")

DEFAULT_CONFIG = {
    "id": str(uuid.uuid4()),
    "port": 9876,
    "pairing_token": str(uuid.uuid4()),
    "auto_start": False,
    "allowed_devices": [],
}


def load_config() -> dict:
    os.makedirs(CONFIG_DIR, exist_ok=True)
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, "r") as f:
            return json.load(f)
    # Create default config
    save_config(DEFAULT_CONFIG)
    return DEFAULT_CONFIG.copy()


def save_config(config: dict):
    os.makedirs(CONFIG_DIR, exist_ok=True)
    with open(CONFIG_FILE, "w") as f:
        json.dump(config, f, indent=2)


def get_config_value(key: str, default=None):
    config = load_config()
    return config.get(key, default)
