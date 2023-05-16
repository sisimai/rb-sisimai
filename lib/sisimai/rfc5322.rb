module Sisimai
  # Sisimai::RFC5322 provide methods for checking email address.
  module RFC5322
    class << self
      require 'sisimai/string'
      HeaderTable = {
        :messageid => %w[message-id],
        :subject   => %w[subject],
        :listid    => %w[list-id],
        :date      => %w[date posted-date posted resent-date],
        :addresser => %w[from return-path reply-to errors-to reverse-path x-postfix-sender envelope-from x-envelope-from],
        :recipient => %w[to delivered-to forward-path envelope-to x-envelope-to resent-to apparently-to],
      }.freeze

      build_flatten_rfc822header_list = lambda do
        # Convert HEADER: structured hash table to flatten hash table for being called from Sisimai::Lhost::*
        fv = {}
        HeaderTable.each_value do |e|
          e.each { |ee| fv[ee] = true }
        end
        return fv
      end
      HeaderIndex = build_flatten_rfc822header_list.call

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
      # @return   [Array,Hash]    RFC822 Header list
      def HEADERFIELDS(group = '')
        return HeaderIndex if group.empty?
        return HeaderTable[group] if HeaderTable[group]
        return HeaderTable
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

        hosts = []
        value = { 'from' => '', 'by' => '' }

        # Received: (qmail 10000 invoked by uid 999); 24 Apr 2013 00:00:00 +0900
        return [] if argv1.include?('(qmail ') && argv1.include?(' invoked ')

        p1 = argv1.index('from ')     || -1
        p2 = argv1.index('by ')       || -1
        p3 = argv1.index(' ', p2 + 3) || -1

        if p1 == 0 && p2 > 1 && p2 < p3
          # Received: from localhost (localhost) by nijo.example.jp (V8/cf) id s1QB5ma0018057;
          #   Wed, 26 Feb 2014 06:05:48 -0500
          value['from'] = Sisimai::String.sweep(argv1[p1 + 5, p2 - p1 - 5])
          value['by']   = Sisimai::String.sweep(argv1[p2 + 3, p3 - p2 - 3])

        elsif p1 != 0 && p2 > -1
          # Received: by 10.70.22.98 with SMTP id c2mr1838265pdf.3; Fri, 18 Jul 2014 00:31:02 -0700 (PDT)
          value['from'] = Sisimai::String.sweep(argv1[p2 + 3, argv1.size])
          value['by']   = Sisimai::String.sweep(argv1[p2 + 3, p3 - p2 - 3])
        end

        if value['from'].include?(' ')
          # Received: from [10.22.22.222] (smtp.kyoto.ocn.ne.jp [192.0.2.222]) (authenticated bits=0)
          #   by nijo.example.jp (V8/cf) with ESMTP id s1QB5ka0018055; Wed, 26 Feb 2014 06:05:47 -0500
          received = value['from'].split(' ')
          namelist = []
          addrlist = []
          hostname = ''
          hostaddr = ''

          while e = received.shift do
            # Received: from [10.22.22.222] (smtp-gateway.kyoto.ocn.ne.jp [192.0.2.222])
            cv = Sisimai::String.ipv4(e) || []
            if cv.size > 0
              # [192.0.2.1] or (192.0.2.1)
              addrlist.append(*cv)
            else
              # hostname
              e = e.delete('()').strip
              namelist << e
            end
          end

          while e = namelist.shift do
            # 1. Hostname takes priority over all other IP addresses
            next unless e.include?('.')
            hostname = e
            break
          end

          if hostname.empty?
            # 2. Use IP address as a remote host name
            addrlist.each do |e|
              # Skip if the address is a private address
              next if e.start_with?('10.', '127.', '192.168.')
              next if e =~ /\A172[.](?:1[6-9]|2[0-9]|3[0-1])[.]/
              hostaddr = e
              break
            end
          end

          value['from'] = hostname || hostaddr || addrlist[-1]
        end

        %w[from by].each do |e|
          # Copy entries into hosts
          next if value[e].empty?
          value[e] = value[e].delete('[]();?')
          hosts << value[e]
        end
        return hosts
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

