module Sisimai
  # Sisimai::Mail is a handler of UNIX mbox or Maildir for reading each mail. It is
  # wrapper class of Sisimai::Mail::Mbox and Sisimai::Mail::Maildir classes.
  class Mail
    # Imported from p5-Sisimail/lib/Sisimai/Mail.pm
    @@roaccessors = [
      :path,  # [String] path to mbox or Maildir/
      :type,  # [String] Data type: mailbox, maildir, or stdin
    ]
    @@rwaccessors = [
      :mail,  # [Sisimai::Mail::Mbox, Sisimai::Mail::Maildir] Object
    ]
    @@roaccessors.each { |e| attr_reader   e }
    @@rwaccessors.each { |e| attr_accessor e }

    # Constructor of Sisimai::Mail
    # @param    [String] argv1         Path to mbox or Maildir/
    # @return   [Sisimai::Mail, Undef] Object or Undef if the argument was wrong
    def initialize(argv1)
      classname = nil
      parameter = { 'path' => argv1, 'type' => nil, 'mail' => nil }

      if argv1.is_a?(::String)
        # Path to mail or '<STDIN>' ?
        if argv1 == '<STDIN>'
          # Sisimai::Mail.new('<STDIN>')
          classname = sprintf('%s::STDIN', self.class)
          parameter['type'] = 'stdin'
          parameter['path'] = $stdin

        else
          # The argumenet is a mailbox or a Maildir/.
          mediatype = File.ftype(argv1)

          if mediatype == 'file'
            # The argument is a file, it is an mbox or email file in Maildir/
            classname = sprintf('%s::Mbox', self.class)
            parameter['type'] = 'mailbox'

          elsif mediatype == 'directory'
            # The agument is not a file, it is a Maildir/
            classname = sprintf('%s::Maildir', self.class)
            parameter['type'] = 'maildir'
          end
        end

      elsif argv1.is_a?(IO)
        # Read from STDIN
        # The argument neither a mailbox nor a Maildir/.
        classname = sprintf('%s::STDIN', self.class)
        parameter['type'] = 'stdin'

      end

      return nil unless classname

      classpath = classname.gsub('::', '/').downcase
      require classpath
      parameter['mail'] = Module.const_get(classname).new(parameter['path'])

      @path = parameter['path']
      @type = parameter['type']
      @mail = parameter['mail']
    end

    # Mbox/Maildir reader, works as an iterator.
    # @return   [String] Contents of mbox/Maildir
    def read
      return nil unless mail
      return mail.read
    end

    # Close the handle
    # @return   [True,False]  true:  Successfully closed the handle
    #                         false: Mail handle is not defined
    def close
      return false unless mail.handle
      mail.handle = nil
      return true
    end
  end
end
