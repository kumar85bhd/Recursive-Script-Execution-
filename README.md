# RTL Workflow Automation (Claude-Driven)

Automates RTL testcase execution. One command, unattended overnight.

## Quick Start

    git clone <repo>
    cd project-root
    chmod +x run.sh scripts/*.sh scripts/utils/*.sh
    bash run.sh

## Run Options

    bash run.sh                               all, sequential (default)
    bash run.sh --parallel                    all, parallel
    bash run.sh --category IO                 single category
    bash run.sh --category IO --testcase IO_1 single test case
    bash run.sh --resume                      skip completed steps
    bash run.sh --no-resume                   force full re-run

## Integrate Your EDA Tool

Edit ONLY the marked block in scripts/03_run_simulation.sh.

## Check Results

    cat state/summary.csv
    ls output/
    cat logs/master.log
