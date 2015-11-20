require 'sisimai/version'

# Sisimai is the system formerly known as bounceHammer 4, is a Ruby module for
# analyzing bounce mails and generate structured data in a JSON format (YAML is
# also available if "YAML" module is installed on your system) from parsed bounce
# messages. Sisimai is a coined word: Sisi (the number 4 is pronounced "Si" in
# Japanese) and MAI (acronym of "Mail Analyzing Interface").
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
