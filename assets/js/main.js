/* ============================================================
   FoodBridge – Global JavaScript
   ============================================================ */

document.addEventListener('DOMContentLoaded', () => {

  /* ── Sidebar toggle (dashboard pages) ── */
  const sidebar   = document.getElementById('fbSidebar');
  const toggleBtn = document.getElementById('sidebarToggle');
  if (toggleBtn && sidebar) {
    toggleBtn.addEventListener('click', () => sidebar.classList.toggle('open'));
    document.addEventListener('click', e => {
      if (sidebar.classList.contains('open') && !sidebar.contains(e.target) && e.target !== toggleBtn)
        sidebar.classList.remove('open');
    });
  }

  /* ── Auth tabs (login / register) ── */
  document.querySelectorAll('.auth-tab').forEach(tab => {
    tab.addEventListener('click', () => {
      const target = tab.dataset.tab;
      document.querySelectorAll('.auth-tab').forEach(t => t.classList.remove('active'));
      document.querySelectorAll('.auth-panel').forEach(p => p.classList.add('d-none'));
      tab.classList.add('active');
      document.getElementById(target)?.classList.remove('d-none');
    });
  });

  /* ── Toast notification helper ── */
  window.fbToast = (msg, type = 'success') => {
    const t = document.createElement('div');
    t.className = `fb-toast fb-toast-${type}`;
    t.innerHTML = `<i class="bi bi-${type === 'success' ? 'check-circle-fill' : 'exclamation-circle-fill'}"></i> ${msg}`;
    document.body.appendChild(t);
    setTimeout(() => t.classList.add('show'), 50);
    setTimeout(() => { t.classList.remove('show'); setTimeout(() => t.remove(), 400); }, 3000);
  };

  /* ── Status filter tabs ── */
  document.querySelectorAll('[data-filter]').forEach(btn => {
    btn.addEventListener('click', () => {
      const group = btn.closest('[data-filter-group]');
      if (group) group.querySelectorAll('[data-filter]').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      const val = btn.dataset.filter;
      document.querySelectorAll('[data-status]').forEach(row => {
        row.style.display = (val === 'all' || row.dataset.status === val) ? '' : 'none';
      });
    });
  });

  /* ── Confirm dialog ── */
  window.fbConfirm = (msg, cb) => {
    if (confirm(msg)) cb();
  };

  /* ── Simple chart bars (CSS-only progress) ── */
  document.querySelectorAll('[data-progress]').forEach(el => {
    el.querySelector('.fb-progress-bar').style.width = el.dataset.progress + '%';
  });

});

/* Toast styles injected via JS */
const toastStyle = document.createElement('style');
toastStyle.textContent = `
  .fb-toast { position:fixed; bottom:1.5rem; right:1.5rem; background:#1a1a1a; color:#fff;
    padding:.75rem 1.4rem; border-radius:10px; font-size:.88rem; display:flex; align-items:center;
    gap:.6rem; box-shadow:0 8px 24px rgba(0,0,0,.2); opacity:0; transform:translateY(12px);
    transition:all .3s ease; z-index:9999; }
  .fb-toast.show { opacity:1; transform:translateY(0); }
  .fb-toast-success i { color:#52c41a; }
  .fb-toast-error   i { color:#ff4d4f; }
`;
document.head.appendChild(toastStyle);
