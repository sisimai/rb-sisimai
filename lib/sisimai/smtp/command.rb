module Sisimai
  module SMTP
    # Sisimai::SMTP::Transcript is an SMTP Command related utilities
    module Command
      class << self
        Detectable = [
          'HELO', 'EHLO', 'STARTTLS', 'AUTH PLAIN', 'AUTH LOGIN', 'AUTH CRAM-', 'AUTH DIGEST-',
          'MAIL F', 'RCPT', 'RCPT T', 'DATA'
        ].freeze

        # Pick an SMTP command from the given string
        # @param    [String] argv0  A transcript text MTA returned
        # @return   [String]        An SMTP command
        # @return   [undef]         Failed to find an SMTP command or the 1st argument is missing
        # @since v5.0.0
        def find(argv0 = '')
          return nil unless argv0.size > 3
          return nil unless argv0 =~ /(?:HELO|EHLO|STARTTLS|AUTH|MAIL|RCPT|DATA)/

          stringsize = argv0.size
          commandset = []
          previouspp = 0

          Detectable.each do |e|
            # Find an SMTP command from the given string
            p = argv0.index(e, previouspp)
            next unless p
            next if p + 4 > stringsize
            previouspp = p
            v = argv0[p, 4]
            next if commandset.include?(v)
            commandset << v
          end

          return nil if commandset.empty?
          return commandset.pop
        end
      end
    end
  end
end

