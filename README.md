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

## 🔧 Environment File Update Logic (IMPORTANT)

This system uses template-driven environment configuration with selective overrides.

### 🧭 Principle
Templates define defaults. Input files override only when values are explicitly provided.

### 📁 Template Example
export MODE=fast
export ENABLE_LOG=1

export VAL1=default1
export VAL2=default2
export VAL3=default3

### 📊 Input Example
Name,VAL1,VAL2,VAL3
TC1,10,,30

### ✅ Result
export MODE=fast
export ENABLE_LOG=1

export VAL1=10
export VAL2=default2
export VAL3=30

### ⚠️ Rules
- Only update when value is present AND non-empty
- Missing or blank values must NOT override template
- Do NOT remove lines
- Do NOT reorder variables
- Do NOT modify comments

---

## 📊 Debug Tracking — Variable Updates

### 📁 File
state/env_updates.csv

### 📄 Format
TestCase,FileName,Updates

### 📊 Example
IO_1,env.back_ann,VAL1:10;VAL3:30
IO_1,env.common,MODE:fast
DCT_1,env.back_ann,VAL2:20

### 🧠 Behavior
- Only updated variables are recorded
- Default/unchanged variables are NOT logged
- Multiple variables separated by ';'
- One row per testcase and file

### 🔍 Usage
grep IO_1 state/env_updates.csv

---

## ⚙️ Execution Model

Each testcase runs:
1. create_folders
2. populate_env
3. run_simulation
4. workflow

### 🔁 Retry Model
retry_0 → retry_1 → retry_2

- Sequential per testcase
- No parallel retries

### 📁 Output
output/<CATEGORY>/<TESTCASE>/<RUN_ID>/

---

## 📊 State Tracking

state/progress.csv → step tracking
state/summary.csv → final status
state/env_updates.csv → variable updates

---

## 🚀 Running Workflow (Click & Forget)

Use in Claude Code:

Run the full RTL workflow end-to-end:
1. Validate inputs
2. Execute using run.sh
3. Analyze results

Do not stop between steps.

---

## 🔍 Debug Workflow

1. Check summary:
cat state/summary.csv

2. Check updates:
cat state/env_updates.csv

3. Check logs:
logs/<CATEGORY>/<TESTCASE>/retry_<N>.log

---

## 🧭 Design Philosophy

- Template-driven config
- Selective overrides
- Deterministic execution
- Centralized debugging
