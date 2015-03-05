# rb-Sisimai/Makefile
#  __  __       _         __ _ _      
# |  \/  | __ _| | _____ / _(_) | ___ 
# | |\/| |/ _` | |/ / _ \ |_| | |/ _ \
# | |  | | (_| |   <  __/  _| | |  __/
# |_|  |_|\__,_|_|\_\___|_| |_|_|\___|
# ---------------------------------------------------------------------------
SHELL = /bin/sh
HERE  = $(shell `pwd`)
TIME  = $(shell date '+%s')
NAME  = Sisimai
RUBY  = ruby
RSPEC = rspec -w -I./lib
GIT   = /usr/bin/git

.PHONY: clean
test: user-test
user-test:
	$(RSPEC) ./spec

push:
	for G in `grep -E '^[[]remote' .git/config | cut -d' ' -f2 | tr -d '"]'`; do \
		$(GIT) push --tags $$G master; \
	done

