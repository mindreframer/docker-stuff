require 'spec_helper'

describe 'docker-registry' do
  let(:title) { 'docker-registry' }

  ['Debian', 'RedHat'].each do |osfamily|
    describe "docker-registry class without any parameters on #{osfamily}" do 
      let(:params) {{ }}
      let(:facts) { { :osfamily => osfamily } }

      it { should create_class('docker-registry') }
      it { should create_package('docker-registry') }
      it { should create_file('/etc/docker-registry.conf') }
      it {
        should create_file('/etc/docker-registry.conf')\
        .with_content(/^server pool.docker-registry.org$/)
      }
      if osfamily == 'RedHat' 
        it { should create_service('docker-registryd') }
      else
        it { should create_service('docker-registry') }
      end
    end
  end
end
