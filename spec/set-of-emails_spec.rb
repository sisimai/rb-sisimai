require 'spec_helper'

checkuntil = 2
publicfile = [
  './set-of-emails/maildir/err',
  './set-of-emails/maildir/bsd',
  './set-of-emails/maildir/dos',
  './set-of-emails/to-be-debugged-because/sisimai-cannot-parse-yet',
  './set-of-emails/to-be-debugged-because/reason-is-undefined',
]
privatefile = './set-of-emails/private'

describe 'Public samples' do
  publicfile.each do |d|
    example 'directory exists' do
      expect(Dir.exist?(d)).to be true
    end

    h = Dir.open(d)
    while e = h.read do
      next if e == '.'
      next if e == '..'

      emailfn = sprintf('%s/%s', d, e)
      lnindex = 0

      next unless File.exist?(emailfn)
      it 'has valid file' do
        expect(File.readable?(emailfn)).to be true
        expect(File.size(emailfn)).to be > 0
      end

      File.open(emailfn,'r') do |fhandle|
        fhandle.each_line do |f|
          lnindex += 1
          f = f.scrub('?')
          it 'end with 0x0a' do
            expect(f).to match %r/\x0a\z/
          end
          break if lnindex > checkuntil
        end
      end

    end
    h.close
  end
end

describe 'Private samples' do
  break unless Dir.exist?(privatefile)
  dir0 = Dir.open(privatefile)

  while e = dir0.read do
    next if e == '.'
    next if e == '..'

    directory1 = sprintf('%s/%s', privatefile, e)
    dir1 = Dir.open(directory1)
    while f = dir1.read do
      next if f == '.'
      next if f == '..'

      emailfn = sprintf('%s/%s', directory1, f)
      lnindex = 0

      next unless File.exist?(emailfn)
      it 'has valid file' do
        expect(File.readable?(emailfn)).to be true
        expect(File.size(emailfn)).to be > 0
      end

      if emailfn =~ /[.]eml/
        File.open(emailfn,'r') do |fhandle|
          fhandle.each_line do |g|
            lnindex += 1
            g = g.scrub('?')
            it 'end with 0x0a' do
              expect(g).to match %r/\x0a\z/
            end
            break if lnindex > checkuntil
          end
        end
      end

    end
    dir1.close

  end
  dir0.close

end
