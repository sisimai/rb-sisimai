module Sisimai
  # Sisimai::RFC1123 is a class related to the Internet host
  module RFC1123
    class << self
      require 'sisimai/string'
      require 'sisimai/rfc791'
      Sandwiched = [
          # (Postfix) postfix/src/smtp/smtp_proto.c: "host %s said: %s (in reply to %s)",
          # - <kijitora@example.com>: host re2.example.com[198.51.100.2] said: 550 ...
          # - <kijitora@example.org>: host r2.example.org[198.51.100.18] refused to talk to me:
          ["host ", " said: "],
          ["host ", " talk to me: "],
          ["while talking to ", ":"], # (Sendmail) ... while talking to mx.bouncehammer.jp.:
          ["host ", " ["],            # (Exim) host mx.example.jp [192.0.2.20]: 550 5.7.0 
          [" by ", ". ["],            # (Gmail) ...for the recipient domain example.jp by mx.example.jp. [192.0.2.1].

          # (MailFoundry)
          # - Delivery failed for the following reason: Server mx22.example.org[192.0.2.222] failed with: 550...
          # - Delivery failed for the following reason: mail.example.org[192.0.2.222] responded with failure: 552..
          ["delivery failed for the following reason: ", " with"],
          ["remote system: ", "("],   # (MessagingServer) Remote system: dns;mx.example.net (mx. -- 
          ["smtp server <", ">"],     # (X6) SMTP Server <smtpd.libsisimai.org> rejected recipient ...
          ["-mta: ", ">"],            # (MailMarshal) Reporting-MTA:      <rr1.example.com>
          [" : ", "["],               # (SendGrid) cat:000000:<cat@example.jp> : 192.0.2.1 : mx.example.jp:[192.0.2.2]...
      ].freeze
      StartAfter = [
          "generating server: ",      # (Exchange2007) en-US/Generating server: mta4.example.org
          "serveur de g",             # (Exchange2007) fr-FR/Serveur de g辿?辿?ation
          "server di generazione",    # (Exchange2007) it-CH
          "genererande server",       # (Exchange2007) sv-SE
      ].freeze
      ExistUntil = [
          " did not like our ",       # (Dragonfly) mail-inbound.libsisimai.net [192.0.2.25] did not like our DATA: ...
      ].freeze

      # Returns "true" when the given string is a valid internet host
      # @param    [String] argv0 Hostname
      # @return   [Boolean]      false: is not a valid internet host, true: is a valid interneet host
      # @since v5.2.0
      def is_internethost(argv0 = '')
        return false if argv0.nil? || argv0.size < 4 || argv0.size > 255
        return true  if argv0 == 'localhost' || argv0 == 'localhost6'
        return false if argv0.include?(".") == false
        return false if argv0.include?("..") || argv0.include?("--")
        return false if argv0.start_with?(".", "-") || argv0.end_with?("-")

        characters = argv0.upcase.split("")
        characters.each do |e|
          # Check each characater is a number or an alphabet
          f = e.ord
          return false if f <  45             # 45 = '-'
          return false if f == 47             # 47 = '/'
          return false if f >  57 && f <  65  # 57 = '9', 65 = 'A'
          return false if f >  90             # 90 = 'Z'
        end

        p1 = argv0.rindex(".")
        cv = argv0[p1 + 1, argv0.size - p1]; return false if cv.size > 63
        cv.split("").each do |e|
          # The top level domain should not include a number
          f = e.ord; return false if f > 47 && f < 58
        end
        return true
      end

      # returns true if the domain part is [IPv4:...] or [IPv6:...].
      # @param    [String] email  Email address.
      # @return   [Boolean]       false: the domain part is not a domain literal.
      #                           true:  the domain part is a domain literal.
      def is_domainliteral(email)
        return false if email.is_a?(::String) == false

        email = email.delete_prefix('<').delete_suffix('>')
        return false if email.size < 16 # e@[IPv4:0.0.0.0] is 16 characters
        return false if email[-1, 1] != ']'

        lastb = email.rindex('@[IPv'); return false if lastb == false
        dpart = email.split('@')[-1]

        if email.include?('@[IPv4:')
          # neko@[IPv4:192.0.2.25]
          ipv4a = email[lastb + 7, 16].delete_suffix(']')
          return Sisimai::RFC791.is_ipv4address(ipv4a)

        elsif email.include?('@[IPv6:')
          # neko@[IPv6:2001:0DB8:0000:0000:0000:0000:0000:0001]
          # neko@[IPv6:2001:0DB8:0000:0000:0000:0000:0000:0001]
          # IPv6-address-literal  = "IPv6:" IPv6-addr
          #    IPv6-addr      = IPv6-full / IPv6-comp / IPv6v4-full / IPv6v4-comp
          #    IPv6-hex       = 1*4HEXDIG
          #    IPv6-full      = IPv6-hex 7(":" IPv6-hex)
          #    IPv6-comp      = [IPv6-hex *5(":" IPv6-hex)] "::"
          #                     [IPv6-hex *5(":" IPv6-hex)]
          #                     ; The "::" represents at least 2 16-bit groups of
          #                     ; zeros.  No more than 6 groups in addition to the
          #                     ; "::" may be present.
          #    IPv6v4-full    = IPv6-hex 5(":" IPv6-hex) ":" IPv4-address-literal
          #    IPv6v4-comp    = [IPv6-hex *3(":" IPv6-hex)] "::"
          #                     [IPv6-hex *3(":" IPv6-hex) ":"]
          #                     IPv4-address-literal
          #                     ; The "::" represents at least 2 16-bit groups of
          #                     ; zeros.  No more than 4 groups in addition to the
          #                     ; "::" and IPv4-address-literal may be present.
          return true if dpart.size > 2 && dpart.rindex(':') > 7
        end
        return false
      end

      # find() returns a valid internet hostname found from the argument
      # @param    string argv1  String including hostnames
      # @return   string        A valid internet hostname found in the argument
      # @since v5.2.0
      def find(argv1 = "")
        return "" if argv1.nil? || argv1.size < 5

        sourcetext = argv1.downcase
        sourcelist = []
        foundtoken = []
        thelongest = 0
        hostnameis = ""

        # Replace some string for splitting by " "
        # - mx.example.net[192.0.2.1] => mx.example.net [192.0.2.1]
        # - mx.example.jp:[192.0.2.1] => mx.example.jp :[192.0.2.1]
        sourcetext = sourcetext.gsub("[", " [").gsub("(", " (").gsub("<", " <") # Prefix a space character before each bracket
        sourcetext = sourcetext.gsub("]", "] ").gsub(")", ") ").gsub(">", "> ") # Suffix a space character behind each bracket
        sourcetext = sourcetext.gsub(":", ": ").gsub(";", "; ")                 # Suffix a space character behind : and ;
        sourcetext = Sisimai::String.sweep(sourcetext)

        catch :MAKELIST do
          Sandwiched.each do |e|
            # Check a hostname exists between the $e->[0] and $e->[1] at array "Sandwiched"
            # Each array in Sandwiched have 2 elements
            next if Sisimai::String.aligned(sourcetext, e) == false

            p1 = sourcetext.index(e[0])
            p2 = sourcetext.index(e[1])
            cw = e[0].size
            next if p1 + cw >= p2

            sourcelist = sourcetext[p1 + cw, p2 - cw - p1].split(" ")
            throw :MAKELIST
          end

          # Check other patterns which are not sandwiched
          StartAfter.each do |e|
            # StartAfter have some strings, not an array
            p1 = sourcetext.index(e); next if p1.nil?
            cw = e.size
            sourcelist = sourcetext[p1 + cw, sourcetext.size].split(" ")
            throw :MAKELIST
          end
          ExistUntil.each do |e|
            # ExistUntil have some strings, not an array
            p1 = sourcetext.index(e); next if p1.nil?
            sourcelist = sourcetext[0, p1].split(" ")
            throw :MAKELIST
          end

          sourcelist = sourcetext.split(" ") if sourcelist.size == 0
          throw :MAKELIST
        end

        sourcelist.each do |e|
          # Pick some strings which is 4 or more length, is including "." character
          e.chop! if e[-1, 1] == "." # Remove "." at the end of the string
          e.delete!('[]()<>:;')

          next if e.size < 4
          next if e.include?(".") == false
          next if Sisimai::RFC1123.is_internethost(e) == false
          foundtoken << e
        end
        return ""            if foundtoken.size == 0
        return foundtoken[0] if foundtoken.size == 1

        foundtoken.each do |e|
          # Returns the longest hostname
          cw = e.size; next if thelongest >= cw
          hostnameis = e
          thelongest = cw
        end
        return hostnameis
      end
    end
  end
end

