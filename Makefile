# rb-Sisimai/Makefile
#  __  __       _         __ _ _      
# |  \/  | __ _| | _____ / _(_) | ___ 
# | |\/| |/ _` | |/ / _ \ |_| | |/ _ \
# | |  | | (_| |   <  __/  _| | |  __/
# |_|  |_|\__,_|_|\_\___|_| |_|_|\___|
# -----------------------------------------------------------------------------
SHELL := /bin/sh
HERE  := $(shell pwd)
TIME  := $(shell date '+%s')
NAME  := sisimai
RUBY  := ruby
MKDIR := mkdir -p
RSPEC := rspec -Ilib -f progress
LS    := ls -1
CP    := cp
RM    := rm -f
GIT   := /usr/bin/git

.DEFAULT_GOAL = git-status
FOR_MAKETEST := ./eg/maildir-as-a-sample/new
CRLF_SAMPLES := ./eg/maildir-as-a-sample/dos
CRFORMATMAIL := ./eg/maildir-as-a-sample/mac
MAILBOX_FILE := ./eg/mbox-as-a-sample
MTAMODULEDIR := ./lib/$(NAME)/mta
MSPMODULEDIR := ./lib/$(NAME)/msp
MTARELATIVES := arf rfc3464 rfc3834

# -----------------------------------------------------------------------------
.PHONY: clean
install-from-cpan: cpanm
	sudo ./cpanm $(NAME)

install-from-local: cpanm
	sudo ./cpanm .

# -----------------------------------------------------------------------------
#  _____                    _          __                  _                _   
# |_   _|_ _ _ __ __ _  ___| |_ ___   / _| ___  _ __    __| | _____   _____| |  
#   | |/ _` | '__/ _` |/ _ \ __/ __| | |_ / _ \| '__|  / _` |/ _ \ \ / / _ \ |  
#   | | (_| | | | (_| |  __/ |_\__ \ |  _| (_) | |    | (_| |  __/\ V /  __/ |_ 
#   |_|\__,_|_|  \__, |\___|\__|___/ |_|  \___/|_|     \__,_|\___| \_/ \___|_(_)
#                |___/                                                          
# -----------------------------------------------------------------------------
test: user-test
user-test:
	$(RSPEC) spec/

author-test:

cover-test:

release-test:

dist:

push:
	@ for v in `git remote show | grep -v origin`; do \
		printf "[%s]\n" $$v; \
		$(GIT) push --tags $$v master; \
	done

git-status:
	git status

loc:
	@ for v in `find lib -type f -name '*.rb'`; do \
		x=`wc -l $$v | awk '{ print $$1 }'`; \
		y=`cat -n $$v | grep '\t1;' | tail -n 1 | awk '{ print $$1 }'`; \
		z=`grep -E '^\s*#|^$$' $$v | wc -l | awk '{ print $$1 }'`; \
		echo "$$x - ( $$x - $$y ) - $$z" | bc ;\
	done | awk '{ s += $$1 } END { print s }'

clean:

