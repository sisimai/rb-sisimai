module Sisimai
  # Sisimai::Address provide methods for dealing email address.
  class Address
    # Imported from p5-Sisimail/lib/Sisimai/Address.pm
    require 'sisimai/rfc5322'
    @@undisclosed = 'libsisimai.org.invalid'

    # Return pseudo recipient or sender address
    # @param    [Symbol] argv1  Address type: :r or :s
    # @return   [String, Nil]   Pseudo recipient address or sender address or
    #                           nil when the argv1 is neither :r nor :s
    def self.undisclosed(argv1)
      return nil unless argv1
      return nil unless %w|r s|.index(argv1.to_s)

      local = argv1 == :r ? 'recipient' : 'sender'
      return sprintf('undisclosed-%s-in-headers@%s', local, @@undisclosed)
    end

    # New constructor of Sisimai::Address
    # @param    [Hash] argvs        Email address, name, and other elements
    # @return   [Sisimai::Address]  Object or nil when the email address was
    #                               not valid.
    # @example  make({address: 'neko@example.org', name: 'Neko', comment: '(nyaan)')}
    #           # => Sisimai::Address object
    def self.make(argvs)
      return nil unless argvs.is_a? Hash
      return nil unless argvs.key?(:address)
      return nil if argvs[:address].empty?

      thing = Sisimai::Address.new(argvs[:address])
      return nil unless thing
      return nil if thing.void

      thing.name    = argvs[:name]    || ''
      thing.comment = argvs[:comment] || ''

      return thing
    end

    def self.find(argv1 = nil, addrs = false)
      # Email address parser with a name and a comment
      # @param    [String] argv1  String including email address
      # @param    [Boolean] addrs true:  Returns list including all the elements
      #                           false: Returns list including email addresses only
      # @return   [Array, Nil]    Email address list or nil when there is no
      #                           email address in the argument
      # @example  Parse email address
      #   find('Neko <neko(nyaan)@example.org>')
      #   #=> [{ address: 'neko@example.org', name: 'Neko', comment: '(nyaan)'}]
      return nil unless argv1
      argv1 = argv1.gsub(/[\r\n]/, '')

      emailtable = { address: '', name: '', comment: '' }
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
            if v[:address] =~ /\A[<].+[@].+[>]\z/
              # An email address has already been picked

              if readcursor & indicators[:'comment-block'] > 0
                # The cursor is in the comment block (Neko, Nyaan)
                v[:comment] += e

              elsif readcursor & indicators[:'quoted-string'] > 0
                # "Neko, Nyaan"
                v[:name] += e

              else
                # The cursor is not in neither the quoted-string nor the comment block
                readcursor = 0  # reset cursor position
                readbuffer << v
                v = { address: '', name: '', comment: '' }
                p = ''
              end
            else
              # "Neko, Nyaan" <neko@nyaan.example.org> OR <"neko,nyaan"@example.org>
              p.size > 0 ? (v[p] += e) : (v[:name] += e)
            end
            next
          end # End of if(',')

          if e == '<'
            # <: The beginning of an email address or not
            if v[:address].size > 0
              p.size > 0 ? (v[p] += e) : (v[:name] += e)

            else
              # <neko@nyaan.example.org>
              readcursor |= indicators[:'email-address']
              v[:address] += e
              p = :address
            end
            next
          end
          # End of if('<')

          if e == '>'
            # >: The end of an email address or not
            if readcursor & indicators[:'email-address'] > 0
              # <neko@example.org>
              readcursor &= ~indicators[:'email-address']
              v[:address] += e
              p = ''
            else
              # a comment block or a display name
              p.size > 0 ? (v[:comment] += e) : (v[:name] += e)
            end
            next
          end # End of if('>')

          if e == '('
            # The beginning of a comment block or not
            if readcursor & indicators[:'email-address'] > 0
              # <"neko(nyaan)"@example.org> or <neko(nyaan)@example.org>
              if v[:address] =~ /["]/
                # Quoted local part: <"neko(nyaan)"@example.org>
                v[:address] += e

              else
                # Comment: <neko(nyaan)@example.org>
                readcursor |= indicators[:'comment-block']
                v[:comment] += ' ' if v[:comment] =~ /[)]\z/
                v[:comment] += e
                p = :comment
              end
            elsif readcursor & indicators[:'comment-block'] > 0
              # Comment at the outside of an email address (...(...)
              v[:comment] += ' ' if v[:comment] =~ /[)]\z/
              v[:comment] += e

            elsif readcursor & indicators[:'quoted-string'] > 0
              # "Neko, Nyaan(cat)", Deal as a display name
              v[:name] += e

            else
              # The beginning of a comment block
              readcursor |= indicators[:'comment-block']
              v[:comment] += ' ' if v[:comment] =~ /[)]\z/
              v[:comment] += e
              p = :comment
            end
            next
          end # End of if('(')

          if e == ')'
            # The end of a comment block or not
            if readcursor & indicators[:'email-address'] > 0
              # <"neko(nyaan)"@example.org> OR <neko(nyaan)@example.org>
              if v[:address] =~ /["]/
                # Quoted string in the local part: <"neko(nyaan)"@example.org>
                v[:address] += e

              else
                # Comment: <neko(nyaan)@example.org>
                readcursor &= ~indicators[:'comment-block']
                v[:comment] += e
                p = :address
              end
            elsif readcursor & indicators[:'comment-block'] > 0
              # Comment at the outside of an email address (...(...)
              readcursor &= ~indicators[:'comment-block']
              v[:comment] += e
              p = ''

            else
              # Deal as a display name
              readcursor &= ~indicators[:'comment-block']
              v[:name] = e
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
              v[:name] += e
              if readcursor & indicators[:'quoted-string'] > 0
                # "Neko, Nyaan"
                unless v[:name] =~ /\x5c["]\z/
                  # "Neko, Nyaan \"...
                  readcursor &= ~indicators[:'quoted-string']
                  p = ''
                end
              end
            end
            next
          end # End of if('"')
        else
          # The character is not a delimiter
          p.size > 0 ? (v[p] += e) : (v[:name] += e)
          next
        end
      end

      if v[:address].size > 0
        # Push the latest values
        readbuffer << v
      else
        # No email address like <neko@example.org> in the argument
        if cv = v[:name].match(validemail)
          # String like an email address will be set to the value of "address"
          v[:address] = sprintf('%s@%s', cv[1], cv[2])

        elsif Sisimai::RFC5322.is_mailerdaemon(v[:name])
          # Allow if the argument is MAILER-DAEMON
          v[:address] = v[:name]
        end

        if v[:address].size > 0
          # Remove the comment from the address
          if cv = v[:address].match(/(.*)([(].+[)])(.*)/)
            # (nyaan)nekochan@example.org, nekochan(nyaan)cat@example.org or
            # nekochan(nyaan)@example.org
            v[:address] = cv[1] + cv[3]
            v[:comment] = cv[2]
          end
          readbuffer << v
        end
      end

      readbuffer.each do |e|
        # The element must not include any character except from 0x20 to 0x7e.
        next if e[:address] =~ /[^\x20-\x7e]/

        unless e[:address] =~ /\A.+[@].+\z/
          # Allow if the argument is MAILER-DAEMON
          next unless Sisimai::RFC5322.is_mailerdaemon(e[:address])
        end

        # Remove angle brackets, other brackets, and quotations: []<>{}'`
        # except a domain part is an IP address like neko@[192.0.2.222]
        e[:address] = e[:address].sub(/\A[\[<{('`]/, '')
        e[:address] = e[:address].sub(/['`>})]\z/, '')
        e[:address] = e[:address].sub(/\]\z/, '') unless e[:address] =~ /[@]\[[0-9A-Z:\.]+\]\z/i

        unless e[:address] =~ /\A["].+["][@]/
          # Remove double-quotations
          e[:address] = e[:address].sub(/\A["]/, '')
          e[:address] = e[:address].sub(/["]\z/, '')
        end

        if addrs
          # Almost compatible with parse() method, returns email address only
          e.delete(:name)
          e.delete(:comment)
        else
          # Remove double-quotations, trailing spaces.
          [:name, :comment].each do |f|
            e[f] = e[f].sub(/\A\s*/, '')
            e[f] = e[f].sub(/\s*\z/, '')
          end
          e[:comment] = '' unless e[:comment] =~ /\A[(].+[)]/

          e[:name] = e[:name].squeeze(' ')     unless e[:name] =~ /\A["].+["]\z/
          e[:name] = e[:name].sub(/\A["]/, '') unless e[:name] =~ /\A["].+["][@]/
          e[:name] = e[:name].sub(/["]\z/, '')
        end
        addrtables << e
      end

      return nil if addrtables.empty?
      return addrtables
    end

    # Email address parser
    # @param    [Array] argvs   List of strings including email address
    # @return   [Array, Nil]    Email address list or nil when there is no
    #                           email address in the argument
    # @until    v4.22.1
    def self.parse(argvs = nil)
      return nil unless argvs
      return nil unless argvs.is_a? Array
      return nil if argvs.empty?

      warn ' ***warning: Sisimai::Address.parse is marked as obsoleted'
      addrs = []

      argvs.each do |e|
        # Parse each element in the array
        #   1. The element must include '@'.
        #   2. The element must not include character except from 0x20 to 0x7e.
        next unless e
        next unless e.is_a? Object::String
        next if e.empty?

        v = Sisimai::Address.find(e, 1) || []
        next if v.empty?
        v.each { |f| addrs << f[:address] }
      end

      return nil if addrs.empty?
      return addrs
    end

    # Runs like ruleset 3,4 of sendmail.cf
    # @param    [String] input  Text including an email address
    # @return   [String]        Email address without comment, brackets
    # @example  s3s4('<neko@example.cat>') #=> 'neko@example.cat'
    def self.s3s4(input)
      return nil unless input
      return input unless input.is_a? Object::String

      addrs = Sisimai::Address.find(input, 1) || []
      return input if addrs.empty?
      return addrs[0][:address]
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
        verp0 = sprintf('%s@%s', cv[1], cv[2])
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
    @@rwaccessors = [
      :name,    # [String] Display name
      :comment, # [String] Comment
    ]
    @@roaccessors.each { |e| attr_reader   e }
    @@rwaccessors.each { |e| attr_accessor e }

    # Constructor of Sisimai::Address
    # @param <str>  [String] argv1          Email address
    # @return       [Sisimai::Address, Nil] Object or nil when the email
    #                                       address was not valid
    def initialize(argv1)
      return nil unless argv1

      addrs = Sisimai::Address.find(argv1)
      return nil unless addrs
      return nil if addrs.empty?
      thing = addrs.shift

      if cv = thing[:address].match(/\A([^\s]+)[@]([^@]+)\z/) ||
              thing[:address].match(/\A(["].+?["])[@]([^@]+)\z/)
        # Get the local part and the domain part from the email address
        lpart = cv[1]
        dpart = cv[2]
        email = Sisimai::Address.expand_verp(thing[:address])
        aname = nil

        if email.empty?
          # Is not VERP address, try to expand the address as an alias
          email = Sisimai::Address.expand_alias(thing[:address])
          aname = true unless email.empty?
        end

        if email =~ /\A.+[@].+?\z/
          # The address is a VERP or an alias
          if aname
            # The address is an alias: neko+nyaan@example.jp
            @alias = thing[:address]
          else
            # The address is a VERP: b+neko=example.jp@example.org
            @verp  = thing[:address]
          end
        end
        @user    = lpart
        @host    = dpart
        @address = sprintf('%s@%s', lpart, dpart)

      else
        # The argument does not include "@"
        return nil unless Sisimai::RFC5322.is_mailerdaemon(thing[:address])
        return nil if thing[:address] =~ /[ ]/

        # The argument does not include " "
        @user    = thing[:address]
        @host  ||= ''
        @address = thing[:address]
      end

      @alias ||= ''
      @verp  ||= ''
      @name    = thing[:name]    || ''
      @comment = thing[:comment] || ''
    end

    # Check whether the object has valid content or not
    # @return        [True,False]   returns true if the object is void
    def void
      return true unless @address
      return false
    end

    # Check the "address" is an undisclosed address or not
    # @param    [None]
    # @return   [Boolean] true:  Undisclosed address
    #                     false: Is not undisclosed address
    def is_undisclosed
      return true if self.host == @@undisclosed
      return false
    end

    # Returns the value of address as String
    # @return [String] Email address
    def to_json(*)
      return self.address.to_s
    end

    # Returns the value of address as String
    # @return [String] Email address
    def to_s
      return self.address.to_s
    end

  end
end
