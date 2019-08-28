module Sisimai
  # Sisimai::MIME is MIME Utilities for Sisimai.
  module MIME
    # Imported from p5-Sisimail/lib/Sisimai/MIME.pm
    class << self
      require 'base64'
      require 'sisimai/string'

      ReE = {
        :'7bit-encoded' => %r/^content-transfer-encoding:[ ]*7bit/m,
        :'quoted-print' => %r/^content-transfer-encoding:[ ]*quoted-printable/m,
        :'some-iso2022' => %r/^content-type:[ ]*.+;[ ]*charset=["']?(iso-2022-[-a-z0-9]+?)['"]?\b/m,
        :'another-8bit' => %r/^content-type:[ ]*.+;[ ]*charset=["']?(.+?)['"]?\b/m,
        :'with-charset' => %r/^content[-]type:[ ]*.+[;][ ]*charset=['"]?(.+?)['"]?\b/,
        :'only-charset' => %r/^[\s\t]+charset=['"]?(.+?)['"]?\b/,
        :'html-message' => %r|^content-type:[ ]*text/html;|m,
      }.freeze
      AlsoAppend = %r{\A(?:text/rfc822-headers|message/)}.freeze
      ThisFormat = %r/\A(?:Content-Transfer-Encoding:\s*.+\n)?Content-Type:\s*([^ ;\s]+)/.freeze
      LeavesOnly = %r{\A(?>
         text/(?:plain|html|rfc822-headers)
        |message/(?:x?delivery-status|rfc822|partial|feedback-report)
        |multipart/(?:report|alternative|mixed|related|partial)
        )
      }x.freeze

      # Make MIME-Encoding and Content-Type related headers regurlar expression
      # @return   [Array] Regular expressions related to MIME encoding
      def patterns
        return ReE
      end

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
        characterset = nil
        encodingname = nil
        decodedtext0 = []

        while e = argvs.shift do
          # Check and decode each element
          e = e.strip.delete('"')

          if self.is_mimeencoded(e)
            # MIME Encoded string like "=?utf-8?B?55m954yr44Gr44KD44KT44GT?="
            next unless cv = e.match(/\A(.*)=[?]([-_0-9A-Za-z]+)[?]([BbQq])[?](.+)[?]=?(.*)\z/)

            characterset ||= cv[2]
            encodingname ||= cv[3]
            mimeencoded0   = cv[4]

            decodedtext0 << cv[1]
            decodedtext0 << if encodingname == 'B'
                              Base64.decode64(mimeencoded0)
                            else
                              mimeencoded0.unpack('M').first
                            end
            decodedtext0[-1].gsub!(/\r\n/, '')
            decodedtext0 << cv[5]
          else
            decodedtext0 << if decodedtext0.empty? then e else ' ' << e end
          end
        end

        return '' if decodedtext0.empty?
        decodedtext1 = decodedtext0.join('')

        if characterset && encodingname
          # utf8 => UTF-8
          characterset = 'UTF-8' if characterset.casecmp('UTF8') == 0

          unless characterset.casecmp('UTF-8') == 0
            # Characterset is not UTF-8
            begin
              decodedtext1.encode!('UTF-8', characterset)
            rescue
              decodedtext1 = 'FAILED TO CONVERT THE SUBJECT'
            end
          end
        end

        return decodedtext1.force_encoding('UTF-8')
      end

      # Decode MIME Quoted-Printable Encoded string
      # @param  [String] argv1   MIME Encoded text
      # @param  [Hash]   heads   Email header
      # @return [String]         MIME Decoded text
      def qprintd(argv1 = nil, heads = {})
        return nil unless argv1
        return argv1.unpack('M').first unless heads['content-type']
        return argv1.unpack('M').first if heads['content-type'].empty?

        # Quoted-printable encoded part is the part of the text
        boundary00 = Sisimai::MIME.boundary(heads['content-type'], 0)

        # Decoded using unpack('M') entire body string when the boundary string
        # or "Content-Transfer-Encoding: quoted-printable" are not included in
        # the message body.
        return argv1.unpack('M').first if boundary00.empty?
        return argv1.unpack('M').first unless argv1.downcase =~ ReE[:'quoted-print']

        boundary01 = Sisimai::MIME.boundary(heads['content-type'], 1)
        bodystring = ''
        notdecoded = ''

        encodename = nil
        ctencoding = nil
        mimeinside = false
        hasdivided = argv1.split("\n")

        while e = hasdivided.shift do
          # This is a multi-part message in MIME format. Your mail reader does not
          # understand MIME message format.
          # --=_gy7C4Gpes0RP4V5Bs9cK4o2Us2ZT57b-3OLnRN+4klS8dTmQ
          # Content-Type: text/plain; charset=iso-8859-15
          # Content-Transfer-Encoding: quoted-printable
          if mimeinside
            # Quoted-Printable encoded text block
            if e == boundary00
              # The next boundary string has appeared
              # --=_gy7C4Gpes0RP4V5Bs9cK4o2Us2ZT57b-3OLnRN+4klS8dTmQ
              hasdecoded = Sisimai::String.to_utf8(notdecoded.unpack('M').first, encodename)
              bodystring << hasdecoded << e + "\n"

              notdecoded = ''
              mimeinside = false
              ctencoding = false
              encodename = nil
            else
              # Inside of Quoted-Printable encoded text
              if e.size > 76
                # Invalid line exists in "quoted-printable" part
                e = [e].pack('M').chomp
              else
                # A bounce message generated by Office365(Outlook) include lines
                # which are not proper as Quoted-Printable:
                #   - `=` is not encoded
                #   - Longer than 76 charaters a line
                #
                # Content-Transfer-Encoding: quoted-printable
                # X-Microsoft-Exchange-Diagnostics:
                #     1;SLXP216MB0381;27:IdH7U/WHGgJu6J8lFrE7KvVxhnAwyKrNbSXMFYs3/Gzz6ZdXYYjzHj55K2O+cndpeVwkvBJqmo6y0IF4AhLfHtFzznw/BzhERU6wi/TCWRpyjYuW8v0/aTcflH3oAdgZ4Pwrp7PxLiiA8rYgU/E7SQ==
                # ...
                mustencode = true
                while true do
                  break if e.end_with?(' ', "\t")
                  break if e.split('').any? { |c| c.ord < 32 || c.ord > 126 }
                  if e.end_with?('=')
                    # Padding character of Base64 or not
                    break if e =~ /[\+\/0-9A-Za-z]{32,}[=]+\z/
                  else
                    if e.include?('=') && ! e.upcase.include?('=3D')
                      # Including "=" not as "=3D"
                      break
                    end
                  end
                  mustencode = false
                  break
                end
                e = [e].pack('M').chomp if mustencode
                mustencode = false
              end
              notdecoded << e + "\n"
            end
          else
            # NOT Quoted-Printable encoded text block
            lowercased = e.downcase
            if e =~ /\A[-]{2}[^\s]+[^-]\z/
              # Start of the boundary block
              # --=_gy7C4Gpes0RP4V5Bs9cK4o2Us2ZT57b-3OLnRN+4klS8dTmQ
              unless e == boundary00
                # New boundary string has appeared
                boundary00 = e
                boundary01 = e + '--'
              end
            elsif cv = lowercased.match(ReE[:'with-charset']) || lowercased.match(ReE[:'only-charset'])
              # Content-Type: text/plain; charset=ISO-2022-JP
              encodename = cv[1]
              mimeinside = true if ctencoding

            elsif lowercased =~ ReE[:'quoted-print']
              # Content-Transfer-Encoding: quoted-printable
              ctencoding = true
              mimeinside = true if encodename

            elsif e == boundary01
              # The end of boundary block
              # --=_gy7C4Gpes0RP4V5Bs9cK4o2Us2ZT57b-3OLnRN+4klS8dTmQ--
              mimeinside = false
            end

            bodystring << e + "\n"
          end
        end

        bodystring << notdecoded unless notdecoded.empty?
        return bodystring
      end

      # Decode MIME BASE64 Encoded string
      # @param  [String] argv1   MIME Encoded text
      # @return [String]         MIME-Decoded text
      def base64d(argv1)
        return nil unless argv1

        plain = nil
        if cv = argv1.match(%r|([+/\=0-9A-Za-z\r\n]+)|) then plain = Base64.decode64(cv[1]) end
        return plain.force_encoding('UTF-8')
      end

      # Get boundary string
      # @param    [String]  argv1 The value of Content-Type header
      # @param    [Integer] start -1: boundary string itself
      #                            0: Start of boundary
      #                            1: End of boundary
      # @return   [String] Boundary string
      def boundary(argv1 = nil, start = -1)
        return nil unless argv1
        value = ''

        if cv = argv1.match(/\bboundary=([^ ]+)/i)
          # Content-Type: multipart/mixed; boundary=Apple-Mail-5--931376066
          # Content-Type: multipart/report; report-type=delivery-status;
          #    boundary="n6H9lKZh014511.1247824040/mx.example.jp"
          value = cv[1]
          value.delete!(%q|'";\\|)
          value = '--' + value if start > -1
          value = value + '--' if start >  0
        end

        return value
      end

      # Breaks up each multipart/* block
      # @param    [String] argv0 Text block of multipart/*
      # @param    [String] argv1 MIME type of the outside part
      # @return   [String] Decoded part as a plain text(text part only)
      def breaksup(argv0 = nil, argv1 = '')
        return nil unless argv0

        hasflatten = '' # Message body including only text/plain and message/*
        mimeformat = '' # MIME type string of this part
        alternates = argv1.start_with?('multipart/alternative') ? true : false

        # Get MIME type string from Content-Type: "..." field at the first line
        # or the second line of the part.
        if cv = argv0.match(ThisFormat) then mimeformat = cv[1].downcase end

        # Sisimai require only MIME types defined in LeavesOnly variable
        return '' unless mimeformat =~ LeavesOnly
        return '' if alternates && mimeformat == 'text/html'

        (upperchunk, lowerchunk) = argv0.split(/^$/m, 2)
        upperchunk.tr!("\n", ' ').squeeze(' ')

        # Content-Description: Undelivered Message
        # Content-Type: message/rfc822
        # <EOM>
        lowerchunk ||= ''

        if mimeformat.start_with?('multipart/')
          # Content-Type: multipart/*
          mpboundary = Regexp.new(Regexp.escape(Sisimai::MIME.boundary(upperchunk, 0)) << "\n")
          innerparts = lowerchunk.split(mpboundary)

          innerparts.shift if innerparts[0].empty?
          while e = innerparts.shift do
            # Find internal multipart/* blocks and decode
            if cv = e.match(ThisFormat)
              # Found "Content-Type" field at the first or second line of this
              # splitted part
              nextformat = cv[1].downcase

              next unless nextformat =~ LeavesOnly
              next if nextformat == 'text/html'

              hasflatten << Sisimai::MIME.breaksup(e, mimeformat)
            else
              # The content of this part is almost '--': a part of boundary
              # string which is used for splitting multipart/* blocks.
              hasflatten << "\n"
            end
          end
        else
          # Is not "Content-Type: multipart/*"
          if cv = upperchunk.match(/Content-Transfer-Encoding: ([^\s;]+)/)
            # Content-Transfer-Encoding: quoted-printable|base64|7bit|...
            ctencoding = cv[1].downcase
            getdecoded = ''

            if ctencoding == 'quoted-printable'
              # Content-Transfer-Encoding: quoted-printable
              getdecoded = Sisimai::MIME.qprintd(lowerchunk)

            elsif ctencoding == 'base64'
              # Content-Transfer-Encoding: base64
              getdecoded = Sisimai::MIME.base64d(lowerchunk)

            elsif ctencoding == '7bit'
              # Content-Transfer-Encoding: 7bit
              if cv = upperchunk.downcase.match(ReE[:'some-iso2022'])
                # Content-Type: text/plain; charset=ISO-2022-JP
                getdecoded = Sisimai::String.to_utf8(lowerchunk, cv[1])
              else
                # No "charset" parameter in Content-Type field
                getdecoded = lowerchunk
              end
            else
              # Content-Transfer-Encoding: 8bit, binary, and so on
              getdecoded = lowerchunk
            end
            getdecoded.gsub!(/\r\n/, "\n") if getdecoded.include?("\r\n") # Convert CRLF to LF

            if mimeformat =~ AlsoAppend
              # Append field when the value of Content-Type: begins with
              # message/ or equals text/rfc822-headers.
              upperchunk.sub!(/Content-Transfer-Encoding:\s*[^\s]+./, '').strip!
              hasflatten << upperchunk

            elsif mimeformat == 'text/html'
              # Delete HTML tags inside of text/html part whenever possible
              getdecoded.gsub!(/[<][^@ ]+?[>]/, '')
            end

            unless getdecoded.empty?
              # The string will be encoded to UTF-8 forcely and call String#scrub
              # method to avoid the following errors:
              #   - incompatible character encodings: ASCII-8BIT and UTF-8
              #   - invalid byte sequence in UTF-8
              unless getdecoded.encoding.to_s == 'UTF-8'
                if cv = upperchunk.downcase.match(ReE[:'another-8bit'])
                  # ISO-8859-1, GB2312, and so on
                  getdecoded = Sisimai::String.to_utf8(getdecoded, cv[1])
                end
              end
              # A part which has no "charset" parameter causes an ArgumentError:
              # invalid byte sequence in UTF-8 so String#scrub should be called
              hasflatten << getdecoded.scrub!('?') << "\n\n"
            end
          else
            # Content-Type: text/plain OR text/rfc822-headers OR message/*
            if mimeformat.start_with?('message/') || mimeformat == 'text/rfc822-headers'
              # Append headers of multipart/* when the value of "Content-Type"
              # is inlucded in the following MIME types:
              #  - message/delivery-status
              #  - message/rfc822
              #  - text/rfc822-headers
              hasflatten << upperchunk
            end
            lowerchunk.sub!(/^--\z/m, '')
            lowerchunk << "\n" unless lowerchunk =~ /\n\z/
            hasflatten << lowerchunk
          end
        end

        return hasflatten
      end

      # MIME decode entire message body
      # @param    [String] argv0 Content-Type header
      # @param    [String] argv1 Entire message body
      # @return   [String] Decoded message body
      def makeflat(argv0 = nil, argv1 = nil)
        return nil unless argv0
        return nil unless argv1

        ehboundary = Sisimai::MIME.boundary(argv0, 0)
        mimeformat = ''
        bodystring = ''

        # Get MIME type string from an email header given as the 1st argument
        if cv = argv0.match(%r|\A([0-9a-z]+/[^ ;]+)|) then mimeformat = cv[1] end

        return '' unless mimeformat.include?('multipart/')
        return '' if ehboundary.empty?

        # Some bounce messages include lower-cased "content-type:" field such as
        #   content-type: message/delivery-status
        #   content-transfer-encoding: quoted-printable
        argv1.gsub!(/[Cc]ontent-[Tt]ype:/m, 'Content-Type:')
        argv1.gsub!(/[Cc]ontent-[Tt]ransfer-[Ee]ncodeing:/m, 'Content-Transfer-Encoding:')

        # 1. Some bounce messages include upper-cased "Content-Transfer-Encoding",
        #    and "Content-Type" value such as
        #      - Content-Type: multipart/RELATED;
        #      - Content-Transfer-Encoding: 7BIT
        # 2. Unused fields inside of mutipart/* block should be removed
        argv1.gsub!(/(Content-[A-Za-z-]+?):[ ]*([^\s]+)/) do "#{$1}: #{$2.downcase}" end
        argv1.gsub!(/^Content-(?:Description|Disposition):.+?$/, '')

        multiparts = argv1.split(Regexp.new(Regexp.escape(ehboundary) << "\n"))
        multiparts.shift if multiparts[0].empty?

        while e = multiparts.shift do
          # Find internal multipart blocks and decode
          catch :XCCT do
            while true
              # Remove fields except Content-Type, Content-Transfer-Encoding in
              # each part such as the following:
              #   Date: Thu, 29 Apr 2018 22:22:22 +0900
              #   MIME-Version: 1.0
              #   Message-ID: ...
              #   Content-Transfer-Encoding: quoted-printable
              #   Content-Type: text/plain; charset=us-ascii
              throw :XCCT if e =~ /\AContent-T[ry]/
              if cv = e.match(/\A(.+?)Content-Type:/)
                throw :XCCT if cv[1] =~ /\n\n/
              end
              e.sub!(/\A.+?(Content-T[ry].+)\z/, '\1')
              throw :XCCT
            end
          end

          if e =~ /\A(?:Content-[A-Za-z-]+:.+?\r\n)?Content-Type:[ ]*[^\s]+/
            # Content-Type: multipart/*
            bodystring << Sisimai::MIME.breaksup(e, mimeformat)
          else
            # Is not multipart/* block
            e.sub!(%r|^Content-Transfer-Encoding:.+?\n|mi, '')
            e.sub!(%r|^Content-Type:\s*text/plain.+?\n|mi, '')
            bodystring << e
          end
        end
        bodystring.gsub!(%r{^(Content-Type:\s*message/(?:rfc822|delivery-status)).+$}, '\1')
        bodystring.gsub!(/^\n{2,}/, "\n")

        return bodystring
      end

    end
  end
end

