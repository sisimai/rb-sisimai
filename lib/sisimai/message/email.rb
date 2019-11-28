module Sisimai
  class Message
    # Sisimai::Message::Email convert bounce email text to data structure. It
    # resolves an email text into an UNIX From line, the header part of the mail,
    # delivery status, and RFC822 header part. When the email given as a argument
    # of "new" method is not a bounce email, the method returns nil.
    class Email
      # Imported from p5-Sisimail/lib/Sisimai/Message/Email.pm
      require 'sisimai/message'

      # Make data structure from the email message(a body part and headers)
      # @param         [Hash] argvs   Email data
      # @options argvs [String] data  Entire email message
      # @options argvs [Array]  load  User defined MTA module list
      # @options argvs [Array]  field Email header names to be captured
      # @options argvs [Array]  order The order of MTA modules
      # @options argvs [Code]   hook  Reference to callback method
      # @return        [Hash]         Resolved data structure
      def self.make(argvs)
        Sisimai::Message.warn(self.name)
        return Sisimai::Message.make(argvs)
      end
    end
  end
end

