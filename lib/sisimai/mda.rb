module Sisimai
  # Sisimai::MDA - Error message parser for MDA
  module MDA
    # Imported from p5-Sisimail/lib/Sisimai/MDA.pm
    class << self
      AgentNames = {
        # dovecot/src/deliver/deliver.c
        # 11: #define DEFAULT_MAIL_REJECTION_HUMAN_REASON \
        # 12: "Your message to <%t> was automatically rejected:%n%r"
        :'dovecot'    => %r/\AYour message to .+ was automatically rejected:\z/,
        :'mail.local' => %r/\Amail[.]local: /,
        :'procmail'   => %r/\Aprocmail: /,
        :'maildrop'   => %r/\Amaildrop: /,
        :'vpopmail'   => %r/\Avdelivermail: /,
        :'vmailmgr'   => %r/\Avdeliver: /,
      }.freeze
      MarkingsOf = {
        message: %r{\A(?>
           Your[ ]message[ ]to[ ].+[ ]was[ ]automatically[ ]rejected:\z
          |(?:mail[.]local|procmail|maildrop|vdelivermail|vdeliver):[ ]
          )
        }x
      }.freeze

      # dovecot/src/deliver/mail-send.c:94
      ReFailures = {
        :'dovecot' => {
          :userunknown => %r/\Amailbox doesn't exist: /,
          :mailboxfull => %r{\A(?:
             quota[ ]exceeded # Dovecot 1.2 dovecot/src/plugins/quota/quota.c
            |quota[ ]exceeded[ ][(]mailbox[ ]for[ ]user[ ]is[ ]full[)]  # dovecot/src/plugins/quota/quota.c
            |not[ ]enough[ ]disk[ ]space
            )
          }x,
        },
        :'mail.local' => {
          :userunknown => %r{[:][ ](?:
             unknown[ ]user[:]
            |user[ ]unknown
            |invalid[ ]mailbox[ ]path
            |user[ ]missing[ ]home[ ]directory
            )
          }x,
          :mailboxfull => %r{(?:
             disc[ ]quota[ ]exceeded
            |mailbox[ ]full[ ]or[ ]quota[ ]exceeded
            )
          }x,
          :systemerror => %r/temporary file write error/,
        },
        :'procmail' => {
          :mailboxfull => %r/quota exceeded while writing/,
          :systemfull  => %r/no space left to finish writing/,
        },
        :'maildrop' => {
          :userunknown => %r{(?:
             invalid[ ]user[ ]specified[.]
            |Cannot[ ]find[ ]system[ ]user
            )
          }x,
          :mailboxfull => %r/maildir over quota[.]\z/,
        },
        :'vpopmail' => {
          :userunknown => %r/sorry, no mailbox here by that name[.]/,
          :filtered    => %r{(?:
             account[ ]is[ ]locked[ ]email[ ]bounced
            |user[ ]does[ ]not[ ]exist,[ ]but[ ]will[ ]deliver[ ]to[ ]
            )
          }x,
          :mailboxfull => %r/(?:domain|user) is over quota/,
        },
        :'vmailmgr' => {
          :userunknown => %r{(?>
             invalid[ ]or[ ]unknown[ ](?:base[ ]user[ ]or[ ]domain|virtual[ ]user)
            |user[ ]name[ ]does[ ]not[ ]refer[ ]to[ ]a[ ]virtual[ ]user/
            )
          }x,
          :mailboxfull => %r/delivery failed due to system quota violation/,
        },
      }.freeze

      # Parse message body and return reason and text
      # @param         [Hash] mhead       Message header of a bounce email
      # @options mhead [String] from      From header
      # @options mhead [String] date      Date header
      # @options mhead [String] subject   Subject header
      # @options mhead [Array]  received  Received headers
      # @options mhead [String] others    Other required headers
      # @param         [String] mbody     Message body of a bounce email
      # @return        [Hash, Nil]        Bounce data list and message/rfc822 part
      #                                   or nil if it failed to parse or the
      #                                   arguments are missing
      def scan(mhead, mbody)
        return nil unless mhead
        return nil unless mbody
        return nil if mhead.keys.size.zero?
        return nil if mbody.empty?
        return nil unless mhead['from'].downcase =~ /\A(?:mail delivery subsystem|mailer-daemon|postmaster)/

        agentname0 = ''   # [String] MDA name
        reasonname = ''   # [String] Error reason
        bouncemesg = ''   # [String] Error message
        hasdivided = mbody.split("\n")
        linebuffer = []

        while e = hasdivided.shift do
          # Check each line with each MDA's symbol regular expression.
          if agentname0 == ''
            # Try to match with each regular expression
            next unless e.size > 0
            next unless e =~ MarkingsOf[:message]

            AgentNames.each_key do |f|
              # Detect the agent name from the line
              next unless e =~ AgentNames[f]
              agentname0 = f.to_s
              break
            end
          end

          # Append error message lines to @linebuffer
          linebuffer << e
          break unless e.size > 0
        end
        return nil unless agentname0.size > 0
        return nil unless linebuffer.size > 0

        ReFailures[agentname0.to_sym].each_key do |e|
          # Detect an error reason from message patterns of the MDA.
          linebuffer.each do |f|
            # Try to match with each regular expression
            next unless f.downcase =~ ReFailures[agentname0.to_sym][e]
            reasonname = e.to_s
            bouncemesg = f
            break
          end
          break if bouncemesg.size > 0 && reasonname.size > 0
        end

        return {
          'mda'     => agentname0,
          'reason'  => reasonname || '',
          'message' => bouncemesg || '',
        }
      end
    end
  end
end

