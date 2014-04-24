PREFIX=/usr/local

all: build

build:
	ocaml pkg/build.ml native=true native-dynlink=true unix=true lwt=true

install: build
	opam-installer --prefix=$(PREFIX) *.install

PHONY: clean

clean:
	ocamlbuild -clean
