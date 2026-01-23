# frozen_string_literal: true

module SolidQueueMonitor
  class StylesheetGenerator
    def generate
      <<-CSS
        .solid_queue_monitor {
          --primary-color: #3b82f6;
          --success-color: #10b981;
          --error-color: #ef4444;
          --warning-color: #f59e0b;
          --text-color: #1f2937;
          --text-muted: #6b7280;
          --border-color: #e5e7eb;
          --background-color: #f9fafb;
          --card-background: #ffffff;
          --card-shadow: 0 1px 3px rgba(0,0,0,0.1);
          --input-background: #ffffff;
          --input-border: #d1d5db;
          --hover-background: #f3f4f6;
          --code-background: #f5f5f5;
        }

        /* Dark theme */
        .solid_queue_monitor.dark-theme {
          --primary-color: #60a5fa;
          --success-color: #34d399;
          --error-color: #f87171;
          --warning-color: #fbbf24;
          --text-color: #f9fafb;
          --text-muted: #9ca3af;
          --border-color: #2d2d2d;
          --background-color: #000000;
          --card-background: #121212;
          --card-shadow: 0 1px 3px rgba(0,0,0,0.5);
          --input-background: #1e1e1e;
          --input-border: #3d3d3d;
          --hover-background: #1e1e1e;
          --code-background: #1e1e1e;
        }

        .solid_queue_monitor * { box-sizing: border-box; margin: 0; padding: 0; }

        .solid_queue_monitor {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
          line-height: 1.5;
          color: var(--text-color);
          background: var(--background-color);
        }

        .solid_queue_monitor .container {
          width: 95%;
          max-width: 1800px;
          margin: 0 auto;
          padding: 2rem;
        }

        .solid_queue_monitor header {
          margin-bottom: 2rem;
          text-align: center;
        }

        .solid_queue_monitor h1 {
          font-size: 2rem;
          font-weight: 600;
          margin-bottom: 0.5rem;
        }

        .solid_queue_monitor .navigation {
          display: flex;
          flex-wrap: wrap;
          justify-content: center;
          gap: 0.5rem;
          padding: 0.5rem;
        }

        .solid_queue_monitor .nav-link {
          text-decoration: none;
          color: var(--text-color);
          padding: 0.5rem 1rem;
          border-radius: 0.375rem;
          background: var(--card-background);
          box-shadow: var(--card-shadow);
          transition: all 0.2s;
        }

        .solid_queue_monitor .nav-link:hover {
          background: var(--primary-color);
          color: white;
        }

        .solid_queue_monitor .section-wrapper {
          margin-top: 2rem;
        }


        .solid_queue_monitor .section h2 {
          padding: 1rem;
          border-bottom: 1px solid var(--border-color);
          font-size: 1.25rem;
          background: var(--background-color);
        }

        .solid_queue_monitor .section-header-row {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 1.5rem;
          padding: 1rem;
          background: var(--card-background);
          border-radius: 0.5rem;
          box-shadow: var(--card-shadow);
        }

        .solid_queue_monitor .section-header-left {
          display: flex;
          align-items: center;
          gap: 1rem;
        }

        .solid_queue_monitor .section-header-right {
          display: flex;
          align-items: center;
          gap: 0.5rem;
        }

        .solid_queue_monitor .stats-container {
          margin-bottom: 2rem;
        }

        .solid_queue_monitor .stats {
          display: flex;
          flex-direction: row;
          flex-wrap: wrap;
          gap: 1rem;
          margin: 0 -0.5rem;
        }

        .solid_queue_monitor .stat-card {
          flex: 1 1 0;
          min-width: 150px;
          background: var(--card-background);
          padding: 1.5rem 1rem;
          border-radius: 0.5rem;
          box-shadow: var(--card-shadow);
          text-align: center;
        }

        .solid_queue_monitor .stat-card h3 {
          color: var(--text-muted);
          font-size: 0.875rem;
          text-transform: uppercase;
          letter-spacing: 0.05em;
          margin-bottom: 0.5rem;
        }

        .solid_queue_monitor .stat-card p {
          font-size: 1.5rem;
          font-weight: 600;
          color: var(--primary-color);
        }

        .solid_queue_monitor .section h2 {
          padding: 1rem;
          border-bottom: 1px solid var(--border-color);
          font-size: 1.25rem;
        }

        .solid_queue_monitor .table-container {
          width: 100%;
          overflow-x: auto;
          -webkit-overflow-scrolling: touch;
        }

        .solid_queue_monitor table {
          width: 100%;
          min-width: 800px; /* Ensures table doesn't get too squeezed */
          border-collapse: collapse;
          white-space: nowrap;
        }

        .solid_queue_monitor th,#{' '}
        .solid_queue_monitor td {
          padding: 0.75rem 1rem;
          text-align: left;
          border-bottom: 1px solid var(--border-color);
        }

        .solid_queue_monitor th {
          background: var(--hover-background);
          font-weight: 500;
          font-size: 0.875rem;
          text-transform: uppercase;
          letter-spacing: 0.05em;
          color: var(--text-muted);
        }

        .solid_queue_monitor .status-badge {
          display: inline-block;
          padding: 0.25rem 0.5rem;
          border-radius: 9999px;
          font-size: 0.75rem;
          font-weight: 500;
        }

        .solid_queue_monitor .table-actions {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: 1rem;
          border-top: 1px solid var(--border-color);
        }

        .solid_queue_monitor .select-all {
          display: flex;
          align-items: center;
          gap: 0.5rem;
          cursor: pointer;
        }

        .solid_queue_monitor .execute-btn:disabled {
          opacity: 0.5;
          cursor: not-allowed;
        }

        .solid_queue_monitor input[type="checkbox"] {
          width: 1rem;
          height: 1rem;
          cursor: pointer;
        }

        .solid_queue_monitor .status-completed { background: #d1fae5; color: #065f46; }
        .solid_queue_monitor .status-failed { background: #fee2e2; color: #991b1b; }
        .solid_queue_monitor .status-scheduled { background: #dbeafe; color: #1e40af; }
        .solid_queue_monitor .status-pending { background: #f3f4f6; color: #374151; }
        .solid_queue_monitor .status-active { background: #d1fae5; color: #065f46; }
        .solid_queue_monitor .status-paused { background: #fef3c7; color: #92400e; }

        .solid_queue_monitor .queue-paused {
          background-color: #fffbeb;
        }

        .solid_queue_monitor .pause-button {
          background: #f59e0b;
          color: white;
        }

        .solid_queue_monitor .pause-button:hover {
          background: #d97706;
        }

        .solid_queue_monitor .resume-button {
          background: #10b981;
          color: white;
        }

        .solid_queue_monitor .resume-button:hover {
          background: #059669;
        }

        .solid_queue_monitor .execute-btn {
          background: var(--primary-color);
          color: white;
          border: none;
          padding: 0.5rem 1rem;
          border-radius: 0.375rem;
          font-size: 0.875rem;
          cursor: pointer;
          transition: background-color 0.2s;
        }

        .solid_queue_monitor .execute-btn:hover {
          background: #2563eb;
        }

        .solid_queue_monitor .message {
          padding: 1rem;
          margin-bottom: 1rem;
          border-radius: 0.375rem;
          transition: opacity 0.5s ease-in-out;
        }

        .solid_queue_monitor .message-success {
          background: #d1fae5;
          color: #065f46;
        }

        .solid_queue_monitor .message-error {
          background: #fee2e2;
          color: #991b1b;
        }

        .solid_queue_monitor footer {
          text-align: center;
          padding: 2rem 0;
          color: var(--text-muted);
        }

        .solid_queue_monitor .pagination {
          display: flex;
          justify-content: center;
          gap: 0.5rem;
          margin-top: 1rem;
          padding: 1rem;
        }

        .solid_queue_monitor .pagination-nav {
          padding: 0.5rem 1rem;
          font-size: 0.875rem;
        }
      #{'  '}
        .solid_queue_monitor .pagination-gap {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          min-width: 2rem;
          height: 2rem;
          padding: 0 0.5rem;
          color: var(--text-color);
        }

        .solid_queue_monitor .pagination-link.disabled {
          opacity: 0.5;
          cursor: not-allowed;
          pointer-events: none;
        }

        .solid_queue_monitor .pagination-link,
        .solid_queue_monitor .pagination-current {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          min-width: 2rem;
          height: 2rem;
          padding: 0 0.5rem;
          border-radius: 0.375rem;
          font-size: 0.875rem;
          text-decoration: none;
          transition: all 0.2s;
        }

        .solid_queue_monitor .pagination-link {
          background: var(--card-background);
          color: var(--text-color);
          border: 1px solid var(--border-color);
        }

        .solid_queue_monitor .pagination-link:hover {
          background: var(--primary-color);
          color: white;
          border-color: var(--primary-color);
        }

        .solid_queue_monitor .pagination-current {
          background: var(--primary-color);
          color: white;
          font-weight: 500;
        }

        /* Arguments styling */
        .solid_queue_monitor .args-container {
          position: relative;
          max-height: 100px;
          overflow: hidden;
        }

        .solid_queue_monitor .args-content {
          display: block;
          white-space: pre-wrap;
          word-break: break-word;
          max-height: 100px;
          overflow-y: auto;
          padding: 8px;
          background: var(--code-background);
          border-radius: 4px;
          font-size: 0.9em;
        }

        .solid_queue_monitor .args-single-line {
          display: inline-block;
          padding: 4px 8px;
          background: var(--code-background);
          border-radius: 4px;
          font-size: 0.9em;
        }

        .solid_queue_monitor .args-content::-webkit-scrollbar {
          width: 8px;
        }

        .solid_queue_monitor .args-content::-webkit-scrollbar-track {
          background: #f1f1f1;
          border-radius: 4px;
        }

        .solid_queue_monitor .args-content::-webkit-scrollbar-thumb {
          background: #888;
          border-radius: 4px;
        }

        .solid_queue_monitor .args-content::-webkit-scrollbar-thumb:hover {
          background: #666;
        }

      @media (max-width: 768px) {
        .solid_queue_monitor .container {
          padding: 0.5rem;
        }

        .solid_queue_monitor .stats {
          margin: 0;
        }

        .solid_queue_monitor .stat-card {
          flex: 1 1 calc(33.333% - 1rem);
          min-width: 120px;
        }

        .solid_queue_monitor .section {
          margin: 0.5rem 0;
          border-radius: 0.375rem;
        }

        .solid_queue_monitor .table-container {
          width: 100%;
          overflow-x: auto;
        }
      }

      @media (max-width: 480px) {
        .solid_queue_monitor .stat-card {
          flex: 1 1 calc(50% - 1rem);
        }

        .solid_queue_monitor .nav-link {
          width: 100%;
          text-align: center;
        }
        .solid_queue_monitor .pagination-nav {
          display: none;
        }
      }

      .solid_queue_monitor .filter-and-actions-container {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        gap: 1rem;
        margin-bottom: 1rem;
      }

      .solid_queue_monitor .filter-form-container {
        background: var(--card-background);
        padding: 1rem;
        border-radius: 0.5rem;
        box-shadow: var(--card-shadow);
        flex: 3;
      }

      .solid_queue_monitor .bulk-actions-container {
        display: flex;
        flex-direction: row;
        gap: 0.75rem;
        padding: 1rem;
        background: var(--card-background);
        border-radius: 0.5rem;
        box-shadow: var(--card-shadow);
        flex: 2;
        align-items: center;
        justify-content: center;
      }

      .solid_queue_monitor .large-button {
        padding: 0.75rem 1.25rem;
        font-size: 0.9rem;
        text-align: center;
        flex: 1;
      }

      @media (max-width: 992px) {
        .solid_queue_monitor .filter-and-actions-container {
          flex-direction: column;
        }
      #{'  '}
        .solid_queue_monitor .bulk-actions-container {
          width: 100%;
        }
      }

      .solid_queue_monitor .filter-form {
        display: flex;
        flex-wrap: wrap;
        gap: 1rem;
        align-items: flex-end;
      }

      .solid_queue_monitor .filter-group {
        flex: 1;
        min-width: 200px;
      }

      .solid_queue_monitor .filter-group label {
        display: block;
        margin-bottom: 0.5rem;
        font-size: 0.875rem;
        font-weight: 500;
        color: var(--text-muted);
      }

      .solid_queue_monitor .filter-group input,
      .solid_queue_monitor .filter-group select {
        width: 100%;
        padding: 0.5rem;
        border: 1px solid var(--input-border);
        border-radius: 0.375rem;
        font-size: 0.875rem;
        background: var(--input-background);
        color: var(--text-color);
      }

      .solid_queue_monitor .filter-actions {
        display: flex;
        gap: 0.5rem;
      }

      .solid_queue_monitor .filter-button {
        background: var(--primary-color);
        color: white;
        border: none;
        padding: 0.5rem 1rem;
        border-radius: 0.375rem;
        font-size: 0.875rem;
        cursor: pointer;
        transition: background-color 0.2s;
      }

      .solid_queue_monitor .filter-button:hover {
        background: #2563eb;
      }

      .solid_queue_monitor .reset-button {
        background: var(--hover-background);
        color: var(--text-muted);
        border: 1px solid var(--border-color);
        padding: 0.5rem 1rem;
        border-radius: 0.375rem;
        font-size: 0.875rem;
        text-decoration: none;
        cursor: pointer;
        transition: background-color 0.2s;
      }

      .solid_queue_monitor .reset-button:hover {
        background: var(--border-color);
      }

      .solid_queue_monitor .action-button {
        padding: 0.5rem 1rem;
        border-radius: 0.375rem;
        font-size: 0.75rem;
        font-weight: 500;
        cursor: pointer;
        transition: background-color 0.2s;
        border: none;
        text-decoration: none;
      }

      .solid_queue_monitor .retry-button {
        background: #3b82f6;
        color: white;
      }

      .solid_queue_monitor .retry-button:hover {
        background: #2563eb;
      }

      .solid_queue_monitor .discard-button {
        background: #ef4444;
        color: white;
      }

      .solid_queue_monitor .discard-button:hover {
        background: #dc2626;
      }

      .solid_queue_monitor .action-button:disabled {
        opacity: 0.5;
        cursor: not-allowed;
      }

      .solid_queue_monitor .inline-form {
        display: inline-block;
        margin-right: 0.5rem;
      }

      .solid_queue_monitor .actions-cell {
        white-space: nowrap;
      }

      .solid_queue_monitor .bulk-actions {
        display: flex;
        gap: 0.5rem;
      }

      .solid_queue_monitor .error-message {
        color: #dc2626;
        font-weight: 500;
        margin-bottom: 0.25rem;
      }

      .solid_queue_monitor .error-backtrace {
        font-size: 0.75rem;
        white-space: pre-wrap;
        max-height: 200px;
        overflow-y: auto;
        background: var(--code-background);
        padding: 0.5rem;
        border-radius: 0.25rem;
        margin-top: 0.5rem;
      }

      .solid_queue_monitor details {
        margin-top: 0.25rem;
      }

      .solid_queue_monitor summary {
        cursor: pointer;
        color: var(--text-muted);
        font-size: 0.75rem;
      }

      .solid_queue_monitor summary:hover {
        color: var(--text-color);
      }

      .solid_queue_monitor .job-checkbox,
      .solid_queue_monitor .select-all-checkbox {
        width: 1rem;
        height: 1rem;
      }

      .solid_queue_monitor .bulk-actions-bar {
        display: flex;
        gap: 0.75rem;
        margin: 1rem 0;
        background: var(--card-background);
        padding: 0.75rem;
        border-radius: 0.5rem;
        box-shadow: var(--card-shadow);
      }

      .solid_queue_monitor .bulk-actions-bar .action-button {
        padding: 0.6rem 1rem;
        font-size: 0.875rem;
      }

      .solid_queue_monitor .execute-button {
        background: var(--primary-color);
        color: white;
      }

      .solid_queue_monitor .execute-button:hover {
        background: #2563eb;
      }

      /* Header top row with title and auto-refresh */
      .solid_queue_monitor .header-top {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 0.5rem;
      }

      /* Auto-refresh styles - compact design */
      .solid_queue_monitor .auto-refresh-container {
        position: relative;
        display: flex;
        align-items: center;
        gap: 0.5rem;
        padding: 0.375rem 0.625rem;
        background: var(--card-background);
        border-radius: 2rem;
        box-shadow: var(--card-shadow);
        font-size: 0.75rem;
        color: var(--text-muted);
        cursor: default;
      }

      /* Tooltip styles */
      .solid_queue_monitor .auto-refresh-container::after {
        content: attr(data-tooltip);
        position: absolute;
        top: calc(100% + 8px);
        right: 0;
        background: #1f2937;
        color: white;
        padding: 0.5rem 0.75rem;
        border-radius: 0.375rem;
        font-size: 0.75rem;
        line-height: 1.4;
        white-space: nowrap;
        max-width: 280px;
        white-space: normal;
        text-align: left;
        opacity: 0;
        visibility: hidden;
        transition: opacity 0.2s, visibility 0.2s;
        z-index: 1000;
        box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        pointer-events: none;
      }

      /* Tooltip arrow */
      .solid_queue_monitor .auto-refresh-container::before {
        content: "";
        position: absolute;
        top: calc(100% + 2px);
        right: 16px;
        border: 6px solid transparent;
        border-bottom-color: #1f2937;
        opacity: 0;
        visibility: hidden;
        transition: opacity 0.2s, visibility 0.2s;
        z-index: 1001;
        pointer-events: none;
      }

      .solid_queue_monitor .auto-refresh-container:hover::after,
      .solid_queue_monitor .auto-refresh-container:hover::before {
        opacity: 1;
        visibility: visible;
      }

      .solid_queue_monitor .auto-refresh-indicator {
        width: 6px;
        height: 6px;
        border-radius: 50%;
        background: var(--border-color);
        flex-shrink: 0;
      }

      .solid_queue_monitor .auto-refresh-indicator.active {
        background: var(--success-color);
        animation: pulse 2s infinite;
      }

      @keyframes pulse {
        0%, 100% { opacity: 1; }
        50% { opacity: 0.5; }
      }

      .solid_queue_monitor .auto-refresh-countdown {
        font-variant-numeric: tabular-nums;
        font-weight: 500;
        min-width: 1.75rem;
        color: var(--text-color);
        transition: opacity 0.2s;
      }

      /* Toggle switch */
      .solid_queue_monitor .auto-refresh-switch {
        position: relative;
        display: inline-block;
        width: 32px;
        height: 18px;
        flex-shrink: 0;
      }

      .solid_queue_monitor .auto-refresh-switch input {
        opacity: 0;
        width: 0;
        height: 0;
      }

      .solid_queue_monitor .switch-slider {
        position: absolute;
        cursor: pointer;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background-color: var(--border-color);
        transition: 0.2s;
        border-radius: 18px;
      }

      .solid_queue_monitor .switch-slider:before {
        position: absolute;
        content: "";
        height: 14px;
        width: 14px;
        left: 2px;
        bottom: 2px;
        background-color: var(--card-background);
        transition: 0.2s;
        border-radius: 50%;
        box-shadow: 0 1px 2px rgba(0,0,0,0.2);
      }

      .solid_queue_monitor .auto-refresh-switch input:checked + .switch-slider {
        background-color: var(--success-color);
      }

      .solid_queue_monitor .auto-refresh-switch input:checked + .switch-slider:before {
        transform: translateX(14px);
      }

      .solid_queue_monitor .refresh-now-btn {
        display: flex;
        align-items: center;
        justify-content: center;
        background: transparent;
        border: none;
        padding: 0.25rem;
        border-radius: 0.25rem;
        cursor: pointer;
        color: var(--text-muted);
        transition: all 0.2s;
      }

      .solid_queue_monitor .refresh-now-btn:hover {
        color: var(--primary-color);
        background: rgba(59, 130, 246, 0.1);
      }

      @media (max-width: 768px) {
        .solid_queue_monitor .header-top {
          flex-direction: column;
          gap: 0.75rem;
        }

        .solid_queue_monitor .auto-refresh-container {
          align-self: center;
        }

        /* Hide tooltip on mobile - use native title instead */
        .solid_queue_monitor .auto-refresh-container::after,
        .solid_queue_monitor .auto-refresh-container::before {
          display: none;
        }
      }

      /* Navigation active state */
      .solid_queue_monitor .nav-link.active {
        background: var(--primary-color);
        color: white;
        border-left: 3px solid #1d4ed8;
      }

      /* Chart styles */
      .solid_queue_monitor .chart-section {
        background: var(--card-background);
        border-radius: 0.5rem;
        box-shadow: var(--card-shadow);
        padding: 1rem 1.5rem;
        margin-bottom: 2rem;
      }

      .solid_queue_monitor .chart-section.collapsed {
        padding-bottom: 1rem;
      }

      .solid_queue_monitor .chart-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        flex-wrap: wrap;
        gap: 0.75rem;
      }

      .solid_queue_monitor .chart-header-left {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        flex-wrap: wrap;
      }

      .solid_queue_monitor .chart-header h3 {
        font-size: 1rem;
        font-weight: 600;
        color: var(--text-color);
        margin: 0;
      }

      .solid_queue_monitor .chart-toggle-btn {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 28px;
        height: 28px;
        background: var(--hover-background);
        border: 1px solid var(--border-color);
        border-radius: 0.375rem;
        cursor: pointer;
        color: var(--text-muted);
        transition: all 0.2s;
      }

      .solid_queue_monitor .chart-toggle-btn:hover {
        background: var(--border-color);
        color: var(--text-color);
      }

      .solid_queue_monitor .chart-toggle-icon {
        transition: transform 0.2s;
      }

      .solid_queue_monitor .chart-section.collapsed .chart-toggle-icon {
        transform: rotate(-90deg);
      }

      .solid_queue_monitor .chart-summary {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        font-size: 0.8rem;
        color: var(--text-muted);
        margin-left: 0.5rem;
        padding-left: 0.75rem;
        border-left: 1px solid var(--border-color);
      }

      .solid_queue_monitor .summary-item {
        white-space: nowrap;
      }

      .solid_queue_monitor .summary-created {
        color: #3b82f6;
      }

      .solid_queue_monitor .summary-completed {
        color: #10b981;
      }

      .solid_queue_monitor .summary-failed {
        color: #ef4444;
      }

      .solid_queue_monitor .summary-separator {
        color: var(--border-color);
      }

      .solid_queue_monitor .chart-time-select-wrapper {
        position: relative;
      }

      .solid_queue_monitor .chart-time-select {
        appearance: none;
        padding: 0.5rem 2rem 0.5rem 0.75rem;
        font-size: 0.8rem;
        color: var(--text-color);
        background: var(--input-background);
        border: 1px solid var(--border-color);
        border-radius: 0.375rem;
        cursor: pointer;
        background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='16' height='16' viewBox='0 0 24 24' fill='none' stroke='%236b7280' stroke-width='2'%3E%3Cpolyline points='6 9 12 15 18 9'%3E%3C/polyline%3E%3C/svg%3E");
        background-repeat: no-repeat;
        background-position: right 0.5rem center;
        background-size: 14px;
        min-width: 140px;
      }

      .solid_queue_monitor .chart-time-select:hover {
        border-color: var(--text-muted);
      }

      .solid_queue_monitor .chart-time-select:focus {
        outline: none;
        border-color: var(--primary-color);
        box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.1);
      }

      .solid_queue_monitor .chart-collapsible {
        overflow: hidden;
        transition: max-height 0.3s ease-out, opacity 0.2s ease-out, margin-top 0.3s ease-out;
        max-height: 500px;
        opacity: 1;
        margin-top: 1rem;
      }

      .solid_queue_monitor .chart-section.collapsed .chart-collapsible {
        max-height: 0;
        opacity: 0;
        margin-top: 0;
      }

      .solid_queue_monitor .chart-container {
        width: 100%;
        overflow-x: auto;
        overflow-y: hidden;
      }

      .solid_queue_monitor .chart-container svg {
        display: block;
        width: 100%;
        height: auto;
      }

      .solid_queue_monitor .job-activity-chart {
        width: 100%;
        height: auto;
        min-height: 250px;
      }

      .solid_queue_monitor .grid-line {
        stroke: var(--border-color);
        stroke-width: 1;
        stroke-dasharray: 4 4;
      }

      .solid_queue_monitor .axis-line {
        stroke: var(--border-color);
        stroke-width: 1;
      }

      .solid_queue_monitor .axis-label {
        font-size: 11px;
        fill: var(--text-muted);
      }

      .solid_queue_monitor .x-label {
        text-anchor: middle;
      }

      .solid_queue_monitor .y-label {
        text-anchor: end;
      }

      .solid_queue_monitor .chart-line {
        stroke-linecap: round;
        stroke-linejoin: round;
      }

      .solid_queue_monitor .data-point {
        cursor: pointer;
        transition: r 0.2s;
      }

      .solid_queue_monitor .data-point:hover {
        r: 6;
      }

      .solid_queue_monitor .chart-legend {
        display: flex;
        justify-content: center;
        gap: 1.5rem;
        margin-top: 1rem;
        flex-wrap: wrap;
      }

      .solid_queue_monitor .legend-item {
        display: flex;
        align-items: center;
        gap: 0.375rem;
        font-size: 0.875rem;
        color: var(--text-muted);
      }

      .solid_queue_monitor .legend-color {
        width: 12px;
        height: 12px;
        border-radius: 2px;
      }

      .solid_queue_monitor .chart-tooltip {
        position: fixed;
        background: #1f2937;
        color: white;
        padding: 0.5rem 0.75rem;
        border-radius: 0.375rem;
        font-size: 0.75rem;
        pointer-events: none;
        z-index: 1000;
        box-shadow: 0 4px 6px rgba(0,0,0,0.1);
      }

      .solid_queue_monitor .tooltip-label {
        font-weight: 500;
        margin-bottom: 0.25rem;
      }

      .solid_queue_monitor .tooltip-value {
        color: #d1d5db;
      }

      .solid_queue_monitor .chart-empty {
        display: flex;
        align-items: center;
        justify-content: center;
        height: 200px;
        color: var(--text-muted);
        font-size: 0.875rem;
      }

      @media (max-width: 768px) {
        .solid_queue_monitor .chart-section {
          padding: 1rem;
        }

        .solid_queue_monitor .chart-header {
          flex-direction: column;
          align-items: flex-start;
        }

        .solid_queue_monitor .chart-header-left {
          width: 100%;
          flex-wrap: wrap;
        }

        .solid_queue_monitor .chart-summary {
          margin-left: 0;
          padding-left: 0;
          border-left: none;
          margin-top: 0.5rem;
          width: 100%;
        }

        .solid_queue_monitor .chart-time-select {
          width: 100%;
        }

        .solid_queue_monitor .job-activity-chart {
          min-height: 200px;
        }

        .solid_queue_monitor .chart-legend {
          gap: 1rem;
        }
      }

      /* Theme toggle button */
      .solid_queue_monitor .theme-toggle-btn {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 36px;
        height: 36px;
        background: var(--card-background);
        border: 1px solid var(--border-color);
        border-radius: 50%;
        cursor: pointer;
        color: var(--text-muted);
        transition: all 0.2s;
        box-shadow: var(--card-shadow);
      }

      .solid_queue_monitor .theme-toggle-btn:hover {
        color: var(--text-color);
        border-color: var(--text-muted);
      }

      .solid_queue_monitor .theme-toggle-btn svg {
        width: 18px;
        height: 18px;
      }

      /* Hide moon icon in light mode, show sun icon */
      .solid_queue_monitor .theme-icon-moon {
        display: none;
      }

      .solid_queue_monitor .theme-icon-sun {
        display: block;
      }

      /* In dark mode, show moon icon, hide sun icon */
      .solid_queue_monitor.dark-theme .theme-icon-moon {
        display: block;
      }

      .solid_queue_monitor.dark-theme .theme-icon-sun {
        display: none;
      }

      .solid_queue_monitor .header-controls {
        display: flex;
        align-items: center;
        gap: 0.75rem;
      }

      /* Workers Page Styles */
      .solid_queue_monitor .workers-summary {
        display: grid;
        grid-template-columns: repeat(4, 1fr);
        gap: 1rem;
        margin-bottom: 1.5rem;
      }

      .solid_queue_monitor .summary-card {
        background: var(--card-background);
        border: 1px solid var(--border-color);
        border-radius: 0.5rem;
        padding: 1rem 1.25rem;
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 0.25rem;
        border-left: 4px solid var(--border-color);
        position: relative;
      }

      .solid_queue_monitor .summary-card .summary-label {
        font-size: 0.75rem;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        color: var(--text-muted);
      }

      .solid_queue_monitor .summary-card .summary-value {
        font-size: 1.75rem;
        font-weight: 600;
        color: var(--text-color);
      }

      .solid_queue_monitor .summary-healthy {
        border-left-color: #10b981;
      }

      .solid_queue_monitor .summary-healthy .summary-value {
        color: #10b981;
      }

      .solid_queue_monitor .summary-stale {
        border-left-color: #f59e0b;
      }

      .solid_queue_monitor .summary-stale .summary-value {
        color: #f59e0b;
      }

      .solid_queue_monitor .summary-dead {
        border-left-color: #ef4444;
      }

      .solid_queue_monitor .summary-dead .summary-value {
        color: #ef4444;
      }

      .solid_queue_monitor .summary-action {
        font-size: 0.75rem;
        color: #f59e0b;
        text-decoration: none;
        border: 1px solid #f59e0b;
        padding: 0.25rem 0.5rem;
        border-radius: 0.25rem;
        margin-top: 0.5rem;
        transition: all 0.2s;
      }

      .solid_queue_monitor .summary-action:hover {
        background: #f59e0b;
        color: #000;
      }

      .solid_queue_monitor .kind-badge {
        display: inline-block;
        padding: 0.25rem 0.5rem;
        border-radius: 0.25rem;
        font-size: 0.75rem;
        font-weight: 500;
      }

      .solid_queue_monitor .kind-worker {
        background: rgba(59, 130, 246, 0.15);
        color: #3b82f6;
      }

      .solid_queue_monitor .kind-dispatcher {
        background: rgba(249, 115, 22, 0.15);
        color: #f97316;
      }

      .solid_queue_monitor .kind-scheduler {
        background: rgba(168, 85, 247, 0.15);
        color: #a855f7;
      }

      .solid_queue_monitor .kind-other {
        background: rgba(107, 114, 128, 0.15);
        color: #6b7280;
      }

      .solid_queue_monitor .status-healthy {
        background: rgba(16, 185, 129, 0.15);
        color: #10b981;
      }

      .solid_queue_monitor .status-stale {
        background: rgba(245, 158, 11, 0.15);
        color: #f59e0b;
      }

      .solid_queue_monitor .status-dead {
        background: rgba(239, 68, 68, 0.15);
        color: #ef4444;
      }

      .solid_queue_monitor .queue-tag {
        display: inline-block;
        background: var(--card-background);
        border: 1px solid var(--border-color);
        padding: 0.125rem 0.375rem;
        border-radius: 0.25rem;
        font-size: 0.75rem;
        margin-right: 0.25rem;
      }

      .solid_queue_monitor .queue-more {
        color: var(--text-muted);
        font-size: 0.75rem;
      }

      .solid_queue_monitor .jobs-idle {
        color: var(--text-muted);
        font-style: italic;
      }

      .solid_queue_monitor .jobs-processing {
        color: #10b981;
      }

      .solid_queue_monitor .jobs-processing .job-names {
        color: var(--text-muted);
        font-size: 0.8em;
      }

      .solid_queue_monitor .worker-dead {
        background: rgba(239, 68, 68, 0.05);
      }

      .solid_queue_monitor .worker-stale {
        background: rgba(245, 158, 11, 0.05);
      }

      .solid_queue_monitor .action-placeholder {
        color: var(--text-muted);
      }

      /* Table Link Styles */
      .solid_queue_monitor .job-class-link {
        color: var(--text-color);
        text-decoration: none;
        transition: color 0.2s;
      }

      .solid_queue_monitor .job-class-link:hover {
        color: #3b82f6;
        text-decoration: underline;
      }

      .solid_queue_monitor .queue-link {
        color: var(--text-color);
        text-decoration: none;
        transition: color 0.2s;
      }

      .solid_queue_monitor .queue-link:hover {
        color: #3b82f6;
        text-decoration: underline;
      }

      .solid_queue_monitor .back-link {
        color: var(--text-muted);
        text-decoration: none;
        display: inline-flex;
        align-items: center;
        gap: 0.25rem;
        font-size: 0.875rem;
        transition: color 0.2s;
      }

      .solid_queue_monitor .back-link:hover {
        color: var(--text-color);
      }

      .solid_queue_monitor .job-back-link {
        margin-bottom: 1rem;
      }

      .solid_queue_monitor .empty-state {
        text-align: center;
        padding: 3rem 1rem;
        color: var(--text-muted);
      }

      .solid_queue_monitor .empty-state p {
        margin: 0.5rem 0;
      }

      .solid_queue_monitor .empty-state-hint {
        font-size: 0.875rem;
        opacity: 0.7;
      }

      @media (max-width: 768px) {
        .solid_queue_monitor .workers-summary {
          grid-template-columns: repeat(2, 1fr);
        }
      }

      @media (max-width: 480px) {
        .solid_queue_monitor .workers-summary {
          grid-template-columns: 1fr;
        }
      }
      CSS
    end
  end
end
