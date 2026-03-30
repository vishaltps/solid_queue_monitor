# frozen_string_literal: true

module SolidQueueMonitor
  class ChartDataService
    TIME_RANGES = {
      '15m' => { duration: 15.minutes, buckets: 15, label_format: '%H:%M', label: 'Last 15 minutes' },
      '30m' => { duration: 30.minutes, buckets: 15, label_format: '%H:%M', label: 'Last 30 minutes' },
      '1h' => { duration: 1.hour,     buckets: 12, label_format: '%H:%M', label: 'Last 1 hour' },
      '3h' => { duration: 3.hours,    buckets: 18, label_format: '%H:%M', label: 'Last 3 hours' },
      '6h' => { duration: 6.hours,    buckets: 24, label_format: '%H:%M', label: 'Last 6 hours' },
      '12h' => { duration: 12.hours, buckets: 24, label_format: '%H:%M', label: 'Last 12 hours' },
      '1d' => { duration: 1.day,      buckets: 24, label_format: '%H:%M', label: 'Last 24 hours' },
      '3d' => { duration: 3.days,     buckets: 36, label_format: '%m/%d %H:%M', label: 'Last 3 days' },
      '1w' => { duration: 7.days,     buckets: 28, label_format: '%m/%d', label: 'Last 7 days' }
    }.freeze

    DEFAULT_TIME_RANGE = '1d'

    def initialize(time_range: DEFAULT_TIME_RANGE)
      @time_range = TIME_RANGES.key?(time_range) ? time_range : DEFAULT_TIME_RANGE
      @config     = TIME_RANGES[@time_range]
    end

    def calculate
      end_time       = Time.current
      start_time     = end_time - @config[:duration]
      bucket_seconds = (@config[:duration] / @config[:buckets]).to_i
      buckets        = build_buckets(start_time, bucket_seconds)

      created_data   = bucket_counts(SolidQueue::Job, :created_at,  start_time, end_time, bucket_seconds)
      completed_data = bucket_counts(SolidQueue::Job, :finished_at, start_time, end_time, bucket_seconds, exclude_nil: true)
      failed_data    = bucket_counts(SolidQueue::FailedExecution, :created_at, start_time, end_time, bucket_seconds)

      created_arr   = fill_buckets(buckets, created_data)
      completed_arr = fill_buckets(buckets, completed_data)
      failed_arr    = fill_buckets(buckets, failed_data)

      {
        labels: buckets.map { |b| b[:label] }, # rubocop:disable Rails/Pluck
        created: created_arr,
        completed: completed_arr,
        failed: failed_arr,
        totals: { created: created_arr.sum, completed: completed_arr.sum, failed: failed_arr.sum },
        time_range: @time_range,
        time_range_label: @config[:label],
        available_ranges: TIME_RANGES.transform_values { |v| v[:label] }
      }
    end

    private

    def build_buckets(start_time, bucket_seconds)
      @config[:buckets].times.map do |i|
        bucket_start = start_time + (i * bucket_seconds)
        { index: i, start: bucket_start, label: bucket_start.strftime(@config[:label_format]) }
      end
    end

    # Returns a Hash of { bucket_index => count } using SQL GROUP BY.
    # The bucket index is computed as: (epoch(column) - epoch(start_time)) / interval
    # This works identically on PostgreSQL and SQLite.
    def bucket_counts(model, column, start_time, end_time, interval, exclude_nil: false)
      start_epoch = start_time.to_i
      expr = bucket_index_expr(column, start_epoch, interval)

      scope = model.where(column => start_time..end_time)
      scope = scope.where.not(column => nil) if exclude_nil

      # rubocop:disable Style/HashTransformKeys -- pluck returns Array<Array>, not Hash
      scope
        .group(Arel.sql(expr))
        .pluck(Arel.sql("#{expr} AS bucket_idx, COUNT(*) AS cnt"))
        .to_h { |idx, cnt| [idx.to_i, cnt] }
      # rubocop:enable Style/HashTransformKeys
    end

    def fill_buckets(buckets, index_counts)
      buckets.map { |b| index_counts.fetch(b[:index], 0) }
    end

    # Cross-DB bucket index expression.
    # PostgreSQL: CAST((EXTRACT(EPOCH FROM col) - start) / interval AS INTEGER)
    # SQLite:     CAST((CAST(strftime('%s', col) AS INTEGER) - start) / interval AS INTEGER)
    # MySQL:      CAST((UNIX_TIMESTAMP(col) - start) / interval AS SIGNED)
    def bucket_index_expr(column, start_epoch, interval_seconds)
      if adapter?('sqlite')
        "CAST((CAST(strftime('%s', #{column}) AS INTEGER) - #{start_epoch}) / #{interval_seconds} AS INTEGER)"
      elsif adapter?('mysql') || adapter?('trilogy')
        "CAST((UNIX_TIMESTAMP(#{column}) - #{start_epoch}) / #{interval_seconds} AS SIGNED)"
      else
        "CAST((EXTRACT(EPOCH FROM #{column}) - #{start_epoch}) / #{interval_seconds} AS INTEGER)"
      end
    end

    def adapter?(name)
      ActiveRecord::Base.connection.adapter_name.downcase.include?(name)
    end
  end
end
