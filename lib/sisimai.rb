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
    # @param    [String] path   Path to mbox or Maildir/
    # @return   [Array]         Parsed objects
    # @return   [nil]           nil if the argument was wrong or an empty array
    def make(path)
      return nil unless path

      require 'sisimai/mail'
      mail = Sisimai::Mail.new(path)
      mesg = nil
      data = nil
      list = []

      return nil unless mail
      require 'sisimai/data'
      require 'sisimai/message'

      while r = mail.read do
        # Read and parse each mail file
        mesg = Sisimai::Message.new(data: r)
        next if mesg.void
        data = Sisimai::Data.make(data: mesg)
        next unless data
        list.concat(data) if data.size > 0
      end

      return nil if list.size == 0
      return list
    end

    # Wrapper method to parse mailbox/Maildir and dump as JSON
    # @param        [String] path Path to mbox or Maildir/
    # @return       [String]      Parsed data as JSON text
    def dump(path)
      return nil unless path

      require 'json'
      parseddata = Sisimai.make(path) || []
      jsonoption = ::JSON::state.new

      jsonoption.space = ' '
      jsonoption.object_nl = ' '

      return JSON.generate(parseddata, jsonoption)
    end
  end

end
