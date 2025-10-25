module Sisimai
  # Sisimai::Reason detects the bounce reason from the Hash table which is to be constructed to 
  # Sisimai::Fact object as an argument of find() method. This class is called only Sisimai::Fact.
  module Reason
    class << self
      # All the error reason list Sisimai support
      # @return   [Array] Reason list
      def index
        return %w[
          AuthFailure BadReputation Blocked ContentError ExceedLimit Expired FailedSTARTTLS Filtered
          HasMoved HostUnknown MailboxFull MailerError MesgTooBig NetworkError NotAccept NotCompliantRFC
          OnHold Rejected NoRelaying Speeding SpamDetected VirusDetected PolicyViolation SecurityError
          Suspend RequirePTR SystemError SystemFull TooManyConn Suppressed UserUnknown SyntaxError
        ]
      end

      # @abstract is_explicit() returns 0 when the argument is empty or is "undefined" or is "onhold"
      # @param    string argv1  Reason name
      # @return   bool          false: The reaosn is not explicit
      def is_explicit(argv1 = '')
        return false if argv1.nil?
        return false if argv1.empty?
        return false if argv1 == "undefined" || argv1 == "onhold" || argv1.empty?
        return true
      end

      # @abstract Returns Sisimai::Reason::* module path table
      # @return   [Hash] Module path table
      # @since    v4.25.6
      def path
        index = Sisimai::Reason.index
        table = {}
        index.each { |e| table["Sisimai::Reason::#{e}"] = "sisimai/reason/#{e.downcase}" }
        return table
      end

      # Reason list better to retry detecting an error reason
      # @return   [Hash] Reason list
      def retry
        return {
          'undefined' => true, 'onhold' => true, 'systemerror' => true, 'securityerror' => true,
          'expired' => true, 'networkerror' => true, 'hostunknown' => true, 'userunknown' => true
        }.freeze
      end
      ModulePath = Sisimai::Reason.path
      GetRetried = Sisimai::Reason.retry
      ClassOrder = [
        %w[
          MailboxFull MesgTooBig ExceedLimit Suspend HasMoved NoRelaying AuthFailure UserUnknown
          Filtered RequirePTR NotCompliantRFC BadReputation ContentError Rejected HostUnknown
          SpamDetected Speeding TooManyConn Blocked
        ],
        %w[
          MailboxFull AuthFailure BadReputation Speeding SpamDetected VirusDetected PolicyViolation 
          NoRelaying SystemError NetworkError Suspend ContentError SystemFull NotAccept Expired
          FailedSTARTTLS SecurityError Suppressed MailerError
        ],
        %w[
          MailboxFull MesgTooBig ExceedLimit Suspend UserUnknown Filtered Rejected HostUnknown
          SpamDetected Speeding TooManyConn Blocked SpamDetected AuthFailure FailedSTARTTLS
          SecurityError SystemError NetworkError Suspend Expired ContentError HasMoved SystemFull
          NotAccept MailerError NoRelaying Suppressed SyntaxError OnHold
        ]
      ]

      # Detect the bounce reason
      # @param    [Hash] argvs  Decoded email object
      # @return   [String] Bounce reason or an empty string if the argument is missing or not Hash
      # @see anotherone
      def find(argvs)
        return "" if argvs.nil?
        if GetRetried[argvs['reason']].nil?
          # Return reason text already decided except reason match with the regular expression of
          # retry() method.
          return argvs['reason'] if argvs['reason'].empty? == false
        end
        return 'delivered' if argvs['deliverystatus'].start_with?('2.')

        reasontext = ''
        issuedcode = argvs['diagnosticcode'] || ''
        codeformat = argvs['diagnostictype'] || ''

        if codeformat == 'SMTP' || codeformat == ''
          # Diagnostic-Code: SMTP; ... or empty value
          ClassOrder[0].each do |e|
            # Check the value of Diagnostic-Code: and the value of Status:, it is a deliverystats,
            # with true() method in each Sisimai::Reason::* class.
            p = "Sisimai::Reason::#{e}"
            r = nil
            begin
              require ModulePath[p]
              r = Module.const_get(p)
            rescue
              warn " ***warning: Failed to load #{p}"
              next
            end
            next if r.true(argvs) == false
            reasontext = r.text
            break
          end
        end

        if reasontext.empty? || reasontext == 'undefined'
          # Bounce reason is not detected yet.
          reasontext = self.anotherone(argvs)

          if reasontext == 'undefined' || reasontext.empty?
            # Action: delayed => "expired"
            reasontext   = nil
            reasontext ||= 'expired' if argvs['action'] == 'delayed'
            return reasontext if reasontext

            # Try to match with message patterns in Sisimai::Reason::Vacation
            require 'sisimai/reason/vacation'
            reasontext   = 'vacation' if Sisimai::Reason::Vacation.match(issuedcode.downcase)
            reasontext ||= 'onhold'   if issuedcode.empty? == false
            reasontext ||= 'undefined'
          end
        end
        return reasontext
      end

      # Detect the other bounce reason, fall back method for find()
      # @param    [Hash] argvs  Decoded email object
      # @return   [String, Nil] Bounce reason or nli if the argument is missing or not Hash
      # @see      find()
      def anotherone(argvs)
        return argvs['reason'] if argvs['reason'].empty? == false

        require 'sisimai/smtp/status'
        issuedcode = argvs['diagnosticcode'].downcase || ''
        codeformat = argvs['diagnostictype']          || ''
        actiontext = argvs['action']                  || ''
        statuscode = argvs['deliverystatus']          || ''
        reasontext = Sisimai::SMTP::Status.name(statuscode)
        trytomatch = reasontext.empty? ? true : false
        trytomatch ||= true if GetRetried[reasontext] || codeformat != 'SMTP'

        while trytomatch
          # Could not decide the reason by the value of Status:
          ClassOrder[1].each do |e|
            # Trying to match with other patterns in Sisimai::Reason::* classes
            p = "Sisimai::Reason::#{e}"
            r = nil
            begin
              require ModulePath[p]
              r = Module.const_get(p)
            rescue
              warn " ***warning: Failed to load #{p}"
              next
            end

            next if r.match(issuedcode) == false
            reasontext = e.downcase
            break
          end
          break if reasontext.empty? == false

          # Check the value of Status:
          code2digit = statuscode[0, 3] || ''
          if code2digit == '5.6' || code2digit == '4.6'
            #  X.6.0   Other or undefined media error
            reasontext = 'contenterror'

          elsif code2digit == '5.7' || code2digit == '4.7'
            #  X.7.0   Other or undefined security status
            reasontext = 'securityerror'

          elsif codeformat.start_with?('X-UNIX')
            # Diagnostic-Code: X-UNIX; ...
            reasontext = 'mailererror'

          else
            # 50X Syntax Error?
            require 'sisimai/reason/syntaxerror'
            reasontext = 'syntaxerror' if Sisimai::Reason::SyntaxError.true(argvs)
          end
          break if reasontext.empty? == false

          # Check the value of Action: field, first
          if actiontext.start_with?('delayed', 'expired')
            # Action: delayed, expired
            reasontext = 'expired'
          else
            # Rejected at connection or after EHLO|HELO
            thecommand = argvs['command'] || ''
            reasontext = 'blocked' if %w[HELO EHLO].index(thecommand)
          end
          break
        end
        return reasontext
      end

      # Detect the bounce reason from given text
      # @param    [String] argv1  Error message
      # @return   [String]        Bounce reason
      def match(argv1)
        return "" if argv1.nil?

        reasontext = ''
        issuedcode = argv1.downcase

        # Diagnostic-Code: SMTP; ... or empty value
        ClassOrder[2].each do |e|
          # Check the value of Diagnostic-Code: and the value of Status:, it is a deliverystats, with
          # true() method in each Sisimai::Reason::* class.
          p = "Sisimai::Reason::#{e}"
          r = nil
          begin
            require ModulePath[p]
            r = Module.const_get(p)
          rescue
            warn " ***warning: Failed to load #{p}"
            next
          end

          next if r.match(issuedcode) == false
          reasontext = r.text
          break
        end
        return reasontext if reasontext.empty? == false

        if issuedcode.upcase.include?('X-UNIX; ')
          # X-Unix; ...
          reasontext = 'mailererror'
        else
          # Detect the bounce reason from "Status:" code
          require 'sisimai/smtp/status'
          reasontext = Sisimai::SMTP::Status.name(Sisimai::SMTP::Status.find(argv1))
          reasontext = "undefined" if reasontext.empty?
        end
        return reasontext
      end

    end
  end
end

