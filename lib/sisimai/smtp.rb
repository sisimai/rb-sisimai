module Sisimai
  # Sisimai::SMTP is a parent class of Sisimai::SMTP::Status and Sisimai::SMTP::Reply.
  module SMTP
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/SMTP.pm

      # Detector for SMTP commands in a bounce mail message
      # @private
      # @return   [Hash] SMTP command regular expressions
      def command
        return {
          :helo => %r/\b(?:HELO|EHLO)\b/,
          :mail => %r/\bMAIL F(?:ROM|rom)\b/,
          :rcpt => %r/\bRCPT T[Oo]\b/,
          :data => %r/\bDATA\b/,
        }
      end

    end
  end
end

