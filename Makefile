# rb-Sisimai/Makefile
#  __  __       _         __ _ _      
# |  \/  | __ _| | _____ / _(_) | ___ 
# | |\/| |/ _` | |/ / _ \ |_| | |/ _ \
# | |  | | (_| |   <  __/  _| | |  __/
# |_|  |_|\__,_|_|\_\___|_| |_|_|\___|
# -----------------------------------------------------------------------------
SHELL := /bin/sh
TIME  := $(shell date '+%s')
NAME  := sisimai
RUBY  := ruby
RAKE  := rake
MKDIR := mkdir -p
RSPEC := rspec -Ilib -f progress
CP    := cp
RM    := rm -f

.DEFAULT_GOAL = git-status
REPOS_TARGETS = git-status git-push git-commit-amend git-tag-list git-diff \
				git-reset-soft git-rm-cached git-branch

# -----------------------------------------------------------------------------
.PHONY: clean

install-from-rubygems:
	gem install $(NAME)

install-from-local: cpanm
	bundle exec $(RAKE) install

release:
	bundle exec $(RAKE) release

test: user-test

user-test:
	$(RAKE) spec

patrol:
	rubocop -fp --display-cop-names --display-style-guide --no-color lib

$(REPOS_TARGETS):
	$(MAKE) -f Repository.mk $@

diff push branch:
	@$(MAKE) git-$@
fix-commit-message: git-commit-amend
cancel-the-latest-commit: git-reset-soft
remove-added-file: git-rm-cached

clean:
	$(MAKE) -f Repository.mk clean

