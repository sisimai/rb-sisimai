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

THELASTBHVER := 2.7.13p3
BOUNCEHAMMER := /usr/local/bouncehammer
MBOXPARSERV0 := $(BOUNCEHAMMER)/bin/mailboxparser -T
PERL5SISIMAI := p5-Sisimai
PRECISIONTAB := ANALYTICAL-PRECISION
PARSERLOGDIR := tmp/parser-logs
MAILCLASSDIR := lib/$(NAME)/Bite/Email
JSONCLASSDIR := lib/$(NAME)/Bite/JSON
MTARELATIVES := ARF rfc3464 rfc3834

BENCHMARKDIR := tmp/benchmark
PRECISIONDIR := tmp/emails-for-precision
COMPARINGDIR := tmp/emails-for-comparing

PARSERSCRIPT := $(RUBY) sbin/emparser --delivered
RELEASEVERMP := $(RUBY) -rsisimai
DEVELOPVERMP := $(RUBY) -I./lib -rsisimai
HOWMANYMAILS := $(DEVELOPVERMP) -e 'print Sisimai.make($$*.shift, delivered: true).size' $(COMPARINGDIR)

BENCHMARKEMP := sbin/mp

SET_OF_EMAIL := set-of-emails
PRIVATEMAILS := $(SET_OF_EMAIL)/private
PUBLICEMAILS := $(SET_OF_EMAIL)/maildir/bsd
DOSFORMATSET := $(SET_OF_EMAIL)/maildir/dos
MACFORMATSET := $(SET_OF_EMAIL)/maildir/mac

INDEX_LENGTH := 24
DESCR_LENGTH := 50
BH_CAN_PARSE := AmazonSES AmazonWorkMail Aol Bigfoot Biglobe Courier EZweb Exim \
				Facebook GSuite Google KDDI MessageLabs MessagingServer Office365 \
				Postfix SendGrid Sendmail Verizon X5 Yandex qmail

# -----------------------------------------------------------------------------
.PHONY: clean

private-sample:
	$(RM) -r ./$(PRIVATEMAILS)
	$(CP) -vRp ../$(PERL5SISIMAI)/$(PRIVATEMAILS) $(SET_OF_EMAIL)

precision-table:
	cat ../$(PERL5SISIMAI)/$(PRECISIONTAB) | sed \
		-e 's/Email::qmail/Email::Qmail/g' \
		-e 's/Email::mFILTER/Email::MFILTER/g' > $(PRECISIONTAB)

update-other-format-emails:
	for v in `find $(PUBLICEMAILS) -name '*-01.eml' -type f`; do \
		f="`basename $$v`" ;\
		nkf -Lw $$v > $(DOSFORMATSET)/$$f ;\
		nkf -Lm $$v > $(MACFORMATSET)/$$f ;\
	done

emails-for-precision:
	for v in `$(LS) ./$(MAILCLASSDIR)/*.rb | grep -v userdefined`; do \
		MTA=`echo $$v | cut -d/ -f6 | tr '[A-Z]' '[a-z]' | sed 's/.rb//g'` ;\
		$(MKDIR) $(PRECISIONDIR)/email-$$MTA ;\
		$(CP) $(PUBLICEMAILS)/email-$$MTA-*.eml $(PRECISIONDIR)/email-$$MTA/ ;\
		$(CP) $(PRIVATEMAILS)/email-$$MTA/* $(PRECISIONDIR)/email-$$MTA/ ;\
	done
	for v in arf rfc3464 rfc3834; do \
		$(MKDIR) $(PRECISIONDIR)/$$v ;\
		$(CP) $(PUBLICEMAILS)/$$v*.eml $(PRECISIONDIR)/$$v/ ;\
		$(CP) $(PRIVATEMAILS)/$$v/* $(PRECISIONDIR)/$$v/ ;\
	done

emails-for-comparing:
	@ rm -fr ./$(COMPARINGDIR)
	@ $(MKDIR) $(COMPARINGDIR)
	@ for v in $(BH_CAN_PARSE); do \
		$(CP) $(PUBLICEMAILS)/email-`echo $$v | tr '[A-Z]' '[a-z]'`-*.eml $(COMPARINGDIR)/; \
		test -d $(PRIVATEEMAILS) && $(CP) $(PRIVATEMAILS)/email-`echo $$v | tr '[A-Z]' '[a-z]'`/*.eml $(COMPARINGDIR)/; \
	done

comparison: emails-for-comparing
	@ echo -------------------------------------------------------------------
	@ echo `$(HOWMANYMAILS)` emails in $(COMPARINGDIR)
	@ echo -n 'Calculating the velocity of parsing 1000 mails: multiply by '
	@ echo "scale=6; 1000 / `$(HOWMANYMAILS)`" | bc
	@ echo -------------------------------------------------------------------
	@ uptime
	@ echo -------------------------------------------------------------------
	@ if [ -x "$(BOUNCEHAMMER)/bin/mailboxparser" ]; then \
		echo bounceHammer $(THELASTBHVER); \
		n=1; while [ $$n -le 5 ]; do \
			/usr/bin/time $(MBOXPARSERV0) -Fjson $(COMPARINGDIR) > /dev/null ;\
			sleep 1; \
			n=`expr $$n + 1`; \
		done; \
		echo -------------------------------------------------------------------; \
	fi
	@ echo 'Sisimai' `$(RELEASEVERMP) -e 'puts Sisimai.version'` $(RELEASEVERMP)
	@ n=1; while [ $$n -le 5 ]; do \
		/usr/bin/time $(RELEASEVERMP) -e 'Sisimai.make($$*.shift, deliverd: true)' $(COMPARINGDIR) > /dev/null ;\
		sleep 1; \
		n=`expr $$n + 1`; \
	done
	@ echo -------------------------------------------------------------------
	@ echo 'Sisimai' `$(DEVELOPVERMP) -e 'puts Sisimai.version'` $(DEVELOPVERMP)
	@ n=1; while [ $$n -le 5 ]; do \
		/usr/bin/time $(DEVELOPVERMP) -e 'Sisimai.make($$*.shift, deliverd: true)' $(COMPARINGDIR) > /dev/null ;\
		sleep 1; \
		n=`expr $$n + 1`; \
	done
	@ echo -------------------------------------------------------------------

clean:
	$(RM) -r ./$(PRECISIONDIR)
	$(RM) -r ./$(BENCHMARKDIR)
	$(RM) -f tmp/subject-list tmp/senders-list


