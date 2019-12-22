require 'spec_helper'
require 'sisimai/message'

SampleEmails = [
  'email-domino-03.eml',
  'email-mfilter-04.eml',
]

describe 'CallbackMethod' do
  callbackto = lambda do |argv|
    catch = { 'passed' => false, 'base64' => false }

    argv['message'].split(/\n/).each do |v|
      next unless v =~ %r|\A[0-9A-Za-z=/]{32,64}\z|
      catch['base64'] = true
      break
    end
    catch['passed'] = true
    return catch
  end

  SampleEmails.each do |e|
    pathtomail = './set-of-emails/maildir/bsd/' + e
    mailstring = File.open(pathtomail).read
    example(pathtomail + 'is not empty') { expect(mailstring.size).to be > 0 }

    messageobj = Sisimai::Message.new(data: mailstring, hook: callbackto)
    describe '.new' do
      it('returns Sisimai::Message object') { expect(messageobj).to be_a Sisimai::Message }
      example('#header returns Hash') { expect(messageobj.header).to be_a Hash }
      example('#ds returns Array') { expect(messageobj.ds).to be_a Array }
      example('#rfc822 returns Hash') { expect(messageobj.rfc822).to be_a Hash }
      example('#from returns String') { expect(messageobj.from).to be_a String }
      example('#catch returns Hash')  { expect(messageobj.catch).to be_a Hash }
    end

    describe '.catch' do
      example('["passed"] returns true') { expect(messageobj.catch['passed']).to be true }
      example('["base64"] returns false') { expect(messageobj.catch['base64']).to be false }
    end
  end
end

