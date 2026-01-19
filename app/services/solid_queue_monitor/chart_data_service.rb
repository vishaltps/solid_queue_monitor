# frozen_string_literal: true

module SolidQueueMonitor
  class ChartDataService
    TIME_RANGES = {
      '15m' => { duration: 15.minutes, buckets: 15, label_format: '%H:%M', label: 'Last 15 minutes' },
      '30m' => { duration: 30.minutes, buckets: 15, label_format: '%H:%M', label: 'Last 30 minutes' },
      '1h' => { duration: 1.hour, buckets: 12, label_format: '%H:%M', label: 'Last 1 hour' },
      '3h' => { duration: 3.hours, buckets: 18, label_format: '%H:%M', label: 'Last 3 hours' },
      '6h' => { duration: 6.hours, buckets: 24, label_format: '%H:%M', label: 'Last 6 hours' },
      '12h' => { duration: 12.hours, buckets: 24, label_format: '%H:%M', label: 'Last 12 hours' },
      '1d' => { duration: 1.day, buckets: 24, label_format: '%H:%M', label: 'Last 24 hours' },
      '3d' => { duration: 3.days, buckets: 36, label_format: '%m/%d %H:%M', label: 'Last 3 days' },
      '1w' => { duration: 7.days, buckets: 28, label_format: '%m/%d', label: 'Last 7 days' }
    }.freeze

    DEFAULT_TIME_RANGE = '1d'

    def initialize(time_range: DEFAULT_TIME_RANGE)
      @time_range = TIME_RANGES.key?(time_range) ? time_range : DEFAULT_TIME_RANGE
      @config = TIME_RANGES[@time_range]
    end

    def calculate
      end_time = Time.current
      start_time = end_time - @config[:duration]
      bucket_duration = @config[:duration] / @config[:buckets]

      buckets = build_buckets(start_time, bucket_duration)

      created_counts = fetch_created_counts(start_time, end_time)
      completed_counts = fetch_completed_counts(start_time, end_time)
      failed_counts = fetch_failed_counts(start_time, end_time)

      created_data = assign_to_buckets(created_counts, buckets, bucket_duration)
      completed_data = assign_to_buckets(completed_counts, buckets, bucket_duration)
      failed_data = assign_to_buckets(failed_counts, buckets, bucket_duration)

      {
        labels: buckets.map { |b| b[:label] }, # rubocop:disable Rails/Pluck
        created: created_data,
        completed: completed_data,
        failed: failed_data,
        totals: {
          created: created_data.sum,
          completed: completed_data.sum,
          failed: failed_data.sum
        },
        time_range: @time_range,
        time_range_label: @config[:label],
        available_ranges: TIME_RANGES.transform_values { |v| v[:label] }
      }
    end

    private

    def build_buckets(start_time, bucket_duration)
      @config[:buckets].times.map do |i|
        bucket_start = start_time + (i * bucket_duration)
        {
          start: bucket_start,
          end: bucket_start + bucket_duration,
          label: bucket_start.strftime(@config[:label_format])
        }
      end
    end

    def fetch_created_counts(start_time, end_time)
      SolidQueue::Job
        .where(created_at: start_time..end_time)
        .pluck(:created_at)
    end

    def fetch_completed_counts(start_time, end_time)
      SolidQueue::Job
        .where(finished_at: start_time..end_time)
        .where.not(finished_at: nil)
        .pluck(:finished_at)
    end

    def fetch_failed_counts(start_time, end_time)
      SolidQueue::FailedExecution
        .where(created_at: start_time..end_time)
        .pluck(:created_at)
    end

    def assign_to_buckets(timestamps, buckets, _bucket_duration)
      counts = Array.new(buckets.size, 0)

      timestamps.each do |timestamp|
        bucket_index = buckets.find_index do |bucket|
          timestamp >= bucket[:start] && timestamp < bucket[:end]
        end
        counts[bucket_index] += 1 if bucket_index
      end

      counts
    end
  end
end
