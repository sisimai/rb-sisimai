module Sisimai
  module Reason
    # Sisimai::Reason::MailboxFull checks the bounce reason is "mailboxfull" or not. This class is
    # called only Sisimai::Reason class.
    #
    # This is the error that a recipient's mailbox is full. Sisimai will set "mailboxfull" to the
    # reason of email bounce if the value of Status: field in a bounce email is "4.2.2" or "5.2.2".
    module MailboxFull
      class << self
        Index = [
          "452 insufficient disk space",
          "account disabled temporarly for exceeding receiving limits",
          "boite du destinataire pleine",
          "exceeded storage allocation",
          "full mailbox",
          "mailbox exceeds allowed size",
          "mailbox size limit exceeded",
          "mailbox would exceed maximum allowed storage",
          "mailfolder is full",
          "no space left on device",
          "not sufficient disk space",
          "quota violation for",
          "too much mail data", # @docomo.ne.jp
          "user has exceeded quota, bouncing mail",
          "user has too many messages on the server",
          "user's space has been used up",
        ].freeze
        Pairs = [
          ["account is ", " quota"],
          ["disk", "quota"],
          ["enough ", " space"],
          ["mailbox ", "exceeded", " limit"],
          ["mailbox ", "full"],   # Exim/transports/appendfile.c:2567
          ["mailbox ", "quota"],
          ["maildir ", "quota"],
          ["over ", "quota"],
          ["quota ", "exceeded"], # Exim/transports/appendfile.c:3050
        ].freeze

        def text; return 'mailboxfull'; end
        def description; return "Email rejected due to a recipient's mailbox is full"; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [Boolean]       false: Did not match, true: Matched
        def match(argv1)
          return false if argv1.nil? || argv1.empty?
          return true  if Index.any? { |a| argv1.include?(a) }
          return true  if Pairs.any? { |a| Sisimai::String.aligned(argv1, a) }
          return false
        end

        # The envelope recipient's mailbox is full or not
        # @param    [Sisimai::Fact] argvs   Object to be detected the reason
        # @return   [Boolean]               true:  is mailbox full
        #                                   false: is not mailbox full
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return false if argvs['deliverystatus'].empty?
          return true  if argvs['reason'] == 'mailboxfull'

          # Delivery status code points "mailboxfull".
          # Status: 4.2.2
          # Diagnostic-Code: SMTP; 450 4.2.2 <***@example.jp>... Mailbox Full
          return true if Sisimai::SMTP::Status.name(argvs['deliverystatus']) == 'mailboxfull'
          return match(argvs['diagnosticcode'].downcase)
        end

      end
    end
  end
end



