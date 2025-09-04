# Copyright (c) 2025 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

TEST_DIRS = uart_core_ahb i3c
TEST_RESULTS = $(addsuffix /results.xml,${TEST_DIRS})

verify: venv $(TEST_RESULTS)
	. venv/bin/activate;\
	junitparser verify $(TEST_RESULTS)

$(TEST_RESULTS): venv
	. venv/bin/activate;\
	$(MAKE) -C $(@D) all \
		COVERAGE_TYPE=branch \
		COCOTB_RESULTS_FILE="results.xml";

clean:
	-rm -r venv build *.egg-info */dump.fst */results.xml */coverage.dat */sim-build-*

venv: venv/touchfile
venv/touchfile: pyproject.toml
	python3 -m venv venv
	. venv/bin/activate; pip install .
	touch venv/touchfile

dirs:
	echo $(TEST_DIRS)

.PHONY: all test venv clean dirs verify
