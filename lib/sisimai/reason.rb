module Sisimai
  # Sisimai::Reason detects the bounce reason from the content of Sisimai::Data
  # object as an argument of get() method. This class is called only Sisimai::Data
  # class.
  module Reason
    # Imported from p5-Sisimail/lib/Sisimai/Reason.pm
    class << self
      # Reason list better to retry detecting an error reason
      # @return   [Array] Reason list
      def retry
        return %w|undefined onhold systemerror securityerror networkerror|
      end
      RetryReasons = Sisimai::Reason.retry

      # All the error reason list Sisimai support
      # @return   [Array] Reason list
      def index
        return %w[
          Blocked ContentError ExceedLimit Expired Filtered HasMoved HostUnknown
          MailboxFull MailerError MesgTooBig NetworkError NotAccept OnHold
          Rejected NoRelaying SpamDetected SecurityError Suspend SystemError
          SystemFull TooManyConn UserUnknown
        ]
      end

      # Detect the bounce reason
      # @param    [Sisimai::Data] argvs   Parsed email object
      # @return   [String, Undef]         Bounce reason or Undef if the argument
      #                                   is missing or invalid object
      # @see anotherone
      def get(argvs)
        return nil unless argvs
        return nil unless argvs.is_a? Sisimai::Data

        unless RetryReasons.index(argvs.reason)
          # Return reason text already decided except reason match with the
          # regular expression of ->retry() method.
          return argvs.reason if argvs.reason.size > 0
        end

        statuscode = argvs.deliverystatus || ''
        reasontext = ''
        classorder = %w|
          MailboxFull MesgTooBig ExceedLimit Suspend HasMoved NoRelaying UserUnknown
          Filtered Rejected HostUnknown SpamDetected TooManyConn Blocked
        |
        return 'delivered' if statuscode =~ /\A2[.]/

        if argvs.diagnostictype == 'SMTP' || argvs.diagnostictype == ''
          # Diagnostic-Code: SMTP; ... or empty value
          classorder.each do |e|
            # Check the value of Diagnostic-Code: and the value of Status:, it is a
            # deliverystats, with true() method in each Sisimai::Reason::* class.
            p = 'Sisimai::Reason::' + e
            r = nil
            begin
              require p.downcase.gsub('::', '/')
              r = Module.const_get(p)
            rescue
              warn ' ***warning: Failed to load ' + p
              next
            end
            next unless r.true(argvs)
            reasontext = r.text
            break
          end
        end

        if reasontext.empty? || reasontext == 'undefined'
          # Bounce reason is not detected yet.
          loop do
            p = 'Sisimai::Reason::OnHold' # Onhold ?
            r = nil
            begin
              require p.downcase.gsub('::', '/')
              r = Module.const_get(p)
              reasontext = r.text if r.true(argvs)
            rescue
              warn ' ***warning: Failed to load ' + p
            end
            break if reasontext.size > 0

            # Other reason ?
            reasontext = self.anotherone(argvs)
            break
          end

          if reasontext == 'undefined' || reasontext.empty?
            # Action: delayed => "expired"
            if reasontext.nil? || reasontext.empty?
              reasontext = 'expired' if argvs.action == 'delayed'
            end
            if reasontext.nil? || reasontext.empty?
              reasontext = 'onhold'  if argvs.diagnosticcode.size > 0
            end
          end
          reasontext = 'undefined' if reasontext.nil? || reasontext.empty?
        end
        return reasontext
      end

      # Detect the other bounce reason, fall back method for get()
      # @param    [Sisimai::Data] argvs   Parsed email object
      # @return   [String, Undef]         Bounce reason or Undef if the argument
      #                                   is missing or invalid object
      # @see get
      def anotherone(argvs)
        return nil unless argvs
        return nil unless argvs.is_a? Sisimai::Data
        return argvs.reason if argvs.reason.size > 0

        statuscode = argvs.deliverystatus || ''
        diagnostic = argvs.diagnosticcode || ''
        commandtxt = argvs.smtpcommand    || ''
        reasontext = ''
        classorder = %w|
          MailboxFull SpamDetected SecurityError SystemError NetworkError
          Suspend Expired ContentError SystemFull NotAccept MailerError
        |

        require 'sisimai/smtp/status'
        reasontext = Sisimai::SMTP::Status.name(statuscode)

        if reasontext.empty? || reasontext == 'userunknown' || RetryReasons.index(reasontext)
          # Could not decide the reason by the value of Status:
          classorder.each do |e|
            # Trying to match with other patterns in Sisimai::Reason::* classes
            p = 'Sisimai::Reason::' + e
            r = nil
            begin
              require p.downcase.gsub('::', '/')
              r = Module.const_get(p)
            rescue
              warn ' ***warning: Failed to load ' + p
              next
            end

            next unless r.match(diagnostic)
            reasontext = e.downcase
            break
          end

          if reasontext.empty?
            # Check the value of Status:
            v = statuscode[0, 3]
            if v == '5.6' || v == '4.6'
              #  X.6.0   Other or undefined media error
              reasontext = 'contenterror'

            elsif v == '5.7' || v == '4.7'
              #  X.7.0   Other or undefined security status
              reasontext = 'securityerror'

            elsif argvs.diagnostictype =~ /\AX-(?:UNIX|POSTFIX)\z/
              # Diagnostic-Code: X-UNIX; ...
              reasontext = 'mailererror'
            end
          end

          if reasontext.empty?
            # Check the value of Action: field, first
            if argvs.action =~ /\A(?:delayed|expired)/
              # Action: delayed, expired
              reasontext = 'expired'

            else
              # Check the value of SMTP command
              if commandtxt =~ /\A(?:EHLO|HELO)\z/
                # Rejected at connection or after EHLO|HELO
                reasontext = 'blocked'
              end
            end
          end
        end
        return reasontext
      end

      # Detect the bounce reason from given text
      # @param    [String] argv1  Error message
      # @return   [String]        Bounce reason
      def match(argv1)
        return nil unless argv1
        require 'sisimai/smtp/status'

        reasontext = ''
        typestring = ''
        classorder = %w|
          MailboxFull MesgTooBig ExceedLimit Suspend UserUnknown Filtered Rejected
          HostUnknown SpamDetected TooManyConn Blocked SpamDetected SecurityError
          SystemError NetworkError Suspend Expired ContentError HasMoved SystemFull
          NotAccept MailerError NoRelaying OnHold
        |

        statuscode = Sisimai::SMTP::Status.find(argv1)
        if cv = argv1.match(/\A(SMTP|X-.+);/i)
          typestring = cv[1].upcase
        end

        # Diagnostic-Code: SMTP; ... or empty value
        classorder.each do |e|
          # Check the value of Diagnostic-Code: and the value of Status:, it is a
          # deliverystats, with true() method in each Sisimai::Reason::* class.
          p = 'Sisimai::Reason::' + e
          r = nil
          begin
            require p.downcase.gsub('::', '/')
            r = Module.const_get(p)
          rescue
            warn ' ***warning: Failed to load ' + p
            next
          end

          next unless r.match(argv1)
          reasontext = r.text
          break
        end

        if reasontext.empty?
          # Check the value of $typestring
          if typestring == 'X-UNIX'
            # X-Unix; ...
            reasontext = 'mailererror'
          else
            # Detect the bounce reason from "Status:" code
            reasontext = Sisimai::SMTP::Status.name(statuscode) || 'undefined'
          end
        end
        return reasontext
      end

    end
  end
end

