JULIAHOME = $(shell pwd)

include ./Make.inc

default: release

debug release: %: julia-% j/pcre_h.j sys.ji
	./julia test/unittests.j

julia-debug julia-release:
	$(MAKE) -C external
	$(MAKE) -C src lib$@
	$(MAKE) -C ui $@
	$(MAKE) -C ui/webserver $@
	ln -f $@-$(DEFAULT_REPL) julia

sys.ji: j/sysimg.j j/start_image.j src/boot.j src/dump.c j/*.j
	./julia -b sysimg.j

PCRE_CONST = 0x[0-9a-fA-F]+|[-+]?\s*[0-9]+

j/pcre_h.j:
	cpp -dM $(EXTROOT)/include/pcre.h | perl -nle '/^\s*#define\s+(PCRE\w*)\s*\(?($(PCRE_CONST))\)?\s*$$/ and print "$$1 = $$2"' | sort > $@

test: default
	./julia test/tests.j

test-utf8: default
	make -C test/unicode
	./julia test/test_utf8.j

test-perf: default
	./julia test/perf.j

testall: test test-utf8 test-perf

SLOCCOUNT = sloccount \
	--addlang makefile \
	--personcost 100000 \
	--effort 3.6 1.2 \
	--schedule 2.5 0.32 \
	--

J_FILES = $(shell git ls-files | grep '\.j$$')

sloccount:
	@for x in $(J_FILES); do cp $$x $${x%.j}.hs; done
	git ls-files | sed 's/\.j$$/.hs/' | xargs $(SLOCCOUNT) | sed 's/haskell/*julia*/g'
	@for x in $(J_FILES); do rm -f $${x%.j}.hs; done

clean:
	rm -f julia
	rm -f j/pcre_h.j
	rm -f *.ji
	rm -f *~ *#
	$(MAKE) -C src clean
	$(MAKE) -C ui clean
	$(MAKE) -C ui/webserver clean
	$(MAKE) -C test/unicode clean

cleanall: clean
	$(MAKE) -C src clean-flisp clean-support

distclean: cleanall
	$(MAKE) -C external cleanall

.PHONY: default debug release julia-debug julia-release \
	test testall test-* sloccount clean cleanall
