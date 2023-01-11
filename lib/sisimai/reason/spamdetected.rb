module Sisimai
  module Reason
    # Sisimai::Reason::SpamDetected checks the bounce reason is "spamdetected" due to Spam content
    # in the message or not. This class is called only Sisimai::Reason class. This is the error that
    # the message you sent was rejected by "spam filter" which is running on the remote host.
    #
    #    Action: failed
    #    Status: 5.7.1
    #    Diagnostic-Code: smtp; 550 5.7.1 Message content rejected, UBE, id=00000-00-000
    #    Last-Attempt-Date: Thu, 9 Apr 2008 23:34:45 +0900 (JST)
    module SpamDetected
      class << self
        Index = [
          ' - spam',
          '//www.spamhaus.org/help/help_spam_16.htm',
          '//dsbl.org/help/help_spam_16.htm',
          '//mail.163.com/help/help_spam_16.htm',
          '554 5.7.0 reject, id=',
          'appears to be unsolicited',
          'blacklisted url in message',
          'block for spam',
          'blocked by policy: no spam please',
          'blocked by spamassassin',                      # rejected by SpamAssassin
          'blocked for abuse. see http://att.net/blocks', # AT&T
          'bulk email',
          'cannot be forwarded because it was detected as spam',
          'considered unsolicited bulk e-mail (spam) by our mail filters',
          'content filter rejection',
          'cyberoam anti spam engine has identified this email as a bulk email',
          'denied due to spam list',
          'high probability of spam',
          'is classified as spam and is rejected',
          'listed in work.drbl.imedia.ru',
          'the mail server detected your message as spam and has prevented delivery.',   # CPanel/Exim with SA rejections on
          'mail appears to be unsolicited',   # rejected due to spam
          'mail content denied',              # http://service.mail.qq.com/cgi-bin/help?subtype=1&&id=20022&&no=1000726
          'may consider spam',
          'message considered as spam or virus',
          'message contains spam or virus',
          'message content rejected',
          'message detected as spam',
          'message filtered',
          'message filtered. please see the faqs section on spam',
          'message filtered. refer to the troubleshooting page at ',
          'message looks like spam',
          'message is being rejected as it seems to be a spam',
          'message refused by mailmarshal spamprofiler',
          'message refused by trustwave seg spamprofiler',
          'message rejected as spam',
          'message rejected because of unacceptable content',
          'message rejected due to suspected spam content',
          'message rejected for policy reasons',
          'message was rejected for possible spam/virus content',
          'our email server thinks this email is spam',
          'our system has detected that this message is ',
          'probable spam',
          'reject bulk.advertising',
          'rejected: spamassassin score ',
          'rejecting banned content',
          'rejecting mail content',
          'related to content with spam-like characteristics',
          'sending address not accepted due to spam filter',
          'spam blocked',
          'spam check',
          'spam content matched',
          'spam detected',
          'spam email',
          'spam email not accepted',
          'spam message rejected.',   # mail.ru
          'spam not accepted',
          'spam refused',
          'spam rejection',
          'spam score ',
          'spambouncer identified spam',  # SpamBouncer identified SPAM
          'spamming not allowed',
          'too much spam.',               # Earthlink
          'the email message was detected as spam',
          'the message has been rejected by spam filtering engine',
          'the message was rejected due to classification as bulk mail',
          'the content of this message looked like spam', # SendGrid
          'this message appears to be spam',
          'this message has been identified as spam',
          'this message has been scored as spam with a probability',
          'this message was classified as spam',
          'this message was rejected by recurrent pattern detection system',
          'transaction failed spam message not queued',   # SendGrid
          'we dont accept spam',
          'your email appears similar to spam we have received before',
          'your email breaches local uribl policy',
          'your email had spam-like ',
          'your email is considered spam',
          'your email is probably spam',
          'your email was detected as spam',
          'your message as spam and has prevented delivery',
          'your message has been temporarily blocked by our filter',
          'your message has been rejected because it appears to be spam',
          'your message has triggered a spam block',
          'your message may contain the spam contents',
          'your message failed several antispam checks',
        ].freeze
        Pairs = [
          ['greylisted', ' please try again in'],
          ['mail rejete. mail rejected. ', '506'],
          ['our filters rate at and above ', ' percent probability of being spam'],
          ['rejected by ', ' (spam)'],
          ['rule imposed as ', ' is blacklisted on'],
          ['spam ', ' exceeded'],
          ['this message scored ', ' spam points'],
        ].freeze
        Regex = %r{(?>
           (?:\d[.]\d[.]\d|\d{3})[ ]spam\z
          |rejected[ ]due[ ]to[ ]spam[ ](?:url[ ]in[ ])?(?:classification|content)
          |sender[ ]domain[ ]listed[ ]at[ ][^ ]+
          )
        }x.freeze

        def text; return 'spamdetected'; end
        def description; return 'Email rejected by spam filter running on the remote host'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          return true if Index.any? { |a| argv1.include?(a) }
          return true if Pairs.any? { |a| 
            p = (argv1.index(a[0], 0) || -1) + 1
            q = (argv1.index(a[1], p) || -1) + 1
            p * q > 0
          }
          return true if argv1 =~ Regex
          return false
        end

        # Rejected due to spam content in the message
        # @param    [Sisimai::Fact] argvs   Object to be detected the reason
        # @return   [True,False]            true: rejected due to spam
        #                                   false: is not rejected due to spam
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return nil  if argvs['deliverystatus'].empty?
          return true if argvs['reason'] == 'spamdetected'
          return true if Sisimai::SMTP::Status.name(argvs['deliverystatus']).to_s == 'spamdetected'

          # The value of "reason" isn't "spamdetected" when the value of "smtpcommand" is an SMTP
          # command to be sent before the SMTP DATA command because all the MTAs read the headers
          # and the entire message body after the DATA command.
          return false if %w[CONN EHLO HELO MAIL RCPT].include?(argvs['smtpcommand'])
          return true  if match(argvs['diagnosticcode'].downcase)
          return false
        end

      end
    end
  end
end

