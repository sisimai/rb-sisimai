module Sisimai
  # Sisimai::MDA - Error message parser for MDA
  module MDA
    class << self
      AgentNames = {
        # dovecot/src/deliver/deliver.c
        # 11: #define DEFAULT_MAIL_REJECTION_HUMAN_REASON \
        # 12: "Your message to <%t> was automatically rejected:%n%r"
        'dovecot'    => ['Your message to ', ' was automatically rejected:'],
        'mail.local' => ['mail.local: '],
        'procmail'   => ['procmail: '],
        'maildrop'   => ['maildrop: '],
        'vpopmail'   => ['vdelivermail: '],
        'vmailmgr'   => ['vdeliver: '],
      }.freeze

      # dovecot/src/deliver/mail-send.c:94
      MessagesOf = {
        'dovecot' => {
          'userunknown' => ["mailbox doesn't exist: "],
          'mailboxfull' => [
            'quota exceeded',   # Dovecot 1.2 dovecot/src/plugins/quota/quota.c
            'quota exceeded (mailbox for user is full)',    # dovecot/src/plugins/quota/quota.c
            'not enough disk space',
          ],
        },
        'mail.local' => {
          'userunknown' => [
            ': unknown user:',
            ': user unknown',
            ': invalid mailbox path',
            ': user missing home directory',
          ],
          'mailboxfull' => [
            'disc quota exceeded',
            'mailbox full or quota exceeded',
          ],
          'systemerror' => ['temporary file write error'],
        },
        'procmail' => {
          'mailboxfull' => ['quota exceeded while writing'],
          'systemfull'  => ['no space left to finish writing'],
        },
        'maildrop' => {
          'userunknown' => [
            'invalid user specified.',
            'Cannot find system user',
          ],
          'mailboxfull' => ['maildir over quota.'],
        },
        'vpopmail' => {
          'userunknown' => ['sorry, no mailbox here by that name.'],
          'filtered'    => [
            'account is locked email bounced',
            'user does not exist, but will deliver to '
          ],
          'mailboxfull' => ['domain is over quota', 'user is over quota'],
        },
        'vmailmgr' => {
          'userunknown' => [
            'invalid or unknown base user or domain',
            'invalid or unknown virtual user',
            'user name does not refer to a virtual user'
          ],
          'mailboxfull' => ['delivery failed due to system quota violation'],
        },
      }.freeze

      # Parse message body and return reason and text
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        return nil unless mhead
        return nil unless mbody.size > 0
        return nil unless mhead['from'].downcase.start_with?('mail delivery subsystem','mailer-daemon', 'postmaster')

        deliversby = ''   # [String] Mail Delivery Agent name
        reasonname = ''   # [String] Error reason
        bouncemesg = ''   # [String] Error message
        linebuffer = mbody.split("\n")

        AgentNames.each_key do |e|
          # Find a mail delivery agent name from the entire message body
          p = mbody.index(AgentNames[e][0])
          next unless p

          if AgentNames[e].size > 1
            # Try to find the 2nd argument
            q = mbody.index(AgentNames[e][1])
            next unless q
            next if p > q
          end
          deliversby = e
          break
        end
        return nil if deliversby.empty?

        MessagesOf[deliversby].each_key do |e|
          # Detect an error reason from message patterns of the MDA.
          linebuffer.each do |f|
            # Whether the error message include each message defined in MessagesOf
            next unless MessagesOf[deliversby][e].any? { |a| f.downcase.include?(a) }
            reasonname = e
            bouncemesg = f
            break
          end
          break if bouncemesg.size > 0 && reasonname.size > 0
        end

        return {
          'mda'     => deliversby,
          'reason'  => reasonname || '',
          'message' => bouncemesg || '',
        }
      end
    end
  end
end

