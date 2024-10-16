module Sisimai::Lhost
  # Sisimai::Lhost::GoogleGroups decodes a bounce email which created by Google Groups https://groups.google.com.
  # Methods in the module are called from only Sisimai::Message.
  module GoogleGroups
    class << self
      require 'sisimai/lhost'
      Boundaries = ['----- Original message -----'].freeze

      # @abstract Decodes the bounce message from Google Groups
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to decode or the arguments are missing
      # @since v4.25.6
      def inquire(mhead, mbody)
        return nil unless mhead['from'].end_with?('<mailer-daemon@googlemail.com>')
        return nil unless mhead['subject'].start_with?('Delivery Status Notification')
        return nil unless mhead['x-failed-recipients']
        return nil unless mhead['x-google-smtp-source']

        # Hello kijitora@libsisimai.org,
        #
        # We're writing to let you know that the group you tried to contact (group-name)
        # may not exist, or you may not have permission to post messages to the group.
        # A few more details on why you weren't able to post:
        #
        #  * You might have spelled or formatted the group name incorrectly.
        #  * The owner of the group may have removed this group.
        #  * You may need to join the group before receiving permission to post.
        #  * This group may not be open to posting.
        #
        # If you have questions related to this or any other Google Group,
        # visit the Help Center at https://groups.google.com/support/.
        #
        # Thanks,
        #
        # Google Groups
        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailparts = Sisimai::RFC5322.part(mbody, Boundaries)
        recipients = 0
        v = dscontents[-1]

        # * You might have spelled or formatted the group name incorrectly.
        # * The owner of the group may have removed this group.
        # * You may need to join the group before receiving permission to post.
        # * This group may not be open to posting.
        entiremesg = emailparts[0].split(/\n\n/, 5).slice(0, 4).join(' ').tr("\n", ' ');
        receivedby = mhead['received'] || []
        recordwide = {
          'diagnosis' => Sisimai::String.sweep(entiremesg),
          'reason'    => 'onhold',
          'rhost'     => Sisimai::RFC5322.received(receivedby[0])[1],
        }
        recordwide['reason'] = 'rejected' if emailparts[0].scan(/^[ ]?[*][ ]?/).size == 4

        mhead['x-failed-recipients'].split(',').each do |e|
          # X-Failed-Recipients: neko@example.jp, nyaan@example.org, ...
          next unless Sisimai::Address.is_emailaddress(e)

          if v['recipient']
            # There are multiple recipient addresses in the message body.
            dscontents << Sisimai::Lhost.DELIVERYSTATUS
            v = dscontents[-1]
          end
          v['recipient'] = Sisimai::Address.s3s4(e)
          recipients += 1
          recordwide.each_key { |r| v[r] = recordwide[r] }
        end
        return nil unless recipients > 0
        return { 'ds' => dscontents, 'rfc822' => emailparts[1] }
      end
      def description; return 'Google Groups: https://groups.google.com'; end
    end
  end
end

