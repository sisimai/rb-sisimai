module Sisimai
  class Mail
    # Sisimai::Mail::Memory is a class for reading an email string
    class Memory
      # Imported from p5-Sisimail/lib/Sisimai/Mail/Memory.pm
      @@roaccessors = [
        :size,    # [Integer] data size of the email text
      ]
      @@rwaccessors = [
        :data,    # [Array]   Entire bounce mail message
        :offset,  # [Integer] Index of ":data"
      ]
      @@roaccessors.each { |e| attr_reader   e }
      @@rwaccessors.each { |e| attr_accessor e }

      # Constructor of Sisimai::Mail::Memory
      # @param    [String] argv1              Entire email string
      # @return   [Sisimai::Mail::Memory,Nil] Object or nil if the argument is
      #                                       not specified or does not exist
      def initialize(argv1)
        raise 'is not a String' unless argv1.is_a? ::String
        raise 'is empty'        if argv1.empty?

        @size   = argv1.size
        @data   = []
        @offset = 0

        if argv1.start_with?('From ')
          # UNIX mbox
          @data = argv1.split(/^From /).map! { |e| e = 'From ' + e }
          @data.shift
        else
          @data = [argv1]
        end
      end

      # Memory reader, works as an iterator.
      # @return   [String] Contents of a bounce mail
      def read
        return nil unless self.data.size > 0
        self.offset += 1
        return self.data.shift
      end
    end
  end
end

