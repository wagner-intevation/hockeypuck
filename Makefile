PROJECTPATH = $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
export GOPATH := $(PROJECTPATH)
export PATH := /usr/lib/go-1.12/bin:$(PATH)

project = hockeypuck

commands = \
	hockeypuck \
	hockeypuck-load \
	hockeypuck-pbuild

all: lint test build

build:

clean: clean-go

clean-go:
	rm -rf $(PROJECTPATH)/bin
	rm -rf $(PROJECTPATH)/pkg

lint: lint-go

lint-go:
	go fmt $(project)/...
	go vet $(project)/...

test: test-go

test-go:
	go test $(project)/...

test-mongodb:
	go test $(project)/mgohkp/... -mongodb-integration

#
# Generate targets to build Go commands.
#
define make-go-cmd-target
	$(eval cmd_name := $1)
	$(eval cmd_package := $(project)/server/cmd/$(cmd_name))
	$(eval cmd_target := $(cmd_name))

$(cmd_target):
	go install $(cmd_package)

build: $(cmd_target)

endef

$(foreach command,$(commands),$(eval $(call make-go-cmd-target,$(command))))

#
# Generate targets to test Go packages.
#
define make-go-pkg-target
	$(eval pkg_path := $1)
	$(eval pkg_target := $(subst /,-,$(pkg_path)))

coverage-$(pkg_target):
	go test $(pkg_path) -coverprofile=cover.out
	go tool cover -html=cover.out
	rm cover.out

coverage: coverage-$(pkg_target)

test-$(pkg_target):
	go test $(pkg_path)

test-go: test-$(pkg_target)

endef

$(foreach package,$(packages),$(eval $(call make-go-pkg-target,$(package))))
