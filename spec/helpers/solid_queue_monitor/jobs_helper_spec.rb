# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidQueueMonitor::JobsHelper do
  describe '#format_arguments' do
    it 'returns a dash for blank input' do
      expect(helper.format_arguments(nil)).to eq('-')
      expect(helper.format_arguments([])).to eq('-')
    end

    it 'renders short arguments inline' do
      result = helper.format_arguments([1, 2, 3])

      expect(result).to include('args-single-line')
      expect(result).to include('[1, 2, 3]')
    end

    it 'wraps long arguments in a scrollable container' do
      result = helper.format_arguments(Array.new(20, 'xxxxx'))

      expect(result).to include('args-container')
      expect(result).to include('args-content')
    end

    it 'unwraps ActiveJob ruby2 keyword payloads' do
      payload = [{ 'arguments' => [{ '_aj_ruby2_keywords' => ['foo'], 'foo' => 'bar' }] }]
      result = helper.format_arguments(payload)

      expect(result).to include('foo')
      expect(result).not_to include('_aj_ruby2_keywords')
    end
  end

  describe '#format_hash' do
    it 'returns a dash for blank input' do
      expect(helper.format_hash(nil)).to eq('-')
      expect(helper.format_hash({})).to eq('-')
    end

    it 'renders key value pairs with truncated values' do
      result = helper.format_hash(foo: 'bar', baz: 'x' * 100)

      expect(result).to include('<strong>foo:</strong>')
      expect(result).to include('bar')
      expect(result).to include('...')
    end
  end
end
