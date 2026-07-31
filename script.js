(function () {
  const header = document.getElementById("header");
  const nav = document.querySelector("[data-nav]");
  const toggle = document.querySelector("[data-nav-toggle]");
  const modal = document.getElementById("book-modal");
  const toast = document.getElementById("toast");

  function onScroll() {
    if (!header) return;
    header.classList.toggle("is-scrolled", window.scrollY > 12);
  }

  window.addEventListener("scroll", onScroll, { passive: true });
  onScroll();

  if (toggle && nav) {
    toggle.addEventListener("click", () => {
      const open = nav.classList.toggle("is-open");
      toggle.setAttribute("aria-expanded", String(open));
    });
    nav.querySelectorAll("a").forEach((link) => {
      link.addEventListener("click", () => {
        nav.classList.remove("is-open");
        toggle.setAttribute("aria-expanded", "false");
      });
    });
  }

  function openModal(shiftName) {
    if (!modal) return;
    modal.classList.add("is-open");
    modal.setAttribute("aria-hidden", "false");
    document.body.style.overflow = "hidden";
    if (shiftName) {
      const select = modal.querySelector('select[name="shift"]');
      if (select) {
        const opt = Array.from(select.options).find((o) => o.value === shiftName || o.textContent === shiftName);
        if (opt) select.value = opt.value || opt.textContent;
      }
    }
    const first = modal.querySelector("input, select, textarea");
    if (first) setTimeout(() => first.focus(), 50);
  }

  function closeModal() {
    if (!modal) return;
    modal.classList.remove("is-open");
    modal.setAttribute("aria-hidden", "true");
    document.body.style.overflow = "";
  }

  document.querySelectorAll("[data-open-modal]").forEach((btn) => {
    btn.addEventListener("click", (e) => {
      e.preventDefault();
      openModal(btn.getAttribute("data-shift"));
    });
  });

  document.querySelectorAll("[data-close-modal]").forEach((el) => {
    el.addEventListener("click", closeModal);
  });

  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") closeModal();
  });

  function showToast(message) {
    if (!toast) return;
    toast.textContent = message;
    toast.classList.add("is-visible");
    setTimeout(() => toast.classList.remove("is-visible"), 4200);
  }

  document.querySelectorAll("[data-book-form]").forEach((form) => {
    form.addEventListener("submit", (e) => {
      e.preventDefault();
      const data = new FormData(form);
      const name = String(data.get("name") || "").trim();
      closeModal();
      form.reset();
      showToast(
        name
          ? `${name}, заявка принята. Мы свяжемся в течение дня.`
          : "Заявка принята. Мы свяжемся в течение дня."
      );
    });
  });

  /* Tabs */
  const tabs = document.querySelectorAll("[data-tab]");
  const panels = document.querySelectorAll("[data-panel]");

  function activateTab(id) {
    tabs.forEach((tab) => {
      const on = tab.getAttribute("data-tab") === id;
      tab.classList.toggle("is-active", on);
      tab.setAttribute("aria-selected", String(on));
    });
    panels.forEach((panel) => {
      const on = panel.getAttribute("data-panel") === id;
      panel.classList.toggle("is-active", on);
    });
  }

  tabs.forEach((tab) => {
    tab.addEventListener("click", () => {
      const id = tab.getAttribute("data-tab");
      activateTab(id);
      history.replaceState(null, "", `#${id}`);
    });
  });

  const hash = location.hash.replace("#", "");
  if (hash && document.querySelector(`[data-tab="${hash}"]`)) {
    activateTab(hash);
  }

  /* Reveal */
  const reveals = document.querySelectorAll(".reveal");
  if ("IntersectionObserver" in window) {
    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add("is-in");
            io.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.12, rootMargin: "0px 0px -40px 0px" }
    );
    reveals.forEach((el) => io.observe(el));
  } else {
    reveals.forEach((el) => el.classList.add("is-in"));
  }
})();
