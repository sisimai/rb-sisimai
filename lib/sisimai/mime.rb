module Sisimai
  # Sisimai::MIME is MIME Utilities for Sisimai.
  module MIME
    # Imported from p5-Sisimail/lib/Sisimai/MIME.pm
    class << self
      require 'base64'
      require 'sisimai/string'

      ReE = {
        :'7bit-encoded' => %r/^Content-Transfer-Encoding:[ ]*7bit$/im,
        :'quoted-print' => %r/^Content-Transfer-Encoding:[ ]*quoted-printable$/im,
        :'some-iso2022' => %r/^Content-Type:[ ]*.+;[ ]*charset=["']?(iso-2022-[-a-z0-9]+?)['"]?$/im,
        :'with-charset' => %r/^Content[-]Type:[ ]*.+[;][ ]*charset=['"]?(.+?)['"]?$/i,
        :'only-charset' => %r/^[\s\t]+charset=['"]?(.+?)['"]?$/i,
        :'html-message' => %r|^Content-Type:[ ]*text/html;|mi,
      }.freeze

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
        return false unless argv1

        argv1 = argv1.delete('"')
        piece = []
        mime1 = false

        if argv1 =~ /[ ]/
          # Multiple MIME-Encoded strings in a line
          piece = argv1.split(' ')
        else
          piece << argv1
        end

        piece.each do |e|
          # Check all the string in the array
          next unless e =~ /[ \t]*=[?][-_0-9A-Za-z]+[?][BbQq][?].+[?]=?[ \t]*/
          mime1 = true
        end
        return mime1
      end

      # Decode MIME-Encoded string
      # @param    [Array] argvs   Reference to an array including MIME-Encoded text
      # @return   [String]        MIME-Decoded text
      def mimedecode(argvs = [])
        return '' unless argvs
        return '' unless argvs.is_a? Array

        characterset = nil
        encodingname = nil
        mimeencoded0 = nil
        decodedtext0 = []

        notmimetext0 = ''
        notmimetext1 = ''

        argvs.each do |e|
          # Check and decode each element
          e = e.strip
          e = e.delete('"')

          if self.is_mimeencoded(e)
            # MIME Encoded string
            if cv = e.match(/\A(.*)=[?]([-_0-9A-Za-z]+)[?]([BbQq])[?](.+)[?]=?(.*)\z/)
              # =?utf-8?B?55m954yr44Gr44KD44KT44GT?=
              notmimetext0   = cv[1]
              characterset ||= cv[2]
              encodingname ||= cv[3]
              mimeencoded0   = cv[4]
              notmimetext1   = cv[5]

              decodedtext0 << notmimetext0
              if encodingname == 'Q'
                # Quoted-Printable
                decodedtext0 << mimeencoded0.unpack('M').first

              elsif encodingname == 'B'
                # Base64
                decodedtext0 << Base64.decode64(mimeencoded0)
              end
              decodedtext0 << notmimetext1
            end
          else
            decodedtext0 << e
          end
        end

        return '' unless decodedtext0.size > 0
        decodedtext1 = decodedtext0.join('')

        if characterset && encodingname
          # utf8 => UTF-8
          characterset = 'UTF-8' if characterset.casecmp('UTF8').zero?

          unless characterset.casecmp('UTF-8').zero?
            # Characterset is not UTF-8
            begin
              decodedtext1 = decodedtext1.encode('UTF-8', characterset)
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
        return argv1.unpack('M').first unless heads['content-type'].size > 0

        # Quoted-printable encoded part is the part of the text
        boundary00 = Sisimai::MIME.boundary(heads['content-type'], 0)

        # Decoded using unpack('M') entire body string when the boundary string
        # or "Content-Transfer-Encoding: quoted-printable" are not included in
        # the message body.
        return argv1.unpack('M').first if boundary00.size.zero?
        return argv1.unpack('M').first unless argv1 =~ ReE[:'quoted-print']

        boundary01 = Sisimai::MIME.boundary(heads['content-type'], 1)
        reboundary = {
          :begin => Regexp.new('\A' + Regexp.escape(boundary00)),
          :until => Regexp.new(Regexp.escape(boundary01) + '\z')
        }
        bodystring = ''
        notdecoded = ''
        getencoded = ''

        encodename = nil
        ctencoding = nil
        mimeinside = false

        argv1.split("\n").each do |e|
          # This is a multi-part message in MIME format. Your mail reader does not
          # understand MIME message format.
          # --=_gy7C4Gpes0RP4V5Bs9cK4o2Us2ZT57b-3OLnRN+4klS8dTmQ
          # Content-Type: text/plain; charset=iso-8859-15
          # Content-Transfer-Encoding: quoted-printable
          if mimeinside
            # Quoted-Printable encoded text block
            if e =~ reboundary[:begin]
              # The next boundary string has appeared
              # --=_gy7C4Gpes0RP4V5Bs9cK4o2Us2ZT57b-3OLnRN+4klS8dTmQ
              getencoded = Sisimai::String.to_utf8(notdecoded.unpack('M').first, encodename)

              bodystring += getencoded
              bodystring += e + "\n"

              notdecoded = ''
              mimeinside = false
              ctencoding = false
              encodename = nil
            else
              # Inside of Queoted printable encoded text
              notdecoded += e + "\n"
            end
          else
            # NOT Quoted-Printable encoded text block
            if e =~ /\A[-]{2}[^\s]+[^-]\z/
              # Start of the boundary block
              # --=_gy7C4Gpes0RP4V5Bs9cK4o2Us2ZT57b-3OLnRN+4klS8dTmQ
              unless e == boundary00
                # New boundary string has appeared
                boundary00 = e
                boundary01 = e + '--'
                reboundary = {
                  :begin => Regexp.new('\A' + Regexp.escape(boundary00)),
                  :until => Regexp.new(Regexp.escape(boundary01) + '\z')
                }
              end
            elsif cv = e.match(ReE[:'with-charset']) || e.match(ReE[:'only-charset'])
              # Content-Type: text/plain; charset=ISO-2022-JP
              encodename = cv[1]
              mimeinside = true if ctencoding

            elsif e =~ ReE[:'quoted-print']
              # Content-Transfer-Encoding: quoted-printable
              ctencoding = true
              mimeinside = true if encodename

            elsif e =~ reboundary[:until]
              # The end of boundary block
              # --=_gy7C4Gpes0RP4V5Bs9cK4o2Us2ZT57b-3OLnRN+4klS8dTmQ--
              mimeinside = false
            end

            bodystring += e + "\n"
          end
        end

        return bodystring
      end

      # Decode MIME BASE64 Encoded string
      # @param  [String] argv1   MIME Encoded text
      # @return [String]         MIME-Decoded text
      def base64d(argv1)
        return nil unless argv1

        plain = nil
        if cv = argv1.match(%r|([+/\=0-9A-Za-z\r\n]+)|)
          # Decode BASE64
          plain = Base64.decode64(cv[1])
        end
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
          value = value.delete(%q|'"|)
          value = sprintf('--%s', value) if start > -1
          value = sprintf('%s--', value) if start >  0
        end

        return value
      end
    end

  end
end

