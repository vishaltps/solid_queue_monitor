module SolidQueueMonitor
  class StylesheetGenerator
    def generate
      <<-CSS
        :root {
          --primary-color: #3b82f6;
          --success-color: #10b981;
          --error-color: #ef4444;
          --text-color: #1f2937;
          --border-color: #e5e7eb;
          --background-color: #f9fafb;
        }

        * { box-sizing: border-box; margin: 0; padding: 0; }

        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
          line-height: 1.5;
          color: var(--text-color);
          background: var(--background-color);
        }

        .container {
          max-width: 1200px;
          margin: 0 auto;
          padding: 2rem;
        }

        header {
          margin-bottom: 2rem;
          text-align: center;
        }

        h1 {
          font-size: 2rem;
          font-weight: 600;
          margin-bottom: 0.5rem;
        }

        .navigation {
          display: flex;
          flex-wrap: wrap;
          justify-content: center;
          gap: 0.5rem;
          padding: 0.5rem;
        }

        .nav-link {
          text-decoration: none;
          color: var(--text-color);
          padding: 0.5rem 1rem;
          border-radius: 0.375rem;
          background: white;
          box-shadow: 0 1px 3px rgba(0,0,0,0.1);
          transition: all 0.2s;
        }

        .nav-link:hover {
          background: var(--primary-color);
          color: white;
        }

        .section-wrapper {
          margin-top: 2rem;
        }


        .section h2 {
          padding: 1rem;
          border-bottom: 1px solid var(--border-color);
          font-size: 1.25rem;
          background: var(--background-color);
        }

        .stats-container {
          margin-bottom: 2rem;
        }

        .stats {
          display: flex;
          flex-direction: row;
          flex-wrap: wrap;
          gap: 1rem;
          margin: 0 -0.5rem;
        }

        .stat-card {
          flex: 1 1 0;
          min-width: 150px;
          background: white;
          padding: 1.5rem 1rem;
          border-radius: 0.5rem;
          box-shadow: 0 1px 3px rgba(0,0,0,0.1);
          text-align: center;
        }

        .stat-card h3 {
          color: #6b7280;
          font-size: 0.875rem;
          text-transform: uppercase;
          letter-spacing: 0.05em;
          margin-bottom: 0.5rem;
        }

        .stat-card p {
          font-size: 1.5rem;
          font-weight: 600;
          color: var(--primary-color);
        }

        .section h2 {
          padding: 1rem;
          border-bottom: 1px solid var(--border-color);
          font-size: 1.25rem;
        }

        .table-container {
          width: 100%;
          overflow-x: auto;
          -webkit-overflow-scrolling: touch;
        }

        table {
          width: 100%;
          min-width: 800px; /* Ensures table doesn't get too squeezed */
          border-collapse: collapse;
          white-space: nowrap;
        }

        th, td {
          padding: 0.75rem 1rem;
          text-align: left;
          border-bottom: 1px solid var(--border-color);
        }

        th {
          background: var(--background-color);
          font-weight: 500;
          font-size: 0.875rem;
          text-transform: uppercase;
          letter-spacing: 0.05em;
        }

        .status-badge {
          display: inline-block;
          padding: 0.25rem 0.5rem;
          border-radius: 9999px;
          font-size: 0.75rem;
          font-weight: 500;
        }

        .table-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  border-top: 1px solid var(--border-color);
}

.select-all {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  cursor: pointer;
}

.execute-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

input[type="checkbox"] {
  width: 1rem;
  height: 1rem;
  cursor: pointer;
}

        .status-completed { background: #d1fae5; color: #065f46; }
        .status-failed { background: #fee2e2; color: #991b1b; }
        .status-scheduled { background: #dbeafe; color: #1e40af; }
        .status-pending { background: #f3f4f6; color: #374151; }

        .execute-btn {
          background: var(--primary-color);
          color: white;
          border: none;
          padding: 0.5rem 1rem;
          border-radius: 0.375rem;
          font-size: 0.875rem;
          cursor: pointer;
          transition: background-color 0.2s;
        }

        .execute-btn:hover {
          background: #2563eb;
        }

        .message {
          padding: 1rem;
          margin-bottom: 1rem;
          border-radius: 0.375rem;
        }

        .message-success {
          background: #d1fae5;
          color: #065f46;
        }

        .message-error {
          background: #fee2e2;
          color: #991b1b;
        }

        footer {
          text-align: center;
          padding: 2rem 0;
          color: #6b7280;
        }

        .pagination {
          display: flex;
          justify-content: center;
          gap: 0.5rem;
          margin-top: 1rem;
          padding: 1rem;
        }

        .pagination-nav {
          padding: 0.5rem 1rem;
          font-size: 0.875rem;
        }
        
        .pagination-gap {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          min-width: 2rem;
          height: 2rem;
          padding: 0 0.5rem;
          color: var(--text-color);
        }

        .pagination-link.disabled {
          opacity: 0.5;
          cursor: not-allowed;
          pointer-events: none;
        }

        .pagination-link,
        .pagination-current {
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

        .pagination-link {
          background: white;
          color: var(--text-color);
          border: 1px solid var(--border-color);
        }

        .pagination-link:hover {
          background: var(--primary-color);
          color: white;
          border-color: var(--primary-color);
        }

        .pagination-current {
          background: var(--primary-color);
          color: white;
          font-weight: 500;
        }

      @media (max-width: 768px) {
        .container {
          padding: 0.5rem;
        }

        .stats {
          margin: 0;
        }

        .stat-card {
          flex: 1 1 calc(33.333% - 1rem);
          min-width: 120px;
        }

        .section {
          margin: 0.5rem 0;
          border-radius: 0.375rem;
        }

        .table-container {
          width: 100%;
          overflow-x: auto;
        }
      }

      @media (max-width: 480px) {
        .stat-card {
          flex: 1 1 calc(50% - 1rem);
        }

        .nav-link {
          width: 100%;
          text-align: center;
        }
        .pagination-nav {
          display: none;
        }
      }
      CSS
    end
  end
end