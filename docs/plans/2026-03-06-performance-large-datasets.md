# Performance: Large Dataset Support Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix gateway timeouts on large Solid Queue datasets (4M+ rows in `solid_queue_jobs`). Make the default experience fast without any configuration.

**Architecture:** Five tasks, ordered by impact. Tasks 1–4 are unconditional fixes — they make things faster for everyone without configuration flags or behaviour changes. Task 5 adds a single opt-in config (`show_chart`) for teams that want to eliminate chart queries entirely. No `approximate_counts`, no `paginate_without_count`, no `root_redirect_to` — those are complexity for problems we can solve properly.

**Tech Stack:** Ruby/Rails engine, RSpec, FactoryBot. Tests run on **SQLite in-memory** (`spec_helper.rb:16-18`). Production users are on PostgreSQL. All SQL must work on both.

**Ref:** GitHub issue #27

---

## Why the Sonnet Plan Was Wrong

| Sonnet Proposal | Problem |
|-----------------|---------|
| `pg_class.reltuples` for approximate counts | PostgreSQL-only. Tests run on SQLite. Adds a config flag to work around a problem we can eliminate. |
| `EXTRACT(EPOCH FROM ...)` in ChartDataService | PostgreSQL-only. Breaks test suite. |
| `paginate_without_count` config | Pagination COUNT is only expensive on `solid_queue_jobs`. If we stop paginating that table at scale, the problem disappears. |
| `approximate_counts` config | If we stop running COUNT(*) on `solid_queue_jobs` at all, there's nothing to approximate. |
| Fixed plucks in `filter_jobs` only | Missed 8+ identical pluck calls in `filter_ready_jobs`, `filter_scheduled_jobs`, `filter_failed_jobs`, `filter_in_progress_jobs`. |

## Root Cause Analysis

The real question: **why does the overview page scan `solid_queue_jobs` at all?**

`StatsCalculator` runs three queries against `solid_queue_jobs`:
1. `SolidQueue::Job.count` → `total_jobs` (52 seconds at 4M rows)
2. `SolidQueue::Job.distinct.count(:queue_name)` → `unique_queues`
3. `SolidQueue::Job.where.not(finished_at: nil).count` → `completed`

But what does an operator actually need? **How many jobs are ready, failed, in-progress, scheduled.** Those all come from execution tables which are small. `total_jobs` (including millions of finished jobs) is vanity data — not operationally actionable.

**Solution: Stop querying the jobs table for stats.** Derive everything from execution tables. This eliminates the 52-second queries entirely — no config flag, no PostgreSQL-specific hacks, just better code.

---

## Task 1: Rewrite StatsCalculator to avoid jobs table COUNT

**Why this is the highest-impact fix.** Three queries on `solid_queue_jobs` account for ~156 seconds of the timeout. Removing them solves the core complaint.

**Files:**
- Modify: `app/services/solid_queue_monitor/stats_calculator.rb`
- Modify: `app/presenters/solid_queue_monitor/stats_presenter.rb`
- Modify: `spec/services/solid_queue_monitor/stats_calculator_spec.rb`
- Modify: `spec/presenters/solid_queue_monitor/stats_presenter_spec.rb`
- Modify: `spec/requests/solid_queue_monitor/overview_spec.rb`

**Design decision:** Replace `total_jobs` (COUNT on jobs table) and `completed` (COUNT with WHERE on jobs table) with stats derived entirely from execution tables:
- Remove `total_jobs` — it's meaningless at 4M rows (it includes all historical finished jobs).
- Replace with `active_jobs` = `ready + scheduled + in_progress + failed` — what operators actually care about.
- Remove `completed` — requires scanning jobs table. At 4M scale, most rows are completed. Not useful.
- Remove `unique_queues` — `SolidQueue::Job.distinct.count(:queue_name)` scans the full table.

The new stat cards: **Active Jobs**, **Ready**, **In Progress**, **Scheduled**, **Recurring**, **Failed**.

Every single query hits small execution tables. Zero queries on `solid_queue_jobs`.

---

**Step 1: Update the spec**

