module Sisimai
  # Sisimai::RFC2047 is a MIME Utilities for Sisimai.
  module RFC2047
    # Imported from p5-Sisimail/lib/Sisimai/RFC2047.pm
    class << self
      require 'base64'
      require 'sisimai/string'

      # Check that the argument is MIME-Encoded string or not
      # @param    [String] argvs  String to be checked
      # @return   [True,False]    false: Not MIME encoded string
      #                           true:  MIME encoded string
      def is_mimeencoded(argv1)
        return nil unless argv1

        text1 = argv1.delete('"')
        mime1 = false
        piece = []

        if text1.include?(' ')
          # Multiple MIME-Encoded strings in a line
          piece = text1.split(' ')
        else
          piece << text1
        end

        while e = piece.shift do
          # Check all the string in the array
          next unless e =~ /[ \t]*=[?][-_0-9A-Za-z]+[?][BbQq][?].+[?]=?[ \t]*/
          mime1 = true
        end
        return mime1
      end

      # Decode MIME-Encoded string
      # @param    [Array] argvs   An array including MIME-Encoded text
      # @return   [String]        MIME-Decoded text
      def mimedecode(argvs = [])
        ctxcharset = nil
        qbencoding = nil
        textblocks = []

        while e = argvs.shift do
          # Check and decode each element
          e = e.strip.delete('"')

          if self.is_mimeencoded(e)
            # MIME Encoded string like "=?utf-8?B?55m954yr44Gr44KD44KT44GT?="
            next unless cv = e.match(/\A(.*)=[?]([-_0-9A-Za-z]+)[?]([BbQq])[?](.+)[?]=?(.*)\z/)

            ctxcharset ||= cv[2]
            qbencoding ||= cv[3]
            notdecoded   = cv[4]

            textblocks << cv[1]
            textblocks << if qbencoding == 'B'
                              Base64.decode64(notdecoded)
                            else
                              notdecoded.unpack('M').first
                            end
            textblocks[-1].gsub!(/\r\n/, '')
            textblocks << cv[5]
          else
            textblocks << if textblocks.empty? then e else ' ' << e end
          end
        end

        return '' if textblocks.empty?
        p = textblocks.join('')

        if ctxcharset && qbencoding
          # utf8 => UTF-8
          ctxcharset = 'UTF-8' if ctxcharset.casecmp('UTF8') == 0

          unless ctxcharset.casecmp('UTF-8') == 0
            # Characterset is not UTF-8
            begin
              p .encode!('UTF-8', ctxcharset)
            rescue
              p = 'FAILED TO CONVERT THE SUBJECT'
            end
          end
        end

        return p.force_encoding('UTF-8').scrub('?')
      end

      # Find a value of specified field name from Content-Type: header
      # @param    [String] argv0  The value of Content-Type: header
      # @param    [String] argv1  Parameter name
      # @return   [String]        The value of the parameter
      # @since v5.0.0
      def ctvalue(argv0 = '', argv1 = '')
        return nil if argv0.empty?
        parameterq = argv1.size > 0 ? argv1.downcase + '=' : ''
        paramindex = argv1.size > 0 ? argv0.index(parameterq) : 0
        return '' unless paramindex

        # Find the value of the parameter name specified in argv1
        foundtoken = argv0[paramindex + parameterq.size, argv0.size].split(';', 2)[0] || ''
        foundtoken = foundtoken.downcase unless argv1 == 'boundary'
        foundtoken = foundtoken.delete('"').delete("'")
        return foundtoken
      end

      # Get a boundary string
      # @param    [String]  argv0 The value of Content-Type header
      # @param    [Integer] start -1: boundary string itself
      #                            0: Start of boundary
      #                            1: End of boundary
      # @return   [String] Boundary string
      def boundary(argv0 = '', start = -1)
        return nil if argv0.empty?
        btext = ctvalue(argv0, 'boundary')
        return '' if btext.empty?

        # Content-Type: multipart/mixed; boundary=Apple-Mail-5--931376066
        # Content-Type: multipart/report; report-type=delivery-status;
        #    boundary="n6H9lKZh014511.1247824040/mx.example.jp"
        btext = '--' + btext if start > -1
        btext = btext + '--' if start >  0
        return btext
      end

      # Decode MIME Quoted-Printable Encoded string
      # @param  [String] argv0   MIME Encoded text
      # @return [String]         MIME Decoded text
      def qprintd(argv0 = nil)
        return nil unless argv0
        return argv0.unpack('M').first.scrub('?')
      end

      # Decode MIME BASE64 Encoded string
      # @param  [String] argv0   MIME Encoded text
      # @return [String]         MIME-Decoded text
      def base64d(argv0 = nil)
        return nil unless argv0

        p = nil
        if cv = argv0.match(%r|([+/\=0-9A-Za-z\r\n]+)|) then p = Base64.decode64(cv[1]) end
        return p.force_encoding('UTF-8')
      end

      # Cut header fields except Content-Type, Content-Transfer-Encoding from multipart/* block
      # @param    [String] block  multipart/* block text
      # @param    [Boolean] heads 1 = Returns only Content-(Type|Transfer-Encoding) headers
      # @return   [Array]         Two headers and body part of multipart/* block
      # @since v5.0.0
      def haircut(block = '', heads = false)
        return nil if block.empty?

        (upperchunk, lowerchunk) = block.split("\n\n", 2)
        return ['', ''] if     upperchunk.to_s.empty?
        return ['', ''] unless upperchunk.index('Content-Type')

        headerpart = ['', ''] # ["text/plain; charset=iso-2022-jp; ...", "quoted-printable"]
        multipart1 = []       # [headerpart, "body"]

        upperchunk.split("\n").each do |e|
          # Remove fields except Content-Type:, and Content-Transfer-Encoding: in each part of 
          # multipart/* block such as the following:
          #   Date: Thu, 29 Apr 2018 22:22:22 +0900
          #   MIME-Version: 1.0
          #   Message-ID: ...
          #   Content-Transfer-Encoding: quoted-printable
          #   Content-Type: text/plain; charset=us-ascii
          if e.index('Content-Type:') == 0
            # Content-Type: ***
            v = e.split(' ', 2)[-1]
            headerpart[0] = v.index('boundary=') ? v : v.downcase

          elsif e.index('Content-Transfer-Encoding:') == 0
            # Content-Transfer-Encoding: ***
            headerpart[1] = e.split(' ', 2)[-1].downcase

          elsif e.index('boundary=') || e.index('charset=')
            # "Content-Type" field has boundary="..." or charset="utf-8"
            next if headerpart[0].empty?
            headerpart[0] << " " << e
            headerpart[0].gsub!(/\s\s+/, ' ')
          end
        end
        return headerpart if heads

        ctypevalue = headerpart[0].downcase
        ctencoding = headerpart[1]
        multipart1 = headerpart << ''

        while true do
          # Check the upper block: Make a body part at the 2nd element of multipart1
          multipart1[2] = sprintf("Content-Type: %s\n", headerpart[0])

          # Do not append Content-Transfer-Encoding: header when the part is the original message:
          # Content-Type is message/rfc822 or text/rfc822-headers, or message/delivery-status
          break if ctypevalue.index('/rfc822')
          break if ctypevalue.index('/delivery-status')
          break if ctencoding.empty?

          multipart1[2] << sprintf("Content-Transfer-Encoding: %s\n", ctencoding)
          break
        end

        while true do
          # Append LF before the lower chunk into the 2nd element of multipart1
          break if lowerchunk.empty?
          break if lowerchunk[0, 1] == "\n"

          multipart1[2] << "\n"
          break
        end
        multipart1[2] << lowerchunk
        return multipart1
      end

      # Split argv1: multipart/* blocks by a boundary string in argv0
      # @param    [String] argv0  The value of Content-Type header
      # @param    [String] argv1  A pointer to multipart/* message blocks
      # @return   [Array]         List of each part of multipart/*
      # @since v5.0.0
      def levelout(argv0 = '', argv1 = '')
        return [] if argv0.empty?
        return [] if argv1.empty?

        boundary00 = ctvalue(argv0, 'boundary'); return [] if boundary00.empty?
        boundary01 = sprintf("--%s", boundary00)
        multiparts = argv1.split(Regexp.new(Regexp.escape(boundary01) + "\n"))
        partstable = []

        multiparts.shift if multiparts[0].size  < 8
        multiparts.pop   if multiparts[-1].size < 8

        while e = multiparts.shift do
          # Check each part and breaks up internal multipart/* block
          f = haircut(e)
          if f[0].index('multipart/')
            # There is nested multipart/* block
            boundary02 = ctvalue(f[0], 'boundary'); next if boundary02.empty?
            bodyinside = f[-1].split("\n\n", 2)[-1]
            next unless bodyinside.size > 8
            next unless bodyinside.index('--' + boundary02)

            v = levelout(f[0], bodyinside)
            partstable += v if v.size > 0
          else
            # The part is not a multipart/* block
            b = f[-1].size > 0 ? f[-1] : e
            v = {
              'head' => { 'content-type' => f[0], 'content-transfer-encoding' => f[1] },
              'body' => f[0].size > 0 ? b.split("\n\n", 2)[-1] : b
            }
            partstable << v
          end
        end
        return [] if partstable.empty?

        # Remove $boundary01.'--' and strings from the boundary to the end of the body part.
        boundary01.chomp!
        b = partstable[-1]['body']
        p = b.index(boundary01 + '--')
        b[p, b.size] = "" if p

        return partstable
      end

      # Make flat multipart/* part blocks and decode
      # @param    [String] argv0  The value of Content-Type header
      # @param    [String] argv1  A pointer to multipart/* message blocks
      # @return   [String]        Message body
      def makeflat(argv0 = '', argv1 = '')
        return nil unless argv0
        return nil unless argv1
        return ''  unless argv0.index('multipart/')
        return ''  unless argv0.index('boundary=')

        # Some bounce messages include lower-cased "content-type:" field such as the followings:
        #   - content-type: message/delivery-status        => Content-Type: message/delivery-status
        #   - content-transfer-encoding: quoted-printable  => Content-Transfer-Encoding: quoted-printable
        #   - message/xdelivery-status                     => message/delivery-status
        argv1.gsub!(/[Cc]ontent-[Tt]ype:/, 'Content-Type:')
        argv1.gsub!(/[Cc]ontent-[Tt]ransfer-[Ee]ncoding:/, 'Content-Transfer-Encoding:')
        argv1.gsub!('message/xdelivery-status', 'message/delivery-stauts')

        iso2022set = %r/charset=["']?(iso-2022-[-a-z0-9]+)['"]?\b/
        multiparts = levelout(argv0, argv1)
        flattenout = ''

        while e = multiparts.shift do
          # Pick only the following parts Sisimai::Lhost will use, and decode each part
          # - text/plain, text/rfc822-headers
          # - message/delivery-status, message/rfc822, message/partial, message/feedback-report
          ctypevalue = ctvalue(e['head']['content-type']) || 'text/plain';
          istexthtml = false
          next unless ctypevalue =~ %r<\A(?:text|message)/>

          if ctypevalue == 'text/html'
            # Skip text/html part when the value of Content-Type: header in an internal part of
            # multipart/* includes multipart/alternative;
            next if argv1.index('multipart/alternative')
            istexthtml = true
          end

          ctencoding = e['head']['content-transfer-encoding']
          bodyinside = e['body']
          bodystring = ''

          if ctencoding.size > 0
            # Check the value of Content-Transfer-Encoding: header
            if ctencoding == 'base64'
              # Content-Transfer-Encoding: base64
              bodystring = base64d(bodyinside) || ''

            elsif ctencoding == 'quoted-printable'
              # Content-Transfer-Encoding: quoted-printable
              bodystring = qprintd(bodyinside) || ''

            elsif ctencoding == '7bit'
              # Content-Transfer-Encoding: 7bit
              if cv = e['head']['content-type'].downcase.match(iso2022set)
                # Content-Type: text/plain; charset=ISO-2022-JP
                bodystring = Sisimai::String.to_utf8(bodyinside, cv[1]) || ''
              else
                # No "charset" parameter in the value of Content-Type: header
                bodystring = bodyinside
              end
            else
              # Content-Transfer-Encoding: 8bit, binary, and so on
              bodystring = bodyinside
            end

            if istexthtml
              # Try to delete HTML tags inside of text/html part whenever possible
              bodystring = Sisimai::String.to_plain(bodystring) || ''
            end
            next if bodystring.empty?

            # The body string will be encoded to UTF-8 forcely and call String#scrub method to 
            # avoid the following errors:
            #   - incompatible character encodings: ASCII-8BIT and UTF-8
            #   - invalid byte sequence in UTF-8
            unless bodystring.encoding.to_s == 'UTF-8'
              # ASCII-8BIT or other 8bit encodings
              ctxcharset = ctvalue(e['head']['content-type'], 'charset')
              if ctxcharset.empty?
                # The part which has no "charset" parameter causes an ArgumentError:
                # invalid byte sequence in UTF-8 so String#scrub should be called
                bodystring.scrub!('?')
              else
                # ISO-8859-1, GB2312, and so on
                bodystring = Sisimai::String.to_utf8(bodystring, ctxcharset) || ''
              end
              bodystring << "\n\n"
            end

            bodystring.gsub!(/\r\n/, "\n") if bodystring.include?("\r\n") # Convert CRLF to LF

          else
            # There is no Content-Transfer-Encoding header in the part
            bodystring << e['body']
          end

          if ctypevalue =~ %r</(?:delivery-status|rfc822)>
            # Add Content-Type: header of each part (will be used as a delimiter at Sisimai::Lhost) into
            # the body inside when the value of Content-Type: is message/delivery-status, message/rfc822,
            # or text/rfc822-headers
            bodystring = sprintf("Content-Type: %s\n%s", ctypevalue, bodystring)
          end

          # Append "\n" when the last character of $bodystring is not LF
          bodystring << "\n\n" unless bodystring[-2, 2] == "\n\n"
          flattenout << bodystring
        end

        return flattenout
      end

    end
  end
end

