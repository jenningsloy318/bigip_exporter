

GO           ?= go
GOFMT        ?= $(GO)fmt
FIRST_GOPATH := $(firstword $(subst :, ,$(shell $(GO) env GOPATH)))
PROMU        := $(FIRST_GOPATH)/bin/promu
STATICCHECK  := $(FIRST_GOPATH)/bin/staticcheck
GOVENDOR     := $(FIRST_GOPATH)/bin/govendor
GODEP				 := $(FIRST_GOPATH)/bin/dep
pkgs          = ./...

PREFIX                  ?= $(shell pwd)/build
BIN_DIR                 ?= $(shell pwd)/build

all: deps vet fmt style staticcheck unused  build test

## ignore the error of "Using a deprecated function, variable, constant or field" when static check, refer to https://github.com/dominikh/go-tools/blob/master/cmd/staticcheck/docs/checks/SA1019
STATICCHECK_IGNORE = \
  github.com/jenningsloy318/bigip_exporter/bigip_exporter.go:SA1019 

 
style:
	@echo ">> checking code style"
	! $(GOFMT) -d $$(find . -path ./vendor -prune -o -name '*.go' -print) | grep '^'

check_license:
	@echo ">> checking license header"
	@licRes=$$(for file in $$(find . -type f -iname '*.go' ! -path './vendor/*') ; do \
               awk 'NR<=3' $$file | grep -Eq "(Copyright|generated|GENERATED)" || echo $$file; \
       done); \
       if [ -n "$${licRes}" ]; then \
               echo "license header checking failed:"; echo "$${licRes}"; \
               exit 1; \
       fi

test-short:
	@echo ">> running short tests"
	$(GO) test -short $(pkgs)

test:
	@echo ">> running all tests"
	$(GO) test -race $(pkgs)

format:
	@echo ">> formatting code"
	$(GO) fmt $(pkgs)

vet:
	@echo ">> vetting code"
	$(GO) vet $(pkgs)

staticcheck: | $(STATICCHECK)
	@echo ">> running staticcheck"
	$(STATICCHECK) -ignore "$(STATICCHECK_IGNORE)" $(pkgs)

unused: 
	@echo ">> running check for unused packages"
	@$(GOVENDOR) list +unused | grep . && exit 1 || echo 'No unused packages'

build: | $(PROMU)
	@echo ">> building binaries"
	$(PROMU) build --prefix $(PREFIX)

buildrpm: | $(PROMU) build
	@echo ">> building binaries"
	./scripts/build_rpm.sh

deps:  | $(GODEP)
	@echo ">> update the dependencies"
	$(GODEP) ensure -update

tarball:  | $(PROMU) build
	@echo ">> building release tarball"
	$(PROMU) tarball --prefix $(PREFIX) $(BIN_DIR)

fmt:
	@echo ">> format code style"
	$(GOFMT) -w $$(find . -path ./vendor -prune -o -name '*.go' -print) 


$(GODEP):
	GOOS= GOARCH= $(GO) get -u github.com/golang/dep/cmd/dep

$(PROMU):
	GOOS= GOARCH= $(GO) get -u github.com/prometheus/promu

$(STATICCHECK):
	GOOS= GOARCH= $(GO) get -u honnef.co/go/tools/cmd/staticcheck

$(GOVENDOR):
	GOOS= GOARCH= $(GO) get -u github.com/kardianos/govendor

.PHONY: all style check_license format build test vet assets tarball fmt $(GODEP)  $(PROMU) $(STATICCHECK) $(GOVENDOR)