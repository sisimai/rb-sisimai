module Sisimai
  # Sisimai::RFC2606 checks that the domain part of the email address in the
  # argument is reserved or not.
  module RFC2606
    # Imported from p5-Sisimail/lib/Sisimai/RFC2606.pm
    class << self
      # Whether domain part is Reserved or not
      # @param    [String] dpart  Domain part
      # @return   [True,False]    true:  is Reserved top level domain
      #                           false: is NOT reserved top level domain
      # @see      http://www.ietf.org/rfc/rfc2606.txt
      def is_reserved(argv = '')
        return false unless argv
        return false unless argv.is_a?(::String)

        return true  if argv =~ /[.](?:test|example|invalid|localhost)\z/
        return true  if argv =~ /example[.](?:com|net|org|jp)\z/
        return true  if argv =~ /example[.](?:ac|ad|co|ed|go|gr|lg|ne|or)[.]jp\z/
        return false
      end
    end
  end
end
