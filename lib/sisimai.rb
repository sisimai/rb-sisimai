# Sisimai (pronounced /ɕi.ɕi.ma.i/) is a library that decodes complex and diverse bounce emails and
# outputs the results of the delivery failure, such as the reason for the bounce and the recipient
# email address, in structured data. It is also possible to output in JSON format. 
require 'sisimai/version'
module Sisimai
  class << self
    def version(); return Sisimai::VERSION; end
    def libname(); return 'Sisimai';        end

    # Wrapper method for decoding mailbox/maidir
    # @param         [String] argv0      Path to mbox or Maildir/
    # @param         [Hash]   argv0      or Hash (decoded JSON)
    # @param         [IO]     argv0      or STDIN object
    # @param         [Hash]   argv1      Options for decoding(delivered=false)
    # @options argv1 [Boolean] delivered true: Include "delivered" reason
    # @options argv1 [Boolean] vacation  true: Include "vacation" reason
    # @options argv1 [Array]   c___      Proc object to a callback method for the message and each file
    # @return        [Array]             Decoded objects
    # @return        [nil]               nil if the argument was wrong or an empty array
    def rise(argv0, **argv1)
      return nil unless argv0
      require 'sisimai/eb'
      require 'sisimai/mail'
      require 'sisimai/fact'
      return nil unless mail = Sisimai::Mail.new(argv0)

      maxb = Sisimai::Eb::XeBYTE * 32 # 64MB * 32 = 2GB
      if (mail.kind == "mailbox" || mail.kind == "memory") && (mail.data.size > maxb || mail.data.size < 1)
        # Check and limit the max size of entire email data: UNIX mbox and memory: 2GB
        warn " ***warning: Input email is empty or too large: #{mail.data.size} bytes"
        return nil
      end

      c___ = argv1[:c___].is_a?(Array) ? argv1[:c___] : [nil, nil]
      sisi = []
      sumb = 0
      while r = mail.data.read do
        # Read and decode each email file
        if mail.kind == 'maildir'
          # - Check and limit the max size of each email file (64MB)
          # - Skip to the next email when the size of email is larger than 64MB.
          next if mail.data.size > Sisimai::Eb::XeBYTE
        else
          # UNIX mbox, memory, and stdin.
          next if r.bytesize     > Sisimai::Eb::XeBYTE

          if mail.kind == "stdin"
            # Check and limit the max size of entire email data read from STDIN: 2GB
            sumb += r.bytesize; if sumb > maxb
              warn " ***warning: Input email is too large: #{sumb} bytes" 
              return nil
            end
          end
        end

        path = mail.data.path
        args = {data: r, hook: c___[0], origin: path, delivered: argv1[:delivered], vacation: argv1[:vacation]}
        fact = Sisimai::Fact.rise(**args) || []

        if c___[1]
          # Run the callback function specified with "c___" parameter of Sisimai.rise after reading
          # each email file in Maildir/ every time
          args = {'kind' => mail.kind, 'mail' => r, 'path' => path, 'fact' => fact}
          begin
            c___[1].call(args) if c___[1].is_a?(Proc)
          rescue StandardError => ce
            warn ' ***warning: Something is wrong in the second element of the ":c___":' + ce.to_s
          end
        end

        sisi += fact if fact.empty? == false
      end

      return nil if sisi.empty?
      return sisi
    end

    # Wrapper method to decode mailbox/Maildir and dump as JSON
    # @param         [String] argv0      Path to mbox or Maildir/
    # @param         [Hash]   argv0      or Hash (decoded JSON)
    # @param         [IO]     argv0      or STDIN object
    # @param         [Hash] argv1        Options for decoding
    # @options argv1 [Integer] delivered true: Include "delivered" reason
    # @options argv1 [Integer] vacation  true: Include "vacation" reason
    # @options argv1 [Lambda]  hook      Lambda object to be called back
    # @return        [String]            Decoded data as JSON text
    def dump(argv0, **argv1)
      return "" unless argv0
      nyaan = Sisimai.rise(argv0, **argv1) || []

      if RUBY_PLATFORM.start_with?('java')
        # java-based ruby environment like JRuby.
        require 'jrjackson'
        jsonstring = JrJackson::Json.dump(nyaan)
      else
        require 'oj'
        jsonstring = Oj.dump(nyaan, :mode => :compat)
      end
      return jsonstring
    end

    # Decoding engine list (MTA modules)
    # @return   [Hash]     Decoding engine table
    def engine
      table = {}

      %w[Lhost ARF RFC3464 RFC3834].each do |e|
        r = "Sisimai::#{e}"
        require r.gsub('::', '/').downcase

        if e == 'Lhost'
          # Sisimai::Lhost::*
          Module.const_get(r).send(:index).each do |ee|
            # Load and get the value of "description" from each module
            rr = "Sisimai::#{e}::#{ee}"
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
      require 'sisimai/eb'
      require 'sisimai/reason'
      table = {}
      names = Sisimai::Reason.index

      # These reasons are not included in the results of Sisimai::Reason.index
      names += [Sisimai::Eb::ReSENT, Sisimai::Eb::ReFEED, Sisimai::Eb::Re___0, Sisimai::Eb::ReAWAY]
      while e = names.shift do
        # Call .description() method of Sisimai::Reason::*
        r = "Sisimai::Reason::#{e}"
        require r.gsub('::', '/').downcase
        table[e.to_sym] = Module.const_get(r).send(:description)
      end

      return table
    end

    # Try to match with message patterns
    # @param    [String]    Error message text
    # @return   [String]    Reason text
    def match(argvs = '')
      return "" if argvs.empty?
      require 'sisimai/reason'
      return Sisimai::Reason.match(argvs.downcase)
    end
  end
end

