module Sisimai
  # Sisimai::RFC5965 - A class for An Extensible Format for Email Feedback Reports
  module RFC5965
    class << self
      # https://datatracker.ietf.org/doc/html/rfc5965
      def FIELDINDEX
        return [
          # Required Fields
          # The following report header fields MUST appear exactly once:
          'Feedback-Type', 'User-Agent', 'Version',

          # Optional Fields Appearing Once
          # The following header fields are optional and MUST NOT appear more than once:
          # - "Reporting-MTA" is defined in Sisimai::RFC1894->FIELDINDEX()
          'Original-Envelope-Id', 'Original-Mail-From', 'Arrival-Date', 'Source-IP', 'Incidents',

          # Optional Fields Appearing Multiple Times
          # The following set of header fields are optional and may appear any number of times as
          # appropriate:
          'Authentication-Results', 'Original-Rcpt-To', 'Reported-Domain', 'Reported-URI',

          # The historic field "Received-Date" SHOULD also be accepted and interpreted identically
          # to "Arrival-Date".  However, if both are present, the report is malformed and SHOULD be
          # treated as described in Section 4.
          'Received-Date',
        ]
      end
    end
  end
end

