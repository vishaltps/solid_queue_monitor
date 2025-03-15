require 'spec_helper'

RSpec.describe SolidQueueMonitor::JobsPresenter do
  describe '#render' do
    let(:job1) { create(:solid_queue_job, class_name: 'EmailJob') }
    let(:job2) { create(:solid_queue_job, :completed, class_name: 'ReportJob') }
    let(:jobs) { [job1, job2] }
    
    before do
      allow_any_instance_of(SolidQueueMonitor::StatusCalculator).to receive(:calculate).and_return('pending', 'completed')
    end
    
    subject { described_class.new(jobs, current_page: 1, total_pages: 1, filters: {}) }
    
    it 'returns HTML string' do
      expect(subject.render).to be_a(String)
    end
    
    it 'includes a title for the section' do
      expect(subject.render).to include('<h3>Recent Jobs</h3>')
    end
    
    it 'includes the filter form' do
      html = subject.render
      
      expect(html).to include('filter-form-container')
      expect(html).to include('Job Class:')
      expect(html).to include('Queue:')
      expect(html).to include('Status:')
    end
    
    it 'includes a table with jobs' do
      html = subject.render
      
      expect(html).to include('<table>')
      expect(html).to include('EmailJob')
      expect(html).to include('ReportJob')
      expect(html).to include('status-pending')
      expect(html).to include('status-completed')
    end
    
    context 'with filters' do
      subject { described_class.new(jobs, current_page: 1, total_pages: 1, filters: { class_name: 'Email', status: 'pending' }) }
      
      it 'pre-fills filter values' do
        html = subject.render
        
        expect(html).to include('value="Email"')
        expect(html).to include('value="pending" selected')
      end
    end
  end
end 