module Sisimai
  # Sisimai::MIME is MIME Utilities for Sisimai.
  module MIME
    # Imported from p5-Sisimail/lib/Sisimai/MIME.pm
    class << self
      require 'base64'

      # Check that the argument is MIME-Encoded string or not
      # @param    [String] argvs  String to be checked
      # @return   [True,False]    false: Not MIME encoded string
      #                           true:  MIME encoded string
      def is_mimeencoded(argv1)
        return false unless argv1

        argv1 = argv1.tr('"', '')
        return true if argv1 =~ /[\s\t]*=[?][-_0-9A-Za-z]+[?][BbQq][?].+[?]=\s*\z/
        return false
      end

      # Decode MIME-Encoded string
      # @param    [Array] argvs   Reference to an array including MIME-Encoded text
      # @return   [String]        MIME-Decoded text
      def mimedecode(argvs=[])
        return '' unless argvs
        return '' unless argvs.is_a? Array

        characterset = nil
        encodingname = nil
        mimeencoded0 = nil
        decodedtext0 = []
        decodedtext1 = nil

        argvs.each do |e|
          # Check and decode each element
          e = e.gsub(/\A\s+/, '')
          e = e.gsub(/\s+\z/, '')
          e = e.tr('"', '')

          if self.is_mimeencoded(e)
            # MIME Encoded string
            if cv = e.match(/\A=[?]([-_0-9A-Za-z]+)[?]([BbQq])[?](.+)[?]=\z/)
                # =?utf-8?B?55m954yr44Gr44KD44KT44GT?=
                characterset ||= cv[1]
                encodingname ||= cv[2]
                mimeencoded0   = cv[3]

                if encodingname == 'Q'
                    # Quoted-Printable
                    decodedtext0 << mimeencoded0.unpack('M').first

                elsif encodingname == 'B'
                    # Base64
                    decodedtext0 << Base64.decode64(mimeencoded0)
                end
            end
          else
            decodedtext0 << e
          end
        end

        return '' unless decodedtext0.size > 0
        decodedtext1 = decodedtext0.join('')

        if characterset && encodingname
          # utf8 => UTF-8
          characterset = 'UTF-8' if characterset.upcase == 'UTF8'

          if characterset.upcase != 'UTF-8'
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
      # @return [String]         MIME Decoded text
      def qprintd(argv1)
        return nil unless argv1
        return argv1.unpack('M').first
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
      def boundary(argv1=nil, start=-1)
        return nil unless argv1
        value = nil

        if cv = argv1.match(/\bboundary=([^ ]+)/)
          # Content-Type: multipart/mixed; boundary=Apple-Mail-5--931376066
          # Content-Type: multipart/report; report-type=delivery-status;
          #    boundary="n6H9lKZh014511.1247824040/mx.example.jp"
          value = cv[1]
          value = value.tr(%q|'"|, '')
        end

        value = sprintf( '--%s', value ) if start > -1
        value = sprintf( '%s--', value ) if start >  0
        return value
      end
    end

  end
end

