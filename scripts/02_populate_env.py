#!/usr/bin/env python3
"""
scripts/02_populate_env.py
Reads common.txt, simulation.txt, back_ann.txt for the given category
and writes env.common, env.simulation, env.back_ann into RUN_OUTPUT_DIR.

Arguments: <CATEGORY> <TEST_CASE> <FOLDER_NAME>
All paths resolved via PROJECT_ROOT and RUN_OUTPUT_DIR env vars.
"""
import sys, os

CATEGORY    = sys.argv[1]
TEST_CASE   = sys.argv[2]
FOLDER_NAME = sys.argv[3]

SCRIPT_DIR   = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.environ.get('PROJECT_ROOT', os.path.dirname(SCRIPT_DIR))
RUN_OUT      = os.environ['RUN_OUTPUT_DIR']
RUN_ID       = os.environ.get('RUN_ID', 'UNKNOWN')
ENV_UPDATE_FILE = os.path.join(PROJECT_ROOT, 'state', 'env_updates.csv')

sys.path.insert(0, os.path.join(SCRIPT_DIR, 'utils'))
from env_utils import read_txt_as_csv, update_env_file

INPUT_DIR = os.path.join(PROJECT_ROOT, 'input_xls', CATEGORY)
TEMPLATE_DIR = os.path.join(PROJECT_ROOT, 'template')

def track_updates(file_name, updated):
    if updated:
        updates_str = ";".join([f"{k}:{v}" for k, v in updated.items()])
        with open(ENV_UPDATE_FILE, "a") as f:
            f.write(f"{TEST_CASE},{file_name},{updates_str}\n")
        print(f"[ENV UPDATE] {file_name}: {updates_str}")

def main():
    # ── 1. env.common ─────────────────────────────────────────────
    rows = read_txt_as_csv(os.path.join(INPUT_DIR, 'common.txt'))
    values_dict = {r['Var_name']: r['Value'] for r in rows}
    template_path = os.path.join(TEMPLATE_DIR, 'common', 'env.common.txt')
    file_name = os.path.basename(template_path)
    output_path = os.path.join(RUN_OUT, 'common', 'env.common.txt')
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    updated = update_env_file(template_path, output_path, values_dict)
    track_updates(file_name, updated)
    print(f'[INFO] {file_name} written')

    # ── 2. env.simulation ─────────────────────────────────────────
    rows = read_txt_as_csv(os.path.join(INPUT_DIR, 'simulation.txt'))
    match = next((r for r in rows if r['Name'] == TEST_CASE), None)
    if not match:
        raise ValueError(f'Name={TEST_CASE!r} not found in simulation.txt')
    
    values_dict = {
        'DESIGN_PATH': match.get('design_path', ''),
        'DSIM_PATH':   match.get('dsim_path', ''),
    }
    template_path = os.path.join(TEMPLATE_DIR, 'simulation', 'env.simulation.txt')
    file_name = os.path.basename(template_path)
    output_path = os.path.join(RUN_OUT, 'simulation', 'env.simulation.txt')
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    updated = update_env_file(template_path, output_path, values_dict)
    track_updates(file_name, updated)
    print(f'[INFO] {file_name} written')

    # ── 3. env.back_ann ───────────────────────────────────────────
    rows = read_txt_as_csv(os.path.join(INPUT_DIR, 'back_ann.txt'))
    match = next((r for r in rows if r['Name'] == TEST_CASE), None)
    if not match:
        raise ValueError(f'Name={TEST_CASE!r} not found in back_ann.txt')
    
    values_dict = {k: match.get(k, '') for k in ['val1', 'val2', 'val3']}
    template_path = os.path.join(TEMPLATE_DIR, 'back_ann', 'env.back_ann.txt')
    file_name = os.path.basename(template_path)
    output_path = os.path.join(RUN_OUT, 'back_ann', 'env.back_ann.txt')
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    updated = update_env_file(template_path, output_path, values_dict)
    track_updates(file_name, updated)
    print(f'[INFO] {file_name} written')

if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(f'[ERROR] populate_env: {e}', file=sys.stderr)
        sys.exit(1)
