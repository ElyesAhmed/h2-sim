/* Let keyboard users scroll wide scientific tables without adding extra stops. */
(() => {
  'use strict';
  function revealFocus(target) {
    if (target !== document.activeElement) return;
    const button = document.querySelector('.h2sim-community-toggle');
    if (!button) return;
    const box = target.getBoundingClientRect();
    // Include a target below the viewport while native focus scrolling is in flight.
    const overlay = button.getBoundingClientRect();
    if (box.right > overlay.left && box.left < overlay.right &&
        box.bottom > overlay.top) {
      target.scrollIntoView({block: 'center', behavior: 'instant'});
    }
  }
  function mount() {
    // Check after the browser has scrolled its newly focused element into view.
    document.addEventListener('focusin', event => {
      if (event.target.matches('article a, article video, article [tabindex]')) {
        requestAnimationFrame(() => revealFocus(event.target));
      }
    });
    document.querySelectorAll('article .table-wrapper').forEach(wrapper => {
      const table = wrapper.querySelector('table');
      if (!table) return;
      const caption = table.querySelector('caption');
      function update() {
        if (wrapper.scrollWidth > wrapper.clientWidth + 1) {
          wrapper.tabIndex = 0;
          wrapper.setAttribute('role', 'region');
          wrapper.setAttribute('aria-label',
            `${caption ? caption.textContent.trim() : 'Scientific table'} — scroll horizontally`);
        } else {
          wrapper.removeAttribute('tabindex');
          wrapper.removeAttribute('role');
          wrapper.removeAttribute('aria-label');
        }
      }
      update();
      if (typeof ResizeObserver !== 'undefined') new ResizeObserver(update).observe(wrapper);
      else window.addEventListener('resize', update);
    });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', mount);
  else mount();
})();
