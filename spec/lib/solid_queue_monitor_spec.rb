# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidQueueMonitor do
  describe '.base_controller_class' do
    after { described_class.base_controller_class = nil }

    it 'defaults to "ActionController::Base"' do
      described_class.base_controller_class = nil
      expect(described_class.base_controller_class).to eq('ActionController::Base')
    end

    it 'returns the configured class name when set' do
      described_class.base_controller_class = 'AdminController'
      expect(described_class.base_controller_class).to eq('AdminController')
    end

    it 'falls back to the default when reset to nil' do
      described_class.base_controller_class = 'AdminController'
      described_class.base_controller_class = nil
      expect(described_class.base_controller_class).to eq('ActionController::Base')
    end
  end

  describe 'ApplicationController parent class' do
    it 'inherits from ActionController::Base by default' do
      expect(SolidQueueMonitor::ApplicationController.ancestors).to include(ActionController::Base)
    end

    it 'resolves the configured class via safe_constantize at load time' do
      # The application_controller.rb file uses
      #   SolidQueueMonitor.base_controller_class.safe_constantize || ActionController::Base
      # at class-definition time. Re-evaluate the same expression here to confirm
      # the resolution logic works as documented.
      expect(described_class.base_controller_class.safe_constantize).to eq(ActionController::Base)
    end

    it 'falls back to ActionController::Base when the configured name does not resolve' do
      described_class.base_controller_class = 'NotAClass::ThatExists'
      resolved = described_class.base_controller_class.safe_constantize || ActionController::Base
      expect(resolved).to eq(ActionController::Base)
    ensure
      described_class.base_controller_class = nil
    end
  end

  describe 'engine helper wiring' do
    # Regression guard: when ApplicationController inherits from a non-AC::Base
    # parent (custom base_controller_class), Rails will NOT auto-include the
    # engine's helpers. ApplicationController must include them explicitly via
    # `helper SolidQueueMonitor::Engine.helpers` so views keep working.
    let(:helper_methods) { SolidQueueMonitor::ApplicationController._helpers.instance_methods }

    it 'exposes ChartHelper#render_chart on the controller helper module' do
      expect(helper_methods).to include(:render_chart)
    end

    it 'exposes the rest of the engine helpers' do
      # One method per engine helper module, to catch any missing wiring.
      expect(helper_methods).to include(:sortable_header, :visible_pages)
    end
  end
end
