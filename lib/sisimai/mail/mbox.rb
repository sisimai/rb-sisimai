module Sisimai
  class Mail
    # Sisimai::Mail::Mbox is a mailbox file (UNIX mbox) reader.
    class Mbox
      # Imported from p5-Sisimail/lib/Sisimai/Mail/Mbox.pm
      @@roaccessors = [
        :dir,     # [String]  Directory name of the mbox
        :file,    # [String]  File name of the mbox
        :path,    # [String]  Path to mbox
        :size,    # [Integer] File size of the mbox
      ]
      @@rwaccessors = [
        :offset,  # [Integer]  Offset position for seeking
        :handle,  # [IO::File] File handle
      ]
      @@roaccessors.each { |e| attr_reader   e }
      @@rwaccessors.each { |e| attr_accessor e }

      # Constructor of Sisimai::Mail::Mbox
      # @param    [String] argv1            Path to mbox
      # @return   [Sisimai::Mail::Mbox,Nil] Object or nil if the argument is not
      #                                     specified or does not exist
      def initialize(argv1)
        raise Errno::ENOENT   unless File.exist?(argv1)
        raise 'is not a file' unless File.ftype(argv1) == 'file'

        @path   = argv1
        @dir    = File.dirname(argv1)
        @file   = File.basename(argv1)
        @size   = File.size(argv1)
        @offset = 0
        @handle = File.open(argv1, 'r')
      end

      # Mbox reader, works as an iterator.
      # @return   [String] Contents of mbox
      def read
        return nil unless self.offset < self.size

        seekoffset = self.offset || 0
        filehandle = self.handle
        readbuffer = ''
        frombuffer = ''

        begin
          seekoffset = 0 if seekoffset < 0
          filehandle.seek(seekoffset, 0)

          filehandle.each_line do |r|
            # Read the UNIX mbox file from 'From ' to the next 'From '
            if r[0, 5] == 'From ' && readbuffer.size > 0
              frombuffer = r
              break
            end
            readbuffer << r
          end

          seekoffset = filehandle.pos - frombuffer.bytesize
          frombuffer = ''
          self.offset = seekoffset
          filehandle.close unless self.offset < self.size
        end

        return readbuffer.to_s
      end
    end
  end
end

