UNIX ?= $(shell if ocamlfind query unix >/dev/null 2>&1; then echo --flag unix; fi)
LWT ?= $(shell if ocamlfind query lwt.unix >/dev/null 2>&1; then echo --flag lwt; fi)

all: build

dist/setup:
	obuild configure $(UNIX) $(LWT)

build: dist/setup
	obuild build

install: build
	ocamlfind install smtp dist/build/lib-smtp/* dist/build/lib-smtp_unix/* dist/build/lib-smtp_lwt/* lib/META

uninstall:
	ocamlfind remove smtp

reinstall:
	$(MAKE) uninstall || true
	$(MAKE) install

PHONY: clean

clean:
	obuild clean
