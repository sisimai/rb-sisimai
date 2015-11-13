require 'sisimai/version'

module Sisimai
  # Imported from p5-Sisimail/lib/Sisimai.pm
  class << self
    def version(); return Sisimai::VERSION; end
    def sysname(); return 'bouncehammer';   end
    def libname(); return 'Sisimai';        end

    # Wrapper method for parsing mailbox/maidir
    # @param    [String] mbox   Path to mbox or Maildir/
    # @return   [Array]         Parsed objects
    # @return   [nil]           nil if the argument was wrong or an empty array
    def make(path)
    end

    # Wrapper method to parse mailbox/Maildir and dump as JSON
    # @param        [String] mbox Path to mbox or Maildir/
    # @return       [String] Parsed data as JSON text
    def dump(path)
    end
  end

end