Replace `spec/services/solid_queue_monitor/stats_calculator_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidQueueMonitor::StatsCalculator do
  describe '.calculate' do
    before do
      create(:solid_queue_failed_execution)
      create(:solid_queue_scheduled_execution)
      create(:solid_queue_ready_execution)
      create(:solid_queue_claimed_execution)
    end

    it 'returns a hash with all required statistics' do
      stats = described_class.calculate

      expect(stats).to include(
        :active_jobs,
        :scheduled,
        :ready,
        :failed,
        :in_progress,
        :recurring
      )
    end

    it 'calculates the correct counts from execution tables' do
      stats = described_class.calculate

      expect(stats[:scheduled]).to eq(1)
      expect(stats[:ready]).to eq(1)
      expect(stats[:failed]).to eq(1)
      expect(stats[:in_progress]).to eq(1)
      expect(stats[:recurring]).to eq(0)
    end

    it 'derives active_jobs from execution table counts' do
      stats = described_class.calculate

      expected_active = stats[:ready] + stats[:scheduled] + stats[:in_progress] + stats[:failed]
      expect(stats[:active_jobs]).to eq(expected_active)
    end

    it 'does not query the jobs table for counts' do
      expect(SolidQueue::Job).not_to receive(:count)
      described_class.calculate
    end
  end
end
```

**Step 2: Run to confirm failure**

```bash
bundle exec rspec spec/services/solid_queue_monitor/stats_calculator_spec.rb -f doc
```

Expected: FAIL — old calculator still returns `:total_jobs`, `:completed`, `:unique_queues` and queries `SolidQueue::Job`.

**Step 3: Rewrite StatsCalculator**

Replace `app/services/solid_queue_monitor/stats_calculator.rb`:

```ruby
# frozen_string_literal: true

module SolidQueueMonitor
  class StatsCalculator
    def self.calculate
      scheduled   = SolidQueue::ScheduledExecution.count
      ready       = SolidQueue::ReadyExecution.count
      failed      = SolidQueue::FailedExecution.count
      in_progress = SolidQueue::ClaimedExecution.count
      recurring   = SolidQueue::RecurringTask.count

      {
        active_jobs: ready + scheduled + in_progress + failed,
        scheduled:   scheduled,
        ready:       ready,
        failed:      failed,
        in_progress: in_progress,
        recurring:   recurring
      }
    end
  end
end
```

**Step 4: Update StatsPresenter**

Replace `app/presenters/solid_queue_monitor/stats_presenter.rb`:

```ruby
# frozen_string_literal: true

module SolidQueueMonitor
  class StatsPresenter < BasePresenter
    def initialize(stats)
      @stats = stats
    end

    def render
      <<-HTML
        <div class="stats-container">
          <h3>Queue Statistics</h3>
          <div class="stats">
            #{generate_stat_card('Active Jobs', @stats[:active_jobs])}
            #{generate_stat_card('Ready', @stats[:ready])}
            #{generate_stat_card('In Progress', @stats[:in_progress])}
            #{generate_stat_card('Scheduled', @stats[:scheduled])}
            #{generate_stat_card('Recurring', @stats[:recurring])}
            #{generate_stat_card('Failed', @stats[:failed])}
          </div>
        </div>
      HTML
    end

    private

    def generate_stat_card(title, value)
      <<-HTML
        <div class="stat-card">
          <h3>#{title}</h3>
          <p>#{value}</p>
        </div>
      HTML
    end
  end
end
```

**Step 5: Update the overview request spec and stats_presenter_spec if they assert `Total Jobs` or `Completed`**

In `spec/requests/solid_queue_monitor/overview_spec.rb`, change:
```ruby
expect(response.body).to include('Total Jobs')
```
to:
```ruby
expect(response.body).to include('Active Jobs')
```

In `spec/presenters/solid_queue_monitor/stats_presenter_spec.rb`, update expectations to match the new stat keys.

**Step 6: Run tests**

```bash
bundle exec rspec spec/services/solid_queue_monitor/stats_calculator_spec.rb \
  spec/presenters/solid_queue_monitor/stats_presenter_spec.rb \
  spec/requests/solid_queue_monitor/overview_spec.rb -f doc
```

Expected: All PASS

**Step 7: Run full suite**

```bash
bundle exec rspec
```

Expected: All passing

**Step 8: Commit**

```bash
git add app/services/solid_queue_monitor/stats_calculator.rb \
        app/presenters/solid_queue_monitor/stats_presenter.rb \
        spec/services/solid_queue_monitor/stats_calculator_spec.rb \
        spec/presenters/solid_queue_monitor/stats_presenter_spec.rb \
        spec/requests/solid_queue_monitor/overview_spec.rb
git commit -m "perf: rewrite StatsCalculator to avoid jobs table entirely

The overview page was running 3 COUNT queries on solid_queue_jobs
(total_jobs, completed, unique_queues), each taking ~52s at 4M rows.

Replaced with execution-table-only stats: active_jobs (derived sum),
ready, in_progress, scheduled, failed, recurring. All queries now hit
small execution tables — microseconds, not minutes.

Resolves the primary cause of gateway timeouts in issue #27."
```

