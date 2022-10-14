MAKEDIR:=$(shell pwd)
PATH:=$(shell cygpath "$(MAKEDIR)"):$(shell cygpath "$(PREFIX)")/bin:$(PATH)

all: ocaml findlib zarith z3

clean::
	-rm -Rf $(PREFIX)

# ---- OCaml ----

OCAML_VERSION=4.14.0
OCAML_TGZ=ocaml-$(OCAML_VERSION).tar.gz
OCAML_DIR=ocaml-$(OCAML_VERSION)
FLEXDLL_VERSION=0.41
FLEXDLL_TGZ=flexdll-$(FLEXDLL_VERSION).tar.gz
FLEXDLL_DIR=flexdll-$(FLEXDLL_VERSION)
OCAML_EXE=$(PREFIX)/bin/ocamlopt.opt.exe

$(OCAML_TGZ):
	curl -Lfo ocaml-$(OCAML_VERSION).tar.gz https://github.com/ocaml/ocaml/archive/$(OCAML_VERSION).tar.gz

$(OCAML_DIR): $(OCAML_TGZ)
	tar xzfm $(OCAML_TGZ)

$(FLEXDLL_TGZ):
	curl -Lfo $(FLEXDLL_TGZ) https://github.com/alainfrisch/flexdll/archive/$(FLEXDLL_VERSION).tar.gz

$(FLEXDLL_DIR): $(FLEXDLL_TGZ)
	tar xzfm $(FLEXDLL_TGZ)

ocaml-$(OCAML_VERSION)/flexdll/flexdll.c: | $(OCAML_DIR) $(FLEXDLL_DIR)
	cd ocaml-$(OCAML_VERSION)/flexdll && cp -R ../../flexdll-$(FLEXDLL_VERSION)/* .

$(OCAML_EXE): ocaml-$(OCAML_VERSION)/flexdll/flexdll.c | $(OCAML_DIR) $(FLEXDLL_DIR)
	cd ocaml-$(OCAML_VERSION) && \
	./configure --prefix=$(PREFIX) --build=x86_64-pc-cygwin --host=x86_64-w64-mingw32 && \
	make && make install

ocaml: $(OCAML_EXE)
.PHONY: ocaml

clean::
	-rm -Rf ocaml-$(OCAML_VERSION)
	-rm -Rf flexdll-$(FLEXDLL_VERSION)

# ---- Findlib ----

FINDLIB_VERSION=1.9.1
FINDLIB_EXE=$(PREFIX)/bin/ocamlfind.exe
FINDLIB_TGZ=findlib-$(FINDLIB_VERSION).tar.gz
FINDLIB_SRC=findlib-$(FINDLIB_VERSION)/configure
FINDLIB_CFG=findlib-$(FINDLIB_VERSION)/Makefile.config

$(FINDLIB_TGZ):
	curl -Lfo $(FINDLIB_TGZ) http://download.camlcity.org/download/findlib-$(FINDLIB_VERSION).tar.gz

$(FINDLIB_SRC): $(FINDLIB_TGZ)
	tar xzfm $(FINDLIB_TGZ)

$(FINDLIB_CFG): $(OCAML_EXE) $(FINDLIB_SRC)
	cd findlib-$(FINDLIB_VERSION) && \
	./configure \
	  -bindir $(PREFIX)/bin \
	  -mandir $(PREFIX)/man \
	  -sitelib $(PREFIX)/lib/ocaml \
	  -config $(PREFIX)/etc/findlib.conf

$(FINDLIB_EXE): | $(FINDLIB_CFG)
	cd findlib-$(FINDLIB_VERSION) && \
	make all && \
	make opt && \
	make install

findlib: $(FINDLIB_EXE)
.PHONY: findlib

clean::
	-rm -Rf findlib-$(FINDLIB_VERSION)

# ---- zarith ----
ZARITH_VERSION=1.12
ZARITH_SRC=Zarith-release-$(ZARITH_VERSION)
ZARITH_BINARY=$(PREFIX)/lib/ocaml/zarith/zarith.cmxa

zarith-$(ZARITH_VERSION).tar.gz:
	curl -Lfo $@ https://github.com/ocaml/Zarith/archive/refs/tags/release-$(ZARITH_VERSION).tar.gz

$(ZARITH_SRC): zarith-$(ZARITH_VERSION).tar.gz
	tar xzf $<

$(ZARITH_BINARY): $(FINDLIB_EXE) | $(ZARITH_SRC)
	cd $| && CC=x86_64-w64-mingw32-gcc ./configure && make && make install

zarith: $(ZARITH_BINARY)
.PHONY: zarith

clean::
	-rm -Rf $(ZARITH_SRC)

# ---- Z3 ----

Z3_VERSION=4.11.2
Z3_BINARY=$(PREFIX)/lib/libz3.dll
Z3_DIR=z3-Z3-$(Z3_VERSION)
Z3_CFG=$(Z3_DIR)/build/Makefile
Z3_BUILD=$(Z3_DIR)/build/libz3.dll

z3-$(Z3_VERSION).tar.gz:
	curl -Lfo $@ https://github.com/Z3Prover/z3/archive/refs/tags/z3-$(Z3_VERSION).tar.gz

$(Z3_DIR): z3-$(Z3_VERSION).tar.gz
	tar xzf $<

$(Z3_CFG): $(FINDLIB_EXE) $(ZARITH_BINARY) | $(Z3_DIR)
	cd $(Z3_DIR) && CXX=x86_64-w64-mingw32-g++ CC=x86_64-w64-mingw32-gcc AR=x86_64-w64-mingw32-ar python scripts/mk_make.py --ml --prefix=$(PREFIX)

$(Z3_BUILD): $(Z3_CFG)
	cd $(Z3_DIR)/build && make

$(Z3_BINARY): $(Z3_BUILD)
	cd $(Z3_DIR)/build && make install && cp libz3.dll.a $(PREFIX)/lib

z3: $(Z3_BINARY)
.PHONY: z3

clean::
	-rm -Rf $(Z3_DIR)
