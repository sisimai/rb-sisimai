module Sisimai
  module Reason
    # Sisimai::Reason::SecurityError checks the bounce reason is "securityerror"
    # or not. This class is called only Sisimai::Reason class.
    #
    # This is the error that a security violation was detected on a destination
    # mail server. Depends on the security policy on the server, there is any
    # virus in the email, a sender's email address is camouflaged address.
    # Sisimai will set "securityerror" to the reason of email bounce if the value
    # of Status: field in a bounce email is "5.7.*".
    #   Status: 5.7.0
    #   Remote-MTA: DNS; gmail-smtp-in.l.google.com
    #   Diagnostic-Code: SMTP; 552-5.7.0 Our system detected an illegal attachment
    #                    on your message. Please
    module SecurityError
      # Imported from p5-Sisimail/lib/Sisimai/Reason/SecurityError.pm
      class << self
        def text; return 'securityerror'; end
        def description
          return 'Email rejected due to security violation was detected on a destination host'
        end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          regex = %r{(?>
             authentication[ ](?:
               failed;[ ]server[ ].+[ ]said:  # Postfix
              |turned[ ]on[ ]in[ ]your[ ]email[ ]client
              )
            |\d+[ ]denied[ ]\[[a-z]+\][ ].+[(]Mode:[ ].+[)]
            |because[ ](?>
               the[ ]recipient[ ]is[ ]not[ ]accepting[ ]mail[ ]with[ ](?:
                 attachments        # AOL Phoenix
                |embedded[ ]images  # AOL Phoenix
                )
              )
            |domain[ ].+[ ]is[ ]a[ ]dead[ ]domain
            |email[ ](?:
               not[ ]accepted[ ]for[ ]policy[ ]reasons
              # http://kb.mimecast.com/Mimecast_Knowledge_Base/Administration_Console/Monitoring/Mimecast_SMTP_Error_Codes#554
              |rejected[ ]due[ ]to[ ]security[ ]policies
              )
            |Executable[ ]files[ ]are[ ]not[ ]allowed[ ]in[ ]compressed[ ]files
            |insecure[ ]mail[ ]relay
            |sorry,[ ]you[ ]don'?t[ ]authenticate[ ]or[ ]the[ ]domain[ ]isn'?t[ ]in[ ]my[ ]list[ ]of[ ]allowed[ ]rcpthosts
            |the[ ]message[ ]was[ ]rejected[ ]because[ ]it[ ]contains[ ]prohibited[ ]virus[ ]or[ ]spam[ ]content
            |TLS[ ]required[ ]but[ ]not[ ]supported # SendGrid
            |you[ ]are[ ]not[ ]authorized[ ]to[ ]send[ ]mail,[ ]authentication[ ]is[ ]required
            |You[ ]have[ ]exceeded[ ]the[ ]the[ ]allowable[ ]number[ ]of[ ]posts[ ]without[ ]solving[ ]a[ ]captcha
            |verification[ ]failure
            )
          }ix

          return true if argv1 =~ regex
          return false
        end

        # The bounce reason is security error or not
        # @param    [Sisimai::Data] argvs   Object to be detected the reason
        # @return   [True,False]            true: is security error
        #                                   false: is not security error
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(_argvs)
          return nil
        end

      end
    end
  end
end