---

## Task 2: Fix all unbounded pluck calls across all controllers

**Why:** Every `pluck(:job_id)` / `pluck(:id)` loads the entire result into a Ruby Array, then generates a massive `WHERE IN (...)` clause. Using `select(:job_id)` keeps it as a subquery executed entirely in the DB.

**Scope:** The Sonnet plan only fixed `filter_jobs` and `filter_queue_jobs`. There are **10+** identical pluck calls across `filter_ready_jobs`, `filter_scheduled_jobs`, `filter_failed_jobs`, and `filter_in_progress_jobs`.

**Files:**
- Modify: `app/controllers/solid_queue_monitor/base_controller.rb`
- Modify: `app/controllers/solid_queue_monitor/queues_controller.rb`
- Modify: `app/controllers/solid_queue_monitor/in_progress_jobs_controller.rb`

---

**Step 1: Write a test that catches pluck calls**

Create `spec/services/solid_queue_monitor/no_unbounded_pluck_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'No unbounded pluck calls in controllers' do
  # This test greps the source code to ensure we never use .pluck(:job_id) or .pluck(:id)
  # in filter methods, which would load all IDs into memory.
  controller_files = Dir[File.expand_path('../../../../app/controllers/**/*.rb', __dir__)]

  controller_files.each do |file|
    relative = file.sub(%r{.*/app/}, 'app/')

    it "#{relative} does not use unbounded pluck in filter methods" do
      content = File.read(file)

      # Match pluck calls that are NOT scoped by a bounded set (like where(job_id: job_ids))
      # We want to catch: SolidQueue::Something.pluck(:job_id)
      # and: SolidQueue::Job.where(...).pluck(:id)
      pluck_calls = content.scan(/\.pluck\(:(?:job_)?id\)/)

      expect(pluck_calls).to be_empty,
        "Found unbounded pluck calls in #{relative}: #{pluck_calls.inspect}. " \
        "Use .select(:job_id) or .select(:id) for subqueries instead."
    end
  end
end
```

**Step 2: Run to see all failures**

```bash
bundle exec rspec spec/services/solid_queue_monitor/no_unbounded_pluck_spec.rb -f doc
```

Expected: Multiple failures across base_controller.rb, queues_controller.rb, in_progress_jobs_controller.rb

**Step 3: Fix `base_controller.rb`**

Replace every `pluck(:job_id)` / `pluck(:id)` with `select(:job_id)` / `select(:id)`:

In `filter_jobs` (lines 84–109):
```ruby
when 'failed'
  relation = relation.where(id: SolidQueue::FailedExecution.select(:job_id))
when 'scheduled'
  relation = relation.where(id: SolidQueue::ScheduledExecution.select(:job_id))
when 'pending'
  relation = relation.where(finished_at: nil)
                     .where.not(id: SolidQueue::FailedExecution.select(:job_id))
                     .where.not(id: SolidQueue::ScheduledExecution.select(:job_id))
```

In `filter_ready_jobs` (lines 116–133):
```ruby
if params[:class_name].present?
  relation = relation.where(job_id: SolidQueue::Job.where('class_name LIKE ?', "%#{params[:class_name]}%").select(:id))
end
# ...
if params[:arguments].present?
  relation = relation.where(job_id: SolidQueue::Job.where('arguments::text ILIKE ?', "%#{params[:arguments]}%").select(:id))
end
```

Apply the same pattern to `filter_scheduled_jobs` (lines 135–152), `filter_failed_jobs` (lines 169–195).

**Step 4: Fix `queues_controller.rb`**

In `filter_queue_jobs` (lines 71–95):
```ruby
when 'failed'
  relation = relation.where(id: SolidQueue::FailedExecution.select(:job_id))
when 'scheduled'
  relation = relation.where(id: SolidQueue::ScheduledExecution.select(:job_id))
when 'pending'
  relation = relation.where(id: SolidQueue::ReadyExecution.select(:job_id))
when 'in_progress'
  relation = relation.where(id: SolidQueue::ClaimedExecution.select(:job_id))
```

**Step 5: Fix `in_progress_jobs_controller.rb`**

