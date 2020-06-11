

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
VERSION ?= $(shell cat VERSION)
REVERSION ?=$(shell git log -1 --pretty="%H")
BRANCH ?=$(shell git rev-parse --abbrev-ref HEAD)
TIME ?=$(shell date --rfc-3339=seconds)
HOST ?=$(shell hostname)  

all:  fmt style staticcheck   build 

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


staticcheck: | $(STATICCHECK)
	@echo ">> running staticcheck"
	$(STATICCHECK) -ignore "$(STATICCHECK_IGNORE)" $(pkgs)

build: 
	@echo ">> building binaries"
	$(GO) build -o $(PREFIX)/bigip_exporter -ldflags  '-X "github.com/prometheus/common/version.Version=$(VERSION)" -X "github.com/prometheus/common/version.Branch=$(BRANCH)" -X "github.com/prometheus/common/version.Revision=$(REVERSION)" -X "github.com/prometheus/common/version.BuildUser=$(USER)"  -X "github.com/prometheus/common/version.BuildDate=$(TIME)"  '

rpm: | build
	@echo ">> building binaries"
	./scripts/build_rpm.sh

fmt:
	@echo ">> format code style"
	$(GOFMT) -w $$(find . -path ./vendor -prune -o -name '*.go' -print) 

$(STATICCHECK):
	GOOS= GOARCH= $(GO) get -u honnef.co/go/tools/cmd/staticcheck

.PHONY: all style check_license  build fmt  $(STATICCHECK) 