/**
 * Client-side SPA Application Logic
 */

document.addEventListener('DOMContentLoaded', () => {
  const apiStatusText = document.getElementById('api-status-text');
  const dbStatusText = document.getElementById('db-status-text');
  const pubsubStatusText = document.getElementById('pubsub-status-text');
  const systemStatusIndicator = document.getElementById('system-status-indicator');
  const btnRefresh = document.getElementById('btn-refresh');
  const taskForm = document.getElementById('task-form');
  const tasksTbody = document.getElementById('tasks-tbody');

  async function checkHealth() {
    try {
      const res = await fetch('/api/v1/tasks?limit=1');
      if (res.ok) {
        systemStatusIndicator.textContent = 'Operational';
        systemStatusIndicator.className = 'badge status-healthy';
      }
    } catch (e) {
      systemStatusIndicator.textContent = 'Disconnected';
      systemStatusIndicator.className = 'badge status-unhealthy';
    }

    try {
      const res = await fetch('/healthz');
      const data = await res.json();
      if (data.status === 'healthy') {
        apiStatusText.textContent = 'Active (Proxy OK)';
        apiStatusText.className = 'service-status status-healthy';
        dbStatusText.textContent = 'Connected';
        dbStatusText.className = 'service-status status-healthy';
        pubsubStatusText.textContent = 'Connected';
        pubsubStatusText.className = 'service-status status-healthy';
      }
    } catch (e) {
      apiStatusText.textContent = 'Offline';
      apiStatusText.className = 'service-status status-unhealthy';
    }
  }

  async function loadTasks() {
    try {
      const res = await fetch('/api/v1/tasks');
      if (!res.ok) {
        throw new Error(`HTTP ${res.status}`);
      }
      const data = await res.json();
      const tasks = data.items || [];

      if (tasks.length === 0) {
        tasksTbody.innerHTML = '<tr><td colspan="5" class="empty-state">No tasks found. Submit a task using the form.</td></tr>';
        return;
      }

      tasksTbody.innerHTML = tasks
        .map((task) => {
          const statusClass = `status-${task.status}`;
          const dateStr = task.created_at ? new Date(task.created_at).toLocaleTimeString() : 'N/A';
          let resultSummary = '-';
          if (task.result) {
            const r = typeof task.result === 'string' ? JSON.parse(task.result) : task.result;
            resultSummary = r.outcome ? `${r.outcome} (${r.durationMs || 0}ms)` : 'Done';
          }

          return `
            <tr>
              <td><strong>${escapeHtml(task.title)}</strong><br/><small style="color:#94a3b8">${task.id.substring(0, 8)}...</small></td>
              <td>${task.priority || 'MEDIUM'}</td>
              <td><span class="badge-status ${statusClass}">${task.status}</span></td>
              <td>${dateStr}</td>
              <td><code>${escapeHtml(resultSummary)}</code></td>
            </tr>
          `;
        })
        .join('');
    } catch (err) {
      tasksTbody.innerHTML = `<tr><td colspan="5" class="empty-state" style="color:#ef4444">Failed to load tasks: ${escapeHtml(err.message)}</td></tr>`;
    }
  }

  function escapeHtml(str) {
    if (!str) return '';
    return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  taskForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    const btn = document.getElementById('btn-submit-task');
    btn.disabled = true;
    btn.textContent = 'Dispatching...';

    const title = document.getElementById('task-title').value;
    const description = document.getElementById('task-desc').value;
    const priority = document.getElementById('task-priority').value;
    const action = document.getElementById('task-action').value;
    let payload = {};

    try {
      const payloadStr = document.getElementById('task-payload').value;
      payload = JSON.parse(payloadStr);
      payload.actionType = action;
    } catch (parseErr) {
      alert('Invalid JSON in custom payload field');
      btn.disabled = false;
      btn.textContent = 'Dispatch Task to API';
      return;
    }

    try {
      const res = await fetch('/api/v1/tasks', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ title, description, priority, payload }),
      });

      if (!res.ok) {
        const errJson = await res.json().catch(() => ({}));
        throw new Error(errJson.detail || `HTTP ${res.status}`);
      }

      document.getElementById('task-title').value = '';
      document.getElementById('task-desc').value = '';
      await loadTasks();
    } catch (err) {
      alert(`Error submitting task: ${err.message}`);
    } finally {
      btn.disabled = false;
      btn.textContent = 'Dispatch Task to API';
    }
  });

  btnRefresh.addEventListener('click', () => {
    checkHealth();
    loadTasks();
  });

  // Initial load
  checkHealth();
  loadTasks();

  // Periodic poll
  setInterval(() => {
    loadTasks();
  }, 3000);
});
