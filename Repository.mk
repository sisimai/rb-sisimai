# p5-Sisimai/Repository.mk
#  ____                      _ _                               _    
# |  _ \ ___ _ __   ___  ___(_) |_ ___  _ __ _   _   _ __ ___ | | __
# | |_) / _ \ '_ \ / _ \/ __| | __/ _ \| '__| | | | | '_ ` _ \| |/ /
# |  _ <  __/ |_) | (_) \__ \ | || (_) | |  | |_| |_| | | | | |   < 
# |_| \_\___| .__/ \___/|___/_|\__\___/|_|   \__, (_)_| |_| |_|_|\_\
#           |_|                              |___/                  
# -----------------------------------------------------------------------------
SHELL := /bin/sh
GIT   := /usr/bin/git
CP    := cp
B      = master
V      = neko
EMAILS = set-of-emails


.DEFAULT_GOAL = git-status

# -----------------------------------------------------------------------------
.PHONY: clean

git-status:
	$(GIT) status

git-push:
	@ for v in `$(GIT) remote show | grep -v origin`; do \
		printf "[%s]\n" $$v; \
		$(GIT) push --tags $$v $(B); \
	done

git-tag-list:
	$(GIT) tag -l

git-diff:
	$(GIT) diff -w

git-branch:
	$(GIT) branch -a

git-commit-amend:
	$(GIT) commit --amend

git-follow-log:
	$(GIT) log --follow -p $(V) || \
		printf "\nUsage:\n %% make -f Repository.mk $@ V=<filename>\n"

git-branch-tree:
	$(GIT) log --graph \
		--pretty='format:%C(yellow)%h%Creset %s %Cgreen(%an)%Creset %Cred%d%Creset'

git-rm-cached:
	$(GIT) rm -f --cached $(V) || \
		printf "\nUsage:\n %% make -f Repository.mk $@ V=<filename>\n"

git-reset-soft:
	$(GIT) reset --soft HEAD^

import-set-of-emails:
	test -d $(EMAILS)
	$(CP) -vRp ../$(EMAILS)/mailbox/* ./$(EMAILS)/mailbox/
	$(CP) -vRp ../$(EMAILS)/maildir/* ./$(EMAILS)/maildir/
	$(CP) -vRp ../$(EMAILS)/to-be-debugged-because/* ./$(EMAILS)/to-be-debugged-because/

clean:

