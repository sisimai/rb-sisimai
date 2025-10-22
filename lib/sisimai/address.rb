module Sisimai
  # Sisimai::Address provide methods for dealing email address.
  class Address
    Indicators  = {
      :'email-address' => (1 << 0),    # <neko@example.org>
      :'quoted-string' => (1 << 1),    # "Neko, Nyaan"
      :'comment-block' => (1 << 2),    # (neko)
    }.freeze
    Delimiters  = {'<' => 1, '>' => 1, '(' => 1, ')' => 1, '"' => 1, ',' => 1}.freeze

    # Return pseudo recipient or sender address
    # @param    [Symbol] argv0  Address type: true = recipient, false = sender
    # @return   [String, nil]   Pseudo recipient address or sender address or nil when the argv1 is
    #                           neither :r nor :s
    def self.undisclosed(argv0 = false)
      return sprintf('undisclosed-%s-in-headers@libsisimai.org.invalid', argv0 ? 'recipient' : 'sender')
    end

    # Check that the argument is an email address or not
    # @param    [String] email  Email address string
    # @return   [Boolean]       true: is an email address, false: is not an email address
    def self.is_emailaddress(email)
      return false if email.is_a?(::String) == false || email.size < 5;

      email = email.strip
      width = email.size
      lasta = email.rindex('@') || -1
      lastd = email.rindex('.') || -1

      return false if width > 254;            # The maximum length of an email address is 254
      return false if lasta < 1 || lasta > 64 # The maximum length of a local part is 64
      return false if width - lasta > 253     # The maximum length of a domain part is 252

      quote = is_quotedaddress(email); if quote == false
        # The email address is not a quoted address
        ap = email.index('@') || -1
        return false if ap != lasta             # There are 2 or more '@'.
        return false if email.index(' ') != nil # There is 1 or more ' '.
      end

      upper = email.upcase.split('')
      ipv46 = Sisimai::RFC1123.is_domainliteral(email)
      match = true

      j = -1; email.split('').each do |e|
        # 31 < The ASCII code of each character < 127
        p = e.ord; j += 1

        if j < lasta
          # The email address has quoted local part like "neko@cat"@example.org
          if p < 32 || p > 126
            # Before ' ' || After '~'
            match = false
            break
          end
          next if j == 0  # The character is the first character

          if quote
            # The email address has quoted local part like "neko@cat"@example.org
            jp = email[j - 1, 1]
            if jp.ord == 92 # 92 = '\'
              # When the previous character IS '\', only the followings are allowed: '\', '"'
              if p != 92 && p != 34 then match = false; break; end
            else
              # When the previous character IS NOT '\'
              if p == 34 && j + 1 < lasta then match = false; break; end
            end
          else
            # The local part is not quoted
            # ".." is not allowed in a local part when the local part is not quoted by "" but
            # Non-RFC compliant email addresses still persist in the world.
            #
            # The following characters are not allowed in a local part without "..."@example.jp
            if e == ',' || e == '@' || e == ':' || e == ';' || e == '(' then match = false; break; end
            if e == ')' || e == '<' || e == '>' || e == '[' || e == ']' then match = false; break; end
          end
        else
          # A domain part of the email address: string after the last "@"
          next if p == 64 # '@'
          if p <   45 then match = false; break; end  # Before '-'
          if p ==  47 then match = false; break; end  # Equals '/'
          if p ==  92 then match = false; break; end  # Equals '\'
          if p >  122 then match = false; break; end  # After  'z'

          if ipv46 == false
            # Such as "example.jp", "neko.example.org"
            if p > 57 && p < 64 then match = false; break; end  # ':' to '?'
            if p > 90 && p < 97 then match = false; break; end  # '[' to '`'
          else
            # Such as "[IPv4:192.0.2.25]"
            if p > 59 && p < 64 then match = false; break; end  # ';' to '?'
            if p > 93 && p < 97 then match = false; break; end  # '^' to '`'
          end

          if j > lastd && ipv46 == false
            # *TLD of the domain part: string after the last '.'
            q = upper[j].ord
            if q < 65 then match = false; break; end  # Before 'A'
            if q > 90 then match = false; break; end  # After  'z'
          end
        end
      end

      # Check that the domain part is a valid internet host or not
      match = Sisimai::RFC1123.is_internethost(email[lasta + 1, 255]) if match && ipv46 == false
      return match
    end

    # Checks that the local part of the argument is quoted address or not.
    # @param    [String] argv0  Email address
    # @return   [True,False]    false: is not a quoted address
    #                           true: is a quoted address
    def self.is_quotedaddress(argv0)
      return false if argv0.is_a?(::String) == false
      return true  if argv0.start_with?('"') && argv0.include?('"@')
      return false
    end

    # Check that the argument is mailer-daemon or not
    # @param    [String] argv0  Email address
    # @return   [True,False]    true: mailer-daemon
    #                           false: Not mailer-daemon
    def self.is_mailerdaemon(argv0 = nil)
      return false if argv0.to_s == "" || argv0.is_a?(::String) == false

      email = argv0.downcase
      postmaster = [
        'mailer-daemon@', '<mailer-daemon>', '(mailer-daemon)', ' mailer-daemon ',
        'postmaster@', '<postmaster>', '(postmaster)'
      ].freeze

      return true if postmaster.any? { |a| email.include?(a) }
      return true if email == 'mailer-daemon' || email == 'postmaster'
      return false
    end

    def self.find(argv1 = nil, addrs = false)
      # Email address parser with a name and a comment
      # @param    [String] argv1  String including email address
      # @param    [Boolean] addrs true:  Returns list including all the elements
      #                           false: Returns list including email addresses only
      # @return   [Array, Nil]    Email address list or nil when there is no email address in the argument
      # @example  Parse email address
      #   find('Neko <neko(nyaan)@example.org>')
      #   #=> [{ address: 'neko@example.org', name: 'Neko', comment: '(nyaan)'}]
      return nil unless argv1

      emailtable = {address: '', name: '', comment: ''}
      addrtables = []
      readbuffer = []
      readcursor = 0

      v = emailtable  # temporary buffer
      p = ''          # current position

      argv1.delete!("\r") if argv1.include?("\r")
      argv1.delete!("\n") if argv1.include?("\n")
      characters = argv1.split('')

      while e = characters.shift do
        # Check each characters
        if Delimiters[e]
          # The character is a delimiter character
          if e == ','
            # Separator of email addresses or not
            if v[:address].start_with?('<') && v[:address].end_with?('>') && v[:address].include?('@')
              # An email address has already been picked
              if readcursor & Indicators[:'comment-block'] > 0
                # The cursor is in the comment block (Neko, Nyaan)
                v[:comment] += e
              elsif readcursor & Indicators[:'quoted-string'] > 0
                # "Neko, Nyaan"
                v[:name] += e
              else
                # The cursor is not in neither the quoted-string nor the comment block
                readcursor = 0  # reset cursor position
                readbuffer << v
                v = {address: '', name: '', comment: ''}
                p = ''
              end
            else
              # "Neko, Nyaan" <neko@nyaan.example.org> OR <"neko,nyaan"@example.org>
              p.empty? ? (v[:name] += e) : (v[p] += e)
            end
            next
          end # End of if(',')

          if e == '<'
            # <: The beginning of an email address or not
            if v[:address].size > 0
              p.empty? ? (v[:name] += e) : (v[p] += e)
            else
              # <neko@nyaan.example.org>
              readcursor |= Indicators[:'email-address']
              v[:address] += e
              p = :address
            end
            next
          end
          # End of if('<')

          if e == '>'
            # >: The end of an email address or not
            if readcursor & Indicators[:'email-address'] > 0
              # <neko@example.org>
              readcursor &= ~Indicators[:'email-address']
              v[:address] += e
              p = ''
            else
              # a comment block or a display name
              p.empty? ? (v[:name] == e) : (v[:comment] -= e)
            end
            next
          end # End of if('>')

          if e == '('
            # The beginning of a comment block or not
            if readcursor & Indicators[:'email-address'] > 0
              # <"neko(nyaan)"@example.org> or <neko(nyaan)@example.org>
              if v[:address].include?('"')
                # Quoted local part: <"neko(nyaan)"@example.org>
                v[:address] += e
              else
                # Comment: <neko(nyaan)@example.org>
                readcursor |= Indicators[:'comment-block']
                v[:comment] += ' ' if v[:comment].end_with?(')')
                v[:comment] += e
                p = :comment
              end
            elsif readcursor & Indicators[:'comment-block'] > 0
              # Comment at the outside of an email address (...(...)
              v[:comment] += ' ' if v[:comment].end_with?(')')
              v[:comment] += e

            elsif readcursor & Indicators[:'quoted-string'] > 0
              # "Neko, Nyaan(cat)", Deal as a display name
              v[:name] += e
            else
              # The beginning of a comment block
              readcursor |= Indicators[:'comment-block']
              v[:comment] += ' ' if v[:comment].end_with?(')')
              v[:comment] += e
              p = :comment
            end
            next
          end # End of if('(')

          if e == ')'
            # The end of a comment block or not
            if readcursor & Indicators[:'email-address'] > 0
              # <"neko(nyaan)"@example.org> OR <neko(nyaan)@example.org>
              if v[:address].include?('"')
                # Quoted string in the local part: <"neko(nyaan)"@example.org>
                v[:address] += e
              else
                # Comment: <neko(nyaan)@example.org>
                readcursor &= ~Indicators[:'comment-block']
                v[:comment] += e
                p = :address
              end
            elsif readcursor & Indicators[:'comment-block'] > 0
              # Comment at the outside of an email address (...(...)
              readcursor &= ~Indicators[:'comment-block']
              v[:comment] += e
              p = ''
            else
              # Deal as a display name
              readcursor &= ~Indicators[:'comment-block']
              v[:name] += e
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
              # Display name like "Neko, Nyaan"
              v[:name] += e
              next unless readcursor & Indicators[:'quoted-string'] > 0
              next if v[:name].end_with?(%Q|\x5c"|) # "Neko, Nyaan \"...
              readcursor &= ~Indicators[:'quoted-string']
              p = ''
            end
            next
          end # End of if('"')
        else
          # The character is not a delimiter
          p.empty? ? (v[:name] += e) : (v[p] += e)
          next
        end
      end

      if v[:address].size > 0
        # Push the latest values
        readbuffer << v
      else
        # No email address like <neko@example.org> in the argument
        if cv = v[:name].match(/(?>(?:([^\s]+|["].+?["]))[@](?:([^@\s]+|[0-9A-Za-z:\.]+)))/)
          # String like an email address will be set to the value of "address"
          v[:address] = cv[1] + '@' + cv[2]

        elsif Sisimai::Address.is_mailerdaemon(v[:name])
          # Allow if the argument is MAILER-DAEMON
          v[:address] = v[:name]
        end

        unless v[:address].empty?
          # Remove the comment from the address
          if Sisimai::String.aligned(v[:address], ['(', ')'])
            # (nyaan)nekochan@example.org, nekochan(nyaan)cat@example.org or nekochan(nyaan)@example.org
            p1 = v[:address].index('(')
            p2 = v[:address].index(')')
            v[:address] = v[:address][0, p1] + v[:address][p2 + 1, v[:address].size]
            v[:comment] = v[:address][p1, p2 - p1 - 1]
          end
          readbuffer << v
        end
      end

      while e = readbuffer.shift do
        # The element must not include any character except from 0x20 to 0x7e.
        next if e[:address] =~ /[^\x20-\x7e]/
        if e[:address].include?('@') == false
          # Allow if the argument is MAILER-DAEMON
          next unless Sisimai::Address.is_mailerdaemon(e[:address])
        end

        # Remove angle brackets, other brackets, and quotations: []<>{}'` except a domain part is
        # an IP address like neko@[192.0.2.222]
        e[:address] = e[:address].gsub(/\A[\[<{('`]/, '').gsub(/[.,'`>});]\z/, '')
        e[:address] = e[:address].gsub(/[^A-Za-z]\z/, '') unless e[:address].include?('@[')
        e[:address] = e[:address].sub(/\A["]/, '').chomp('"') unless e[:address] =~ /\A["].+["][@]/

        if addrs
          # Almost compatible with parse() method, returns email address only
          e.delete(:name)
          e.delete(:comment)
        else
          # Remove double-quotations, trailing spaces.
          [:name, :comment].each { |f| e[f] = e[f].strip }
          e[:comment] = '' unless e[:comment] =~ /\A[(].+[)]/
          e[:name].squeeze!(' ')     unless e[:name] =~ /\A["].+["]\z/
          e[:name].sub!(/\A["]/, '') unless e[:name] =~ /\A["].+["][@]/
          e[:name].chomp!('"')
        end
        addrtables << e
      end

      return nil if addrtables.empty?
      return addrtables
    end

    # Runs like ruleset 3,4 of sendmail.cf
    # @param    [String] input  Text including an email address
    # @return   [String]        Email address without comment, brackets
    # @example  s3s4('<neko@example.cat>') #=> 'neko@example.cat'
    def self.s3s4(input)
      return "" if input.to_s == ""
      return "" if input.is_a?(Object::String) == false

      addrs = Sisimai::Address.find(input, true) || []
      return input if addrs.empty?
      return addrs[0][:address]
    end

    # Expand VERP: Get the original recipient address from VERP
    # @param    [String] email  VERP Address
    # @return   [String]        Email address
    # @example  Expand VERP address
    #   expand_verp('bounce+neko=example.org@example.org') #=> 'neko@example.org'
    def self.expand_verp(email)
      return "" unless email.is_a? Object::String
      return "" unless cv = email.split('@', 2).first.match(/\A[-\w]+?[+](\w[-.\w]+\w)[=](\w[-.\w]+\w)\z/)
      verp0 = cv[1] + '@' + cv[2]
      return verp0 if Sisimai::Address.is_emailaddress(verp0)
    end

    # Expand alias: remove from '+' to '@'
    # @param    [String] email  Email alias string
    # @return   [String]        Expanded email address
    # @example  Expand alias
    #   expand_alias('neko+straycat@example.org') #=> 'neko@example.org'
    def self.expand_alias(email)
      return "" unless Sisimai::Address.is_emailaddress(email)

      local = email.split('@')
      return "" unless cv = local[0].match(/\A([-\w]+?)[+].+\z/)
      return cv[1] + '@' + local[1]
    end

    # :address, # [String] Email address
    # :user,    # [String] local part of the email address
    # :host,    # [String] domain part of the email address
    # :verp,    # [String] VERP
    # :alias,   # [String] alias of the email address
    # :name,    # [String] Display name
    # :comment, # [String] Comment
    attr_reader   :address, :user, :host, :verp, :alias
    attr_accessor :name, :comment

    # Constructor of Sisimai::Address
    # @param    [Hash] argvs        Email address, name, and other elements
    # @return   [Sisimai::Address]  Object or nil when the email address was not valid.
    # @example  new(address: 'neko@example.org', name: 'Neko', comment: '(nyaan)') # => Sisimai::Address object
    def initialize(argvs)
      return nil if argvs.is_a?(Hash) == false || argvs[:address].nil? || argvs[:address].empty?

      heads = ['<']
      tails = ['>', ',', '.', ';']
      point = argvs[:address].rindex('@')
      if cv = argvs[:address].match(/\A([^\s]+)[@]([^@]+)\z/) ||
              argvs[:address].match(/\A(["].+?["])[@]([^@]+)\z/)
        # Get the local part and the domain part from the email address
        lpart = argvs[:address][0, point]
        dpart = argvs[:address][point + 1,  argvs[:address].size]
        email = Sisimai::Address.expand_verp(argvs[:address])
        aname = nil

        if email.empty?
          # Is not VERP address, try to expand the address as an alias
          email = Sisimai::Address.expand_alias(argvs[:address])
          aname = true if email.empty? == false
        end

        if email.include?('@')
          # The address is a VERP or an alias
          if aname
            # The address is an alias: neko+nyaan@example.jp
            @alias = argvs[:address]
          else
            # The address is a VERP: b+neko=example.jp@example.org
            @verp  = argvs[:address]
          end
        end

        heads.each do |e|
          while lpart[0, 1] == e
            lpart[0, 1] = ''
          end
        end

        tails.each do |e|
          while dpart[-1, 1] == e
            dpart[-1, 1] = ''
          end
        end

        @user    = lpart
        @host    = dpart
        @address = lpart + '@' + dpart
      else
        # The argument does not include "@"
        return nil unless Sisimai::Address.is_mailerdaemon(argvs[:address])
        return nil if argvs[:address].include?(' ')

        # The argument does not include " "
        @user    = argvs[:address]
        @host  ||= ''
        @address = argvs[:address]
      end

      @alias ||= ''
      @verp  ||= ''
      @name    = argvs[:name]    || ''
      @comment = argvs[:comment] || ''
    end

    # Check whether the object has valid content or not
    # @return        [True,False]   returns true if the object is void
    def void
      return true unless @address
      return false
    end

    # Returns the value of address as String
    # @return [String] Email address
    def to_json(*); return self.address.to_s; end

    # Returns the value of address as String
    # @return [String] Email address
    def to_s; return self.address.to_s; end

  end
end

