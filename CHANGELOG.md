# Changelog

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
