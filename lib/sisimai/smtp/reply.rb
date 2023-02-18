# http://www.ietf.org/rfc/rfc5321.txt
#   4.2.1.  Reply Code Severities and Theory
#
#   There are four values for the first digit of the reply code:
#
#   2yz  Positive Completion reply
#       The requested action has been successfully completed.  A new request may be initiated.
#
#   3yz  Positive Intermediate reply
#       The command has been accepted, but the requested action is being held in abeyance, pending
#       receipt of further information. The SMTP client should send another command specifying this
#       information. This reply is used in command sequence groups (i.e., in DATA).
#
#   4yz  Transient Negative Completion reply
#       The command was not accepted, and the requested action did not occur.  However, the error
#       condition is temporary, and the action may be requested again.  The sender should return to
#       the beginning of the command sequence (if any).  It is difficult to assign a meaning to
#       "transient" when two different sites (receiver- and sender-SMTP agents) must agree on the
#       interpretation. Each reply in this category might have a different time value, but the SMTP
#       client SHOULD try again.  A rule of thumb to determine whether a reply fits into the 4yz or
#       the 5yz category (see below) is that replies are 4yz if they can be successful if repeated
#       without any change in command form or in properties of the sender or receiver (that is, the
#       command is repeated identically and the receiver does not put up a new implementation).
#
#   5yz  Permanent Negative Completion reply
#       The command was not accepted and the requested action did not occur. The SMTP client SHOULD
#       NOT repeat the exact request (in the same sequence). Even some "permanent" error conditions
#       can be corrected, so the human user may want to direct the SMTP client to reinitiate the
#       command sequence by direct action at some point in the future (e.g., after the spelling has
#       been changed, or the user has altered the account status).
#
#   The second digit encodes responses in specific categories:
#
#       x0z  Syntax: These replies refer to syntax errors, syntactically correct commands that do
#            not fit any functional category, and unimplemented or superfluous commands.
#       x1z  Information: These are replies to requests for information, such as status or help.
#       x2z  Connections: These are replies referring to the transmission channel.
#       x3z  Unspecified.
#       x4z  Unspecified.
#       x5z  Mail system: These replies indicate the status of the receiver mail system vis-a-vis
#            the requested transfer or other mail system action.

