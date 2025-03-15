require 'spec_helper'

RSpec.describe SolidQueueMonitor::AuthenticationService do
  describe '.authenticate' do
    context 'when authentication is disabled' do
      before do
        allow(SolidQueueMonitor).to receive(:authentication_enabled).and_return(false)
      end
      
      it 'returns true regardless of credentials' do
        expect(described_class.authenticate('wrong', 'wrong')).to be true
        expect(described_class.authenticate(nil, nil)).to be true
      end
    end
    
    context 'when authentication is enabled' do
      before do
        allow(SolidQueueMonitor).to receive(:authentication_enabled).and_return(true)
        allow(SolidQueueMonitor).to receive(:username).and_return('admin')
        allow(SolidQueueMonitor).to receive(:password).and_return('password')
      end
      
      it 'returns true when credentials are correct' do
        expect(described_class.authenticate('admin', 'password')).to be true
      end
      
      it 'returns false when username is incorrect' do
        expect(described_class.authenticate('wrong', 'password')).to be false
      end
      
      it 'returns false when password is incorrect' do
        expect(described_class.authenticate('admin', 'wrong')).to be false
      end
      
      it 'returns false when both username and password are incorrect' do
        expect(described_class.authenticate('wrong', 'wrong')).to be false
      end
    end
  end
  
  describe '.authentication_required?' do
    it 'returns the value of SolidQueueMonitor.authentication_enabled' do
      allow(SolidQueueMonitor).to receive(:authentication_enabled).and_return(true)
      expect(described_class.authentication_required?).to be true
      
      allow(SolidQueueMonitor).to receive(:authentication_enabled).and_return(false)
      expect(described_class.authentication_required?).to be false
    end
  end
end 