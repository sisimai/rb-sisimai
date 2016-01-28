About Sample Emails in set-of-emails/to-be-parsed-for-test Directory
====================================================================

If you want to know whether the latest version of Sisimai ( both Perl version and
Ruby version) can parse bounce emails you have or not, fork this repository and
add these emails to this repository.

```
% cd /usr/local/src
% git clone https://github.com/sisimai/set-of-emails.git
...

% cd set-of-emails
% git checkout -b add-emails-from-<your-account-name-in-github>
% cp /path/to/some/where/*.eml ./to-be-parsed-for-test/
% git add ./to-be-parsed-for-test/*.eml
% git commit -m 'Your commit message here' ./to-be-parsed-for-test/
% git push origin master
```

