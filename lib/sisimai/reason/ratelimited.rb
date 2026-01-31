module Sisimai
  module Reason
    # Sisimai::Reason::RateLimited checks the bounce reason is "ratelimited" or not. This class is
    # called only Sisimai::Reason class.
    #
    # This is the error that SMTP connection was rejected temporarily due to too many recipients or
    # too many concurrency connections to the remote server. This reason has added in Sisimai 4.1.26.
    #
    #   <kijitora@example.ne.jp>: host mx02.example.ne.jp[192.0.1.20] said:
    #     452 4.3.2 Connection rate limit exceeded. (in reply to MAIL FROM command)
    module RateLimited
      class << self
        Index = [
          "has exceeded the max emails per hour ",
          "please try again slower",
          "receiving mail at a rate that prevents additional messages from being delivered",
          "temporarily deferred due to unexpected volume or user complaints",
          "throttling failure: ",
          "too many errors from your ip",         # Free.fr
          "too many recipients",                  # ntt docomo
          "too many smtp sessions for this host", # Sendmail(daemon.c)
          "trop de connexions, ",
          "we have already made numerous attempts to deliver this message",
        ].freeze
        Pairs = [
          ["exceeded ", "allowable number of posts without solving a captcha"],
          ["connection ", "limit"],
          ["temporarily", "rate limited"],
          ["too many con", "s"],
        ].freeze

        def text; return 'ratelimited'; end
        def description; return 'SMTP connection rejected temporarily due to too many concurrency connections to the remote host'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [Boolean]       false: Did not match, true: Matched
        def match(argv1)
          return false if argv1.nil? || argv1.empty?
          return true  if Index.any? { |a| argv1.include?(a) }
          return true  if Pairs.any? { |a| Sisimai::String.aligned(argv1, a) }
          return false
        end

        # Rejected by domain or address filter ?
        # @param    [Sisimai::Fact] argvs   Object to be detected the reason
        # @return   [Boolean]               true:  is rate limited
        #                                   false: is not rate limited
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return true if argvs['reason'] == 'ratelimited'
          return true if Sisimai::SMTP::Status.name(argvs['deliverystatus']) == 'ratelimited'
          return match(argvs['diagnosticcode'].downcase)
        end

      end
    end
  end
end



