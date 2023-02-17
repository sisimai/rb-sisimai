module Sisimai
  module SMTP
    # Sisimai::SMTP::Transcript is an SMTP Command related utilities
    module Command
      class << self
        Detectable = [
          'HELO', 'EHLO', 'STARTTLS', 'AUTH PLAIN', 'AUTH LOGIN', 'AUTH CRAM-', 'AUTH DIGEST-',
          'MAIL F', 'RCPT', 'RCPT T', 'DATA'
        ].freeze

        # Check that an SMTP command in the argument is valid or not
        # @param    [String] argv0  An SMTP command
        # @return   [Boolean]       0: Is not a valid SMTP command, 1: Is a valid SMTP command
        # @since v5.0.0
        def test(argv0 = '')
          return nil  if argv0.empty?
          return nil  if argv0.size < 4
          return true if %w[HELO EHLO MAIL RCPT DATA QUIT AUTH STARTTLS].any? { |a| argv0.include?(a) }
          return true if argv0.include?('CONN') # CONN is a pseudo SMTP command used only in Sisimai
          return false
        end

        # Pick an SMTP command from the given string
        # @param    [String] argv0  A transcript text MTA returned
        # @return   [String]        An SMTP command
        # @return   [undef]         Failed to find an SMTP command or the 1st argument is missing
        # @since v5.0.0
        def find(argv0 = '')
          return nil unless Sisimai::SMTP::Command.test(argv0)

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

