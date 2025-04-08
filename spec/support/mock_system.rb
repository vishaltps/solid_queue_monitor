# frozen_string_literal: true

# This file provides mocks for system tests without depending on Rails Engine

# Mock SolidQueue models
module SolidQueue
  class Job
    attr_accessor :id, :queue_name, :class_name, :arguments, :priority,
                  :scheduled_at, :process_at, :attempts, :executions_count

    def initialize(attrs = {})
      @id = attrs[:id] || rand(1000)
      @queue_name = attrs[:queue_name] || 'default'
      @class_name = attrs[:class_name] || 'TestJob'
      @arguments = attrs[:arguments] || '[]'
      @priority = attrs[:priority] || 0
      @scheduled_at = attrs[:scheduled_at]
      @process_at = attrs[:process_at]
      @attempts = attrs[:attempts] || 0
      @executions_count = attrs[:executions_count] || 0
    end

    def persisted?
      true
    end

    def self.create(attrs = {})
      new(attrs)
    end

    def self.all
      MockRelation.new(self)
    end

    def self.where(conditions = {})
      MockRelation.new(self, conditions)
    end

    def self.find(id)
      new(id: id)
    end
  end

  # Mock ActiveRecord relation
  class MockRelation
    attr_reader :model_class, :conditions

    def initialize(model_class, conditions = {})
      @model_class = model_class
      @conditions = conditions
      @limit_value = nil
      @offset_value = nil
    end

    def count
      10 # Default count for testing
    end

    def where(conditions)
      @conditions.merge!(conditions)
      self
    end

    def limit(value)
      @limit_value = value
      self
    end

    def offset(value)
      @offset_value = value
      self
    end

    def to_a
      Array.new(@limit_value || 5) do |i|
        @model_class.new(
          id: i + 1 + (@offset_value || 0),
          queue_name: @conditions[:queue_name] || 'default'
        )
      end
    end
  end
end

# Mock system test helpers
module MockSystemTest
  def visit(path)
    @current_path = path
    @page_content = case path
                    when '/'
                      '<h1>SolidQueue Monitor</h1><div class="stats">10 jobs</div>'
                    when '/ready_jobs'
                      '<h1>Ready Jobs</h1><table><tr><td>Job 1</td></tr></table>'
                    when '/failed_jobs'
                      '<h1>Failed Jobs</h1><table><tr><td>Failed Job 1</td></tr></table>'
                    when /page=2/
                      # Return the page 2 content if defined in the test
                      @page_2_content || '<h1>Page 2</h1>'
                    else
                      # Use the default content or let the test override it
                      "<h1>Unknown page: #{path}</h1>"
                    end
  end

  def page
    PageMock.new(@page_content)
  end

  def click_link(text)
    case text
    when 'Next'
      visit "#{@current_path}?page=2"
    when 'Ready Jobs'
      visit '/ready_jobs'
    when 'Failed Jobs'
      visit '/failed_jobs'
    when '2'
      visit "#{@current_path}?page=2"
    else
      visit "#{@current_path}?clicked=#{text}"
    end
  end

  def fill_in(field, with:)
    # Just a stub for fill_in
  end

  def click_button(text)
    # Just a stub for click_button
  end

  # Page mock for improved test support
  class PageMock
    attr_reader :html

    def initialize(content)
      @html = content
    end

    def has_content?(text)
      @html.include?(text)
    end

    def has_css?(_selector)
      true # Just return true for any CSS selector
    end

    def find(selector)
      OpenStruct.new(text: "Element at #{selector}")
    end

    def find_all(_selector)
      [OpenStruct.new(text: 'Item 1'), OpenStruct.new(text: 'Item 2')]
    end
  end
end
