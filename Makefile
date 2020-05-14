PACKAGE_NAME := singletons
PACKAGE_VERSION := $(shell bash -c '. src/lib/$(PACKAGE_NAME) 2>/dev/null; singletons::version')
INSTALL_PATH := $(shell python -c 'import sys; sys.stdout.write(sys.prefix) if hasattr(sys, "real_prefix") else exit(255)' 2>/dev/null || echo "/usr/local")
LIB_COMPONENTS := $(wildcard src/lib/$(PACKAGE_NAME)-$(PACKAGE_VERSION)/*)
BIN_COMPONENTS := $(foreach name, $(wildcard src/bin/*), build/bin/$(notdir $(name)))
DIR_COMPONENTS := $(foreach name, bin share lib, build/$(name)) build/share/$(PACKAGE_NAME)

.PHONY: tests clean help

all: build

demo: build/repo
	@build/bin/container-singletons --repo=$< --instance=Demo --new --start
	@build/bin/container-singletons --repo=$< --instance=Demo --status
	@build/bin/container-singletons --repo=$< --instance=Demo --attach
	@build/bin/container-singletons --repo=$< --instance=Demo --stop
	@build/bin/container-singletons --repo=$< --instance=Demo --status

build/repo: build
	-@rm -rf $@e
	@mkdir $@
	@(cd $@ && touch Dockerfile)
	@(cd $@ && git init .)
	@(cd $@ && git add Dockerfile)
	@(cd $@ && git commit -m created)
	@(cd $@ && git branch Demo)
	@(cd $@ && git checkout Demo)
	@cp repo/Dockerfile $@
	@(cd $@ && git add Dockerfile)
	@(cd $@ && git commit -m "added branch Demo")

help:
	@echo "Usage: make build|tests|all|clean|version|install"

build: build/lib/$(PACKAGE_NAME) $(BIN_COMPONENTS)

install: tests
	@echo "Installing into directory '$(INSTALL_PATH)'"
	@rsync -az build/ $(INSTALL_PATH)/

version: build
	@build/bin/container-singletons --version

tests: build
	@PATH="$(shell readlink -f build/bin):$(PATH)" unittests/testsuite

clean:
	-@rm -rf build checkouts

build/lib/$(PACKAGE_NAME): build/lib/$(PACKAGE_NAME)-$(PACKAGE_VERSION) build/lib src/lib/$(PACKAGE_NAME)
	@install -m 755 src/lib/$(PACKAGE_NAME) $@

build/lib/$(PACKAGE_NAME)-$(PACKAGE_VERSION): build/lib $(LIB_COMPONENTS)
	@rsync -az src/lib/$(PACKAGE_NAME)-$(PACKAGE_VERSION)/ $@/

build/bin/%: build/lib/$(PACKAGE_NAME) build/bin | src/bin
	@install -m 755 src/bin/$(notdir $@) $@

$(DIR_COMPONENTS):
	@install -d $@
