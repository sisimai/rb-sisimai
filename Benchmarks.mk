# rb-Sisimai/Benchmarks.mk
#  ____                  _                          _                    _    
# | __ )  ___ _ __   ___| |__  _ __ ___   __ _ _ __| | _____   _ __ ___ | | __
# |  _ \ / _ \ '_ \ / __| '_ \| '_ ` _ \ / _` | '__| |/ / __| | '_ ` _ \| |/ /
# | |_) |  __/ | | | (__| | | | | | | | | (_| | |  |   <\__ \_| | | | | |   < 
# |____/ \___|_| |_|\___|_| |_|_| |_| |_|\__,_|_|  |_|\_\___(_)_| |_| |_|_|\_\
# -----------------------------------------------------------------------------
SHELL := /bin/sh
HERE  := $(shell pwd)
NAME  := Sisimai
RUBY  ?= ruby
MKDIR := mkdir -p
LS    := ls -1
CP    := cp

EMAILROOTDIR := set-of-emails
PUBLICEMAILS := $(EMAILROOTDIR)/maildir/bsd
DOSFORMATSET := $(EMAILROOTDIR)/maildir/dos
MACFORMATSET := $(EMAILROOTDIR)/maildir/mac
SPEEDTESTDIR := $(PUBLICEMAILS)

COMMANDARGVS := -I./lib -rsisimai
TOBEEXECUTED := 'Sisimai.make($$*.shift, delivered: true)' $(PUBLICMAILS)
HOWMANYMAILS := $(PERL) $(COMMANDARGVS) -le 'puts Sisimai.make($$*.shift, delivered: true).size' 

# -----------------------------------------------------------------------------
.PHONY: clean

speed-test:
	@ echo `$(HOWMANYMAILS) $(SPEEDTESTDIR)` emails in $(SPEEDTESTDIR)
	@ echo -------------------------------------------------------------------
	@ uptime
	@ echo -------------------------------------------------------------------
	@ n=1; while [ "$$n" -le "10" ]; do \
		/usr/bin/time $(PERL) $(COMMANDARGVS) -e $(TOBEEXECUTED) $(SPEEDTESTDIR) > /dev/null; \
		sleep 2; \
		n=`expr $$n + 1`; \
	done

profile:
	@ uptime
	$(RUBY) -rprofile $(COMMANDARGVS) -e $(TOBEEXECUTED) $(SPEEDTESTDIR) 2> pf > /dev/null
	cat ./pf | sed -e 's/^ *//g' | tr -s ' ' | sed -e 's/self self/self  self/' | tr ' ' '\t' > profiling-`date '+%Y-%m-%d-%T'`.txt
	$(RM) ./pf

loc:
	@ for v in `find lib -type f -name '*.rb'`; do \
		x=`wc -l $$v | awk '{ print $$1 }'`; \
		z=`grep -E '^\s*#|^$$' $$v | wc -l | awk '{ print $$1 }'`; \
		echo "$$x - $$z" | bc ;\
	done | awk '{ s += $$1 } END { print s }'

clean:

