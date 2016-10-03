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
    # @param         [String] path       Path to mbox or Maildir/
    # @param         [Hash]  argvs       Parser options(delivered=false)
    # @options argvs [Boolean] delivered true: Include "delivered" reason
    # @options argvs [Lambda]  hook      Lambda object to be called back
    # @return        [Array]             Parsed objects
    # @return        [nil]               nil if the argument was wrong or an empty array
    def make(path, **argvs)
      return nil unless path

      require 'sisimai/mail'
      mail = Sisimai::Mail.new(path)
      list = []

      return nil unless mail
      require 'sisimai/data'
      require 'sisimai/message'

      methodargv = { :delivered => argvs[:delivered] || false }
      hookmethod = argvs[:hook] || nil

      while r = mail.read do
        # Read and parse each mail file
        mesg = Sisimai::Message.new(data: r, hook: hookmethod)
        next if mesg.void
        data = Sisimai::Data.make(data: mesg, delivered: methodargv)
        next unless data
        list.concat(data) if data.size > 0
      end

      return nil if list.size == 0
      return list
    end

    # Wrapper method to parse mailbox/Maildir and dump as JSON
    # @param         [String] path       Path to mbox or Maildir/
    # @param         [Hash] argvs        Parser options
    # @options argvs [Integer] delivered true: Include "delivered" reason
    # @options argvs [Lambda]  hook      Lambda object to be called back
    # @return        [String]            Parsed data as JSON text
    def dump(path, **argvs)
      return nil unless path

      nyaan = Sisimai.make(path, argvs) || []
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

    # Parser engine list (MTA/MSP modules)
    # @return   [Hash]     Parser engine table
    def engine
      names = %w|MTA MSP ARF RFC3464 RFC3834|
      table = {}

      names.each do |e|
        r = 'Sisimai::' + e
        require r.gsub('::', '/').downcase

        if e == 'MTA' || e == 'MSP'
          # Sisimai::MTA or Sisimai::MSP
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
        r = 'Sisimai::Reason::' + e
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

