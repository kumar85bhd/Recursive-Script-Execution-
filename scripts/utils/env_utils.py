#!/usr/bin/env python3
"""
scripts/utils/env_utils.py
Shared utilities for reading/writing env files and CSV-style txt files.
All functions raise exceptions on error — callers decide how to handle.
"""
import os, csv
from typing import Dict
from datetime import datetime


def read_env_file(env_path: str) -> Dict[str, str]:
    """Read KEY=VALUE env file. Skips blank lines and # comments."""
    if not os.path.exists(env_path):
        raise FileNotFoundError(f'Env file not found: {env_path}')
    result = {}
    with open(env_path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#') or '=' not in line:
                continue
            key, _, val = line.partition('=')
            result[key.strip()] = val.strip()
    return result


def read_txt_as_csv(txt_path: str) -> list:
    """Read comma-separated .txt with header row. Returns list of dicts."""
    if not os.path.exists(txt_path):
        raise FileNotFoundError(f'Input file not found: {txt_path}')
    with open(txt_path, newline='') as f:
        reader = csv.DictReader(f, skipinitialspace=True)
        return [{k.strip(): v.strip() for k, v in row.items()} for row in reader]


def write_env_file(env_path: str, kv: Dict[str, str]):
    """Write dict as KEY=VALUE lines. Creates parent dirs if needed."""
    os.makedirs(os.path.dirname(env_path), exist_ok=True)
    with open(env_path, 'w') as f:
        for key, val in kv.items():
            f.write(f'{key}={val}\n')


def write_all_env_dump(out_path: str, folder_name: str,
                       sections: Dict[str, Dict[str, str]]):
    """Write all env sections to a human-readable dump file."""
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, 'w') as f:
        f.write(f'=== Environment Dump: {folder_name} ===\n')
        f.write(f'Generated: {datetime.now()}\n\n')
        for section, vals in sections.items():
            f.write(f'[{section}]\n')
            for k, v in vals.items():
                f.write(f'  {k} = {v}\n')
            f.write('\n')
