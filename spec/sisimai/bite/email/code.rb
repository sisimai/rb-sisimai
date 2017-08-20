require 'spec_helper'

module Sisimai
  module Bite
    module Email
      module Code
        class << self
          # Imported from p5-Sisimai/t/600-bite-email-code
          def maketest(enginename=nil, isexpected=[], privateset=nil, onlydebugs=false)
            return nil unless enginename
            return nil unless isexpected

            require 'sisimai/mail'
            require 'sisimai/message'
            require 'sisimai/data'

            modulename = nil
            outofemail = %w|ARF RFC3464 RFC3834|
            samplepath = 'set-of-emails/maildir/bsd'
            emailindex = 0
            mesgmethod = {
              'length' => %w|recipient agent|,
              'exists' => %w|date spec reason status command action alias rhost lhost
                diagnosis feedbacktype softbounce|,
            }
            v = nil

            if outofemail.include? enginename
              # ARF, RFC3464, RFC3834
              require sprintf("sisimai/%s", enginename.downcase)
              modulename = Module.const_get(sprintf("Sisimai::%s", enginename))
              samplepath = sprintf("set-of-emails/private/%s", enginename.downcase) if privateset
            else
              # Other MTA modules
              require sprintf("sisimai/bite/email/%s", enginename.downcase)
              modulename = Module.const_get(sprintf("Sisimai::Bite::Email::%s", enginename))
              samplepath = sprintf("set-of-emails/private/email-%s", enginename.downcase) if privateset
            end

            describe modulename do
              describe '.description' do
                it 'returns String' do
                  expect(modulename.description).to be_a Object::String
                  expect(modulename.description.size).to be > 0
                end
              end

              describe '.pattern' do
                it 'returns Hash' do
                  expect(modulename.pattern).to be_a Hash
                  expect(modulename.pattern.keys.size).to be > 0
                end
              end

              describe '.scan' do
                it('returns nil') { expect(modulename.scan(nil,nil)).to be nil }
              end
            end

            isexpected.each do |e|
              # Open each email in set-of-emails/ directory
              samplefile = nil
              mailobject = nil
              indexlabel = sprintf("%02d", e['n'].to_i)

              if onlydebugs
                # Debug mode
                emailindex += 1
                next unless onlydebugs.to_i == e['n'].to_i
              end

              if privateset
                # Private sample
                samplefile = Dir.glob(sprintf("./%s/%s-*.eml", samplepath, e['n'])).shift
              else
                # Public sample
                if outofemail.include? enginename
                  # ARF, RFC3464, RFC3834
                  samplefile = sprintf("./%s/%s-%02d.eml", samplepath, enginename.downcase, e['n'].to_i)
                else
                  # Other MTA modules
                  samplefile = sprintf("./%s/email-%s-%02d.eml", samplepath, enginename.downcase, e['n'].to_i)
                end
              end

              describe sprintf("%s[%s]", enginename, e['n']) do
                # Sendmail[22]
                it('sample exists as ' + samplefile) { expect(File.exist?(samplefile)).to be true }
                it('sample filesize is ' + File.size(samplefile).to_s) { expect(File.size(samplefile)).to be > 0 }

                mailobject = Sisimai::Mail.new(samplefile)
                next unless mailobject.path

                it('could be generated Sisimai::Mail object') { expect(mailobject).to be_a Sisimai::Mail }

                while r = mailobject.read do
                  
                  describe Sisimai::Mail do
                    mesgsource = r.to_s
                    mesgobject = nil
                    dataobject = nil
                    foundindex = 0

                    it '#read returns String' do
                      expect(mesgsource).to be_a Object::String
                      expect(mesgsource.size).to be > 0
                    end

                    pp = nil  # Property
                    lb = nil  # Label
                    re = nil  # Regular expression

                    mesgobject = Sisimai::Message.new(data: r, input: 'email')
                    next unless mesgobject
                    next if mesgobject.void

                    describe Sisimai::Message do
                      it('#class returns Sisimai::Message') { expect(mesgobject).to be_a Sisimai::Message }
                      it('#ds returns Array')    { expect(mesgobject.ds).to be_a Object::Array }
                      it('#ds have elements')    { expect(mesgobject.ds.size).to be > 0 }
                      it('#header returns Hash') { expect(mesgobject.header).to be_a Object::Hash }
                      it('#rfc822 returns Hash') { expect(mesgobject.rfc822).to be_a Object::Hash }
                      it('#from returns String') { expect(mesgobject.from).to be_a Object::String}
                      it('#from has a size')     { expect(mesgobject.from.size).to be > 0 }

                      describe 'Sisimai::Message#ds' do
                        mesgobject.ds.each do |ds|
                          foundindex += 1

                          before do
                            lb = sprintf("%02d-%02d", e['n'].to_i, foundindex)
                            pp = nil
                            re = nil
                          end

                          mesgmethod['length'].each do |rr|
                            # Lenght of each variable is greater than 0
                            it(sprintf("%s [%s] returns value", lb, rr)) { expect(ds[rr].size).to be > 0 }
                          end

                          mesgmethod['exists'].each do |rr|
                            # Each key should be exist
                            it(sprintf("%s [%s] is not nil", lb, rr)) { expect(ds.key?(rr)).not_to be nil }
                          end

                          if enginename == 'X4' || enginename == 'Qmail' || enginename == 'MFILTER'
                            # X4 is qmail clone
                            it sprintf("%s [agent] matches 'qmail' or 'X4' or 'mFILTER'", lb) do
                              expect(ds['agent'].downcase).to match /\Aemail::(?:qmail|x4|mfilter)\z/
                            end
                          elsif enginename == 'RFC3464'
                            # RFC3464
                            if privateset
                              it(sprintf("%s [agent] returns value", lb)) { expect(ds['agent'].size).to be > 0 }
                            else
                              it(sprintf("%s [agent] matches %s", lb, e['a'].to_s)) { expect(ds['agent']).to match e['a'] }
                            end
                          elsif enginename == 'RFC3834'
                            # RFC3834
                            it(sprintf("%s [agent] matches %s", lb, '/RFC3464/')) { expect(ds['agent']).to match /\ARFC3834\z/ }
                          elsif enginename == 'ARF'
                            # ARF
                            re = /.+/
                            it(sprintf("%s [agent] matches %s", lb, '/.+/')) { expect(ds['agent']).to match /.+/ }
                          else
                            # Other MTA module
                            it sprintf("%s [agent] is %s", lb, 'Email::' + enginename) do
                              expect(ds['agent']).to be == 'Email::' + enginename
                            end
                          end

                          pp = 'recipient'
                          re = /[0-9A-Za-z@-_.]+/
                          it(sprintf("%s [%s] matches %s", lb, pp, re.to_s)) { expect(ds[pp]).to match re }

                          pp = 'command'
                          it(sprintf("%s [%s] does not match /[ ]/", lb, pp)) { expect(ds[pp]).not_to match /[ ]/ }

                          pp = 'status'
                          if ds[pp] && ds[pp].size > 0
                            # CHeck the value of "status"
                            re = /\A(?:[245][.]\d[.]\d+)\z/
                            it(sprintf("%s [%s] matches %s", lb, pp, re.to_s)) { expect(ds[pp]).to match re }
                            it(sprintf("%s [%s] does not match /[ ]/", lb, pp)) { expect(ds[pp]).not_to match /[ ]/ }
                          end

                          pp = 'action'
                          if ds[pp] && ds[pp].size > 0
                            # CHeck the value of "action"
                            re = /\A(?:fail.+|delayed|deliverable|delivered|expired|expanded.*|relayed)\z/
                            it(sprintf("%s [%s] matches %s", lb, pp, re.to_s)) { expect(ds[pp]).to match re }
                          end

                          %w|rhost lhost|.each do |rr|
                            next unless ds[rr]
                            next if enginename =~ /\A(?:qmail|Exim|Exchange|X4|MailRu)/
                            next if ds[rr].empty?

                            pp = rr
                            re = /\A(?:[0-9A-Za-z]+|.+[.].+)\z/
                            it(sprintf("%s [%s] matches %s", lb, pp, re.to_s)) { expect(ds[pp]).to match re }
                          end
                        end
                      end # End of Sisimai::Message#ds
                    end # End of Sisimai::Message

                    dataobject = Sisimai::Data.make(data: mesgobject, delivered: true)
                    describe Sisimai::Data do
                      next unless dataobject
                      next if dataobject.empty?

                      it('returns Array') { expect(dataobject).to be_a Object::Array }
                      it('have elements') { expect(dataobject.size).to be > 0 }
                      it('[0]#class returns Sisimai::Data') { expect(dataobject[0]).to be_a Sisimai::Data }

                      dataobject.each do |pr|
                        # checking each Sisimai::Data object
                        lb = sprintf("%02d-%02d", e['n'].to_i, foundindex)

                        it(sprintf("%s #timestamp is a Sisimai::Time", lb)) { expect(pr.timestamp).to be_a Sisimai::Time }
                        it(sprintf("%s #addresser is a Sisimai::Address", lb)) { expect(pr.addresser).to be_a Sisimai::Address }
                        it(sprintf("%s #recipient is a Sisimai::Address", lb)) { expect(pr.recipient).to be_a Sisimai::Address }

                        it(sprintf("%s #replycode is not nil", lb))      { expect(pr.replycode).not_to be nil }
                        it(sprintf("%s #subject is not nil", lb))        { expect(pr.subject).not_to be nil }
                        it(sprintf("%s #smtpcommand is not nil", lb))    { expect(pr.smtpcommand).not_to be nil }
                        it(sprintf("%s #diagnosticcode is not nil", lb)) { expect(pr.diagnosticcode).not_to be nil }
                        it(sprintf("%s #diagnostictype is not nil", lb)) { expect(pr.diagnostictype).not_to be nil }

                        if pr.reason == 'feedback'
                          # reason: "feedback"
                          it(sprintf("%s #deliverystatus is empty", lb)) { expect(pr.deliverystatus).to be_empty }

                          if enginename == 'ARF'
                            if privateset
                              it(sprintf("%s #feedbacktype is not empty", lb)) { expect(pr.feedbacktype).not_to be_empty }
                            else
                              it sprintf("%s #feedbacktype matches %s", lb, e['f'].to_s) do
                                expect(pr.feedbacktype).to match e['f']
                              end
                            end
                          end
                        elsif pr.reason == 'vacation'
                          # reason: "vacation"
                          it(sprintf("%s #deliverystatus is empty", lb)) { expect(pr.deliverystatus).to be_empty }
                          it(sprintf("%s #feedbacktype is empty", lb)) { expect(pr.feedbacktype).to be_empty }
                        else
                          # other reasons
                          it(sprintf("%s #deliverystatus is not empty", lb)) { expect(pr.deliverystatus).not_to be_empty }
                          it(sprintf("%s #feedbacktype is empty", lb)) { expect(pr.feedbacktype).to be_empty }
                        end

                        it(sprintf("%s #token is not empty", lb))          { expect(pr.token).not_to be_empty }
                        it(sprintf("%s #smtpagent is not empty", lb))      { expect(pr.smtpagent).not_to be_empty }
                        it(sprintf("%s #timezoneoffset is not empty", lb)) { expect(pr.timezoneoffset).not_to be_empty }

                        it sprintf("%s #addresser.host is equals to senderdomain", lb) do
                          expect(pr.addresser.host).to be == pr.senderdomain
                        end
                        it sprintf("%s #recipient.host is equals to destination", lb) do
                          expect(pr.recipient.host).to be == pr.destination
                        end

                        it sprintf("%s #softbounce is within -1 of 1", lb) do
                          expect([-1, 0, 1]).to include pr.softbounce.to_i
                        end

                        if privateset
                          # Explicit value is not defined for private samples
                          it(sprintf("%s #softbounce is not empty", lb)) { expect(pr.softbounce.to_s).not_to be_empty }
                          it sprintf("%s #deliverystatus matches with [245].\d.\d", lb) do
                            expect(pr.deliverystatus).to match /\A(?:[245][.]\d[.]\d+|)\z/
                          end
                        else
                          # Try to match with the explicit value
                          it sprintf("%s #softbounce matches with %s", lb, e['b'].to_s) do
                            expect(pr.softbounce.to_s).to match e['b']
                          end
                          it sprintf("%s #deliverystatus matches with %s", lb, e['s'].to_s) do
                            expect(pr.deliverystatus).to match e['s']
                          end
                        end

                        it sprintf("%s #replycode matches with the valid format", lb) do
                          expect(pr.replycode).to match /\A(?:[245]\d\d|)\z/
                        end
                        it sprintf("%s #timezoneoffset matches with the valid format", lb) do
                          expect(pr.timezoneoffset).to match /\A[-+]\d{4}\z/
                        end
                        it sprintf("%s #diagnostictype matches with the valid format", lb) do
                          expect(pr.diagnostictype).to match /.*/
                        end
                        it sprintf("%s #reason matches with %s", lb, e['r'].to_s) do
                          expect(pr.reason).to match e['r']
                        end
                        it sprintf("%s #token matches with the valid format", lb) do
                          expect(pr.token).to match /\A([0-9a-f]{40})\z/ 
                        end
                        it sprintf("%s #alias does not include [ ]", lb) do
                          expect(pr.alias).not_to match /[ ]/
                        end

                        %w|smtpcommand lhost rhost alias listid action messageid|.each do |pp|
                          it sprintf("%s #%s does not include [ ]", lb, pp) do
                            expect(pr.send(pp)).not_to match(/[ \r]/)
                          end
                        end

                        it sprintf("%s #diagnosticcode does not include __END_OF_EMAIL_MESSAGE__", lb) do
                          expect(pr.diagnosticcode).not_to match /__END_OF_EMAIL_MESSAGE__/
                        end

                        %w|user host verp alias|.each do |rr|
                          it sprintf("%s #addresser.%s does not include [ ]", lb, rr) do
                            expect(pr.addresser.send(rr)).not_to match(/[ \r]/)
                          end
                          it sprintf("%s #recipient.%s does not include [ ]", lb, rr) do
                            expect(pr.recipient.send(rr)).not_to match(/[ \r]/)
                          end
                        end

                        %w|addresser recipient|.each do |rr|
                          if pr.send(rr).alias.size > 0
                            it sprintf("%s #%s.alias includes @", lb, rr) do
                              expect(pr.send(rr).alias).to match(/[@]/)
                            end
                          end
                          if pr.send(rr).verp.size > 0
                            it sprintf("%s #%s.verp includes @", lb, rr) do
                              expect(pr.send(rr).verp).to match(/[@]/)
                            end
                          end
                        end

                      end
                    end

                  end # End of Sisimai::Mail

                end

              end


            end


          end

        end
      end
    end
  end
end
