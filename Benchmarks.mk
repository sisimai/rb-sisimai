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
PRIVATEMAILS := $(EMAILROOTDIR)/private
SPEEDTESTDIR := tmp/emails-for-speed-test

COMMANDARGVS := -I./lib -rsisimai
PROFILEARGVS := -rrblineprof -rrblineprof-report
PROFCOMMANDS := 'p = lineprof(%r|./lib/sisimai|) { Sisimai.make($$*.shift, delivered: true) }; LineProf.report(p, out: "pf")'
HOWMANYMAILS := $(RUBY) $(COMMANDARGVS) -le 'puts Sisimai.make($$*.shift, delivered: true).size' 

# -----------------------------------------------------------------------------
.PHONY: clean

emails-for-speed-test:
	@ rm -fr ./$(SPEEDTESTDIR)
	@ $(MKDIR) $(SPEEDTESTDIR)
	@ $(CP) -Rp $(PUBLICEMAILS)/*.eml $(SPEEDTESTDIR)/
	@ test -d $(PRIVATEMAILS) && find $(PRIVATEMAILS) -type f -name '*.eml' -exec $(CP) -Rp {} $(SPEEDTESTDIR)/ \; || true

speed-test: emails-for-speed-test
	@ echo `$(HOWMANYMAILS) $(SPEEDTESTDIR)` emails in $(SPEEDTESTDIR)
	@ echo -------------------------------------------------------------------
	@ uptime
	@ echo -------------------------------------------------------------------
	@ n=1; while [ "$$n" -le "10" ]; do \
		time $(RUBY) $(COMMANDARGVS) -e $(TOBEEXECUTED) $(SPEEDTESTDIR) > /dev/null; \
		sleep 2; \
		n=`expr $$n + 1`; \
	done

profile:
	@ uptime
	$(RUBY) $(COMMANDARGVS) $(PROFILEARGVS) -e $(PROFCOMMANDS) $(SPEEDTESTDIR)
	cat ./pf > profile-`date '+%Y-%m-%d-%T'`.txt
	$(RM) ./pf

loc:
	@ for v in `find lib -type f -name '*.rb'`; do \
		x=`wc -l $$v | awk '{ print $$1 }'`; \
		z=`grep -E '^\s*#|^$$' $$v | wc -l | awk '{ print $$1 }'`; \
		echo "$$x - $$z" | bc ;\
	done | awk '{ s += $$1 } END { print s }'

clean:
	find . -type f -name 'profiling-*' -ctime +1 -delete
	rm -r $(SPEEDTESTDIR)
