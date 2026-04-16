# Changelog

## [1.3.0] - 2026-04-16

### Added

- Content Security Policy compatibility for nonce-based strict CSP. The monitor now reads `content_security_policy_nonce` from the host controller and stamps it onto every inline `<style>` and `<script>` tag emitted by the engine. When no nonce is configured, HTML is byte-identical to prior versions. ([#36](https://github.com/vishaltps/solid_queue_monitor/issues/36))

### Changed

- Removed all inline `onclick`, `onchange`, and `onsubmit` attributes. Behavior is now wired via `addEventListener` and `data-*` attributes.
- Replaced runtime `element.style.display|opacity|transform` mutations with CSS class toggles (`.is-hidden`, `.is-fading`, `.is-expanded`, `.tooltip-visible`, `.countdown-paused`). Tooltip cursor-tracking position is unchanged.
- Consolidated confirm-on-submit dialogs into a single `data-confirm="…"` pattern.

### Notes

No host-app changes required. Apps already using nonce-based CSP will see the UI start working once they upgrade. Apps without CSP continue to receive identical output.

## [1.2.2] - 2026-03-30

### Added

- Support for MySQL Trilogy adapter, enabling use with `trilogy` gem alongside the default `mysql2` adapter ([#34](https://github.com/vishaltps/solid_queue_monitor/pull/34))

## [1.2.1] - 2026-03-17

### Added

- Support for callable values (Proc/Lambda) in `username` and `password` configuration, enabling use with `Rails.application.credentials` and other deferred sources ([#31](https://github.com/vishaltps/solid_queue_monitor/issues/31))
- Initializer template now shows ENV variable and Lambda examples for credentials

## [1.2.0] - 2026-03-07

### Changed

- **BREAKING**: Dashboard "Total Jobs" and "Completed" stats replaced with "Active Jobs" (sum of ready + scheduled + in-progress + failed). This avoids expensive `COUNT(*)` on the jobs table at scale.

### Fixed

- **Performance**: Overview page no longer queries `solid_queue_jobs` for stats — all counts derived from execution tables (resolves gateway timeouts with millions of rows) ([#27](https://github.com/vishaltps/solid_queue_monitor/issues/27))
- **Performance**: Chart data service uses SQL `GROUP BY` bucketing instead of loading all timestamps into Ruby memory
- **Performance**: All filter methods use `.select(:job_id)` subqueries instead of unbounded `.pluck(:job_id)`
- **Performance**: Queue stats pre-aggregated with 3 `GROUP BY` queries, eliminating N+1 per-queue COUNT queries

### Added

- `config.show_chart` option to disable the job activity chart and skip chart queries entirely

## [1.1.0] - 2026-02-07

### Added

- **Global Search** — Search across all job types (ready, scheduled, failed, in-progress, completed) and recurring tasks
  - Search by class name, queue name, arguments, active job ID, and error messages
  - Results grouped by category with counts
  - Accessible from the header on every page
- **Sortable Column Headers** — Click column headers to sort job tables
  - Sort by any column (class name, queue, created at, priority, etc.)
  - Toggle ascending/descending with visual indicators
  - Available on all job list views

## [1.0.1] - 2026-01-23

### Fixed

- Added missing CSS styles for job details page
- Job details page now uses full width layout consistent with other pages

## [1.0.0] - 2026-01-23

### Added

- **Worker Monitoring** - New dedicated workers page showing all Solid Queue processes
  - Real-time view of workers, dispatchers, and schedulers
  - Health status indicators (healthy, stale, dead) based on heartbeat
  - Shows queues each worker is processing
  - Displays jobs currently being processed by each worker
  - Summary cards showing total, healthy, stale, and dead process counts
- **Dead Process Detection** - Identify and clean up zombie processes
  - Visual highlighting for stale (>5 min) and dead (>10 min) processes
  - "Prune Dead Processes" button to remove defunct process records
  - Automatic detection based on last heartbeat timestamp
- **Job Details Page** - Dedicated page for viewing complete job information
  - Full job timeline showing created, scheduled, started, and finished states
  - Timing breakdown with wait time and execution duration
  - Complete error details with backtrace for failed jobs
  - Job arguments displayed in formatted JSON
  - Quick actions (retry/discard) for failed jobs
  - Clickable job class names throughout the UI link to details page
- **Queue Details Page** - Detailed view for individual queues
  - Shows all jobs in a specific queue
  - Displays queue status (active/paused) with pause/resume controls
  - Job counts and filtering options

### Changed

- Updated ROADMAP to reflect v1.0.0 milestone completion
- All high-priority features from roadmap are now complete

## [0.6.0] - 2026-01-20

### Added

- Job Activity Chart on dashboard showing jobs created, completed, and failed over time
  - Pure SVG line chart with no external dependencies
  - 9 configurable time ranges: 15m, 30m, 1h, 3h, 6h, 12h, 1d, 3d, 1w
  - Collapsible chart section with summary totals visible when collapsed
  - Interactive tooltips on hover
  - Smart empty state handling (hides empty series, shows message when no data)
- Dark theme support with toggle button
  - Toggle between light and dark themes
  - Respects system preference (`prefers-color-scheme: dark`)
  - Persists user preference in localStorage
  - True black (#000000) background for OLED displays
- Wider layout (95% width, max 1800px) for better screen utilization
- Navigation active state highlighting current page
- New `ChartDataService` for aggregating job metrics into time buckets
- New `ChartPresenter` for rendering SVG charts

### Improved

- Updated all UI components to use CSS variables for consistent theming
- Enhanced visual hierarchy with improved color contrast in both themes

## [0.5.0] - 2026-01-16

### Added

- Pause/Resume queue functionality for incident response
  - Pause button to stop processing jobs on specific queues
  - Resume button to restart processing on paused queues
  - Visual status indicator showing Active/Paused state
  - Confirmation dialog before pausing to prevent accidents
  - Paused queues highlighted with amber background
- New `QueuePauseService` for handling pause/resume business logic

### Improved

- Replaced controller specs with request specs for better integration testing
- Enhanced flash message handling for better compatibility across environments
- Improved route loading to prevent duplicate route errors in test environments

### Changed

- Updated CI workflow to test on Ruby 3.2 and 3.3 (Rails 8 requires Ruby >= 3.2)
- Reorganized test support files for better maintainability

## [0.4.0] - 2026-01-09

### Added

- Auto-refresh feature for real-time dashboard monitoring
- Configurable auto-refresh interval via `config.auto_refresh_interval` (default: 30 seconds)
- Toggle to enable/disable auto-refresh globally via `config.auto_refresh_enabled`
- Compact auto-refresh controls integrated into header with:
  - iOS-style toggle switch to enable/disable auto-refresh
  - Live countdown timer showing seconds until next refresh
  - Pulsing green indicator when auto-refresh is active
  - Icon-based refresh button for immediate page reload
  - Informative tooltip on hover explaining the feature
- User preference persistence via localStorage (survives page reloads)
- Responsive design for auto-refresh controls on mobile devices

## [0.3.2] - 2025-06-12

### Added

- Added reject functionality for scheduled jobs with bulk operations support
- New "Reject Selected" button in scheduled jobs view alongside "Execute Selected"
- Added `RejectJobService` for handling job rejection logic
- Added confirmation dialog for reject operations to prevent accidental job cancellation
- Added `POST /reject_jobs` route for bulk rejection operations

### Improved

- Enhanced scheduled jobs UI with dual action buttons (Execute/Reject)
- Improved JavaScript form handling to prevent duplicate job ID submissions
- Added proper error handling and success messaging for reject operations
- Optimized button state management for better user experience

### Fixed

- Fixed duplicate job ID issue in form submissions for bulk operations
- Corrected JavaScript form submission logic to prevent parameter duplication

## [0.3.1] - 2024-03-28

### Improved

- Enhanced job arguments display in tables with better formatting
- Improved handling of different argument types (keyword args and plain arrays)
- Added scrollable container for long argument values with styled scrollbar
- Fixed duplicate argument display issues
- Optimized space usage in job tables

## [0.3.0] - 2024-05-27

### Added

- Added arguments filtering across all job views (Overview, Ready, Scheduled, In Progress, Failed)
- Implemented ILIKE search for arguments to allow partial case-insensitive matching
- Added arguments column to In Progress jobs view

### Changed

- Improved job filtering capabilities for more effective debugging
- Optimized database queries for arguments filtering

## [0.2.0] - 2023-03-28

### Added

- Redesigned with RESTful architecture using separate controllers for each resource
- Added monitoring for In Progress jobs using the SolidQueue claimed executions table
- Added direct retry/discard actions for failed jobs in the Recent Jobs view
- Added improved pagination with ellipsis for better navigation
- Added CSS styling for inline forms to improve action buttons layout

### Changed

- Limited Recent Jobs to 100 entries for better performance in high-volume applications
- Reorganized navigation and stat cards to follow logical job lifecycle
- Improved the redirect handling for job actions to maintain context
- Restructured HTML generation for more consistent table layouts
- Optimized database queries for job status determination

### Fixed

- Fixed pagination display for large result sets
- Fixed routing issues with controller namespacing
- Fixed redirect behavior after job actions

## [0.1.2] - 2024-03-18

### Added

- Ability to retry failed jobs individually or in bulk
- Ability to discard failed jobs individually or in bulk
- Improved error display with collapsible backtrace

## [0.1.1] - 2024-03-16

### Changed

- Added CSS scoping with `.solid_queue_monitor` parent class to prevent style conflicts with host applications
- Improved compatibility with various Rails applications and styling frameworks

## [0.1.0] - 2024-03-15

### Added

- Initial release
- Dashboard overview with job statistics
- Job filtering by class name, queue name, and status
- Support for viewing ready, scheduled, recurring, and failed jobs
- Queue monitoring
- Pagination for job lists
- Optional HTTP Basic Authentication
