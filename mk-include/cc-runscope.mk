.PHONY: install-runscope
install-runscope:
	pip3 install -r $(MK_INCLUDE_BIN)/runscope/requirements.txt

.PHONY: test-runscope
test-runscope:
	python3 $(MK_INCLUDE_BIN)/runscope/run-runscope-test.py $(RUNSCOPE_URL)