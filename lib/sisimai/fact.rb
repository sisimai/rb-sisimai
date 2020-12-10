module Sisimai
  # Sisimai::Fact generate parsed data
  class Fact
    require 'sisimai/message'
    require 'sisimai/rfc1894'
    require 'sisimai/rfc5322'
    require 'sisimai/reason'
    require 'sisimai/address'
    require 'sisimai/datetime'
    require 'sisimai/time'
    require 'sisimai/smtp/error'
    require 'sisimai/string'
    require 'sisimai/rhost'

    @@rwaccessors = [
      :action,          # [String] The value of Action: header
      :addresser,       # [Sisimai::Address] From address
      :alias,           # [String] Alias of the recipient address
      :catch,           # [?] Results generated by hook method
      :deliverystatus,  # [String] Delivery Status(DSN)
      :destination,     # [String] The domain part of the "recipinet"
      :diagnosticcode,  # [String] Diagnostic-Code: Header
      :diagnostictype,  # [String] The 1st part of Diagnostic-Code: Header
      :feedbacktype,    # [String] Feedback Type
      :hardbounce,      # [Boolean] true = Hard bounce, false = is not a hard bounce
      :lhost,           # [String] local host name/Local MTA
      :listid,          # [String] List-Id header of each ML
      :messageid,       # [String] Message-Id: header
      :origin,          # [String] Email path as a data source
      :reason,          # [String] Bounce reason
      :recipient,       # [Sisimai::Address] Recipient address which bounced
      :replycode,       # [String] SMTP Reply Code
      :rhost,           # [String] Remote host name/Remote MTA
      :senderdomain,    # [String] The domain part of the "addresser"
      :smtpagent,       # [String] Module(Engine) name
      :smtpcommand,     # [String] The last SMTP command
      :subject,         # [String] UTF-8 Subject text
      :timestamp,       # [Sisimai::Time] Date: header in the original message
      :timezoneoffset,  # [Integer] Time zone offset(seconds)
      :token,           # [String] Message token/MD5 Hex digest value
    ]
    attr_accessor(*@@rwaccessors)

    RetryIndex = Sisimai::Reason.retry
    RFC822Head = Sisimai::RFC5322.HEADERFIELDS(:all)
    ActionList = %r/\A(?:delayed|delivered|expanded|failed|relayed)\z/

    # Constructor of Sisimai::Fact
    # @param    [Hash] argvs    Including each parameter
    # @return   [Sisimai::Fact] Structured email data
    def initialize(argvs)
      # Create email address object
      @alias          = argvs['alias'] || ''
      @addresser      = argvs['addresser']
      @action         = argvs['action']
      @catch          = argvs['catch']
      @diagnosticcode = argvs['diagnosticcode']
      @diagnostictype = argvs['diagnostictype']
      @deliverystatus = argvs['deliverystatus']
      @destination    = argvs['recipient'].host
      @feedbacktype   = argvs['feedbacktype']
      @hardbounce     = argvs['hardbounce']
      @lhost          = argvs['lhost']
      @listid         = argvs['listid']
      @messageid      = argvs['messageid']
      @origin         = argvs['origin']
      @reason         = argvs['reason']
      @recipient      = argvs['recipient']
      @replycode      = argvs['replycode']
      @rhost          = argvs['rhost']
      @senderdomain   = argvs['addresser'].host
      @smtpagent      = argvs['smtpagent']
      @smtpcommand    = argvs['smtpcommand']
      @subject        = argvs['subject']
      @token          = argvs['token']
      @timestamp      = argvs['timestamp']
      @timezoneoffset = argvs['timezoneoffset']
    end

    # Constructor of Sisimai::Fact
    # @param         [Hash]   argvs
    # @options argvs [String]  data       Entire email message
    # @options argvs [Boolean] delivered  Include the result which has "delivered" reason
    # @options argvs [Proc]    hook       Proc object of callback method
    # @options argvs [Array]   load       User defined MTA module list
    # @options argvs [Array]   order      The order of MTA modules
    # @options argvs [String]  origin     Path to the original email file
    # @return        [Array]              Array of Sisimai::Fact objects
    def self.rise(**argvs)
      return nil unless argvs
      return nil unless argvs.is_a? Hash

      email = argvs[:data]; return nil unless email
      loads = argvs[:load]  || nil
      order = argvs[:order] || nil
      args1 = { data: email, hook: argvs[:hook], load: loads, order: order }
      mesg1 = Sisimai::Message.rise(args1)

      return nil unless mesg1
      return nil unless mesg1['ds']
      return nil unless mesg1['rfc822']

      deliveries = mesg1['ds'].dup
      rfc822data = mesg1['rfc822']
      listoffact = [];

      while e = deliveries.shift do
        # Create parameters for each Sisimai::Fact object
        o = {}  # To be passed to each accessor of Sisimai::Fact
        p = {
          'action'         => e['action']       || '',
          'alias'          => e['alias']        || '',
          'catch'          => mesg1['catch']    || nil,
          'deliverystatus' => e['status']       || '',
          'diagnosticcode' => e['diagnosis']    || '',
          'diagnostictype' => e['spec']         || '',
          'feedbacktype'   => e['feedbacktype'] || '',
          'hardbounce'     => false,
          'lhost'          => e['lhost']        || '',
          'origin'         => argvs['origin'],
          'reason'         => e['reason']       || '',
          'recipient'      => e['recipient']    || '',
          'replycode'      => e['replycode']    || '',
          'rhost'          => e['rhost']        || '',
          'smtpagent'      => e['agent']        || '',
          'smtpcommand'    => e['command']      || '',
        }
        unless argvs[:delivered]
          # Skip if the value of "deliverystatus" begins with "2." such as 2.1.5
          next if p['deliverystatus'].start_with?('2.')
        end

        # EMAILADDRESS: Detect email address from message/rfc822 part
        RFC822Head[:addresser].each do |f|
          # Check each header in message/rfc822 part
          g = f.downcase
          next unless rfc822data[g]
          next if rfc822data[g].empty?

          j = Sisimai::Address.find(rfc822data[g]) || next
          p['addresser'] = j.shift
          break
        end

        unless p['addresser']
          # Fallback: Get the sender address from the header of the bounced email if the address is
          # not set at loop above.
          j = Sisimai::Address.find(mesg1.header['to']) || []
          p['addresser'] = j.shift
        end
        next unless p['addresser']
        next unless p['recipient']

        # TIMESTAMP: Convert from a time stamp or a date string to a machine time.
        datestring = nil
        zoneoffset = 0
        datevalues = []; datevalues << e['date'] unless e['date'].to_s.empty?

        # Date information did not exist in message/delivery-status part,...
        RFC822Head[:date].each do |f|
          # Get the value of Date header or other date related header.
          next unless rfc822data[f]
          datevalues << rfc822data[f]
        end

        # Set "date" getting from the value of "Date" in the bounce message
        datevalues << mesg1['header']['date'] if datevalues.size < 2

        while v = datevalues.shift do
          # Parse each date value in the array
          datestring = Sisimai::DateTime.parse(v)
          break if datestring
        end

        if datestring && cv = datestring.match(/\A(.+)[ ]+([-+]\d{4})\z/)
          # Get the value of timezone offset from datestring
          # Wed, 26 Feb 2014 06:05:48 -0500
          datestring = cv[1]
          zoneoffset = Sisimai::DateTime.tz2second(cv[2])
          p['timezoneoffset'] = cv[2]
        end

        begin
          # Convert from the date string to an object then calculate time zone offset.
          t = Sisimai::Time.strptime(datestring, '%a, %d %b %Y %T')
          p['timestamp'] = (t.to_time.to_i - zoneoffset) || nil
        rescue
          warn ' ***warning: Failed to strptime ' << datestring.to_s
        end
        next unless p['timestamp']

        # OTHER_TEXT_HEADERS:
        recvheader = mesg1['header']['received'] || []
        unless recvheader.empty?
          # Get localhost and remote host name from Received header.
          %w[lhost rhost].each { |a| e[a] ||= '' }
          e['lhost'] = Sisimai::RFC5322.received(recvheader[0]).shift if e['lhost'].empty?
          e['rhost'] = Sisimai::RFC5322.received(recvheader[-1]).pop  if e['rhost'].empty?
        end

        # Remove square brackets and curly brackets from the host variable
        %w[rhost lhost].each do |v|
          p[v].delete!('[]()')    # Remove square brackets and curly brackets from the host variable
          p[v].sub!(/\A.+=/, '')  # Remove string before "="
          p[v].chomp!("\r") if p[v].end_with?("\r") # Remove CR at the end of the value

          # Check space character in each value and get the first element
          p[v] = p[v].split(' ', 2).shift if p[v].include?(' ')
          p[v].chomp!('.') if p[v].end_with?('.')   # Remove "." at the end of the value
        end

        # Subject: header of the original message
        p['subject'] = rfc822data['subject'] || ''
        p['subject'].scrub!('?')
        p['subject'].chomp!("\r") if p['subject'].end_with?("\r")

        # The value of "List-Id" header
        p['listid'] = rfc822data['list-id'] || ''
        unless p['listid'].empty?
          # Get the value of List-Id header like "List name <list-id@example.org>"
          if cv = p['listid'].match(/\A.*([<].+[>]).*\z/) then p['listid'] = cv[1] end
          p['listid'].delete!('<>')
          p['listid'].chomp!("\r") if p['listid'].end_with?("\r")
          p['listid'] = '' if p['listid'].include?(' ')
        end

        # The value of "Message-Id" header
        p['messageid'] = rfc822data['message-id'] || ''
        unless p['messageid'].empty?
          # Leave only string inside of angle brackets(<>)
          if cv = p['messageid'].match(/\A([^ ]+)[ ].*/) then p['messageid'] = cv[1] end
          if cv = p['messageid'].match(/[<]([^ ]+?)[>]/) then p['messageid'] = cv[1] end
        end

        # CHECK_DELIVERY_STATUS_VALUE: Cleanup the value of "Diagnostic-Code:" header
        unless p['diagnosticcode'].empty?
          # Count the number of D.S.N. and SMTP Reply Code
          vm = 0
          vs = Sisimai::SMTP::Status.find(p['diagnosticcode'])
          vr = Sisimai::SMTP::Reply.find(p['diagnosticcode'])

          if vs
            # How many times does the D.S.N. appeared
            vm += p['diagnosticcode'].scan(/\b#{vs}\b/).size
            p['deliverystatus'] = vs if vs =~ /\A[45][.][1-9][.][1-9]+\z/
          end

          if vr
            # How many times does the SMTP reply code appeared
            vm += p['diagnosticcode'].scan(/\b#{vr}\b/).size
            p['replycode'] ||= vr
          end

          if vm > 2
            # Build regular expression for removing string like '550-5.1.1'
            # from the value of "diagnosticcode"
            re = %r/[ ]#{vr}[- ](?:#{vs})?/

            # 550-5.7.1 [192.0.2.222] Our system has detected that this message is
            # 550-5.7.1 likely unsolicited mail. To reduce the amount of spam sent to Gmail,
            # 550-5.7.1 this message has been blocked. Please visit
            # 550 5.7.1 https://support.google.com/mail/answer/188131 for more information.
            p['diagnosticcode'] = Sisimai::String.sweep(p['diagnosticcode'].gsub(re, ' '))
          end
        end

        p['diagnostictype'] ||= 'X-UNIX'   if p['reason'] == 'mailererror'
        p['diagnostictype'] ||= 'SMTP' unless %w[feedback vacation].include?(p['reason'])

        # Check the value of SMTP command
        p['smtpcommand'] = '' unless %w[EHLO HELO MAIL RCPT DATA QUIT].include?(p['smtpcommand'])

        # Create parameters for the constructor
        as = Sisimai::Address.new(p['addresser'])          || next; next if as.void
        ar = Sisimai::Address.new(address: p['recipient']) || next; next if ar.void
        ea = %w[
          action deliverystatus diagnosticcode diagnostictype feedbacktype lhost listid messageid
          origin reason replycode rhost smtpagent smtpcommand subject 
        ]

        o = {
          'addresser'    => as,
          'recipient'    => ar,
          'senderdomain' => as.host,
          'destination'  => ar.host,
          'alias'        => p['alias'] || ar.alias,
          'token'        => Sisimai::String.token(as, ar, p['timestamp']),
        }

        # Other accessors
        ea.each { |q| o[q] ||= p[q] || '' }
        o['catch']          = p['catch'] || nil
        o['hardbounce']     = p['hardbounce']
        o['replycode']      = Sisimai::SMTP::Reply.find(p['diagnosticcode']).to_s if o['replycode'].empty?
        o['timestamp']      = Sisimai::Time.parse(::Time.at(p['timestamp']).to_s)
        o['timezoneoffset'] = p['timezoneoffset'] || '+0000'

        # REASON: Decide the reason of email bounce
        if o['reason'].empty? || RetryIndex[o['reason']]
          # The value of "reason" is empty or is needed to check with other values again
          de = o['destination']; r = ''
          r = Sisimai::Rhost.get(o) if Sisimai::Rhost.match(o['rhost'])
          if r.empty?
            # Failed to detect a bounce reason by the value of "rhost"
            r = Sisimai::Rhost.get(o, de) if Sisimai::Rhost.match(de)
            r = Sisimai::Reason.get(o)    if r.empty?
            r = 'undefined'               if r.empty?
          end
          o['reason'] = r
        end

        # HARDBOUNCE: Set the value of "hardbounce", default value of "bouncebounce" is false
        if o['reason'] =~ /\A(?:delivered|feedback|vacation)\z/
          # The value of "reason" is "delivered", "vacation" or "feedback".
          o['replycode'] = '' unless o['reason'] == 'delivered'
        else
          smtperrors = p['deliverystatus']; smtperrors << ' ' << p['diagnosticcode'] unless smtperrors =~ /\A\s+\z/
          softorhard = Sisimai::SMTP::Error.soft_or_hard(o['reason'], smtperrors)
          o['hardbounce'] = true if softorhard == 'hard'
        end

        # DELIVERYSTATUS: Set a pseudo status code if the value of "deliverystatus" is empty
        if o['deliverystatus'].empty?
          smtperrors = p['replycode']; smtperrors << ' ' << p['diagnosticcode'] unless smtperrors =~ /\A\s+\z/
          permanent1 = Sisimai::SMTP::Error.is_permanent(smtperrors)
          o['deliverystatus'] = Sisimai::SMTP::Status.code(o['reason'], permanent1 ? false : true)
        end

        # REPLYCODE: Check both of the first digit of "deliverystatus" and "replycode"
        d1 = o['deliverystatus'][0, 1]
        r1 = o['replycode'][0, 1]
        o['replycode'] = '' unless d1 == r1

        unless o['action'] =~ ActionList
          if ox = Sisimai::RFC1894.field('Action: ' << o['action'])
            # Rewrite the value of "Action:" field to the valid value
            #
            #    The syntax for the action-field is:
            #       action-field = "Action" ":" action-value
            #       action-value = "failed" / "delayed" / "delivered" / "relayed" / "expanded"
            o['action'] = ox[2]
          end
        end
        o['action'] = 'delayed' if o['reason'] == 'expired'
        if o['action'].empty?
          o['action'] = 'faield' if d1.start_with?(4, 5)
        end

        listoffact << Sisimai::Fact.new(o)
      end
      return listoffact
    end

    # Emulate "softbounce" accessor for the backward compatible
    # @return   [Integer]
    def softbounce
      warn ' ***warning: Sisimai::Fact.softbounce will be removed at v5.1.0. Use Sisimai::Fact.hardbounce instead'
      return 0  if self.hardbounce
      return -1 if self.reason =~ /\A(?:delivered|feedback|vacation)\z/
      return 1
    end

    # Convert from Sisimai::Fact object to a Hash
    # @return   [Hash] Hashed data
    def damn
      data = {}
      stringdata = %w[
        action alias catch deliverystatus destination diagnosticcode diagnostictype feedbacktype
        lhost listid messageid origin reason replycode rhost senderdomain smtpagent smtpcommand
        subject timezoneoffset token
      ]

      begin
        v = {}
        stringdata.each { |e| v[e] = self.send(e.to_sym) || '' }
        v['hardbounce'] = self.hardbounce
        v['addresser']  = self.addresser.address
        v['recipient']  = self.recipient.address
        v['timestamp']  = self.timestamp.to_time.to_i
        data = v
      rescue
        warn ' ***warning: Failed to execute Sisimai::Fact.damn'
      end
      return data
    end
    alias :to_hash :damn

    # Data dumper
    # @param    [String] type   Data format: json, yaml
    # @return   [String, nil]   Dumped data or nil if the value of the first argument is neither
    #                           "json" nor "yaml"
    def dump(type = 'json')
      return nil unless %w[json yaml].include?(type)
      referclass = 'Sisimai::Fact::' << type.upcase

      begin
        require referclass.downcase.gsub('::', '/')
      rescue
        warn '***warning: Failed to load' << referclass
      end

      dumpeddata = Module.const_get(referclass).dump(self)
      return dumpeddata
    end

    # JSON handler
    # @return   [String]        JSON string converted from Sisimai::Fact
    def to_json(*)
      return self.dump('json')
    end

  end
end

