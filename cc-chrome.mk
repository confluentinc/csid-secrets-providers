INIT_CI_TARGETS += install-chrome

.PHONY: install-chrome
install-chrome:
	@echo "BIN_PATH: $(BIN_PATH)"
	@echo "Installing google chrome"
	@sudo wget --timeout=20 --tries=15 --retry-connrefused https://confluent-packaging-tools.s3.us-west-2.amazonaws.com/google-chrome-stable_105.0.5195.125-1_amd64.deb
	@sudo apt install ./google-chrome-stable_105.0.5195.125-1_amd64.deb -y
