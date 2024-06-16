module Sisimai::Lhost
  # Sisimai::Lhost::FML decodes a bounce email which created by fml mailing list server/manager
  # https://www.fml.org/. Methods in the module are called from only Sisimai::Message.
  module FML
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      Boundaries = ['Original mail as follows:'].freeze
      ErrorTitle = {
        'rejected' => [
          ' are not member',
          'NOT MEMBER article from ',
          'reject mail ',
          'Spam mail from a spammer is rejected',
        ],
        'systemerror' => [
          'fml system error message',
          'Loop Alert: ',
          'Loop Back Warning: ',
          'WARNING: UNIX FROM Loop',
        ],
        'securityerror' => ['Security Alert'],
      }.freeze
      ErrorTable = {
        'rejected' => [
          ' header may cause mail loop',
          'NOT MEMBER article from ',
          'reject mail from ',
          'reject spammers:',
          'You are not a member of this mailing list',
        ],
        'systemerror' => [
          ' has detected a loop condition so that',
          'Duplicated Message-ID',
          'Loop Back Warning:',
        ],
        'securityerror' => ['Security alert:'],
      }.freeze

      # @abstract Decodes the bounce message from fml mailling list server/manager
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to decode or the arguments are missing
      # @since v4.22.3
      def inquire(mhead, mbody)
        return nil unless mhead['x-mlserver']
        return nil unless mhead['from'].include?('-admin@')
        return nil unless mhead['message-id'].index('.FML') > 1

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailparts = Sisimai::RFC5322.part(mbody, Boundaries)
        bodyslices = emailparts[0].split("\n")
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        v = nil

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          next if e.empty?

          # Duplicated Message-ID in <2ndml@example.com>.
          # Original mail as follows:
          v = dscontents[-1]

          p1 = e.index('<')  || -1
          p2 = e.rindex('>') || -1
          if p1 > 0 && p2 > 0
            # You are not a member of this mailing list <neko-nyaan@example.org>.
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = e[p1 + 1, p2 - p1 - 1]
            v['diagnosis'] = e
            recipients += 1
          else
            # If you know the general guide of this list, please send mail with
            # the mail body
            v['diagnosis'] ||= ''
            v['diagnosis'] << e
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          ErrorTable.each_key do |f|
            # Try to match with error messages defined in ErrorTable
            next unless ErrorTable[f].any? { |a| e['diagnosis'].include?(a) }
            e['reason'] = f
            break
          end

          unless e['reason']
            # Error messages in the message body did not matched
            ErrorTitle.each_key do |f|
              # Try to match with the Subject string
              next unless mhead['subject'] =~ ErrorTitle[f]
              e['reason'] = f
              break
            end
          end
        end

        return { 'ds' => dscontents, 'rfc822' => emailparts[1] }
      end
      def description; return 'fml mailing list server/manager'; end
    end
  end
end

