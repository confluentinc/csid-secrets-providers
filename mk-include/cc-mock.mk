# Use this file if you're using `mocker` to generate your go mocks
# Must include it AFTER cc-go.mk
#
# The actual generation will happen during `make generate`, this file is included simply to make sure
# that `mocker` tool is installed when `make generate` runs.
#
# As a usage example, consider:
# - project
#   |- main.go
#   |- app
#   |   |- file_to_mock.go
#   |   |- file_with_generate_directive.go
#   |- logic
#   |   |- other_file_to_mock.go
# We want to mock file_to_mock.go. We can include a generate directive in our file_with_generate_directive.go like so:
#
# //go:generate mocker --prefix some_prefix --dst dest_file.go --pkg dest_pkg ../app/file_to_mock.go InterfaceInFile
#
# That will create a file dest_file.go in the package dest_pkg. For the other_file_to_mock, we can do:
#
# //go:generate mocker --prefix some_prefix --dst dest_file.go --pkg dest_pkg ../logic/other_file_to_mock.go InterfaceInFile
#
# When we run `make generate` the mocks will be generated.
GO_EXTRA_DEPS += install-mocker

MOCKER_VERSION ?= 1.1.1

.PHONY: install-mocker
install-mocker:
	$(GO) install github.com/travisjeffery/mocker/cmd/mocker@v$(MOCKER_VERSION)
