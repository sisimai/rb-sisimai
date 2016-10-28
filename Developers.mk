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
MBOXPARSERV0 := /usr/local/bouncehammer/bin/mailboxparser -T
PERL_SISIMAI := p5-Sisimai
PRECISIONTAB := ANALYTICAL-PRECISION
BENCHMARKDIR := tmp/benchmark
PARSERLOGDIR := var/log
MTAMODULEDIR := lib/sisimai/mta
MSPMODULEDIR := lib/sisimai/msp
MTARELATIVES := ARF rfc3464 rfc3834
EMAIL_PARSER := sbin/emparser
BENCHMARKEMP := sbin/mp
VELOCITYTEST := tmp/emails-for-velocity-measurement
BENCHMARKSET := tmp/sample

SET_OF_EMAIL := set-of-emails
PRIVATEMAILS := $(SET_OF_EMAIL)/private
PUBLICEMAILS := $(SET_OF_EMAIL)/maildir/bsd
DOSFORMATSET := $(SET_OF_EMAIL)/maildir/dos
MACFORMATSET := $(SET_OF_EMAIL)/maildir/mac

INDEX_LENGTH := 24
DESCR_LENGTH := 48
BH_CAN_PARSE := courier exim messagingserver postfix sendmail surfcontrol x5 \
				jp-ezweb jp-kddi ru-yandex uk-messagelabs us-amazonses us-aol \
				us-bigfoot us-facebook us-outlook us-verizon

# -----------------------------------------------------------------------------
.PHONY: clean

private-sample:
	$(RM) -r ./$(PRIVATEMAILS)
	$(CP) -vRp ../$(PERL_SISIMAI)/$(PRIVATEMAILS) $(SET_OF_EMAIL)

precision-table:
	cat ../$(PERL_SISIMAI)/$(PRECISIONTAB) | sed \
		-e 's/MTA::qmail/MTA::Qmail/g' \
		-e 's/MTA::mFILTER/MTA::MFILTER/g' > $(PRECISIONTAB)

update-sample-emails:
	for v in `find $(PUBLICEMAILS) -name '*-01.eml' -type f`; do \
		f="`basename $$v`" ;\
		nkf -Lw $$v > $(DOSFORMATSET)/$$f ;\
		nkf -Lm $$v > $(MACFORMATSET)/$$f ;\
	done

sample:
	for v in `$(LS) ./$(MTAMODULEDIR)/*.rb | grep -v userdefined`; do \
		MTA=`echo $$v | cut -d/ -f5 | tr '[A-Z]' '[a-z]' | sed 's/.rb//g'` ;\
		$(MKDIR) $(BENCHMARKSET)/$$MTA ;\
		$(CP) $(PUBLICEMAILS)/$$MTA-*.eml $(BENCHMARKSET)/$$MTA/ ;\
		$(CP) $(PRIVATEMAILS)/$$MTA/* $(BENCHMARKSET)/$$MTA/ ;\
	done
	for c in `$(LS) ./$(MSPMODULEDIR)`; do \
		for v in `$(LS) ./$(MSPMODULEDIR)/$$c/*.rb`; do \
			DIR=`echo $$c | tr '[A-Z]' '[a-z]' | tr -d '/'` ;\
			MSP="`echo $$v | cut -d/ -f6 | tr '[A-Z]' '[a-z]' | sed 's/.rb//g'`" ;\
			$(MKDIR) $(BENCHMARKSET)/$$DIR-$$MSP ;\
			$(CP) $(PUBLICEMAILS)/$$DIR-$$MSP-*.eml $(BENCHMARKSET)/$$DIR-$$MSP/ ;\
			$(CP) $(PRIVATEMAILS)/$$DIR-$$MSP/* $(BENCHMARKSET)/$$DIR-$$MSP/ ;\
		done ;\
	done
	for v in arf rfc3464 rfc3834; do \
		$(MKDIR) $(BENCHMARKSET)/$$v ;\
		$(CP) $(PUBLICEMAILS)/$$v*.eml $(BENCHMARKSET)/$$v/ ;\
		$(CP) $(PRIVATEMAILS)/$$v/* $(BENCHMARKSET)/$$v/ ;\
	done

profile: benchmark-mbox
	$(RUBY) -rprofile $(EMAIL_PARSER) $(BENCHMARKDIR) > /dev/null

velocity-measurement:
	@ $(MKDIR) $(VELOCITYTEST)
	@ for v in $(BH_CAN_PARSE); do \
		$(CP) $(PUBLICEMAILS)/$$v-*.eml $(VELOCITYTEST)/; \
		$(CP) $(PRIVATEMAILS)/$$v/*.eml $(VELOCITYTEST)/; \
	done
	@ echo -------------------------------------------------------------------
	@ echo `$(LS) $(VELOCITYTEST) | wc -l` emails in $(VELOCITYTEST)
	@ echo -n 'Calculating the velocity of 1000 mails: multiply by '
	@ echo "scale=4; 1000 / `$(LS) $(VELOCITYTEST) | wc -l`" | bc
	@ echo -n 'Calculating the velocity of 2000 mails: multiply by '
	@ echo "scale=4; 2000 / `$(LS) $(VELOCITYTEST) | wc -l`" | bc
	@ echo -------------------------------------------------------------------
	@ echo 'Sisimai(1)' $(BENCHMARKEMP)
	@ n=1; while [ $$n -le 5 ]; do \
		/usr/bin/time $(BENCHMARKEMP) $(VELOCITYTEST) > /dev/null ;\
		sleep 1; \
		n=`expr $$n + 1`; \
	done
	@ echo -------------------------------------------------------------------
	@ echo bounceHammer $(BH_LATESTVER)
	@ n=1; while [ $$n -le 5 ]; do \
		/usr/bin/time $(MBOXPARSERV0) -Fjson $(VELOCITYTEST) > /dev/null ;\
		sleep 1; \
		n=`expr $$n + 1`; \
	done

benchmark-mbox: sample
	$(MKDIR) -p $(BENCHMARKDIR)
	$(CP) `find $(BENCHMARKSET) -type f` $(BENCHMARKDIR)/

loc:
	@ for v in `find lib -type f -name '*.rb'`; do \
		x=`wc -l $$v | awk '{ print $$1 }'`; \
		z=`grep -E '^\s*#|^$$' $$v | wc -l | awk '{ print $$1 }'`; \
		echo "$$x - $$z" | bc ;\
	done | awk '{ s += $$1 } END { print s }'

clean:
	$(RM) -r ./$(BENCHMARKSET)
	$(RM) -r ./$(BENCHMARKDIR)
	$(RM) -f tmp/subject-list tmp/senders-list


