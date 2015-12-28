         ____       _      ___   __   _____                 _ _     
        / ___|  ___| |_   / _ \ / _| | ____|_ __ ___   __ _(_) |___ 
        \___ \ / _ \ __| | | | | |_  |  _| | '_ ` _ \ / _` | | / __|
         ___) |  __/ |_  | |_| |  _| | |___| | | | | | (_| | | \__ \
        |____/ \___|\__|  \___/|_|   |_____|_| |_| |_|\__,_|_|_|___/
                                                                    
About "set-of-emails" repository
================================
This repository hold bounce mail collections for developing Sisimai. Email files
in this repository are read from `make test` at p5-Sisimai and rb-Sisimai.


| Directory                     | Description                                  |
|-------------------------------|----------------------------------------------|
| mailbox/                      | Unix mbox files                              |
| maildir/                      | Email files                                  |
|  - bsd/                       | A newline is LF                              |
|  - mac/                       | A newline is CR                              |
|  - dos/                       | A newline is CRLF                            |
|  - err/                       | Divided email files of mailbox/mbox-0        |
|  - not/                       | Is not a bounce mail                         |
| to-be-debugged-becase/        | Email files for debugging                    |
|  - reason-is-onhold/          | Reason is "onhold" in parsed results         |
|  - reason-is-undefined/       | Reason is "undefined" in parsed results      |
|  - sisimai-cannot-parse-yet/  | Emails could not be parsed by Sisimai        |
|  - something-is-wrong/        | Sisimai can parse but something is wrong     |

See Also
========
* __libsisimai.org__ | [Sisimai — A successor to bounceHammer, Library to parse error mails](http://libsisimai.org/)
* __GitHub__ | [github.com/sisimai/p5-Sisimai](https://github.com/sisimai/p5-Sisimai)
* __Perl Verson__ | [Perl version of Sisimai(Stable)](https://github.com/sisimai/p5-Sisimai)
* __Ruby verson__ | [Ruby version of Sisimai(Under the development)](https://github.com/sisimai/rb-Sisimai)

