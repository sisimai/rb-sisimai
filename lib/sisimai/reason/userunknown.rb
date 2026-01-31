module Sisimai
  module Reason
    # Sisimai::Reason::UserUnknown checks the bounce reason is "userunknown" or not. This class is
    # called only Sisimai::Reason class.
    #
    # This is the error that a local part (Left hand side of @ sign) of a recipient's email address
    # does not exist. In many case, a user has changed internet service provider, or has quit company,
    # or the local part is misspelled. Sisimai will set "userunknown" to the reason of email bounce
    # if the value of Status: field in a bounce email is "5.1.1", or connection was refused at SMTP
    # RCPT command, or the contents of Diagnostic-Code: field represents that it is unknown user.
    #
    #   <kijitora@example.co.jp>: host mx01.example.co.jp[192.0.2.8] said:
    #   550 5.1.1 Address rejected kijitora@example.co.jp (in reply to
    #   RCPT TO command)
    module UserUnknown
      class << self
        PreMatches = %w[NoRelaying Blocked MailboxFull HasMoved Rejected NotAccept]
        ModulePath = {
          'Sisimai::Reason::NoRelaying'  => 'sisimai/reason/norelaying',
          'Sisimai::Reason::Blocked'     => 'sisimai/reason/blocked',
          'Sisimai::Reason::MailboxFull' => 'sisimai/reason/mailboxfull',
          'Sisimai::Reason::HasMoved'    => 'sisimai/reason/hasmoved',
          'Sisimai::Reason::Rejected'    => 'sisimai/reason/rejected',
          'Sisimai::Reason::NotAccept'   => 'sisimai/reason/notaccept',
        }
        Index = [
          "#5.1.1 bad address",
          "550 address invalid",
          "5.1.0 address rejected.",
          "address not present in directory",
          "address unknown",
          "badrcptto",
          "can't accept user",
          "destination addresses were unknown",
          "destination server rejected recipients",
          "domain or user isn't in my list of allowed rcpthosts",
          "email account that you tried to reach does not exist",
          "email address could not be found",
          "invalid address",
          "invalid mailbox",
          "is not a known user",
          "is not a valid mailbox",
          "mailbox does not exist",
          "mailbox invalid",
          "mailbox not present",
          "mailbox not found",
          "nessun utente simile in questo indirizzo",
          "no account by that name here",
          "no existe dicha persona",
          "no existe ese usuario ",
          "no such recipient",
          "no such user",
          "no thank you rejected: account unavailable",
          "no valid recipients, bye",
          "not a valid recipient",
          "not a valid user here",
          "not a local address",
          "not email addresses",
          "recipient address rejected. (in reply to rcpt to command)",
          "recipient address rejected: access denied",
          "recipient address rejected: userunknown",
          "recipient is in my badrecipientto list",
          "recipient is not accepted",
          "recipient is not in my validrcptto list",
          "recipient is not local",
          "recipient not ok",
          "recipient refuses to accept your mail",
          "recipient unknown",
          "recipients was undeliverable",
          "spectator does not exist",
          "there is no one at this address",
          "unknown mailbox",
          "unknown recipient",
          "unknown user",
          "user missing home directory",
          "user not known",
          "user unknown",
          "utilisateur inconnu !",
          "weil die adresse nicht gefunden wurde oder keine e-mails empfangen kann",
          "your envelope recipient has been denied",
        ].freeze
        Pairs = [
          ["<", "> not found"],
          ["<", ">... blocked by "],
          ["account ", " does not exist at the organization"],
          ["address", " no longer"],
          ["address", " not exist"],
          ["bad", "recipient"],
          ["invalid", "recipient"],
          ["invalid", "user"],
          ["mailbox ", "does not exist"],
          ["mailbox ", "unavailable"],
          ["no ", " in name directory"],
          ["no ", "mail", "box "],
          ["no ", "such", "address"],
          ["non", "existent user"],
          ["rcpt <", " does not exist"],
          ["rcpt (", "t exist "],
          ["recipient no", "found"],
          ["recipient ", " not exist"],
          ["recipient ", " was not found in"],
          ["this user doesn't have a ", " account"],
          ["unknown e", "mail address"],
          ["unknown local", "part"],
          ["user ", " not exist"],
          ["user ", "not found"],
          ["user (", ") unknown"],
        ].freeze

        def text; return 'userunknown'; end
        def description; return "Email rejected due to a local part of a recipient's email address does not exist"; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [Boolean]       false: Did not match, true: Matched
        def match(argv1)
          return false if argv1.nil? || argv1.empty?
          return true  if Index.any? { |a| argv1.include?(a) }
          return true  if Pairs.any? { |a| Sisimai::String.aligned(argv1, a) }
          return false
        end

        # Whether the address is "userunknown" or not
        # @param    [Sisimai::Fact] argvs   Object to be detected the reason
        # @return   [Boolean]               true:  is unknown user
        #                                   false: is not unknown user.
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return true  if argvs['reason'] == 'userunknown'
          return false if Sisimai::SMTP::Command::BeforeRCPT.include?(argvs['command'])

          tempreason = Sisimai::SMTP::Status.name(argvs['deliverystatus'])
          return false if tempreason == 'suspend'

          issuedcode = argvs['diagnosticcode'].downcase
          if tempreason == 'userunknown'
            # *.1.1 = 'Bad destination mailbox address'
            #   Status: 5.1.1
            #   Diagnostic-Code: SMTP; 550 5.1.1 <***@example.jp>:
            #     Recipient address rejected: User unknown in local recipient table
            matchother = false
            PreMatches.each do |e|
              # Check the value of "Diagnostic-Code" with other error patterns.
              p = "Sisimai::Reason::#{e}"
              r = nil
              begin
                require ModulePath[p]
                r = Module.const_get(p)
              rescue
                warn "***warning: Failed to load #{p}"
                next
              end

              next if r.match(issuedcode) == false
              # Match with reason defined in Sisimai::Reason::* except UserUnknown.
              matchother = true
              break
            end
            return true if matchother == false  # Did not match with other message patterns

          elsif argvs['command'] == 'RCPT'
            # When the SMTP command is not "RCPT", the session rejected by other
            # reason, maybe.
            return true if match(issuedcode)
          end

          return false
        end

      end
    end
  end
end