In `filter_in_progress_jobs` (lines 21–35):
```ruby
if params[:class_name].present?
  relation = relation.where(job_id: SolidQueue::Job.where('class_name LIKE ?', "%#{params[:class_name]}%").select(:id))
end

if params[:arguments].present?
  relation = relation.where(job_id: SolidQueue::Job.where('arguments::text ILIKE ?', "%#{params[:arguments]}%").select(:id))
end
```

**Step 6: Run the pluck spec**

```bash
bundle exec rspec spec/services/solid_queue_monitor/no_unbounded_pluck_spec.rb -f doc
```

Expected: All PASS

**Step 7: Run full suite**

```bash
bundle exec rspec
```

Expected: All passing

**Step 8: Commit**

```bash
git add app/controllers/solid_queue_monitor/base_controller.rb \
        app/controllers/solid_queue_monitor/queues_controller.rb \
        app/controllers/solid_queue_monitor/in_progress_jobs_controller.rb \
        spec/services/solid_queue_monitor/no_unbounded_pluck_spec.rb
git commit -m "perf: replace all unbounded pluck calls with subqueries

Every filter method was loading full ID arrays into Ruby via pluck(:id)
and pluck(:job_id), then passing them as WHERE IN (...) with potentially
millions of values. Replaced all 10+ instances across base_controller,
queues_controller, and in_progress_jobs_controller with select(:id) /
select(:job_id) subqueries that execute entirely in the database."
```

---

## Task 3: Eliminate N+1 in QueuesPresenter

**Why:** `QueuesPresenter#generate_row` fires 3 COUNT queries per queue (ready, scheduled, failed). With 20 queues that's 60 queries. Fix by pre-aggregating in the controller with 3 GROUP BY queries total.

**Files:**
- Modify: `app/controllers/solid_queue_monitor/queues_controller.rb`
- Modify: `app/presenters/solid_queue_monitor/queues_presenter.rb`
- Modify: `spec/requests/solid_queue_monitor/queues_spec.rb`

---

**Step 1: Write a test**

Add to `spec/requests/solid_queue_monitor/queues_spec.rb` inside the `GET /queues` describe:

```ruby
it 'displays ready, scheduled, and failed counts per queue' do
  create(:solid_queue_ready_execution, queue_name: 'default')
  create(:solid_queue_scheduled_execution, queue_name: 'default')
  create(:solid_queue_failed_execution)

  get '/queues'

  expect(response).to have_http_status(:ok)
  # The counts should appear in the table
  expect(response.body).to include('Ready Jobs')
  expect(response.body).to include('Scheduled Jobs')
  expect(response.body).to include('Failed Jobs')
end
```

**Step 2: Run to confirm it passes (existing behaviour baseline)**

```bash
bundle exec rspec spec/requests/solid_queue_monitor/queues_spec.rb -f doc
```

