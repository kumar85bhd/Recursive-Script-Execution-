#!/usr/bin/env python3
"""
scripts/utils/env_utils.py
Shared utilities for reading/writing env files and CSV-style txt files.
All functions raise exceptions on error — callers decide how to handle.
"""
import os, csv, re
from typing import Dict
from datetime import datetime

def read_env_file(env_path: str) -> Dict[str, str]:
    """Read KEY=VALUE, setenv, or set env file. Skips blank lines and # comments."""
    if not os.path.exists(env_path):
        raise FileNotFoundError(f'Env file not found: {env_path}')
    result = {}
    with open(env_path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            
            if line.startswith("export") and "=" in line:
                key = line.split("=")[0].replace("export", "").strip()
                val = line.split("=", 1)[1].strip()
                result[key] = val
            elif line.startswith("setenv"):
                parts = line.split(maxsplit=2)
                if len(parts) >= 3:
                    key = parts[1].strip()
                    val = parts[2].strip().strip('"').strip("'")
                    result[key] = val
            elif line.startswith("set ") and "=" in line:
                match = re.match(r"set\s+(\w+)\s*=\s*\"?(.*?)\"?", line)
                if match:
                    key = match.group(1)
                    val = match.group(2)
                    result[key] = val
            # Fallback for simple KEY=VALUE without export
            elif "=" in line and not line.startswith("set"):
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

def update_env_file(template_path, output_path, values_dict):
    updated_vars = {}

    # Normalize input keys to uppercase for robust matching
    normalized_values = {str(k).strip().upper(): v for k, v in values_dict.items() if k is not None}

    with open(template_path) as f:
        lines = f.readlines()

    updated_lines = []

    for line in lines:
        stripped = line.strip()

        # export VAR=value
        if stripped.startswith("export") and "=" in stripped:
            key = stripped.split("=")[0].replace("export", "").strip()
            upper_key = key.upper()

            if upper_key in normalized_values:
                val = normalized_values[upper_key]
                if val is not None and str(val).strip() != "":
                    updated_lines.append(f"export {key}={val}\n")
                    updated_vars[key] = val
                else:
                    updated_lines.append(line)
            else:
                updated_lines.append(line)

        # setenv VAR "value"
        elif stripped.startswith("setenv"):
            parts = stripped.split()
            if len(parts) >= 3:
                key = parts[1]
                upper_key = key.upper()

                if upper_key in normalized_values:
                    val = normalized_values[upper_key]
                    if val is not None and str(val).strip() != "":
                        updated_lines.append(f'setenv {key} "{val}"\n')
                        updated_vars[key] = val
                    else:
                        updated_lines.append(line)
                else:
                    updated_lines.append(line)
            else:
                updated_lines.append(line)

        # set VAR = "value"
        elif stripped.startswith("set ") and "=" in stripped:
            match = re.match(r"set\s+(\w+)\s*=\s*\"?.*\"?", stripped)
            if match:
                key = match.group(1)
                upper_key = key.upper()

                if upper_key in normalized_values:
                    val = normalized_values[upper_key]
                    if val is not None and str(val).strip() != "":
                        updated_lines.append(f'set {key} = "{val}"\n')
                        updated_vars[key] = val
                    else:
                        updated_lines.append(line)
                else:
                    updated_lines.append(line)
            else:
                updated_lines.append(line)

        else:
            updated_lines.append(line)

    with open(output_path, "w") as f:
        f.writelines(updated_lines)

    return updated_vars