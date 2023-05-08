module Sisimai
  module SMTP
    # Sisimai::SMTP::Transcript is a parser for transcript logs of SMTP session
    module Transcript
      class << self
        require 'sisimai/smtp/reply'
        require 'sisimai/smtp/status'

        #  Parse a transcript of an SMTP session and makes structured data
        # @param    [String] argv0  A transcript text MTA returned
        # @param    [String] argv1  A label string of a SMTP client
        # @apram    [String] argv2  A label string of a SMTP server
        # @return   [Array]         Structured data
        #           [Nil]           Failed to parse or the 1st argument is missing
        # @since v5.0.0
        def rise(argv0 = '', argv1 = '>>>', argv2 = '<<<')
          return nil if argv0.size == 0

          # 1. Replace label strings of SMTP client/server at the each line
          argv0.gsub!(/^[ ]+#{argv1}\s+/m, '>>> '); return nil unless argv0.include?('>>> ')
          argv0.gsub!(/^[ ]+#{argv2}\s+/m, '<<< '); return nil unless argv0.include?('<<< ')

          # 2. Remove strings until the first '<<<' or '>>>'
          esmtp = []
          table = lambda do
            return {
              'command'   => nil, # SMTP command
              'argument'  => '',  # An argument of each SMTP command sent from a client
              'parameter' => {},  # Parameter pairs of the SMTP command
              'response'  => {    # A Response from an SMTP server
                  'reply'  => '', # - SMTP reply code such as 550
                  'status' => '', # - SMTP status such as 5.1.1
                  'text'   => [], # - Response text lines
              }
            }
          end
          parameters = ''   # Command parameters of MAIL, RCPT
          cursession = nil  # Current session for $esmtp

          cv = ''
          p0 = argv0.index('<<<') || -1 # Server response
          p1 = argv0.index('>>>') || -1 # Sent command
          if p0 < p1
            # An SMTP server response starting with '<<<' is the first
            esmtp << table.call
            cursession = esmtp[-1]
            cursession['command'] = 'CONN'
            argv0 = argv0[p0, argv0.size] if p0 > -1
          else
            # An SMTP command starting with '>>>' is the first
            argv0 = argv0[p1, argv0.size] if p1 > -1
          end

          # 3. Remove unused lines, concatenate folded lines
          argv0 = argv0[0, argv0.index("\n\n") - 1] # Remove strings from the first blank line to the tail
          argv0.gsub!(/\n[ ]+/m, ' ')               # Concatenate folded lines to each previous line

          argv0.split("\n").each do |e|
            # 4. Read each SMTP command and server response
            if e.start_with?('>>> ')
              # SMTP client sent a command ">>> SMTP-command arguments"
              if cv = e.match(/\A>>>[ ]([A-Z]+)[ ]?(.*)\z/)
                # >>> SMTP Command
                thecommand = cv[1]
                commandarg = cv[2]

                esmtp << table.call
                cursession = esmtp[-1]
                cursession['command'] = thecommand.upcase

                if thecommand =~ /\A(?:MAIL|RCPT|XFORWARD)/
                  # MAIL or RCPT
                  if cv = commandarg.match(/\A(?:FROM|TO):[ ]*<(.+[@].+)>[ ]*(.*)\z/)
                    # >>> MAIL FROM: <neko@example.com> SIZE=65535
                    # >>> RCPT TO: <kijitora@example.org>
                    cursession['argument'] = cv[1]
                    parameters = cv[2]

                  else
                    # >>> XFORWARD NAME=neko2-nyaan3.y.example.co.jp ADDR=230.0.113.2 PORT=53672
                    # <<< 250 2.0.0 Ok
                    # >>> XFORWARD PROTO=SMTP HELO=neko2-nyaan3.y.example.co.jp IDENT=2LYC6642BLzFK3MM SOURCE=REMOTE
                    # <<< 250 2.0.0 Ok
                    parameters = commandarg
                    commandarg = ''
                  end

                  parameters.split(" ").each do |p|
                    # SIZE=22022, PROTO=SMTP, and so on
                    if cv = p.match(/\A([^ =]+)=([^ =]+)\z/) then cursession['parameter'][cv[1].downcase] = cv[2] end
                  end
                else
                  # HELO, EHLO, AUTH, DATA, QUIT or Other SMTP command
                  cursession['argument'] = commandarg
                end
              end
            else
              # SMTP server sent a response "<<< response text"
              p = e.index('<<< '); next unless p == 0

              e = e[4, e.size]

              e.sub!(/\A<<<[ ]/, '')
              if cv = e.match(/\A([2-5]\d\d)[ ]/) then cursession['response']['reply'] = cv[1] end
              if cv = e.match(/\A[245]\d\d[ ]([245][.]\d{1,3}[.]\d{1,3})[ ]/) then cursession['response']['status'] = cv[1] end
              cursession['response']['text'] << e
            end
          end

          return nil if esmtp.size == 0
          return esmtp
        end




          


      end
    end
  end
end

