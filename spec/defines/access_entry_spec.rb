require 'spec_helper'

describe 'sendmail::access::entry' do
  let(:title) { 'example.com' }

  let(:facts) do
    { :operatingsystem => 'Debian' }
  end

  context 'with value' do
    let(:params) do
      { :value => 'REJECT' }
    end

    it {
      should contain_augeas('/etc/mail/access-example.com') \
              .that_requires('Class[sendmail::access::file]') \
              .that_notifies('Class[sendmail::makeall]')
    }
  end

  context 'without value' do
    let(:params) do
      { :ensure => 'present' }
    end

    it {
      expect {
        should compile
      }.to raise_error(/value must be set when creating an access entry/)
    }
  end
end
