require 'sisimai/version'

# Sisimai is the system formerly known as bounceHammer 4, is a Ruby module for
# analyzing bounce mails and generate structured data in a JSON format (YAML is
# also available if "YAML" module is installed on your system) from parsed bounce
# messages. Sisimai is a coined word: Sisi (the number 4 is pronounced "Si" in
# Japanese) and MAI (acronym of "Mail Analyzing Interface").
module Sisimai
  # Imported from p5-Sisimail/lib/Sisimai.pm
  class << self
    def version(); return Sisimai::VERSION; end
    def sysname(); return 'bouncehammer';   end
    def libname(); return 'Sisimai';        end

    # Wrapper method for parsing mailbox/maidir
    # @param         [String] argv0      Path to mbox or Maildir/
    # @param         [Hash]   argv0      or Hash (decoded JSON)
    # @param         [IO]     argv0      or STDIN object
    # @param         [Hash]   argv1      Parser options(delivered=false)
    # @options argv1 [Boolean] delivered true: Include "delivered" reason
    # @options argv1 [Lambda]  hook      Lambda object to be called back
    # @options argv1 [String]  input     Input data format: 'email', 'json'
    # @options argv1 [Array]   field     Email header name to be captured
    # @return        [Array]             Parsed objects
    # @return        [nil]               nil if the argument was wrong or an empty array
    def make(argv0, **argv1)
      return nil unless argv0

      require 'sisimai/data'
      require 'sisimai/message'

      rtype = nil
      input = argv1[:input] || nil
      field = argv1[:field] || []
      raise ' ***error: "field" accepts an array reference only' unless field.is_a? Array

      unless input
        # "input" did not specified, try to detect automatically.
        rtype = argv0.class.to_s
        if rtype == 'String' || rtype == 'IO'
          # The argument may be a path to email
          input = 'email'

        elsif rtype =~ /\A(?:Array|Hash)\z/
          # The argument may be a decoded JSON object
          input = 'json'
        end
      end

      methodargv = {}
      delivered1 = argv1[:delivered] || false
      hookmethod = argv1[:hook] || nil
      bouncedata = []

      if input == 'email'
        # Path to mailbox or Maildir/, or STDIN: 'input' => 'email'
        require 'sisimai/mail'
        mail = Sisimai::Mail.new(argv0)
        return nil unless mail

        while r = mail.read do
          # Read and parse each mail file
          methodargv = { data: r, hook: hookmethod, input: 'email', field: field }
          mesg = Sisimai::Message.new(methodargv)
          next if mesg.void

          methodargv = { data: mesg, hook: hookmethod, input: 'email', delivered: delivered1 }
          data = Sisimai::Data.make(methodargv)
          next unless data
          bouncedata.concat(data) if data.size > 0
        end

      elsif input == 'json'
        # Decoded JSON object: 'input' => 'json'
        type = argv0.class.to_s
        list = []

        if type == 'Array'
          # [ {...}, {...}, ... ]
          argv0.each do |e|
            list << e
          end
        else
          list << argv0
        end

        list.each do |e|
          methodargv = { data: e, hook: hookmethod, input: 'json' }
          mesg = Sisimai::Message.new(methodargv)
          next if mesg.void

          methodargv = { data: mesg, hook: hookmethod, input: 'json', delivered: delivered1 }
          data = Sisimai::Data.make(methodargv)

          next unless data
          bouncedata.concat(data) if data.size > 0
        end

      else
        # The value of "input" neither "email" nor "json"
        raise ' ***error: invalid value of "input"'
      end

      return nil if bouncedata.size.zero?
      return bouncedata
    end

    # Wrapper method to parse mailbox/Maildir and dump as JSON
    # @param         [String] argv0      Path to mbox or Maildir/
    # @param         [Hash]   argv0      or Hash (decoded JSON)
    # @param         [IO]     argv0      or STDIN object
    # @param         [Hash] argv1        Parser options
    # @options argv1 [Integer] delivered true: Include "delivered" reason
    # @options argv1 [Lambda]  hook      Lambda object to be called back
    # @options argv1 [String]  input     Input data format: 'email', 'json'
    # @return        [String]            Parsed data as JSON text
    def dump(argv0, **argv1)
      return nil unless argv0

      nyaan = Sisimai.make(argv0, argv1) || []
      if RUBY_PLATFORM =~ /java/
        # java-based ruby environment like JRuby.
        require 'jrjackson'
        jsonstring = JrJackson::Json.dump(nyaan)
      else
        require 'oj'
        jsonstring = Oj.dump(nyaan, :mode => :compat)
      end
      return jsonstring
    end

    # Parser engine list (MTA modules)
    # @return   [Hash]     Parser engine table
    def engine
      names = %w|Bite::Email Bite::JSON ARF RFC3464 RFC3834|
      table = {}

      names.each do |e|
        r = 'Sisimai::' << e
        require r.gsub('::', '/').downcase

        if e =~ /\ABite::(?:Email|JSON)\z/
          # Sisimai::Bite::Email or Sisimai::Bite::JSON
          Module.const_get(r).send(:index).each do |ee|
            # Load and get the value of "description" from each module
            rr = sprintf('Sisimai::%s::%s', e, ee)
            require rr.gsub('::', '/').downcase
            table[rr.to_sym] = Module.const_get(rr).send(:description)
          end
        else
          # Sisimai::ARF, Sisimai::RFC3464, and Sisimai::RFC3834
          table[r.to_sym] = Module.const_get(r).send(:description)
        end
      end

      return table
    end

    # Reason list Sisimai can detect
    # @return   [Hash]     Reason list table
    def reason
      require 'sisimai/reason'
      table = {}
      names = Sisimai::Reason.index

      # These reasons are not included in the results of Sisimai::Reason.index
      names.concat(%w|Delivered Feedback Undefined Vacation|)

      names.each do |e|
        # Call .description() method of Sisimai::Reason::*
        r = 'Sisimai::Reason::' << e
        require r.gsub('::', '/').downcase
        table[e.to_sym] = Module.const_get(r).send(:description)
      end

      return table
    end

    # Try to match with message patterns
    # @param    [String]    Error message text
    # @return   [String]    Reason text
    def match(argvs = '')
      return nil if argvs.empty?
      require 'sisimai/reason'
      return Sisimai::Reason.match(argvs)
    end
  end
end

