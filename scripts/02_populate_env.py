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

sys.path.insert(0, os.path.join(SCRIPT_DIR, 'utils'))
from env_utils import read_txt_as_csv, write_env_file

INPUT_DIR = os.path.join(PROJECT_ROOT, 'input_xls', CATEGORY)

def main():
    # ── 1. env.common ─────────────────────────────────────────────
    rows = read_txt_as_csv(os.path.join(INPUT_DIR, 'common.txt'))
    write_env_file(os.path.join(RUN_OUT, 'common', 'env.common'),
                  {r['Var_name']: r['Value'] for r in rows})
    print('[INFO] env.common written')

    # ── 2. env.simulation ─────────────────────────────────────────
    rows = read_txt_as_csv(os.path.join(INPUT_DIR, 'simulation.txt'))
    match = next((r for r in rows if r['Name'] == TEST_CASE), None)
    if not match:
        raise ValueError(f'Name={TEST_CASE!r} not found in simulation.txt')
    write_env_file(os.path.join(RUN_OUT, 'simulation', 'env.simulation'), {
        'DESIGN_PATH': match['design_path'],
        'DSIM_PATH':   match['dsim_path'],
    })
    print('[INFO] env.simulation written')

    # ── 3. env.back_ann ───────────────────────────────────────────
    rows = read_txt_as_csv(os.path.join(INPUT_DIR, 'back_ann.txt'))
    match = next((r for r in rows if r['Name'] == TEST_CASE), None)
    if not match:
        raise ValueError(f'Name={TEST_CASE!r} not found in back_ann.txt')
    # To add new parameters: extend this list and add column to back_ann.txt
    write_env_file(os.path.join(RUN_OUT, 'back_ann', 'env.back_ann'),
                  {k: match[k] for k in ['val1', 'val2', 'val3']})
    print('[INFO] env.back_ann written')

if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(f'[ERROR] populate_env: {e}', file=sys.stderr)
        sys.exit(1)