module Sisimai
  module SMTP
    # Sisimai::SMTP::Reply is utilities for getting SMTP Reply Code value from error message text.
    module Reply
      class << self
        ReplyCode2 = [
          # http://www.ietf.org/rfc/rfc5321.txt
          # 211   System status, or system help reply
          # 214   Help message (Information on how to use the receiver or the meaning of a particular
          #       non-standard command; this reply is useful only to the human user)
          # 220   <domain> Service ready
          # 221   <domain> Service closing transmission channel
          # 235   Authentication successful (See RFC2554)
          # 250   Requested mail action okay, completed
          # 251   User not local; will forward to <forward-path> (See Section 3.4)
          # 252   Cannot VRFY user, but will accept message and attempt delivery (See Section 3.5.3)
          # 253   OK, <n> pending messages for node <domain> started (See RFC1985)
          # 354   Start mail input; end with <CRLF>.<CRLF>
          '211', '214', '220', '221', '235', '250', '251', '252', '253', '354'
        ].freeze
        ReplyCode4 = [
          # 421   <domain> Service not available, closing transmission channel (This may be a reply
          #       to any command if the service knows it must shut down)
          # 422   (See RFC5248)
          # 430   (See RFC5248)
          # 432   A password transition is needed (See RFC4954)
          # 450   Requested mail action not taken: mailbox unavailable (e.g., mailbox busy or temporarily
          #       blocked for policy reasons)
          # 451   Requested action aborted: local error in processing
          # 452   Requested action not taken: insufficient system storage
          # 453   You have no mail (See RFC2645)
          # 454   Temporary authentication failure (See RFC4954)
          # 455   Server unable to accommodate parameters
          # 456   please retry immediately the message over IPv4 because it fails SPF and DKIM (See
          #       https://datatracker.ietf.org/doc/html/draft-martin-smtp-ipv6-to-ipv4-fallback-00
          # 458   Unable to queue messages for node <domain> (See RFC1985)
          # 459   Node <domain> not allowed: <reason> (See RFC51985)
          '421', '450', '451', '452', '422', '430', '432', '453', '454', '455', '456', '458', '459'
        ].freeze
        ReplyCode5 = [
          # 500   Syntax error, command unrecognized (This may include errors such as command line too long)
          # 501   Syntax error in parameters or arguments
          # 502   Command not implemented (see Section 4.2.4)
          # 503   Bad sequence of commands
          # 504   Command parameter not implemented
          # 520   Please use the correct QHLO ID (See https://datatracker.ietf.org/doc/id/draft-fanf-smtp-quickstart-01.txt)
          # 521   Host does not accept mail (See RFC7504)
          # 523   Encryption Needed (See RFC5248)
          # 524   (See RFC5248)
          # 525   User Account Disabled (See RFC5248)
          # 530   Authentication required (See RFC4954)
          # 533   (See RFC5248)
          # 534   Authentication mechanism is too weak (See RFC4954)
          # 535   Authentication credentials invalid (See RFC4954)
          # 538   Encryption required for requested authentication mechanism (See RFC4954)
          # 550   Requested action not taken: mailbox unavailable (e.g., mailbox not found, no access, or
          #       command rejected for policy reasons)
          # 551   User not local; please try <forward-path> (See Section 3.4)
          # 552   Requested mail action aborted: exceeded storage allocation
          # 553   Requested action not taken: mailbox name not allowed (e.g., mailbox syntax incorrect)
          # 554   Transaction failed (Or, in the case of a connection-opening response, "No SMTP service here")
          # 555   MAIL FROM/RCPT TO parameters not recognized or not implemented
          # 556   Domain does not accept mail (See RFC7504)
          '550', '552', '553', '551', '521', '525', '502', '520', '523', '524', '530', '533', '534',
          '535', '538', '551', '555', '556', '554', '500', '501', '502', '503', '504',
        ].freeze
        CodeOfSMTP = { '2' => ReplyCode2, '4' => ReplyCode4, '5' => ReplyCode5 }.freeze

        # Check whether a reply code is a valid code or not
        # @param    [String] argv1  Reply Code(DSN)
        # @return   [Boolean]       0 = Invalid reply code, 1 = Valid reply code
        # @see      code
        # @since v5.0.0
        def test(argv1 = '')
          return nil if argv1.empty?

          reply = argv1.to_i
          first = (reply / 100).to_i

          return false if reply < 200
          return false if reply > 599
          return false if reply % 100 > 59

          if first == 2
            # 2yz
            return false if reply < 211
            return false if reply > 252
            return false if reply > 221 && reply < 250
            return true
          end

          if first == 3
            # 3yz
            return false unless reply == 354
            return true
          end

          return true
        end

        # Get SMTP Reply Code from the given string
        # @param    [String] argv1  String including SMTP Reply Code like 550
        # @param    [String] argv2  Status code like 5.1.1 or 2 or 4 or 5
        # @return   [String]        SMTP Reply Code
        #           [Nil]           The first argument did not include SMTP Reply Code value
        def find(argv1 = '', argv2 = 'x')
          return nil if argv1.to_s.size < 4
          return nil if argv1.upcase.include?('X-UNIX')

          statuscode = argv2[0, 1]
          replycodes = if statuscode == '5' || statuscode == '4' || statuscode == '2'
                         CodeOfSMTP[statuscode]
                       else
                         [*CodeOfSMTP['5'], *CodeOfSMTP['4'], *CodeOfSMTP['2']]
                       end
          esmtperror = ' ' + argv1
          esmtpreply = '' # SMTP Reply Code
          replyindex =  0 # A position of SMTP reply code found by the index()
          formerchar =  0 # a character that is one character before the SMTP reply code
          latterchar =  0 # a character that is one character after  the SMTP reply code

          replycodes.each do |e|
            # Try to find an SMTP Reply Code from the given string
            replyindex = esmtperror.index(e); next unless replyindex
            formerchar = esmtperror[replyindex - 1, 1].ord || 0
            lattercahr = esmtperror[replyindex + 3, 1].ord || 0

            next if formerchar > 45 && formerchar < 58
            next if latterchar > 45 && latterchar < 58
            esmtpreply = e
            break
          end

          return esmtpreply
        end

      end
    end
  end
end

