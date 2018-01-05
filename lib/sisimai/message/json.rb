module Sisimai
  class Message
    # Sisimai::Message::JSON convert from a bounce object (decoded JSON) which is
    # retrieved from some Cloud Email Deliveries API to data structure.
    class JSON
      # Imported from p5-Sisimail/lib/Sisimai/Message/JSON.pm
      require 'sisimai/order/json'

      @@ToBeLoaded = []
      @@TryOnFirst = []

      DefaultSet = Sisimai::Order::JSON.default
      ObjectKeys = Sisimai::Order::JSON.by('keyname')

      # Make data structure from decoded JSON object
      # @param         [Hash] argvs   Bounce object
      # @options argvs [Hash]   data  Decoded JSON
      # @options argvs [Array]  load  User defined MTA(JSON) module list
      # @options argvs [Array]  order The order of MTA(JSON) modules
      # @options argvs [Code]   hook  Reference to callback method
      # @return        [Hash]         Resolved data structure
      def self.make(argvs)
        hookmethod = argvs['hook'] || nil
        processing = {
          'from'   => '',  # From_ line
          'header' => {},  # Email header
          'rfc822' => '',  # Original message part
          'ds'     => [],  # Parsed data, Delivery Status
          'catch'  => nil, # Data parsed by callback method
        }
        methodargv = {
          'load'  => argvs['load'] || [],
          'order' => argvs['order'] || []
        }
        @@ToBeLoaded = Sisimai::Message::JSON.load(methodargv)
        @@TryOnFirst = Sisimai::Message::JSON.makeorder(argvs['data'])

        # Rewrite message body for detecting the bounce reason
        methodargv = { 'hook' => hookmethod, 'json' => argvs['data'] }
        bouncedata = Sisimai::Message::JSON.parse(methodargv)

        return nil unless bouncedata
        return nil if bouncedata.empty?
        processing['ds']     = bouncedata['ds']
        processing['catch']  = bouncedata['catch']
        processing['rfc822'] = bouncedata['rfc822']

        return processing
      end

      # Load MTA(JSON) modules which specified at 'order' and 'load' in the argument
      # @param         [Hash] argvs       Module information to be loaded
      # @options argvs [Array]  load      User defined MTA(JSON) module list
      # @options argvs [Array]  order     The order of MTA(JSON) modules
      # @return        [Array]            Module list
      # @since v4.20.0
      def self.load(argvs)
        modulelist = []
        tobeloaded = []

        %w|load order|.each do |e|
          # The order of MTA(JSON) modules specified by user
          next unless argvs.key?(e)
          next unless argvs[e].is_a? Array
          next if argvs[e].empty?

          modulelist.concat(argvs['order']) if e == 'order'
          next unless e == 'load'

          # Load user defined MTA(JSON) module
          argvs['load'].each do |v|
            # Load user defined MTA(JSON) module
            begin
              require v.to_s.gsub('::', '/').downcase
            rescue LoadError
              warn ' ***warning: Failed to load ' + v
              next
            end
            tobeloaded << v
          end
        end

        modulelist.each do |e|
          # Append the custom order of MTA(JSON) modules
          next if tobeloaded.index(e)
          tobeloaded << e
        end

        return tobeloaded
      end

      # Check the decoded JSON strucutre for detecting MTA(JSON) modules and
      # returns the order of modules to be called.
      # @param         [Hash] heads   Decoded JSON object
      # @return        [Array]        Order of MTA(JSON) modules
      def self.makeorder(argvs)
        return [] unless argvs
        return [] unless argvs.keys.size > 0
        order = []

        # Seek some key names from given argument
        ObjectKeys.each_key do |e|
          # Get MTA(JSON) module list matched with a specified key
          next unless argvs.key?(e)

          # Matched and push it into the order list
          order.concat(ObjectKeys[e])
          break
        end
        return order
      end

      # Parse bounce object with each MTA(JSON) module
      # @param               [Hash] argvs    Processing message entity.
      # @param options argvs [Hash] json     Decoded bounce object
      # @param options argvs [Proc] hook     Hook method to be called
      # @return              [Hash]          Parsed and structured bounce mails
      def self.parse(argvs)
        bouncedata = argvs['json'] || {}
        hookmethod = argvs['hook'] || nil
        havecaught = nil
        haveloaded = {}
        hasadapted = nil

        # Call the hook method
        if hookmethod.is_a? Proc
          # Execute hook method
          begin
            p = {
              'datasrc' => 'json',
              'headers' => nil,
              'message' => nil,
              'bounces' => argvs['json']
            }
            havecaught = hookmethod.call(p)
          rescue StandardError => ce
            warn sprintf(' ***warning: Something is wrong in hook method :%s', ce.to_s)
          end
        end

        catch :ADAPTOR do
          while true
            # 1. User-Defined Module
            # 2. MTA(JSON) Module Candidates to be tried on first
            # 3. Sisimai::Bite::JSON::*
            #
            @@ToBeLoaded.each do |r|
              # Call user defined MTA(JSON) modules
              next if haveloaded[r]
              begin
                require r.gsub('::', '/').downcase
              rescue LoadError => ce
                warn ' ***warning: Failed to load ' + ce.to_s
                next
              end
              hasadapted = Module.const_get(r).adapt(bouncedata)
              haveloaded[r] = true
              throw :ADAPTOR if hasadapted
            end

            @@TryOnFirst.each do |r|
              # Try MTA(JSON) module candidates which are detected from object
              # key names
              next if haveloaded.key?(r)
              begin
                require r.gsub('::', '/').downcase
              rescue LoadError => ce
                warn ' ***warning: ' + ce.to_s
                next
              end
              hasadapted = Module.const_get(r).adapt(bouncedata)
              haveloaded[r] = true
              throw :ADAPTOR if hasadapted
            end

            DefaultSet.each do |r|
              # Default order of MTA(JSON) modules
              next if haveloaded.key?(r)
              begin
                require r.gsub('::', '/').downcase
              rescue => ce
                warn ' ***warning: ' + ce.to_s
                next
              end

              hasadapted = Module.const_get(r).adapt(bouncedata)
              haveloaded[r] = true
              throw :ADAPTOR if hasadapted
            end

            break # as of now, we have no sample JSON data for coding this block
          end
        end

        hasadapted['catch'] = havecaught if hasadapted
        return hasadapted
      end

    end
  end
end

