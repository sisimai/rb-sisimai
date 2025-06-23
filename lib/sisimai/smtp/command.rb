module Sisimai
  module SMTP
    # Sisimai::SMTP::Transcript is an SMTP Command related utilities
    module Command
      class << self
        Availables = [
          "HELO", "EHLO", "MAIL", "RCPT", "DATA", "QUIT", "RSET", "NOOP", "VRFY", "ETRN", "EXPN",
          "HELP", "AUTH", "STARTTLS", "XFORWARD",
          "CONN", # CONN is a pseudo SMTP command used only in Sisimai
        ].freeze
        Detectable = [
          "HELO", "EHLO", "STARTTLS", "AUTH PLAIN", "AUTH LOGIN", "AUTH CRAM-", "AUTH DIGEST-",
          "MAIL F", "RCPT", "RCPT T", "DATA", "QUIT", "XFORWARD",
        ].freeze

        # Check that an SMTP command in the argument is valid or not
        # @param    [String] argv0  An SMTP command
        # @return   [Boolean]       0: Is not a valid SMTP command, 1: Is a valid SMTP command
        # @since v5.0.0
        def test(argv0 = '')
          return false if argv0.nil? || argv0.empty? || argv0.size < 4
          return true  if Availables.any? { |a| argv0.include?(a) }
          return false
        end

        # Pick an SMTP command from the given string
        # @param    [String] argv0  A transcript text MTA returned
        # @return   [String]        An SMTP command
        # @since v5.0.0
        def find(argv0 = '')
          return "" unless Sisimai::SMTP::Command.test(argv0)

          issuedcode = " " + argv0.downcase + " "
          commandmap = {"STAR" => "STARTTLS", "XFOR" => "XFORWARD"}
          commandset = []

          Detectable.each do |e|
            # Find an SMTP command from the given string
            p0 = argv0.index(e); next unless p0
            if e.include?(" ") == false
              # For example, "RCPT T" does not appear in an email address or a domain name
              cx = true; while true do
                # Exclude an SMTP command in the part of an email address, a domain name, such as
                # DATABASE@EXAMPLE.JP, EMAIL.EXAMPLE.COM, and so on.
                ca = issuedcode[p0, 1].ord
                cz = issuedcode[p0 + e.size + 1, 1].ord

                break if ca > 47 && ca <  58 || cz > 47 && cz <  58;  # 0-9
                break if ca > 63 && ca <  91 || cz > 63 && cz <  91;  # @-Z
                break if ca > 96 && ca < 123 || cz > 96 && cz < 123;  # `-z
                cx = false; break
              end
              next if cx == true
            end

            # There is the same command in the "commanset" or nor
            cv = e[0, 4]; next if commandset.any? { |a| cv.start_with?(a) }
            cv = commandmap[cv] if commandmap.has_key?(cv)
            commandset << cv
          end

          return "" if commandset.empty?
          return commandset.pop
        end
      end
    end
  end
end

