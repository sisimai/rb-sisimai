module Sisimai
  # Sisimai::Address provide methods for dealing email address.
  class Address
    # Imported from p5-Sisimail/lib/Sisimai/Address.pm
    require 'sisimai/rfc5322'

    # Return pseudo recipient or sender address
    # @param    [String] argv1  Address type: 'r' or 's'
    # @return   [String, Nil]   Pseudo recipient address or sender address or
    #                           Undef when the $argv1 is neither 'r' nor 's'
    def self.undisclosed(argv1)
      return nil unless argv1
      return nil unless ['r', 's'].index(argv1)

      local = argv1 == 'r' ? 'recipient' : 'sender'
      return sprintf('undisclosed-%s-in-headers@dummy-domain.invalid', local)
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
        next unless e =~ /[@]/
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
      # no space character between " and < .
      input = input.sub(/\A(.+)"<(.+)\z/, '\1" <\2')      # "=?ISO-2022-JP?B?....?="<user@example.jp>, 
      input = input.sub(/\A(.+)[?]=<(.+)\z/, '\1?= <\2')  # =?ISO-2022-JP?B?....?=<user@example.jp>

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
          next unless e =~ /\A[<]?.+[@][-.0-9A-Za-z]+[.]?[A-Za-z]{2,}[>]?\z/
          addrs << e
        end
      end

      if addrs.size > 1
        # Get the first element which is <...> format string from @addrs array.
        canon = addrs.detect { |e| e =~ /\A[<].+[>]\z/ }
        canon = addrs[0] if canon.size < 1

      else
        canon = addrs.shift
      end

      return '' if !canon || canon == ''
      canon = canon.tr('<>[]():;', '')  # Remove brackets, colons

      if canon =~ /\A["].+["][@].+\z/
        # "localpart..."@example.jp
        canon = canon.tr(%q|{}'`|, '')

      else
        # Remove brackets, quotations
        canon = canon.tr(%q|{}'"`|, '')
      end
      return canon
    end

    # Expand VERP: Get the original recipient address from VERP
    # @param    [String] email  VERP Address
    # @return   [String]        Email address
    # @example  Expand VERP address
    #   expand_verp('bounce+neko=example.jp@example.org') #=> 'neko@example.jp'
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
    #   expand_alias('neko+straycat@example.jp') #=> 'neko@example.jp'
    def self.expand_alias(email)
      value = ''
      local = []
      return '' unless Sisimai::RFC5322.is_emailaddress(email)

      local = email.split('@')
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
        lpart = lpart.tr(%q|`'"<>|, '') unless lpart =~ /\A["].+["]\z/

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
        return nil
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
    def to_json
      return self.address.to_s
    end

  end
end
