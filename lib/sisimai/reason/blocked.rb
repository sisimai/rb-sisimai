module Sisimai
  module Reason
    # Sisimai::Reason::Blocked checks the bounce reason is "blocked" or not. This class is called
    # only Sisimai::Reason class.
    #
    # This is the error that SMTP connection was rejected due to a client IP address or a hostname,
    # or the parameter of "HELO/EHLO" command. This reason has added in Sisimai 4.0.0.
    module Blocked
      class << self
        require 'sisimai/string'

        Index = [
          ' said: 550 blocked',
          '//www.spamcop.net/bl.',
          'bad sender ip address',
          'banned sending ip',    # Office365
          'blacklisted by',
          'blocked using ',
          'blocked - see http',
          'dnsbl:attrbl',
          'client host rejected: abus detecte gu_eib_02',     # SFR
          'client host rejected: abus detecte gu_eib_04',     # SFR
          'client host rejected: may not be mail exchanger',
          'client host rejected: was not authenticated',      # Microsoft
          'confirm this mail server',
          'connection dropped',
          'connection refused by',
          'connection reset by peer',
          'connection was dropped by remote host',
          'connections not accepted from ip addresses on spamhaus xbl',
          'currently sending spam see: ',
          'domain does not exist:',
          'dynamic/zombied/spam ips blocked',
          'error: no valid recipients from ',
          'esmtp not accepting connections',  # icloud.com
          'extreme bad ip profile',
          'go away',
          'helo command rejected:',
          'host network not allowed',
          'hosts with dynamic ip',
          'invalid ip for sending mail of domain',
          'is not allowed to send mail from',
          'no access from mail server',
          'no matches to nameserver query',
          'not currently accepting mail from your ip',    # Microsoft
          'part of their network is on our block list',
          'please use the smtp server of your isp',
          'refused - see http',
          'rejected - multi-blacklist', # junkemailfilter.com
          'rejected because the sending mta or the sender has not passed validation',
          'rejecting open proxy', # Sendmail(srvrsmtp.c)
          'sender ip address rejected',
          'server access forbidden by your ip ',
          'service not available, closing transmission channel',
          'smtp error from remote mail server after initial connection:', # Exim
          "sorry, that domain isn't in my list of allowed rcpthosts",
          'sorry, your remotehost looks suspiciously like spammer',
          'temporarily deferred due to unexpected volume or user complaints',
          'to submit messages to this e-mail system has been rejected',
          'too many spams from your ip',  # free.fr
          'too many unwanted messages have been sent from the following ip address above',
          'we do not accept mail from dynamic ips',   # @mail.ru
          'you are not allowed to connect',
          'you are sending spam',
          'your ip address is listed in the rbl',
          'your network is temporary blacklisted',
          'your server requires confirmation',
        ].freeze
        Pairs = [
          ['access from ip address ', ' blocked'],
          ['client host ', ' blocked using'],
          ['connections will not be accepted from ', " because the ip is in spamhaus's list"],
          ['dnsbl:rbl ', '>_is_blocked'],
          ['email blocked by ', '.barracudacentral.org'],
          ['email blocked by ', 'spamhaus'],
          ['ip ', ' is blocked by earthlink'],    # Earthlink
          ['is in an ', 'rbl on '],
          ['mail server at ', ' is blocked'],
          ['mail from ',' refused:'],
          ['message from ', ' rejected based on blacklist'],
          ['messages from ', ' temporarily deferred due to user complaints'], # Yahoo!
          ['server ip ', ' listed as abusive'],
          ['sorry! your ip address', ' is blocked by rbl'], # junkemailfilter.com
          ['the domain ', ' is blacklisted'],
          ['the email ', ' is blacklisted'],
          ['the ip', ' is blacklisted'],
          ['veuillez essayer plus tard. service refused, please try later. ', '103'],
          ['veuillez essayer plus tard. service refused, please try later. ', '510'],
          ["your sender's ip address is listed at ", '.abuseat.org'],
        ].freeze
        Regex = %r{(?>
           [(][^ ]+[@][^ ]+:blocked[)]
          |host[ ][^ ]+[ ]refused[ ]to[ ]talk[ ]to[ ]me:[ ]\d+[ ]blocked
          |is[ ]in[ ]a[ ]black[ ]list(?:[ ]at[ ][^ ]+[.])?
          |was[ ]blocked[ ]by[ ][^ ]+
          )
        }x.freeze

        def text; return 'blocked'; end
        def description; return 'Email rejected due to client IP address or a hostname'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          return true if Index.any? { |a| argv1.include?(a) }
          return true if Pairs.any? { |a| Sisimai::String.aligned(argv1, a) }
          return true if argv1 =~ Regex
          return false
        end

        # Blocked due to client IP address or hostname
        # @param    [Hash] argvs  Hash to be detected the value of reason
        # @return   [true,false]  true: is blocked
        #                         false: is not blocked by the client
        # @see      http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return true if argvs['reason'] == 'blocked'
          return true if Sisimai::SMTP::Status.name(argvs['deliverystatus']).to_s == 'blocked'
          return true if match(argvs['diagnosticcode'].downcase)
          return false
        end

      end
    end
  end
end