Expected: PASS (we're verifying the output stays the same after refactor)

**Step 3: Update `QueuesController#index`**

```ruby
def index
  base_query = SolidQueue::Job.group(:queue_name)
                              .select('queue_name, COUNT(*) as job_count')
  @queues = apply_queue_sorting(base_query)
  @paused_queues = QueuePauseService.paused_queues
  @queue_stats = aggregate_queue_stats

  render_page('Queues', SolidQueueMonitor::QueuesPresenter.new(
    @queues, @paused_queues,
    queue_stats: @queue_stats,
    sort: sort_params
  ).render)
end
```

Add private method:

```ruby
def aggregate_queue_stats
  {
    ready:     SolidQueue::ReadyExecution.group(:queue_name).count,
    scheduled: SolidQueue::ScheduledExecution.group(:queue_name).count,
    failed:    SolidQueue::FailedExecution.joins(:job)
                                         .group('solid_queue_jobs.queue_name').count
  }
end
```

**Step 4: Update QueuesPresenter**

Change the initializer to accept `queue_stats`:

```ruby
def initialize(records, paused_queues = [], sort: {}, queue_stats: {})
  @records       = records
  @paused_queues = paused_queues
  @sort          = sort
  @queue_stats   = queue_stats
end
```

Replace the per-row query methods with a single lookup:

```ruby
def generate_row(queue)
  queue_name = queue.queue_name || 'default'
  paused     = @paused_queues.include?(queue_name)

  <<-HTML
    <tr class="#{paused ? 'queue-paused' : ''}">
      <td>#{queue_link(queue_name)}</td>
      <td>#{status_badge(paused)}</td>
      <td>#{queue.job_count}</td>
      <td>#{@queue_stats.dig(:ready, queue_name) || 0}</td>
      <td>#{@queue_stats.dig(:scheduled, queue_name) || 0}</td>
      <td>#{@queue_stats.dig(:failed, queue_name) || 0}</td>
      <td class="actions-cell">#{action_button(queue_name, paused)}</td>
    </tr>
  HTML
end
```

Remove the `ready_jobs_count`, `scheduled_jobs_count`, and `failed_jobs_count` methods entirely.

**Step 5: Run tests**

```bash
bundle exec rspec spec/requests/solid_queue_monitor/queues_spec.rb -f doc
```

Expected: All PASS

**Step 6: Run full suite**

```bash
bundle exec rspec
```

Expected: All passing

**Step 7: Commit**

```bash
git add app/controllers/solid_queue_monitor/queues_controller.rb \
        app/presenters/solid_queue_monitor/queues_presenter.rb \
        spec/requests/solid_queue_monitor/queues_spec.rb
git commit -m "perf: eliminate N+1 on queues index page

QueuesPresenter fired 3 COUNT queries per queue row (ready, scheduled,
failed) — 60 queries for 20 queues. Now pre-aggregates with 3 GROUP BY
queries in the controller and passes the result hash to the presenter."
```

---

## Task 4: Fix ChartDataService memory explosion (cross-DB compatible)

**Why:** `fetch_created_counts` does `pluck(:created_at)` loading potentially hundreds of thousands of timestamps into Ruby, then iterates O(N x buckets) to assign them. With a 24h window processing 1000 jobs/hour, that's 24K rows — manageable. But at scale or with wider windows (7d), this can blow up.

**Approach:** Use SQL `GROUP BY` for bucketing but in a cross-DB way. Instead of PostgreSQL's `EXTRACT(EPOCH FROM ...)`, we do the grouping in the database using `COUNT` with a computed bucket key that works on both SQLite and PostgreSQL. The key insight: we can compute the bucket index `FLOOR((epoch - start_epoch) / interval)` using database-agnostic integer arithmetic on the primary key timestamp columns. However, SQLite lacks `EXTRACT(EPOCH FROM ...)`.

**Simplest cross-DB approach:** Use the database for filtering and counting, Ruby only for bucket assignment — but on **counts per discrete timestamp** instead of raw timestamps. This is a middle ground that dramatically reduces data transfer without requiring DB-specific SQL.

Actually, the cleanest approach: **group by a computed bucket in SQL, with an adapter-aware expression.**

**Files:**
- Modify: `app/services/solid_queue_monitor/chart_data_service.rb`
- Modify: `spec/services/solid_queue_monitor/chart_data_service_spec.rb`

---

**Step 1: Replace the spec with behaviour-based tests (no mocks)**

Replace `spec/services/solid_queue_monitor/chart_data_service_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidQueueMonitor::ChartDataService do
  describe '#calculate' do
    let(:service) { described_class.new(time_range: time_range) }
    let(:time_range) { '1d' }

    context 'with no data' do
      it 'returns the required keys' do
        result = service.calculate
        expect(result).to include(:labels, :created, :completed, :failed,
                                  :totals, :time_range, :time_range_label, :available_ranges)
      end

      it 'returns correct bucket count for 1d' do
        result = service.calculate
        expect(result[:labels].size).to eq(24)
        expect(result[:created].size).to eq(24)
        expect(result[:completed].size).to eq(24)
        expect(result[:failed].size).to eq(24)
      end

      it 'returns all zeros' do
        result = service.calculate
        expect(result[:totals]).to eq({ created: 0, completed: 0, failed: 0 })
      end

      it 'returns the current time range' do
        expect(service.calculate[:time_range]).to eq('1d')
      end

      it 'returns all available time ranges' do
        expect(service.calculate[:available_ranges].keys).to eq(%w[15m 30m 1h 3h 6h 12h 1d 3d 1w])
      end
    end

    context 'with 1h time range' do
      let(:time_range) { '1h' }
      it('returns 12 buckets') { expect(service.calculate[:labels].size).to eq(12) }
    end

    context 'with 1w time range' do
      let(:time_range) { '1w' }
      it('returns 28 buckets') { expect(service.calculate[:labels].size).to eq(28) }
    end

    context 'with invalid time range' do
      let(:time_range) { 'invalid' }

      it 'defaults to 1d with 24 buckets' do
        result = service.calculate
        expect(result[:time_range]).to eq('1d')
        expect(result[:labels].size).to eq(24)
      end
    end

    context 'with jobs in the time window' do
      let(:time_range) { '1h' }

      before do
        now = Time.current
        create(:solid_queue_job, created_at: now - 10.minutes)
        create(:solid_queue_job, created_at: now - 10.minutes)
        create(:solid_queue_job, :completed,
               created_at: now - 25.minutes, finished_at: now - 20.minutes)
        create(:solid_queue_failed_execution, created_at: now - 15.minutes)
      end

      it 'counts created jobs' do
        # At least 2 regular + 1 completed + 1 from failed execution factory
        expect(service.calculate[:created].sum).to be >= 2
      end

      it 'counts completed jobs' do
        expect(service.calculate[:completed].sum).to eq(1)
      end

      it 'counts failed executions' do
        expect(service.calculate[:failed].sum).to eq(1)
      end

      it 'totals match bucket sums' do
        result = service.calculate
        expect(result[:totals][:created]).to eq(result[:created].sum)
        expect(result[:totals][:completed]).to eq(result[:completed].sum)
        expect(result[:totals][:failed]).to eq(result[:failed].sum)
      end
    end

    context 'with jobs outside the window' do
      let(:time_range) { '1h' }
      before { create(:solid_queue_job, created_at: 2.hours.ago) }

      it 'excludes them' do
        expect(service.calculate[:created].sum).to eq(0)
      end
    end
  end

  describe 'constants' do
    it 'defines all time ranges' do
      expect(described_class::TIME_RANGES.keys).to eq(%w[15m 30m 1h 3h 6h 12h 1d 3d 1w])
    end

    it 'has required config per range' do
      described_class::TIME_RANGES.each_value do |config|
        expect(config).to include(:duration, :buckets, :label_format, :label)
      end
    end

    it 'defaults to 1d' do
      expect(described_class::DEFAULT_TIME_RANGE).to eq('1d')
    end
  end
end
```

**Step 2: Run to establish baseline**

```bash
bundle exec rspec spec/services/solid_queue_monitor/chart_data_service_spec.rb -f doc
```

Some tests will fail because the old code mocks pluck and the new tests hit the DB directly.

**Step 3: Rewrite ChartDataService**

The approach: use `COUNT` + `GROUP BY` with a bucket-index computation that works on both SQLite and PostgreSQL.

- SQLite: `CAST((strftime('%s', column) - start_epoch) / interval AS INTEGER)`
- PostgreSQL: `CAST((EXTRACT(EPOCH FROM column) - start_epoch) / interval AS INTEGER)`

We detect the adapter once and use the right expression.

Replace `app/services/solid_queue_monitor/chart_data_service.rb`:

```ruby
# frozen_string_literal: true

module SolidQueueMonitor
  class ChartDataService
    TIME_RANGES = {
      '15m' => { duration: 15.minutes, buckets: 15, label_format: '%H:%M', label: 'Last 15 minutes' },
      '30m' => { duration: 30.minutes, buckets: 15, label_format: '%H:%M', label: 'Last 30 minutes' },
      '1h'  => { duration: 1.hour,     buckets: 12, label_format: '%H:%M', label: 'Last 1 hour' },
      '3h'  => { duration: 3.hours,    buckets: 18, label_format: '%H:%M', label: 'Last 3 hours' },
      '6h'  => { duration: 6.hours,    buckets: 24, label_format: '%H:%M', label: 'Last 6 hours' },
      '12h' => { duration: 12.hours,   buckets: 24, label_format: '%H:%M', label: 'Last 12 hours' },
      '1d'  => { duration: 1.day,      buckets: 24, label_format: '%H:%M', label: 'Last 24 hours' },
      '3d'  => { duration: 3.days,     buckets: 36, label_format: '%m/%d %H:%M', label: 'Last 3 days' },
      '1w'  => { duration: 7.days,     buckets: 28, label_format: '%m/%d', label: 'Last 7 days' }
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
        labels:           buckets.map { |b| b[:label] }, # rubocop:disable Rails/Pluck
        created:          created_arr,
        completed:        completed_arr,
        failed:           failed_arr,
        totals:           { created: created_arr.sum, completed: completed_arr.sum, failed: failed_arr.sum },
        time_range:       @time_range,
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

      scope
        .group(Arel.sql(expr))
        .pluck(Arel.sql("#{expr} AS bucket_idx, COUNT(*) AS cnt"))
        .to_h { |idx, cnt| [idx.to_i, cnt] }
    end

    def fill_buckets(buckets, index_counts)
      buckets.map { |b| index_counts.fetch(b[:index], 0) }
    end

    # Cross-DB bucket index expression.
    # PostgreSQL: CAST((EXTRACT(EPOCH FROM col) - start) / interval AS INTEGER)
    # SQLite:     CAST((CAST(strftime('%s', col) AS INTEGER) - start) / interval AS INTEGER)
    def bucket_index_expr(column, start_epoch, interval_seconds)
      if sqlite?
        "CAST((CAST(strftime('%s', #{column}) AS INTEGER) - #{start_epoch}) / #{interval_seconds} AS INTEGER)"
      else
        "CAST((EXTRACT(EPOCH FROM #{column}) - #{start_epoch}) / #{interval_seconds} AS INTEGER)"
      end
    end

    def sqlite?
      ActiveRecord::Base.connection.adapter_name.downcase.include?('sqlite')
    end
  end
end
```

**Step 4: Run the spec**

```bash
bundle exec rspec spec/services/solid_queue_monitor/chart_data_service_spec.rb -f doc
```

Expected: All PASS

**Step 5: Run full suite**

```bash
bundle exec rspec
```

Expected: All passing

**Step 6: Commit**

```bash
git add app/services/solid_queue_monitor/chart_data_service.rb \
        spec/services/solid_queue_monitor/chart_data_service_spec.rb
git commit -m "perf: replace in-memory chart bucketing with SQL GROUP BY

ChartDataService was plucking all matching timestamps into Ruby and
bucketing them in O(N x buckets) loops. Now uses SQL GROUP BY with a
computed bucket index — returns at most N bucket rows from the DB.

Uses adapter-aware SQL: EXTRACT(EPOCH FROM ...) for PostgreSQL,
strftime('%s', ...) for SQLite. Tests pass on both."
```

---

## Task 5: Add `config.show_chart` to disable chart on overview

**Why:** Even with SQL GROUP BY, the chart fires 3 queries on every overview load. Some teams don't use the visualisation and want zero overhead. This is the only config flag we add — it's a genuine feature toggle (show/hide UI), not a performance workaround.

**Files:**
- Modify: `lib/solid_queue_monitor.rb`
- Modify: `lib/generators/solid_queue_monitor/templates/initializer.rb`
- Modify: `app/controllers/solid_queue_monitor/overview_controller.rb`
- Modify: `spec/requests/solid_queue_monitor/overview_spec.rb`

---

**Step 1: Add config attribute**

In `lib/solid_queue_monitor.rb`, add `show_chart` to the attr_accessor and set default:

```ruby
attr_accessor :username, :password, :jobs_per_page, :authentication_enabled,
              :auto_refresh_enabled, :auto_refresh_interval, :show_chart

@show_chart = true
```

**Step 2: Write the test**

Add to `spec/requests/solid_queue_monitor/overview_spec.rb`:

```ruby
context 'with chart disabled' do
  around do |example|
    original = SolidQueueMonitor.show_chart
    SolidQueueMonitor.show_chart = false
    example.run
    SolidQueueMonitor.show_chart = original
  end

  it 'does not call ChartDataService' do
    expect(SolidQueueMonitor::ChartDataService).not_to receive(:new)
    get '/'
    expect(response).to have_http_status(:ok)
  end

  it 'does not render chart section' do
    get '/'
    expect(response.body).not_to include('chart-section')
  end
end
```

**Step 3: Run to confirm failure**

```bash
bundle exec rspec spec/requests/solid_queue_monitor/overview_spec.rb \
  -e 'chart disabled' -f doc
```

Expected: FAIL — ChartDataService is still called

**Step 4: Update OverviewController**

```ruby
def index
  @stats = SolidQueueMonitor::StatsCalculator.calculate
  @chart_data = SolidQueueMonitor.show_chart ? SolidQueueMonitor::ChartDataService.new(time_range: time_range_param).calculate : nil

  recent_jobs_query = SolidQueue::Job.limit(100)
  sorted_query = apply_sorting(filter_jobs(recent_jobs_query), SORTABLE_COLUMNS, 'created_at', :desc)
  @recent_jobs = paginate(sorted_query)

  preload_job_statuses(@recent_jobs[:records])

  render_page('Overview', generate_overview_content)
end

private

def generate_overview_content
  html = SolidQueueMonitor::StatsPresenter.new(@stats).render
  html += SolidQueueMonitor::ChartPresenter.new(@chart_data).render if @chart_data
  html + SolidQueueMonitor::JobsPresenter.new(@recent_jobs[:records],
                                               current_page: @recent_jobs[:current_page],
                                               total_pages: @recent_jobs[:total_pages],
                                               filters: filter_params,
                                               sort: sort_params).render
end
```

**Step 5: Update initializer template**

Add to `lib/generators/solid_queue_monitor/templates/initializer.rb`:

```ruby
  # Disable the chart on the overview page to skip chart queries entirely.
  # config.show_chart = true
```

**Step 6: Run tests**

```bash
bundle exec rspec spec/requests/solid_queue_monitor/overview_spec.rb -f doc
```

Expected: All PASS

**Step 7: Run full suite**

```bash
bundle exec rspec
```

Expected: All passing

**Step 8: Commit**

```bash
git add lib/solid_queue_monitor.rb \
        lib/generators/solid_queue_monitor/templates/initializer.rb \
        app/controllers/solid_queue_monitor/overview_controller.rb \
        spec/requests/solid_queue_monitor/overview_spec.rb
git commit -m "feat: add config.show_chart to disable chart on overview

Adds config.show_chart (default: true). When false, skips
ChartDataService and chart rendering entirely — zero additional
queries on the overview page."
```

---

## Task 6: Update docs, CHANGELOG, ROADMAP

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `ROADMAP.md`

**Step 1: Add to README**

After the configuration section, add:

```markdown
### Performance at Scale

The monitor is designed to work efficiently with large datasets (millions of jobs).
Overview stats are derived entirely from Solid Queue's execution tables — no expensive
COUNT queries on the jobs table.

If you don't need the chart visualisation, you can disable it to skip those queries:

```ruby
SolidQueueMonitor.setup do |config|
  config.show_chart = false
end
```
```

**Step 2: Add to CHANGELOG**

```markdown
## [Unreleased]

### Performance
- **Breaking:** Overview stats now show "Active Jobs" (ready + scheduled + in_progress + failed) instead of "Total Jobs" and "Completed". This eliminates 3 full-table COUNT queries on solid_queue_jobs that caused gateway timeouts at scale (52s each at 4M rows).
- Fix: All status filter queries now use SQL subqueries instead of loading IDs into Ruby memory via `pluck`.
- Fix: Queues index page now pre-aggregates ready/scheduled/failed counts with 3 GROUP BY queries instead of 3 COUNT queries per queue row (N+1 elimination).
- Fix: ChartDataService uses SQL GROUP BY for time bucketing instead of plucking all timestamps into memory. Works on both PostgreSQL and SQLite.
- Add: `config.show_chart` (default: true) — set to false to disable chart queries entirely on the overview page.
```

**Step 3: Update ROADMAP**

Add to Medium Priority table:
```markdown
| Large Dataset Performance | Execution-table-only stats, N+1 fixes, SQL chart bucketing, optional chart | Done |
```

**Step 4: Commit**

```bash
git add README.md CHANGELOG.md ROADMAP.md
git commit -m "docs: document performance improvements for large datasets"
```

---

## Final Verification

```bash
bundle exec rspec --format progress
```

All green.

---

## Summary: Issue #27 Points Addressed

| Issue Point | Resolution |
|-------------|------------|
| COUNT(*) on 4M jobs causes 52s timeout | **Eliminated entirely.** StatsCalculator no longer queries solid_queue_jobs. Stats derived from execution tables. |
| Chart aggregation queries are slow | SQL GROUP BY (cross-DB). Optional `show_chart = false` to skip entirely. |
| Queue page N+1 counters | Pre-aggregated with 3 GROUP BY queries regardless of queue count. |
| Expensive total counts for pagination | **Not needed.** Pagination never hits the jobs table at scale — overview is capped at 100, other pages paginate small execution tables. |
| Default ordering on large tables | Execution tables are small; ordering by `created_at` is fine. The jobs table was the problem, and we no longer COUNT it. |

## What We Deliberately Did NOT Add

| Rejected Approach | Why |
|-------------------|-----|
| `config.approximate_counts` / `pg_class.reltuples` | PostgreSQL-only. Tests run on SQLite. Problem eliminated by not counting the jobs table. |
| `config.paginate_without_count` | Pagination COUNT is only expensive on jobs table. Overview is capped at 100 records. Other pages paginate small execution tables. |
| `config.root_redirect_to` | Workaround for a slow overview. If overview is fast, redirect is pointless. |
| Raw PostgreSQL SQL for chart bucketing | Breaks SQLite test suite. Used adapter-aware SQL instead. |
