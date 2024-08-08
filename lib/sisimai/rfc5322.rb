module Sisimai
  # Sisimai::RFC5322 provide methods for checking email address.
  module RFC5322
    class << self
      require 'sisimai/string'
      require 'sisimai/address'
      HeaderTable = {
        :messageid => %w[message-id],
        :subject   => %w[subject],
        :listid    => %w[list-id],
        :date      => %w[date posted-date posted resent-date],
        :addresser => %w[from return-path reply-to errors-to reverse-path x-postfix-sender envelope-from x-envelope-from],
        :recipient => %w[to delivered-to forward-path envelope-to x-envelope-to resent-to apparently-to],
      }.freeze
      def HEADERTABLE; return HeaderTable; end

      def FIELDINDEX
        return %w[
          Resent-Date From Sender Reply-To To Message-ID Subject Return-Path Received Date X-Mailer
          Content-Type Content-Transfer-Encoding Content-Description Content-Disposition
        ]
        # The following fields are not referred in Sisimai
        #   Resent-From Resent-Sender Resent-Cc Cc Bcc Resent-Bcc In-Reply-To References
        #   Comments Keywords
      end

      # Grouped RFC822 headers
      # @param    [Symbol] group  RFC822 Header group name
      # @return   [Array]         RFC822 Header list
      def HEADERFIELDS(group = '')
        return HeaderTable[group] if HeaderTable[group]
        return []
      end

      # Fields that might be long
      # @return   [Hash] Long filed(email header) list
      def LONGFIELDS
        return { 'to' => true, 'from' => true, 'subject' => true, 'message-id' => true }
      end

      # Convert Received headers to a structured data
      # @param    [String] argv1  Received header
      # @return   [Array]         Received header as a structured data
      def received(argv1)
        return [] unless argv1.is_a?(::String)
        return [] if argv1.include?(' invoked by uid')
        return [] if argv1.include?(' invoked from network')

        # - https://datatracker.ietf.org/doc/html/rfc5322
        #   received        =   "Received:" *received-token ";" date-time CRLF
        #   received-token  =   word / angle-addr / addr-spec / domain
        #
        # - Appendix A.4. Message with Trace Fields
        #   Received:
        #       from x.y.test
        #       by example.net
        #       via TCP
        #       with ESMTP
        #       id ABC12345
        #       for <mary@example.net>;  21 Nov 1997 10:05:43 -0600
        recvd = argv1.split(' ')
        label = %w[from by via with id for]
        token = {}
        other = []
        alter = []
        right = false
        range = recvd.size
        index = -1

        recvd.each do |e|
          # Look up each label defined in "label" from Received header
          index += 1
          break unless index < range; f = e.downcase
          next  unless label.any? { |a| f == a }
          token[f] = recvd[index + 1] || next
          token[f] = token[f].downcase.delete('();')

          next  unless f == 'from'
          break unless index + 2 < range
          next  unless recvd[index + 2].start_with?('(')

          # Get and keep a hostname in the comment as follows:
          # from mx1.example.com (c213502.kyoto.example.ne.jp [192.0.2.135]) by mx.example.jp (V8/cf)
          # [
          #   "from",                         # index + 0
          #   "mx1.example.com",              # index + 1
          #   "(c213502.kyoto.example.ne.jp", # index + 2
          #   "[192.0.2.135])",               # index + 3
          #   "by",
          #   "mx.example.jp",
          #   "(V8/cf)",
          #   ...
          # ]
          # The 2nd element after the current element is NOT a continuation of the current element
          # such as "(c213502.kyoto.example.ne.jp)"
          other << recvd[index + 2].delete('();')

          # The 2nd element after the current element is a continuation of the current element.
          # such as "(c213502.kyoto.example.ne.jp", "[192.0.2.135])"
          break unless index + 3 < range
          other << recvd[index + 3].delete('();')
        end

        other.each do |e|
          # Check alternatives in "other", and then delete uninformative values.
          next if e.nil?
          next if e.size < 4
          next if e == 'unknown'
          next if e == 'localhost'
          next if e == '[127.0.0.1]'
          next if e == '[IPv6:::1]'
          next unless e.include?('.')
          next if e.include?('=')
          alter << e
        end

        %w[from by].each do |e|
          # Remove square brackets from the IP address such as "[192.0.2.25]"
          next if token[e].nil?
          next if token[e].empty?
          next unless token[e].start_with?('[')
          token[e] = Sisimai::String.ipv4(token[e]).shift || ''
        end
        token['from'] ||= ''

        while true do
          # Prefer hostnames over IP addresses, except for localhost.localdomain and similar.
          break if token['from'] == 'localhost'
          break if token['from'] == 'localhost.localdomain'
          break unless token['from'].include?('.')  # A hostname without a domain name
          break unless Sisimai::String.ipv4(token['from']).empty?

          # No need to rewrite token['from']
          right = true
          break
        end

        while true do
          # Try to rewrite uninformative hostnames and IP addresses in token['from']
          break if right        # There is no need to rewrite
          break if alter.empty? # There is no alternative to rewriting
          break if alter[0].include?(token['from'])

          if token['from'].start_with?('localhost')
            # localhost or localhost.localdomain
            token['from'] = alter[0]
          elsif token['from'].index('.')
            # A hostname without a domain name such as "mail", "mx", or "mbox"
            token['from'] = alter[0] if alter[0].include?('.')
          else
            # An IPv4 address
            token['from'] = alter[0]
          end
          break
        end
        token.delete('from') if token['from'].nil?
        token.delete('by')   if token['by'].nil?
        token['for'] = Sisimai::Address.s3s4(token['for']) if token.has_key?('for')

        token.keys.each do |e|
          # Delete an invalid value
          token[e] = '' if token[e].include?(' ')
          token[e].delete!('[]')  # Remove "[]" from the IP address
        end

        return [
          token['from'] || '',
          token['by']   || '',
          token['via']  || '',
          token['with'] || '',
          token['id']   || '',
          token['for']  || '',
        ]
      end

      # Split given entire message body into error message lines and the original message part only
      # include email headers
      # @param    [String] email  Entire message body
      # @param    [Array]  cutby  List of strings which is a boundary of the original message part
      # @param    [Bool]   keeps  Flag for keeping strings after "\n\n"
      # @return   [Array]         [Error message lines, The original message]
      # @since    v5.0.0
      def part(email = '', cutby = [], keeps = false)
        return nil if email.empty?
        return nil if cutby.empty?

        boundaryor = ''   # A boundary string divides the error message part and the original message part
        positionor = nil  # A Position of the boundary string
        formerpart = ''   # The error message part
        latterpart = ''   # The original message part

        cutby.each do |e|
          # Find a boundary string(2nd argument) from the 1st argument
          positionor = email.index(e); next unless positionor
          boundaryor = e
          break
        end

        if positionor
          # There is the boundary string in the message body
          formerpart = email[0, positionor]
          latterpart = email[positionor + boundaryor.size + 1, email.size - positionor]
        else
          # Substitute the entire message to the former part when the boundary string is not included
          # the "email"
          formerpart = email
          latterpart = ''
        end

        if latterpart.size > 0
          # Remove blank lines, the message body of the original message, and append "\n" at the end
          # of the original message headers
          # 1. Remove leading blank lines
          # 2. Remove text after the first blank line: \n\n
          # 3. Append "\n" at the end of test block when the last character is not "\n"
          latterpart.sub!(/\A[\r\n\s]+/, '')
          if keeps == false
            #  Remove text after the first blank line: \n\n when "keeps" is false
            latterpart = latterpart[0, latterpart.index("\n\n")] if latterpart.include?("\n\n")
          end
          latterpart << "\n" unless latterpart.end_with?("\n")
        end

        return [formerpart, latterpart]
      end

    end
  end
end

