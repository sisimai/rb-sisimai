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
          "blacklisted url in message",
          "block for spam",
          "blocked by policy: no spam please",
          "blocked by spamassassin", # rejected by SpamAssassin
          "classified as spam and is rejected",
          "content filter rejection",
          "denied due to spam list",
          "identified spam", # 554 SpamBouncer identified SPAM, message permanently rejected (#5.3.0)
          "may consider spam",
          "message content rejected",
          "message has been temporarily blocked by our filter",
          "message is being rejected as it seems to be a spam",
          "message was rejected by recurrent pattern detection system",
          "our email server thinks this email is spam",
          "reject bulk.advertising",
          "spam check",
          "spam content ",
          "spam detected",
          "spam email",
          "spam-like header",
          "spam message",
          "spam not accepted",
          "spam refused",
          "spamming not allowed",
          "unsolicited ",
          "your email breaches local uribl policy",
        ].freeze
        Pairs = [
          ["accept", " spam"],
          ["appears", " to ", "spam"],
          ["bulk", "mail"],
          ["considered", " spam"],
          ["contain", " spam"],
          ["detected", " spam"],
          ["greylisted", " please try again in"],
          ["mail score (", " over "],
          ["mail rejete. mail rejected. ", "506"],
          ["message ", "as spam"],
          ["message ", "like spam"],
          ["message ", "spamprofiler"],
          ["probab", " spam"],
          ["refused by", " spamprofiler"],
          ["reject", " content"],
          ["reject, id=", "spam"],
          ["rejected by ", " (spam)"],
          ["rejected due to spam ", "classification"],
          ["rule imposed as ", " is blacklisted on"],
          ["score", "spam"],
          ["spam ", "block"],
          ["spam ", "filter"],
          ["spam ", " exceeded"],
          ["spam ", "score"],
        ].freeze

        def text; return 'spamdetected'; end
        def description; return 'Email rejected by spam filter running on the remote host'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [Boolean]       false: Did not match, true: Matched
        def match(argv1)
          return false if argv1.nil? || argv1.empty?
          return true  if Index.any? { |a| argv1.include?(a) }
          return true  if Pairs.any? { |a| Sisimai::String.aligned(argv1, a) }
          return false
        end

        # Rejected due to spam content in the message
        # @param    [Sisimai::Fact] argvs   Object to be detected the reason
        # @return   [Boolean]               true: rejected due to spam
        #                                   false: is not rejected due to spam
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return false if argvs['deliverystatus'].empty?
          return true  if argvs['reason'] == 'spamdetected'
          return true  if Sisimai::SMTP::Status.name(argvs['deliverystatus']) == 'spamdetected'

          # The value of "reason" isn't "spamdetected" when the value of "command" is an SMTP command
          # to be sent before the SMTP DATA command because all the MTAs read the headers and the
          # entire message body after the DATA command.
          return false if Sisimai::SMTP::Command::ExceptDATA.include?(argvs['command'])
          return match(argvs['diagnosticcode'].downcase)
        end

      end
    end
  end
end

