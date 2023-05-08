module Sisimai
  module SMTP
    # Sisimai::SMTP::Transcript is an SMTP Command related utilities
    module Command
      class << self
        Detectable = [
          'HELO', 'EHLO', 'STARTTLS', 'AUTH PLAIN', 'AUTH LOGIN', 'AUTH CRAM-', 'AUTH DIGEST-',
          'MAIL F', 'RCPT', 'RCPT T', 'DATA', 'QUIT', 'XFORWARD',
        ].freeze

        # Check that an SMTP command in the argument is valid or not
        # @param    [String] argv0  An SMTP command
        # @return   [Boolean]       0: Is not a valid SMTP command, 1: Is a valid SMTP command
        # @since v5.0.0
        def test(argv0 = '')
          return nil  if argv0.empty?
          return nil  if argv0.size < 4

          comm0 = %w[HELO EHLO MAIL RCPT DATA QUIT RSET NOOP VRFY ETRN EXPN HELP]
          comm1 = %w[AUTH STARTTLS XFORWARD]
          return true if comm0.any? { |a| argv0.include?(a) }
          return true if comm1.any? { |a| argv0.include?(a) }
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
          commandmap = { 'STAR' => 'STARTTLS', 'XFOR' => 'XFORWARD' }
          commandset = []
          previouspp = 0

          Detectable.each do |e|
            # Find an SMTP command from the given string
            p0 = argv0.index(e, previouspp)
            next unless p0
            next if p0 + 4 > stringsize
            previouspp = p0

            cv = argv0[p0, 4]; next if commandset.include?(cv)
            cv = commandmap[cv] if commandmap.has_key?(cv)
            commandset << cv
          end

          return nil if commandset.empty?
          return commandset.pop
        end
      end
    end
  end
end

