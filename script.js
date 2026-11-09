(function () {
  const header = document.getElementById("header");
  const nav = document.querySelector("[data-nav]");
  const toggle = document.querySelector("[data-nav-toggle]");
  const modal = document.getElementById("book-modal");
  const toast = document.getElementById("toast");
  const quizModal = document.getElementById("quiz-modal");

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

  /* Quiz — works for inline panel and modal */
  const quizCopy = {
    winter: {
      title: "Время чудес",
      meta: "2–9 января · 8 дней",
      shift: "Время чудес",
      why: {
        swim: "Зимняя смена с ежедневным бассейном: мягкий вход в воду без летней толпы, плюс праздничный сюжет.",
        english: "Короткие English-игры встроены в день смены — без зубрёжки, зато с живым общением.",
        friends: "Новогодний квест и командные огоньки: быстро сходятся даже те, кто едет впервые.",
      },
    },
    spring: {
      title: "Весенний импульс",
      meta: "28 марта – 4 апреля · 8 дней",
      shift: "Весенний импульс",
      why: {
        swim: "Весенний заезд держит плавание в ритме каникул — хороший момент подтянуть технику до лета.",
        english: "Упор на разговорный English в игре и быту: ребёнок говорит, потому что это нужно в смене.",
        friends: "Компактная смена на каникулах: успеть подружиться, устать от дела и вернуться к учёбе с зарядом.",
      },
    },
    summer: {
      title: "Лето в Бухте",
      meta: "10–20 июня или 15–25 августа",
      shift: "Лето в Бухте · 10–20 июня",
      why: {
        swim: "Главный летний заезд у воды: плавание каждый день и береговые станции под уровень ребёнка.",
        english: "Утром English-блоки, днём вода и квесты — язык не отдельный урок, а часть дня.",
        friends: "Длинный сюжет, выезды и общая история смены — то, из-за чего просят «ещё раз» в августе.",
      },
    },
  };

  const ageHint = {
    young: "Для 7–9 лет держим мягкий ритм и понятный распорядок — первый заезд без лишнего стресса.",
    mid: "Для 10–12 лет это «золотая» возрастная середина: и самостоятельно, и ещё по-детски увлечённо.",
    teen: "Для 13–15 лет даём больше ответственности в команде и задач посильнее — без ощущения «младшей группы».",
  };

  function initQuiz(root, options) {
    if (!root) return null;
    const isModal = Boolean(options && options.isModal);
    const answers = { age: "", focus: "", when: "" };
    let step = 1;

    function setStep(next) {
      step = next;
      const label = root.querySelector("[data-quiz-step-label]");
      const bar = root.querySelector("[data-quiz-progress]");
      root.querySelectorAll("[data-quiz-step]").forEach((el) => {
        const id = el.getAttribute("data-quiz-step");
        const on = String(id) === String(next);
        el.classList.toggle("is-active", on);
        if (on) el.removeAttribute("hidden");
        else el.setAttribute("hidden", "");
      });
      if (next === "result") {
        if (label) label.textContent = "Готово";
        if (bar) bar.style.width = "100%";
        return;
      }
      if (label) label.textContent = `Вопрос ${next} из 3`;
      if (bar) bar.style.width = `${(Number(next) / 3) * 100}%`;
    }

    function renderResult() {
      const pack = quizCopy[answers.when] || quizCopy.summer;
      const focus = answers.focus || "friends";
      const whyFocus = pack.why[focus] || pack.why.friends;
      const whyAge = ageHint[answers.age] || "";
      const title = root.querySelector("[data-quiz-result-title]");
      const meta = root.querySelector("[data-quiz-result-meta]");
      const why = root.querySelector("[data-quiz-result-why]");
      if (title) title.textContent = pack.title;
      if (meta) meta.textContent = pack.meta;
      if (why) why.textContent = `${whyFocus} ${whyAge}`.trim();
      root.dataset.recommendedShift = pack.shift;
      setStep("result");
    }

    function reset() {
      answers.age = "";
      answers.focus = "";
      answers.when = "";
      delete root.dataset.recommendedShift;
      root.querySelectorAll(".quiz-option.is-selected").forEach((el) => el.classList.remove("is-selected"));
      setStep(1);
    }

    function open() {
      closeModal();
      reset();
      if (isModal) {
        root.classList.add("is-open");
        root.setAttribute("aria-hidden", "false");
        document.body.style.overflow = "hidden";
      }
    }

    function close() {
      if (!isModal) return;
      root.classList.remove("is-open");
      root.setAttribute("aria-hidden", "true");
      if (!modal || !modal.classList.contains("is-open")) {
        document.body.style.overflow = "";
      }
    }

    root.querySelectorAll("[data-quiz-answer]").forEach((btn) => {
      btn.addEventListener("click", () => {
        const key = btn.getAttribute("data-quiz-answer");
        const value = btn.getAttribute("data-value");
        if (!key || !value) return;
        answers[key] = value;
        const stepEl = btn.closest("[data-quiz-step]");
        if (stepEl) {
          stepEl.querySelectorAll(".quiz-option").forEach((o) => o.classList.remove("is-selected"));
        }
        btn.classList.add("is-selected");
        window.setTimeout(() => {
          if (step === 1) setStep(2);
          else if (step === 2) setStep(3);
          else if (step === 3) renderResult();
        }, 180);
      });
    });

    const restart = root.querySelector("[data-quiz-restart]");
    if (restart) restart.addEventListener("click", reset);

    const book = root.querySelector("[data-quiz-book]");
    if (book) {
      book.addEventListener("click", () => {
        const shift = root.dataset.recommendedShift || "";
        close();
        openModal(shift);
      });
    }

    root.querySelectorAll("[data-close-quiz]").forEach((el) => {
      el.addEventListener("click", close);
    });

    setStep(1);
    return { open, close, reset };
  }

  const inlineQuiz = initQuiz(document.querySelector("[data-quiz-root]"));
  const modalQuiz = initQuiz(quizModal, { isModal: true });

  document.querySelectorAll("[data-open-quiz]").forEach((btn) => {
    btn.addEventListener("click", (e) => {
      e.preventDefault();
      const pageQuiz = document.getElementById("quiz");
      if (pageQuiz && inlineQuiz) {
        inlineQuiz.reset();
        pageQuiz.scrollIntoView({ behavior: "smooth", block: "start" });
        return;
      }
      if (modalQuiz) modalQuiz.open();
    });
  });

  document.addEventListener("keydown", (e) => {
    if (e.key !== "Escape") return;
    if (quizModal && quizModal.classList.contains("is-open") && modalQuiz) modalQuiz.close();
    else closeModal();
  });
})();
