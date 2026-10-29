#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 tests/validate_fixtures.py | tee logs/schema_preflight.txt
python3 tests/test_schema_negative.py | tee logs/schema_negative_checks.txt
python3 tests/validate_replay_schedule.py | tee logs/replay_schedule_preflight.txt
python3 tests/static_contract_check.py | tee logs/static_contract_check.txt
./tests/run_headless.sh
