module Sisimai
  # Sisimai::LDA - Error message decoder for LDA
  module LDA
    class << self
      LocalAgent = {
        # Each error message should be a lower-cased string
        # dovecot/src/deliver/deliver.c
        # 11: #define DEFAULT_MAIL_REJECTION_HUMAN_REASON \
        # 12: "Your message to <%t> was automatically rejected:%n%r"
        "dovecot"    => ["Your message to <", "> was automatically rejected:"],
        "mail.local" => ["mail.local: "],
        "procmail"   => ["procmail: ", "/procmail "],
        "maildrop"   => ["maildrop: "],
        "vpopmail"   => ["vdelivermail: "],
        "vmailmgr"   => ["vdeliver: "],
      }.freeze

      MessagesOf = {
        # Each error message should be a lower-cased string
        "dovecot" => {
          # dovecot/src/deliver/mail-send.c:94
          "mailboxfull" => [
            "not enough disk space",
            "quota exceeded",   # Dovecot 1.2 dovecot/src/plugins/quota/quota.c
            "quota exceeded (mailbox for user is full)",    # dovecot/src/plugins/quota/quota.c
          ],
          "userunknown" => ["mailbox doesn't exist: "],
        },
        "mail.local" => {
          "mailboxfull" => [
            "disc quota exceeded",
            "mailbox full or quota exceeded",
          ],
          "systemerror" => ["temporary file write error"],
          "userunknown" => [
            ": invalid mailbox path",
            ": unknown user:",
            ": user missing home directory",
            ": user unknown",
          ],
        },
        "procmail" => {
          "mailboxfull" => ["quota exceeded while writing", "user over quota"],
          "systemerror" => ["service unavailable"],
          "systemfull"  => ["no space left to finish writing"],
        },
        "maildrop" => {
          "userunknown" => ["cannot find system user", "invalid user specified."],
          "mailboxfull" => ["maildir over quota."],
        },
        "vpopmail" => {
          "filtered"    => ["user does not exist, but will deliver to "],
          "mailboxfull" => ["domain is over quota", "user is over quota"],
          "suspend"     => ["account is locked email bounced"],
          "userunknown" => ["sorry, no mailbox here by that name."],
        },
        "vmailmgr" => {
          "mailboxfull" => ["delivery failed due to system quota violation"],
          "userunknown" => [
            "invalid or unknown base user or domain",
            "invalid or unknown virtual user",
            "user name does not refer to a virtual user",
          ],
        },
      }.freeze

      # @abstract Decodes the message body and return the LDA name, the reason, and the error message
      # @param  [Sisimai::Fact] argvs Decoded email object
      # @return [String]        Bounce reason
      def find(argvs)
        return "" if argvs.nil?
        return "" if argvs["diagnosticcode"].empty?
        return "" if argvs["command"] != "" && argvs["command"] != "DATA"

        deliversby = ""   # [String] Local Delivery Agent name
        reasontext = ""   # [String] Error reason
        issuedcode = argvs["diagnosticcode"].downcase

        LocalAgent.each_key do |e|
          # Find a lcoal delivery agent name from the entire message body
          next if LocalAgent[e].none? { |a| issuedcode.include?(a) }
          deliversby = e; break
        end
        return "" if deliversby.empty?

        MessagesOf[deliversby].each_key do |e|
          # The key is a bounce reason name
          next if MessagesOf[deliversby][e].none? { |a| issuedcode.include?(a) }
          reasontext = e; break
        end

        reasontext = "mailererror" if reasontext.empty?
        return reasontext
      end
    end
  end
end

