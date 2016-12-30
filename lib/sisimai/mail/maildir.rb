module Sisimai
  class Mail
    # Sisimai::Mail::Maildir is a reader for getting contents of each email in the
    # Maildir/ directory.
    class Maildir
      # Imported from p5-Sisimail/lib/Sisimai/Mail/Maildir.pm
      @@roaccessors = [
        :dir,     # [String] Path to Maildir/
        :size,    # [Integer] The number of entires in the directory
      ]
      @@rwaccessors = [
        :path,    # [String] Path to each file
        :file,    # [String] Each file name of a mail in the Maildir/
        :inodes,  # [Array]  i-node List of files in the Maildir/
        :count,   # [Integer] The number of file has read
        :handle,  # [IO::Dir] Directory handle
      ]
      @@roaccessors.each { |e| attr_reader   e }
      @@rwaccessors.each { |e| attr_accessor e }

      # Constructor of Sisimai::Mail::Maildir
      # @param    [String] argvs                Path to Maildir/
      # @return   [Sisimai::Mail::Maildir,Nil]  Object or nil if the argument is
      #                                         not a directory or does not exist
      def initialize(argv1)
        raise Errno::ENOENT  unless File.exist?(argv1)
        raise Errno::ENOTDIR unless File.ftype(argv1) == 'directory'

        @path   = nil
        @size   = Dir.entries(argv1).size
        @dir    = argv1
        @file   = nil
        @inodes = {}
        @count  = 0
        @handle = Dir.open(argv1)
      end

      # Maildir reader, works as a iterator.
      # @return       [String] Contents of file in Maildir/
      def read
        return nil unless self.count < self.size

        seekhandle = self.handle
        readbuffer = ''

        begin
          while r = seekhandle.read do
            # Read each file in the directory
            next if r == '.' || r == '..'

            emailindir = sprintf('%s/%s', self.dir, r)
            emailindir = emailindir.squeeze('/')

            next unless File.ftype(emailindir) == 'file'
            next unless File.size(emailindir) > 0
            next unless File.readable?(emailindir)

            emailinode = File.stat(emailindir).ino
            next if self.inodes.key?(emailinode)

            filehandle = File.open(emailindir, 'r:UTF-8')
            readbuffer = filehandle.read
            filehandle.close

            self.inodes[emailinode] = 1
            self.path = emailindir
            self.file = r

            break
          end

          self.count += 1
          seekhandle.close unless self.count < self.size
        end

        return readbuffer
      end

    end
  end
end

