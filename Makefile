all: build

dist/setup:
	obuild configure

build: dist/setup
	obuild build

install: build
	ocamlfind install smtp dist/build/lib-smtp/* dist/build/lib-smtp_unix/* dist/build/lib-smtp_lwt/* lib/META

uninstall:
	ocamlfind remove smtp

PHONY: clean

clean:
	obuild clean
