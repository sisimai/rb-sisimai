module Sisimai
  class Mail
    # Sisimai::Mail::STDIN is a reader for getting contents of each email from
    # STDIN
    class STDIN
      # Imported from p5-Sisimail/lib/Sisimai/Mail/STDIN.pm
      # :path   [String]  Fixed string "<STDIN>"
      # :name   [String]  File name of the mbox
      # :size   [Integer] File size of the mbox
      # :offset [Integer]  Offset position for seeking
      # :handle [IO::File] File handle
      attr_reader :path, :name, :size
      attr_accessor :offset, :handle

      # Constructor of Sisimai::Mail::STDIN
      # @param    [IO::STDIN] stdin      Standard-In
      # @return   [Sisimai::Mail::STDIN] Object
      def initialize(stdin = $stdin)
        raise 'is not an IO object' unless stdin.is_a?(IO)

        @path   = '<STDIN>'
        @name   = '<STDIN>'
        @size   = nil
        @offset = 0
        @handle = stdin
      end

      # Mbox reader, works as a iterator.
      # @return   [String] Contents of mbox
      def read
        readhandle = self.handle
        readbuffer = ''

        if readhandle
          return nil if readhandle.closed?
        end

        begin
          readhandle = STDIN unless readhandle
          while r = readhandle.gets
            break if readbuffer.size > 0 && r.start_with?('From ')
            readbuffer << r
          end
        ensure
          readhandle.close
        end

        return readbuffer
      end
    end
  end
end

