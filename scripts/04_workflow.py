#!/usr/bin/env python3
"""
scripts/04_workflow.py
1. Reads all 3 env files from RUN_OUTPUT_DIR
2. Writes output/all_env_values.txt  (complete env dump)
3. Writes simulation_<FOLDER_NAME>.txt  (result record with
   Results=success/failure, error_message, timestamp, run_id)

Arguments: <CATEGORY> <TEST_CASE> <FOLDER_NAME>
"""
import sys, os, csv
from datetime import datetime

CATEGORY    = sys.argv[1]
TEST_CASE   = sys.argv[2]
FOLDER_NAME = sys.argv[3]

SCRIPT_DIR   = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.environ.get('PROJECT_ROOT', os.path.dirname(SCRIPT_DIR))
RUN_OUT      = os.environ['RUN_OUTPUT_DIR']

sys.path.insert(0, os.path.join(SCRIPT_DIR, 'utils'))
from env_utils import read_env_file, read_txt_as_csv, write_all_env_dump

INPUT_DIR = os.path.join(PROJECT_ROOT, 'input_xls', CATEGORY)

def main():
    error_msg = ''
    success   = True

    try:
        common_vals = read_env_file(os.path.join(RUN_OUT, 'common',     'env.common.txt'))
        sim_vals    = read_env_file(os.path.join(RUN_OUT, 'simulation', 'env.simulation.txt'))
        back_vals   = read_env_file(os.path.join(RUN_OUT, 'back_ann',   'env.back_ann.txt'))

        out_path = os.path.join(RUN_OUT, 'output', 'all_env_values.txt')
        os.makedirs(os.path.dirname(out_path), exist_ok=True)
        write_all_env_dump(out_path, FOLDER_NAME, {
            'COMMON':     common_vals,
            'SIMULATION': sim_vals,
            'BACK_ANN':   back_vals,
        })
        print(f'[INFO] Env dump: {out_path}')

    except Exception as e:
        success, error_msg = False, str(e)
        print(f'[ERROR] {e}', file=sys.stderr)

    # Always write result record even on partial failure
    try:
        rows = read_txt_as_csv(os.path.join(INPUT_DIR, 'simulation.txt'))
        row  = next((r for r in rows if r['Name'] == TEST_CASE), None)
        if not row:
            raise ValueError(f'Name={TEST_CASE!r} not found in simulation.txt')

        row['Results']       = 'success' if success else 'failure'
        row['error_message'] = error_msg
        row['timestamp']     = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        row['run_id']        = os.environ.get('RUN_ID', 'unknown')

        result_file = os.path.join(RUN_OUT, f'simulation_{FOLDER_NAME}.txt')
        with open(result_file, 'w', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=list(row.keys()))
            writer.writeheader()
            writer.writerow(row)
        print(f'[INFO] Result: {result_file}')

    except Exception as e:
        success = False
        print(f'[ERROR] Result write: {e}', file=sys.stderr)

    if not success:
        sys.exit(1)

if __name__ == '__main__':
    main()
