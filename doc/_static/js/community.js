/* Public community links. No chat backend, tracking, or API credentials. */
(() => {
  'use strict';
  const communityUrl = new URL('../../community.html', document.currentScript.src).href;
  function mount() {
    if (document.getElementById('h2sim-community')) return;
    const root = document.createElement('aside');
    root.id = 'h2sim-community';
    root.className = 'h2sim-community';
    root.setAttribute('aria-label', 'H2sim community');
    root.innerHTML = `
      <button class="h2sim-community-toggle" id="h2sim-community-toggle" type="button"
        aria-expanded="false" aria-controls="h2sim-community-panel">
        <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path d="M20 11.5a8 8 0 0 1-8 8H5l-3 2v-10a9 9 0 0 1 18 0Z"/><path d="M7 10h10M7 14h7"/></svg>
        Talk to the team
      </button>
      <section class="h2sim-community-panel" id="h2sim-community-panel" role="dialog"
        aria-labelledby="h2sim-community-title" aria-describedby="h2sim-community-description" hidden>
        <div class="h2sim-community-header"><div><span class="h2sim-community-eyebrow">H2SIM COMMUNITY</span>
          <h2 id="h2sim-community-title">Let’s build together.</h2></div>
          <button class="h2sim-community-close" type="button" aria-label="Close community panel">×</button>
        </div>
        <p id="h2sim-community-description">Ask the maintainers, compare workflows, or discuss the next development.</p>
        <nav aria-label="Community conversations">
          <a class="h2sim-community-link" href="https://github.com/sintefmath/h2-sim/discussions/new?category=q-a"><strong>Ask a question <span aria-hidden="true">↗</span></strong><span>Setup, examples, and modeling questions</span></a>
          <a class="h2sim-community-link" href="https://github.com/sintefmath/h2-sim/discussions/categories/general"><strong>Developer conversations <span aria-hidden="true">↗</span></strong><span>Code, coupling, solvers, and contributions</span></a>
          <a class="h2sim-community-link" href="https://github.com/sintefmath/h2-sim/discussions/categories/ideas"><strong>Share an idea <span aria-hidden="true">↗</span></strong><span>Suggest an example or a new capability</span></a>
        </nav>
        <p class="h2sim-community-note">Public conversations on GitHub. Sign in to post; replies are asynchronous.</p>
        <a class="h2sim-community-more" href="${communityUrl}">Explore the community →</a>
      </section>`;
    document.body.append(root);
    const toggle = root.querySelector('.h2sim-community-toggle');
    const panel = root.querySelector('.h2sim-community-panel');
    const closeButton = root.querySelector('.h2sim-community-close');
    function close(restoreFocus) {
      panel.hidden = true;
      toggle.setAttribute('aria-expanded', 'false');
      if (restoreFocus) toggle.focus();
    }
    toggle.addEventListener('click', () => {
      if (!panel.hidden) { close(true); return; }
      panel.hidden = false;
      toggle.setAttribute('aria-expanded', 'true');
      closeButton.focus();
    });
    closeButton.addEventListener('click', () => close(true));
    document.addEventListener('keydown', event => {
      if (event.key === 'Escape' && !panel.hidden) { close(true); event.preventDefault(); }
    });
    document.addEventListener('click', event => {
      if (!panel.hidden && !root.contains(event.target)) close(false);
    });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', mount);
  else mount();
})();
