# p5-Sisimai/Developers.mk
#  ____                 _                                       _    
# |  _ \  _____   _____| | ___  _ __   ___ _ __ ___   _ __ ___ | | __
# | | | |/ _ \ \ / / _ \ |/ _ \| '_ \ / _ \ '__/ __| | '_ ` _ \| |/ /
# | |_| |  __/\ V /  __/ | (_) | |_) |  __/ |  \__ \_| | | | | |   < 
# |____/ \___| \_/ \___|_|\___/| .__/ \___|_|  |___(_)_| |_| |_|_|\_\
#                              |_|                                   
# -----------------------------------------------------------------------------
SHELL := /bin/sh
HERE  := $(shell pwd)
NAME  := Sisimai
RUBY  ?= ruby
MKDIR := mkdir -p
LS    := ls -1
CP    := cp
RM    := rm -f

BH_LATESTVER := 2.7.13p3
BOUNCEHAMMER := /usr/local/bouncehammer
MBOXPARSERV0 := $(BOUNCEHAMMER)/bin/mailboxparser -T
PERL5SISIMAI := p5-Sisimai
PRECISIONTAB := ANALYTICAL-PRECISION
PARSERLOGDIR := var/log
MAILCLASSDIR := lib/$(NAME)/Bite/Email
JSONCLASSDIR := lib/$(NAME)/Bite/JSON
MTARELATIVES := ARF rfc3464 rfc3834

BENCHMARKDIR := tmp/benchmark
BENCHMARKSET := tmp/sample
SPEEDTESTDIR := tmp/emails-for-velocity-measurement

PARSERSCRIPT := $(RUBY) sbin/emparser --delivered
RELEASEVERMP := $(RUBY) -rsisimai
DEVELOPVERMP := $(RUBY) -I./lib -rsisimai
HOWMANYMAILS := $(DEVELOPVERMP) -e 'print Sisimai.make($$*.shift, delivered: true).size' $(SPEEDTESTDIR)

BENCHMARKEMP := sbin/mp

SET_OF_EMAIL := set-of-emails
PRIVATEMAILS := $(SET_OF_EMAIL)/private
PUBLICEMAILS := $(SET_OF_EMAIL)/maildir/bsd
DOSFORMATSET := $(SET_OF_EMAIL)/maildir/dos
MACFORMATSET := $(SET_OF_EMAIL)/maildir/mac

INDEX_LENGTH := 24
DESCR_LENGTH := 50
BH_CAN_PARSE := courier exim messagingserver postfix sendmail surfcontrol x5 \
				ezweb kddi yandex messagelabs amazonses aol bigfoot facebook \
				outlook verizon


# -----------------------------------------------------------------------------
.PHONY: clean

private-sample:
	$(RM) -r ./$(PRIVATEMAILS)
	$(CP) -vRp ../$(PERL5SISIMAI)/$(PRIVATEMAILS) $(SET_OF_EMAIL)

precision-table:
	cat ../$(PERL5SISIMAI)/$(PRECISIONTAB) | sed \
		-e 's/Email::qmail/Email::Qmail/g' \
		-e 's/Email::mFILTER/Email::MFILTER/g' > $(PRECISIONTAB)

update-sample-emails:
	for v in `find $(PUBLICEMAILS) -name '*-01.eml' -type f`; do \
		f="`basename $$v`" ;\
		nkf -Lw $$v > $(DOSFORMATSET)/$$f ;\
		nkf -Lm $$v > $(MACFORMATSET)/$$f ;\
	done

sample:
	for v in `$(LS) ./$(MAILCLASSDIR)/*.rb | grep -v userdefined`; do \
		MTA=`echo $$v | cut -d/ -f6 | tr '[A-Z]' '[a-z]' | sed 's/.rb//g'` ;\
		$(MKDIR) $(BENCHMARKSET)/email-$$MTA ;\
		$(CP) $(PUBLICEMAILS)/email-$$MTA-*.eml $(BENCHMARKSET)/email-$$MTA/ ;\
		$(CP) $(PRIVATEMAILS)/email-$$MTA/* $(BENCHMARKSET)/email-$$MTA/ ;\
	done
	for v in arf rfc3464 rfc3834; do \
		$(MKDIR) $(BENCHMARKSET)/$$v ;\
		$(CP) $(PUBLICEMAILS)/$$v*.eml $(BENCHMARKSET)/$$v/ ;\
		$(CP) $(PRIVATEMAILS)/$$v/* $(BENCHMARKSET)/$$v/ ;\
	done

samples-for-velocity:
	@ rm -fr ./$(SPEEDTESTDIR)
	@ $(MKDIR) $(SPEEDTESTDIR)
	@ for v in $(BH_CAN_PARSE); do \
		$(CP) $(PUBLICEMAILS)/email-$$v-*.eml $(SPEEDTESTDIR)/; \
		test -d $(PRIVATEEMAILS) && $(CP) $(PRIVATEMAILS)/email-$$v/*.eml $(SPEEDTESTDIR)/; \
	done

velocity-measurement: samples-for-velocity
	@ echo -------------------------------------------------------------------
	@ echo `$(HOWMANYMAILS)` emails in $(SPEEDTESTDIR)
	@ echo -n 'Calculating the velocity of parsing 1000 mails: multiply by '
	@ echo "scale=6; 1000 / `$(HOWMANYMAILS)`" | bc
	@ echo -------------------------------------------------------------------
	@ uptime
	@ echo -------------------------------------------------------------------
	@ if [ -x "$(BOUNCEHAMMER)/bin/mailboxparser" ]; then \
		echo bounceHammer $(BH_LATESTVER); \
		n=1; while [ $$n -le 5 ]; do \
			/usr/bin/time $(MBOXPARSERV0) -Fjson $(SPEEDTESTDIR) > /dev/null ;\
			sleep 1; \
			n=`expr $$n + 1`; \
		done; \
		echo -------------------------------------------------------------------; \
	fi
	@ echo 'Sisimai' `$(RELEASEVERMP) -e 'puts Sisimai.version'` $(RELEASEVERMP)
	@ n=1; while [ $$n -le 5 ]; do \
		/usr/bin/time $(RELEASEVERMP) -e 'Sisimai.make($$*.shift, deliverd: true)' $(SPEEDTESTDIR) > /dev/null ;\
		sleep 1; \
		n=`expr $$n + 1`; \
	done
	@ echo -------------------------------------------------------------------
	@ echo 'Sisimai' `$(DEVELOPVERMP) -e 'puts Sisimai.version'` $(DEVELOPVERMP)
	@ n=1; while [ $$n -le 5 ]; do \
		/usr/bin/time $(DEVELOPVERMP) -e 'Sisimai.make($$*.shift, deliverd: true)' $(SPEEDTESTDIR) > /dev/null ;\
		sleep 1; \
		n=`expr $$n + 1`; \
	done
	@ echo -------------------------------------------------------------------

benchmark-mbox: sample
	$(MKDIR) -p $(BENCHMARKDIR)
	$(CP) `find $(BENCHMARKSET) -type f` $(BENCHMARKDIR)/

clean:
	$(RM) -r ./$(BENCHMARKSET)
	$(RM) -r ./$(BENCHMARKDIR)
	$(RM) -f tmp/subject-list tmp/senders-list


