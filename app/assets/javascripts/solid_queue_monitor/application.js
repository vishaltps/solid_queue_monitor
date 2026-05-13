// Solid Queue Monitor - main script
//
// Runtime config is read from <body data-*> attributes set by the layout.
// CSP-safe: no eval, no inline handlers, no string-to-code.

(function () {
  'use strict';

  document.addEventListener('DOMContentLoaded', function () {
    initFlashMessage();
    initAutoRefresh();
    initThemeToggle();
    initChartCollapse();
    initChartTooltip();
    initScheduledBulkActions();
    initFailedJobsBulkActions();
    initJobDetailsBehaviors();
    initGlobalBehaviors();
  });

  function initFlashMessage() {
    var el = document.getElementById('flash-message');
    if (!el) return;

    setTimeout(function () {
      el.classList.add('is-fading');
      setTimeout(function () { el.classList.add('is-hidden'); }, 500);
    }, 5000);
  }

  function initAutoRefresh() {
    var cfg = document.body.dataset;
    if (cfg.autoRefreshEnabled !== 'true') return;

    var refreshInterval = parseInt(cfg.autoRefreshInterval, 10) || 30;
    var countdown = refreshInterval;
    var timerId = null;
    var isEnabled = localStorage.getItem('sqm_auto_refresh') !== 'false';

    var toggle = document.getElementById('auto-refresh-toggle');
    var indicator = document.getElementById('auto-refresh-indicator');
    var countdownEl = document.getElementById('auto-refresh-countdown');
    var refreshBtn = document.getElementById('refresh-now-btn');

    function updateUI() {
      if (toggle) toggle.checked = isEnabled;
      if (indicator) indicator.classList.toggle('active', isEnabled);
      if (countdownEl) {
        countdownEl.textContent = countdown + 's';
        countdownEl.classList.toggle('countdown-paused', !isEnabled);
      }
    }

    function tick() {
      countdown -= 1;
      if (countdown <= 0) {
        window.location.reload();
      } else {
        updateUI();
      }
    }

    function stopTimer() {
      if (timerId) {
        clearInterval(timerId);
        timerId = null;
      }
    }

    function startTimer() {
      stopTimer();
      countdown = refreshInterval;
      updateUI();
      timerId = setInterval(tick, 1000);
    }

    function setEnabled(enabled) {
      isEnabled = enabled;
      localStorage.setItem('sqm_auto_refresh', enabled ? 'true' : 'false');

      if (enabled) {
        startTimer();
      } else {
        stopTimer();
        countdown = refreshInterval;
        updateUI();
      }
    }

    if (toggle) {
      toggle.addEventListener('change', function () { setEnabled(this.checked); });
    }
    if (refreshBtn) {
      refreshBtn.addEventListener('click', function () { window.location.reload(); });
    }

    updateUI();
    if (isEnabled) startTimer();
  }

  function initThemeToggle() {
    var body = document.body;
    var themeBtn = document.getElementById('theme-toggle-btn');
    var storageKey = 'sqm_dark_theme';

    function getPreferredTheme() {
      var saved = localStorage.getItem(storageKey);
      if (saved !== null) return saved === 'true';
      return window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
    }

    function setTheme(isDark) {
      body.classList.toggle('dark-theme', isDark);
      localStorage.setItem(storageKey, isDark ? 'true' : 'false');
    }

    setTheme(getPreferredTheme());

    if (themeBtn) {
      themeBtn.addEventListener('click', function () {
        setTheme(!body.classList.contains('dark-theme'));
      });
    }

    if (window.matchMedia) {
      window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function (e) {
        if (localStorage.getItem(storageKey) === null) setTheme(e.matches);
      });
    }
  }

  function initChartCollapse() {
    var chartSection = document.getElementById('chart-section');
    var toggleBtn = document.getElementById('chart-toggle-btn');
    if (!chartSection || !toggleBtn) return;

    if (localStorage.getItem('sqm_chart_collapsed') === 'true') {
      chartSection.classList.add('collapsed');
    }

    toggleBtn.addEventListener('click', function () {
      chartSection.classList.toggle('collapsed');
      var collapsed = chartSection.classList.contains('collapsed');
      localStorage.setItem('sqm_chart_collapsed', collapsed ? 'true' : 'false');
    });
  }

  function initChartTooltip() {
    var tooltip = document.getElementById('chart-tooltip');
    if (!tooltip) return;

    var dataPoints = document.querySelectorAll('.data-point');
    var seriesNames = { created: 'Created', completed: 'Completed', failed: 'Failed' };

    function positionTooltip(e) {
      var x = e.clientX + 10;
      var y = e.clientY - 30;

      if (x + tooltip.offsetWidth > window.innerWidth) {
        x = e.clientX - tooltip.offsetWidth - 10;
      }
      if (y < 0) {
        y = e.clientY + 10;
      }

      tooltip.style.left = x + 'px';
      tooltip.style.top = y + 'px';
    }

    dataPoints.forEach(function (point) {
      point.addEventListener('mouseenter', function (e) {
        var series = this.getAttribute('data-series');
        var label = this.getAttribute('data-label');
        var value = this.getAttribute('data-value');

        tooltip.querySelector('.tooltip-label').textContent = label;
        tooltip.querySelector('.tooltip-value').textContent = seriesNames[series] + ': ' + value;
        tooltip.classList.add('tooltip-visible');
        positionTooltip(e);
      });

      point.addEventListener('mousemove', positionTooltip);
      point.addEventListener('mouseleave', function () {
        tooltip.classList.remove('tooltip-visible');
      });
    });
  }

  function initGlobalBehaviors() {
    document.addEventListener('submit', function (e) {
      var form = e.target;
      var msg = form.dataset && form.dataset.confirm;
      if (msg && !window.confirm(msg)) e.preventDefault();
    }, true);

    document.addEventListener('click', function (e) {
      var el = e.target.closest('[data-confirm-submit]');
      if (!el) return;

      e.preventDefault();
      var msg = el.dataset.confirm || 'Are you sure?';
      if (!window.confirm(msg)) return;

      var formId = el.dataset.confirmSubmit;
      var form = document.getElementById(formId);
      if (form) form.submit();
    });

    var timeRangeSelect = document.getElementById('chart-time-select');
    if (timeRangeSelect) {
      timeRangeSelect.addEventListener('change', function () {
        window.location.href = '?time_range=' + this.value;
      });
    }
  }

  function initScheduledBulkActions() {
    var form = document.getElementById('scheduled-jobs-form');
    if (!form) return;

    var selectAllCheckbox = document.getElementById('scheduled-jobs-select-all');
    var executeButton = document.getElementById('execute-selected-top');
    var rejectButton = document.getElementById('reject-selected-top');

    function selectedCheckboxes() {
      return Array.prototype.slice.call(document.querySelectorAll('input[name="job_ids[]"]:checked'));
    }

    function allJobCheckboxes() {
      return Array.prototype.slice.call(document.getElementsByName('job_ids[]'));
    }

    function updateButtonStates() {
      var checked = selectedCheckboxes().length > 0;
      if (executeButton) executeButton.disabled = !checked;
      if (rejectButton) rejectButton.disabled = !checked;
    }

    function submitForm(actionUrl, selectedIds) {
      allJobCheckboxes().forEach(function (checkbox) { checkbox.checked = false; });
      Array.prototype.slice.call(form.querySelectorAll('input[type="hidden"][name="job_ids[]"]')).forEach(function (input) {
        input.remove();
      });

      form.action = actionUrl;
      selectedIds.forEach(function (id) {
        var input = document.createElement('input');
        input.type = 'hidden';
        input.name = 'job_ids[]';
        input.value = id;
        form.appendChild(input);
      });
      form.submit();
    }

    if (selectAllCheckbox) {
      selectAllCheckbox.addEventListener('change', function () {
        allJobCheckboxes().forEach(function (checkbox) { checkbox.checked = selectAllCheckbox.checked; });
        updateButtonStates();
      });
    }

    allJobCheckboxes().forEach(function (checkbox) {
      checkbox.addEventListener('change', function () {
        if (selectAllCheckbox) {
          selectAllCheckbox.checked = allJobCheckboxes().every(function (item) { return item.checked; });
        }
        updateButtonStates();
      });
    });

    if (executeButton) {
      executeButton.addEventListener('click', function () {
        var selectedIds = selectedCheckboxes().map(function (checkbox) { return checkbox.value; });
        if (selectedIds.length > 0) submitForm(executeButton.dataset.actionUrl, selectedIds);
      });
    }

    if (rejectButton) {
      rejectButton.addEventListener('click', function () {
        var selectedIds = selectedCheckboxes().map(function (checkbox) { return checkbox.value; });
        if (selectedIds.length === 0) return;
        if (window.confirm('Are you sure you want to reject the selected jobs? This action cannot be undone.')) {
          submitForm(rejectButton.dataset.actionUrl, selectedIds);
        }
      });
    }

    updateButtonStates();
  }

  function initFailedJobsBulkActions() {
    var form = document.getElementById('failed-jobs-form');
    if (!form) return;

    var selectAll = document.getElementById('select-all');
    var retryButton = document.getElementById('retry-selected-top');
    var discardButton = document.getElementById('discard-selected-top');

    function checkboxes() {
      return Array.prototype.slice.call(document.querySelectorAll('.job-checkbox'));
    }

    function checkedBoxes() {
      return checkboxes().filter(function (checkbox) { return checkbox.checked; });
    }

    function updateButtonState() {
      var anyChecked = checkedBoxes().length > 0;
      if (retryButton) retryButton.disabled = !anyChecked;
      if (discardButton) discardButton.disabled = !anyChecked;
    }

    function appendHidden(name, value) {
      var input = document.createElement('input');
      input.type = 'hidden';
      input.name = name;
      input.value = value;
      form.appendChild(input);
    }

    function bulkSubmit(action, promptMsg) {
      var ids = checkedBoxes().map(function (checkbox) { return checkbox.value; });
      if (ids.length === 0 || !window.confirm(promptMsg)) return;
      Array.prototype.slice.call(form.querySelectorAll('input[type="hidden"]')).forEach(function (input) { input.remove(); });
      form.action = action;
      ids.forEach(function (id) { appendHidden('job_ids[]', id); });
      form.submit();
    }

    if (selectAll) {
      selectAll.addEventListener('change', function () {
        checkboxes().forEach(function (checkbox) { checkbox.checked = selectAll.checked; });
        updateButtonState();
      });
    }

    checkboxes().forEach(function (checkbox) {
      checkbox.addEventListener('change', function () {
        if (selectAll) selectAll.checked = checkedBoxes().length === checkboxes().length;
        updateButtonState();
      });
    });

    if (retryButton) {
      retryButton.addEventListener('click', function () {
        bulkSubmit(retryButton.dataset.actionUrl, 'Are you sure you want to retry the selected jobs?');
      });
    }
    if (discardButton) {
      discardButton.addEventListener('click', function () {
        bulkSubmit(discardButton.dataset.actionUrl, 'Are you sure you want to discard the selected jobs?');
      });
    }

    updateButtonState();
  }

  function initJobDetailsBehaviors() {
    document.addEventListener('click', function (e) {
      var el = e.target.closest('[data-action]');
      if (!el) return;

      if (el.dataset.stopPropagation === 'true') e.stopPropagation();

      if (el.dataset.action === 'copy') {
        var target = document.getElementById(el.dataset.target);
        if (!target || !navigator.clipboard) return;
        var original = el.innerHTML;
        navigator.clipboard.writeText(target.innerText || target.textContent).then(function () {
          el.innerHTML = 'Copied!';
          setTimeout(function () { el.innerHTML = original; }, 2000);
        });
      }

      if (el.dataset.action === 'show-backtrace') {
        var which = el.dataset.backtrace;
        var appEl = document.getElementById('app-backtrace');
        var fullEl = document.getElementById('full-backtrace');
        if (appEl) appEl.classList.toggle('is-hidden', which !== 'app');
        if (fullEl) fullEl.classList.toggle('is-hidden', which !== 'full');
        document.querySelectorAll('[data-action="show-backtrace"]').forEach(function (btn) {
          btn.classList.toggle('active', btn.dataset.backtrace === which);
        });
      }

      if (el.dataset.action === 'toggle-section') {
        var section = el.closest('.collapsible-section');
        if (section) section.classList.toggle('is-expanded');
      }
    });
  }
}());
