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
          '#5.1.1 bad address',
          '550 address invalid',
          '5.1.0 address rejected.',
          'address does not exist',
          'address not present in directory',
          'address unknown',
          "can't accept user",
          'does not exist.',
          'destination addresses were unknown',
          'destination server rejected recipients',
          'email address does not exist',
          'email address could not be found',
          'invalid address',
          'invalid mailbox',
          'invalid mailbox path',
          'invalid recipient',
          'is not a known user',
          'is not a valid mailbox',
          'is not an active address at this host',
          'mailbox does not exist',
          'mailbox invalid',
          'mailbox is inactive',
          'mailbox is unavailable',
          'mailbox not present',
          'mailbox not found',
          'mailbox unavaiable',
          'nessun utente simile in questo indirizzo',
          'no account by that name here',
          'no existe dicha persona',
          'no existe ese usuario ',
          'no mail box available for this user',
          'no mailbox by that name is currently available',
          'no mailbox found',
          'no such address here',
          'no such mailbox',
          'no such person at this address',
          'no such recipient',
          'no such user',
          'no thank you rejected: account unavailable',
          'no valid recipients, bye',
          'not a valid recipient',
          'not a valid user here',
          'not a local address',
          'not email addresses',
          'recipient address rejected. (in reply to rcpt to command)',
          'recipient address rejected: access denied',
          'recipient address rejected: invalid user',
          'recipient address rejected: invalid-recipient',
          'recipient address rejected: unknown user',
          'recipient does not exist',
          'recipient is not local',
          'recipient not exist',
          'recipient not found',
          'recipient not ok',
          'recipient refuses to accept your mail',
          'recipient unknown',
          'requested action not taken: mailbox unavailable',
          'resolver.adr.recipient notfound',
          'sorry, user unknown',
          'sorry, badrcptto',
          'sorry, no mailbox here by that name',
          'sorry, your envelope recipient has been denied',
          "that domain or user isn't in my list of allowed rcpthosts",
          'the email account that you tried to reach does not exist',
          'the following recipients was undeliverable',
          "the user's email name is not found",
          'there is no one at this address',
          'this address no longer accepts mail',
          'this email address is wrong or no longer valid',
          'this recipient is in my badrecipientto list',
          'this recipient is not in my validrcptto list',
          'this spectator does not exist',
          'unknown mailbox',
          'unknown recipient',
          'unknown user',
          'user does not exist',
          'user missing home directory',
          'user not active',
          'user not exist',
          'user not found',
          'user not known',
          'user unknown',
          'utilisateur inconnu !',
          'vdeliver: invalid or unknown virtual user',
          'your envelope recipient is in my badrcptto list',
        ].freeze
        Pairs = [
          ['<', '> not found'],
          ['<', '>... blocked by '],
          ['account ', ' does not exist at the organization'],
          ['adresse d au moins un destinataire invalide. invalid recipient.', '416'],
          ['adresse d au moins un destinataire invalide. invalid recipient.', '418'],
          ['bad', 'recipient'],
          ['mailbox ', ' does not exist'],
          ['mailbox ', ' unavailable'],
          ['no ', ' in name directory'],
          ['non', 'existent user'],
          ['rcpt <', ' does not exist'],
          ['recipient ', ' was not found in'],
          ['recipient address rejected: user ', '  does not exist'],
          ['recipient address rejected: user unknown in ', '  table'],
          ['said: 550-5.1.1 ', ' user unknown '],
          ['said: 550 5.1.1 ', ' user unknown '],
          ["this user doesn't have a ", " account"],
          ['unknown e', 'mail address'],
          ['unknown local', 'part'],
          ['user ', ' was not found'],
          ['user ', ' does not exist'],
        ].freeze

        def text; return 'userunknown'; end
        def description; return "Email rejected due to a local part of a recipient's email address does not exist"; end

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
          return false
        end

        # Whether the address is "userunknown" or not
        # @param    [Sisimai::Fact] argvs   Object to be detected the reason
        # @return   [True,False]            true: is unknown user
        #                                   false: is not unknown user.
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return true if argvs['reason'] == 'userunknown'

          tempreason = Sisimai::SMTP::Status.name(argvs['deliverystatus']) || ''
          return false if tempreason == 'suspend'

          diagnostic = argvs['diagnosticcode'].downcase
          if tempreason == 'userunknown'
            # *.1.1 = 'Bad destination mailbox address'
            #   Status: 5.1.1
            #   Diagnostic-Code: SMTP; 550 5.1.1 <***@example.jp>:
            #     Recipient address rejected: User unknown in local recipient table
            matchother = false
            PreMatches.each do |e|
              # Check the value of "Diagnostic-Code" with other error patterns.
              p = 'Sisimai::Reason::' << e
              r = nil
              begin
                require ModulePath[p]
                r = Module.const_get(p)
              rescue
                warn '***warning: Failed to load ' << p
                next
              end

              next unless r.match(diagnostic)
              # Match with reason defined in Sisimai::Reason::* except UserUnknown.
              matchother = true
              break
            end
            return true unless matchother # Did not match with other message patterns

          elsif argvs['smtpcommand'] == 'RCPT'
            # When the SMTP command is not "RCPT", the session rejected by other
            # reason, maybe.
            return true if match(diagnostic)
          end

          return false
        end

      end
    end
  end
end



