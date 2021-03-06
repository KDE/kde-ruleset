#!/usr/bin/make -f

DELETER=./deleter-fb

all: fb-workspace fb-runtime fb-kdelibs

fb-workspace: kdebase-workspace
	cd $< && $(DELETER) wallpapers
	touch $@

fb-runtime: kdebase-runtime
	cd $< && $(DELETER) pics/oxygen pics/crystalsvg pics/locolor pics/wallpapers
	touch $@

fb-kdelibs: KDE/kdelibs
	cd $< && $(DELETER) pics
	touch $@
