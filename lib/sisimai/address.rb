module Sisimai
  # Sisimai::Address provide methods for dealing email address.
  class Address
    # Imported from p5-Sisimail/lib/Sisimai/Address.pm
    require 'sisimai/rfc5322'

    # Return pseudo recipient or sender address
    # @param    [Symbol] argv1  Address type: :r or :s
    # @return   [String, Nil]   Pseudo recipient address or sender address or
    #                           Undef when the $argv1 is neither :r nor :s
    def self.undisclosed(argv1)
      return nil unless argv1
      return nil unless %w|r s|.index(argv1.to_s)

      local = argv1 == :r ? 'recipient' : 'sender'
      return sprintf('undisclosed-%s-in-headers@libsisimai.org.invalid', local)
    end

    def self.make(argvs)
    end

    def self.find(argv1 = nil, addrs = nil)
      # Email address parser with a name and a comment
      # @param    [String] argv1  String including email address
      # @param    [Boolean] addrs true:  Returns list including all the elements
      #                           false: Returns list including email addresses only
      # @return   [Array, Nil]    Email address list or Undef when there is no 
      #                           email address in the argument
      # @example  Parse email address
      #   input:  'Neko <neko(nyaan)@example.org>'
      #   output: [{
      #               'address' => 'neko@example.org',
      #               'name'    => 'Neko',
      #               'comment' => '(nyaan)'
      #           }]
      return nil unless argv1
      argv1 = argv1.gsub(/[\r\n]/, '')

      emailtable = { 'address' => '', 'name' => '', 'comment' => '' }
      addrtables = []
      readbuffer = []
      readcursor = 0
      delimiters = ['<', '>', '(', ')', '"', ',']
      validemail = %r{(?>
        (?:([^\s]+|["].+?["]))          # local part
        [@]
        (?:([^@\s]+|[0-9A-Za-z:\.]+))   # domain part
        )
      }x
      indicators = {
        :'email-address' => (1 << 0),    # <neko@example.org>
        :'quoted-string' => (1 << 1),    # "Neko, Nyaan"
        :'comment-block' => (1 << 2),    # (neko)
      }

      v = emailtable  # temporary buffer
      p = ''          # current position

      argv1.split('').each do |e|
        # Check each characters
        if delimiters.detect { |r| r == e }
          # The character is a delimiter character
          if e == ','
            # Separator of email addresses or not
            if v['address'] =~ /\A[<].+[@].+[>]\z/
              # An email address has already been picked

              if readcursor & indicators[:'comment-block'] > 0
                # The cursor is in the comment block (Neko, Nyaan)
                v['comment'] += e

              elsif readcursor & indicators[:'quoted-string'] > 0
                # "Neko, Nyaan"
                v['name'] += e

              else
                # The cursor is not in neither the quoted-string nor the comment block
                readcursor = 0  # reset cursor position
                readbuffer << v
                v = { 'address' => '', 'name' => '', 'comment' => '' }
                p = ''
              end
            else
              # "Neko, Nyaan" <neko@nyaan.example.org> OR <"neko,nyaan"@example.org>
              p.size > 0 ? (v[p] += e) : (v['name'] += e)
            end
            next
          end # End of if(',')

          if e == '<'
            # <: The beginning of an email address or not
            if v['address'].size > 0
              p.size > 0 ? (v[p] += e) : (v['name'] += e)

            else
              # <neko@nyaan.example.org>
              readcursor |= indicators[:'email-address']
              v['address'] += e
              p = 'address'
            end
            next
          end
          # End of if('<')

          if e == '>'
            # >: The end of an email address or not
            if readcursor & indicators[:'email-address'] > 0
              # <neko@example.org>
              readcursor &= ~indicators[:'email-address']
              v['address'] += e
              p = ''
            else
              # a comment block or a display name
              p.size > 0 ? (v['comment'] += e) : (v['name'] += e)
            end
            next
          end # End of if('>')

          if e == '('
            # The beginning of a comment block or not
            if readcursor & indicators[:'email-address'] > 0
              # <"neko(nyaan)"@example.org> or <neko(nyaan)@example.org>
              if v['address'] =~ /["]/
                # Quoted local part: <"neko(nyaan)"@example.org>
                v['address'] += e

              else
                # Comment: <neko(nyaan)@example.org>
                readcursor |= indicators[:'comment-block']
                v['comment'] += ' ' if v['comment'] =~ /[)]\z/
                v['comment'] += e
              end
            elsif readcursor & indicators[:'comment-block'] > 0
              # Comment at the outside of an email address (...(...)
              v['comment'] += ' ' if v['comment'] =~ /[)]\z/
              v['comment'] += e

            elsif readcursor & indicators[:'quoted-string'] > 0
              # "Neko, Nyaan(cat)", Deal as a display name
              v['name'] += e

            else
              # The beginning of a comment block
              readcursor |= indicators[:'comment-block']
              v['comment'] += ' ' if v['comment'] =~ /[)]\z/
              v['comment'] += e
              p = 'comment'
            end
            next
          end # End of if('(')

          if e == ')'
            # The end of a comment block or not
            if readcursor & indicators[:'email-address'] > 0
              # <"neko(nyaan)"@example.org> OR <neko(nyaan)@example.org>
              if v['address'] =~ /["]/
                # Quoted string in the local part: <"neko(nyaan)"@example.org>
                v['address'] += e

              else
                # Comment: <neko(nyaan)@example.org>
                readcursor &= ~indicators[:'comment-block']
                v['comment'] += e
                p = 'address'
              end
            elsif readcursor & indicators[:'comment-block'] > 0
              # Comment at the outside of an email address (...(...)
              readcursor &= ~indicators[:'comment-block']
              v['comment'] += e
              p = ''

            else
              # Deal as a display name
              readcursor &= ~indicators[:'comment-block']
              v['name'] = e
              p = ''
            end
            next
          end # End of if(')')

          if e == '"'
            # The beginning or the end of a quoted-string
            if p.size > 0
              # email-address or comment-block
              v[p] += e
            else
              # Display name
              v['name'] += e
              if readcursor & indicators[:'quoted-string'] > 0
                # "Neko, Nyaan"
                unless v['name'] =~ /\x5c["]\z/
                  # "Neko, Nyaan \"...
                  readcursor &= ~indicators[:'quoted-string']
                  p = ''
                end
              else
                if readcursor & indicators[:'email-address'] == 0 &&
                   readcursor & indicators[:'comment-block'] == 0
                  # Deal as the beginning of a display name
                  readcursor |= indicators[:'quoted-string']
                  p = 'name'
                end
              end
            end
            next
          end # End of if('"') 
        else
          # The character is not a delimiter
          p.size > 0 ? (v[p] += e) : (v['name'] += e)
          next
        end
      end

      if v['address'].size > 0
        # Push the latest values
        readbuffer << v
      else
        # No email address like <neko@example.org> in the argument
        if v['name'] =~ validemail
          # String like an email address will be set to the value of "address"
          v['address'] = sprintf("%s@%s", cv[1], cv[2])

        elsif Sisimai::RFC5322.is_mailerdaemon(v['name'])
          # Allow if the argument is MAILER-DAEMON
          v['address'] = v['name']
        end

        if v['address'].size > 0
          # Remove the comment from the address
          if cv = v['address'].match(/(.*)([(].+[)])(.*)/)
            # (nyaan)nekochan@example.org, nekochan(nyaan)cat@example.org or
            # nekochan(nyaan)@example.org
            v['address'] = cv[1] + cv[3]
            v['comment'] = cv[2]
          end
          readbuffer << v
        end
      end

      readbuffer.each do |e|
        # The element must not include any character except from 0x20 to 0x7e.
        next if e['address'] =~ /[^\x20-\x7e]/

        unless e['address'] =~ /\A.+[@].+\z/
          # Allow if the argument is MAILER-DAEMON
          next unless Sisimai::RFC5322.is_mailerdaemon(e['address'])
        end

        # Remove angle brackets, other brackets, and quotations: []<>{}'`
        # except a domain part is an IP address like neko@[192.0.2.222]
        e['address'] = e['address'].sub(/\A[\[<{('`]/, '')
        e['address'] = e['address'].sub(/['`>})]\z/, '')
        e['address'] = e['address'].sub(/\]\z/, '') unless e['address'] =~ /[@]\[[0-9A-Z:\.]+\]\z/i

        unless e['address'] =~ /\A["].+["][@]/
          # Remove double-quotations
          e['address'] = e['address'].sub(/\A["]/, '')
          e['address'] = e['address'].sub(/["]\z/, '')
        end

        if addrs
          # Almost compatible with parse() method, returns email address only
          e.delete('name')
          e.delete('comment')
        else
          # Remove double-quotations, trailing spaces.
          %w|name comment|.each do |f|
            e[f] = e[f].sub(/\A\s*/, '')
            e[f] = e[f].sub(/\s*\z/, '')
          end
          e['comment'] = '' unless e['comment'] =~ /\A[(].+[)]/
          e['name'] = e['name'].squeeze(' ')
          e['name'] = e['name'].sub(/\A["]/, '')
          e['name'] = e['name'].sub(/["]\z/, '')
        end
        addrtables << e
      end

      return nil if addrtables.empty?
      return addrtables
    end

    # Email address parser
    # @param    [Array] argvs   List of strings including email address
    # @return   [Array, Nil]    Email address list or Undef when there is no
    #                           email address in the argument
    # @example  Parse email address
    #   parse( [ 'Neko <neko@example.cat>' ] )  #=> [ 'neko@example.cat' ]
    def self.parse(argvs)
      addrs = []
      argvs.each do |e|
        # Parse each element in the array
        #   1. The element must include '@'.
        #   2. The element must not include character except from 0x20 to 0x7e.
        next unless e
        unless e =~ /[@]/
          # Allow if the argument is MAILER-DAEMON
          next unless Sisimai::RFC5322.is_mailerdaemon(e)
        end
        next if e =~ /[^\x20-\x7e]/

        v = Sisimai::Address.s3s4(e)
        if v.size > 0
          # The element includes a valid email address
          addrs << v
        end
      end

      return nil unless addrs.size > 0
      return addrs
    end

    # Runs like ruleset 3,4 of sendmail.cf
    # @param    [String] email  Text including an email address
    # @return   [String]        Email address without comment, brackets
    # @example  Parse email address
    #   s3s4( '<neko@example.cat>' ) #=> 'neko@example.cat'
    def self.s3s4(input)
      unless input =~ /[ ]/
        # no space character between " and < .
        # no space character between " and < .
        input = input.sub(/\A(.+)"<(.+)\z/, '\1" <\2')      # "=?ISO-2022-JP?B?....?="<user@example.org>,
        input = input.sub(/\A(.+)[?]=<(.+)\z/, '\1?= <\2')  # =?ISO-2022-JP?B?....?=<user@example.org>

        # comment-part<localpart@domainpart>
        input = input.sub(/[<]/, ' <') unless input =~ /\A[<]/
        input = input.sub(/[>]/, '> ') unless input =~ /[>]\z/
      end

      canon = ''
      addrs = []
      token = input.split(' ')

      token.map! do |e|
        # Convert character entity; "&lt;" -> ">", "&gt;" -> "<".
        e = e.gsub(/&lt;/, '<')
        e = e.gsub(/&gt;/, '>')
        e = e.gsub(/,\z/, '')
      end

      if token.size == 1
        addrs << token[0]

      else
        token.each do |e|
          e.chomp
          unless e =~ /\A[<]?.+[@][-.0-9A-Za-z]+[.]?[A-Za-z]{2,}[>]?\z/
            # Check whether the element is mailer-daemon or not
            next unless Sisimai::RFC5322.is_mailerdaemon(e)
          end
          addrs << e
        end
      end

      if addrs.size > 1
        # Get the first element which is <...> format string from @addrs array.
        canon = addrs.detect { |e| e =~ /\A[<].+[>]\z/ } || ''
        canon = addrs[0] if canon.size < 1

      else
        canon = addrs.shift
      end

      return '' if !canon || canon == ''
      canon = canon.delete('<>[]():;')  # Remove brackets, colons

      if canon =~ /\A["].+["][@].+\z/
        canon = canon.delete(%q|{}'`|)  # "localpart..."@example.org
      else
        canon = canon.delete(%q|{}'"`|) # Remove brackets, quotations
      end

      return canon
    end

    # Expand VERP: Get the original recipient address from VERP
    # @param    [String] email  VERP Address
    # @return   [String]        Email address
    # @example  Expand VERP address
    #   expand_verp('bounce+neko=example.org@example.org') #=> 'neko@example.org'
    def self.expand_verp(email)
      local = email.split('@', 2).first
      verp0 = ''

      if cv = local.match(/\A[-_\w]+?[+](\w[-._\w]+\w)[=](\w[-.\w]+\w)\z/)
        verp0 = cv[1] + '@' + cv[2]
        return verp0 if Sisimai::RFC5322.is_emailaddress(verp0)

      else
        return ''
      end
    end

    # Expand alias: remove from '+' to '@'
    # @param    [String] email  Email alias string
    # @return   [String]        Expanded email address
    # @example  Expand alias
    #   expand_alias('neko+straycat@example.org') #=> 'neko@example.org'
    def self.expand_alias(email)
      return '' unless Sisimai::RFC5322.is_emailaddress(email)

      local = email.split('@')
      value = ''
      if cv = local[0].match(/\A([-_\w]+?)[+].+\z/)
        value = sprintf('%s@%s', cv[1], local[1])
      end
      return value
    end

    @@roaccessors = [
      :address, # [String] Email address
      :user,    # [String] local part of the email address
      :host,    # [String] domain part of the email address
      :verp,    # [String] VERP
      :alias,   # [String] alias of the email address
    ]
    @@roaccessors.each { |e| attr_reader   e }

    # Constructor of Sisimai::Address
    # @param <str>  [String] email          Email address
    # @return       [Sisimai::Address, Nil] Object or Undef when the email
    #                                       address was not valid
    def initialize(email)
      return nil unless email

      if cv = email.match(/\A([^@]+)[@]([^@]+)\z/)
        # Get the local part and the domain part from the email address
        lpart = cv[1]
        dpart = cv[2]

        # Remove MIME-Encoded comment part
        lpart = lpart.sub(/\A=[?].+[?]b[?].+[?]=/, '')
        lpart = lpart.delete(%q|`'"<>|) unless lpart =~ /\A["].+["]\z/
        aflag = false
        addr0 = sprintf('%s@%s', lpart, dpart)
        addr1 = Sisimai::Address.expand_verp(addr0)

        if addr1.size < 1
          addr1 = Sisimai::Address.expand_alias(addr0)
          aflag = true if addr1.size > 0
        end

        if addr1.size > 0
          # The email address is VERP or alias
          addrs = addr1.split('@')
          if aflag
            # The email address is an alias
            @alias = addr0

          else
            # The email address is a VERP
            @verp = addr0
          end
          @user = addrs[0]
          @host = addrs[1]

        else
          # The email address is neither VERP nor alias.
          @user = lpart
          @host = dpart

        end
        @address = sprintf('%s@%s', @user, @host)
        @alias ||= ''
        @verp  ||= ''

      else
        # The argument does not include "@"
        return nil unless Sisimai::RFC5322.is_mailerdaemon(email)
        @alias ||= ''
        @verp  ||= ''
        @host  ||= ''

        if cv = email.match(/[<]([^ ]+)[>]/)
          # Mail Delivery Subsystem <MAILER-DAEMON>
          @user = cv[1]
          @address = cv[1]
        else
          return nil if email =~ /[ ]/
          # The argument does not include " "
          @user = email
          @address = email
        end
      end
    end

    # Check whether the object has valid content or not
    # @return        [True,False]   returns true if the object is void
    def void
      return true unless @address
      return false
    end

    # Returns the value of address as String
    # @return [String] Email address
    def to_json(*)
      return to_s
    end

    # Returns the value of address as String
    # @return [String] Email address
    def to_s
      return self.address.to_s
    end

  end
end
