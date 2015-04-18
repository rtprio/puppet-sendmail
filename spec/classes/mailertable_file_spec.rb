require 'spec_helper'

describe 'sendmail::mailertable::file' do

  context 'On Debian' do
    let(:title) { 'mailertable' }

    let :facts do
      { :operatingsystem => 'Debian' }
    end

    it do
      should contain_file('/etc/mail/mailertable').with({
        'ensure' => 'file',
        'owner'  => 'smmta',
        'group'  => 'smmsp',
        'mode'   => '0644',
      })
    end
  end
end
