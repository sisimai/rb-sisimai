# rb-sisimai/Developers.mk
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

PERL5SISIMAI := p5-sisimai
PRECISIONTAB := ANALYTICAL-PRECISION
PARSERLOGDIR := tmp/parser-logs
MAILCLASSDIR := lib/$(NAME)/Lhost
MTARELATIVES := ARF rfc3464 rfc3834
BENCHMARKDIR := tmp/benchmark
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

update-other-format-emails:
	for v in `find $(PUBLICEMAILS) -name '*-01.eml' -type f`; do \
		f="`basename $$v`" ;\
		nkf -Lw $$v > $(DOSFORMATSET)/$$f ;\
		nkf -Lm $$v > $(MACFORMATSET)/$$f ;\
	done

clean:
	$(RM) -r ./$(BENCHMARKDIR)

