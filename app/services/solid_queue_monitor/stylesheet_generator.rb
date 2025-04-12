# frozen_string_literal: true

module SolidQueueMonitor
  class StylesheetGenerator
    def generate
      <<-CSS
        .solid_queue_monitor {
          --primary-color: #3b82f6;
          --success-color: #10b981;
          --error-color: #ef4444;
          --text-color: #1f2937;
          --border-color: #e5e7eb;
          --background-color: #f9fafb;
        }

        .solid_queue_monitor * { box-sizing: border-box; margin: 0; padding: 0; }

        .solid_queue_monitor {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
          line-height: 1.5;
          color: var(--text-color);
          background: var(--background-color);
        }

        .solid_queue_monitor .container {
          max-width: 1200px;
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
          background: white;
          box-shadow: 0 1px 3px rgba(0,0,0,0.1);
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
          background: white;
          padding: 1.5rem 1rem;
          border-radius: 0.5rem;
          box-shadow: 0 1px 3px rgba(0,0,0,0.1);
          text-align: center;
        }

        .solid_queue_monitor .stat-card h3 {
          color: #6b7280;
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
          background: var(--background-color);
          font-weight: 500;
          font-size: 0.875rem;
          text-transform: uppercase;
          letter-spacing: 0.05em;
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
          color: #6b7280;
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
          background: white;
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
          background: #f5f5f5;
          border-radius: 4px;
          font-size: 0.9em;
        }

        .solid_queue_monitor .args-single-line {
          display: inline-block;
          padding: 4px 8px;
          background: #f5f5f5;
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
        background: white;
        padding: 1rem;
        border-radius: 0.5rem;
        box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        flex: 3;
      }

      .solid_queue_monitor .bulk-actions-container {
        display: flex;
        flex-direction: row;
        gap: 0.75rem;
        padding: 1rem;
        background: white;
        border-radius: 0.5rem;
        box-shadow: 0 1px 3px rgba(0,0,0,0.1);
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
        color: #4b5563;
      }

      .solid_queue_monitor .filter-group input,
      .solid_queue_monitor .filter-group select {
        width: 100%;
        padding: 0.5rem;
        border: 1px solid #d1d5db;
        border-radius: 0.375rem;
        font-size: 0.875rem;
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
        background: #f3f4f6;
        color: #4b5563;
        border: 1px solid #d1d5db;
        padding: 0.5rem 1rem;
        border-radius: 0.375rem;
        font-size: 0.875rem;
        text-decoration: none;
        cursor: pointer;
        transition: background-color 0.2s;
      }

      .solid_queue_monitor .reset-button:hover {
        background: #e5e7eb;
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
        background: #f3f4f6;
        padding: 0.5rem;
        border-radius: 0.25rem;
        margin-top: 0.5rem;
      }

      .solid_queue_monitor details {
        margin-top: 0.25rem;
      }

      .solid_queue_monitor summary {
        cursor: pointer;
        color: #6b7280;
        font-size: 0.75rem;
      }

      .solid_queue_monitor summary:hover {
        color: #4b5563;
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
        background: white;
        padding: 0.75rem;
        border-radius: 0.5rem;
        box-shadow: 0 1px 3px rgba(0,0,0,0.1);
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
      CSS
    end
  end
end
