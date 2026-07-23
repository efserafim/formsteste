
window.COR_SITE = {
  calcAge(dateStr) {
    if (!dateStr) return null;
    const birth = new Date(String(dateStr).slice(0, 10) + 'T12:00:00');
    if (isNaN(birth.getTime())) return null;
    const today = new Date();
    let age = today.getFullYear() - birth.getFullYear();
    const m = today.getMonth() - birth.getMonth();
    if (m < 0 || (m === 0 && today.getDate() < birth.getDate())) age--;
    return age;
  },

  maskPhone(v) {
    const d = String(v || '').replace(/\D/g, '').slice(0, 11);
    if (d.length <= 2) return d.length ? '(' + d : '';
    if (d.length <= 6) return '(' + d.slice(0, 2) + ') ' + d.slice(2);
    if (d.length <= 10) return '(' + d.slice(0, 2) + ') ' + d.slice(2, 6) + '-' + d.slice(6);
    return '(' + d.slice(0, 2) + ') ' + d.slice(2, 7) + '-' + d.slice(7);
  },

  CONTATOS: [
    { nome: 'Mayara', tel: '(22) 99882-9819', wa: '5522998829819' },
    { nome: 'Aylla', tel: '(22) 99781-2588', wa: '5522997812588' },
    { nome: 'Beatriz', tel: '(22) 92005-0790', wa: '5522920050790' },
    { nome: 'Nicole', tel: '(22) 99805-9390', wa: '5522998059390' }
  ],

  renderContato(selector) {
    const el = typeof selector === 'string' ? document.querySelector(selector) : selector;
    if (!el) return;
    el.classList.add('contato-equipe');
    el.setAttribute('aria-label', 'Contato da equipe');
    el.innerHTML =
      '<img class="board-mark contato-mark" src="image/logos/geracao-eucaristica.png" alt="Geração Eucarística" width="56" height="56" decoding="async">' +
      '<h2>Para mais informações</h2>' +
      '<p class="lead">Contato da equipe responsável pelo XVI C.O.R Jovem — fale pelo WhatsApp:</p>' +
      '<ul class="wa-list">' +
      this.CONTATOS.map(function (c) {
        return (
          '<li><a href="https://wa.me/' + c.wa + '" target="_blank" rel="noopener">' +
          '<span class="wa-name">' + c.nome + '</span>' +
          '<span class="wa-num">' + c.tel + '</span>' +
          '<span class="wa-go">Abrir WhatsApp</span></a></li>'
        );
      }).join('') +
      '</ul>';
  },

  initSaintPeeks(rootOrId, lines) {
    const root = typeof rootOrId === 'string'
      ? document.getElementById(rootOrId)
      : rootOrId;
    if (!root || !lines || !lines.length) return;

    const peeks = [...root.querySelectorAll('.peek')];
    if (!peeks.length) return;

    let i = 0;
    let hideT = null;
    const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    function speak() {
      peeks.forEach(function (p) {
        p.classList.remove('on');
        const b = p.querySelector('.peek-bubble');
        b.classList.remove('show', 'hide');
        b.innerHTML = '';
      });

      const peek = peeks[i % peeks.length];
      const line = lines[i % lines.length];
      const bubble = peek.querySelector('.peek-bubble');
      peek.classList.add('on');
      bubble.innerHTML = '<span class="who">' + line.who + '</span>' + line.text;
      void bubble.offsetWidth;
      bubble.classList.add('show');
      i++;

      clearTimeout(hideT);
      hideT = setTimeout(function () {
        bubble.classList.remove('show');
        bubble.classList.add('hide');
        setTimeout(function () {
          peek.classList.remove('on');
          bubble.classList.remove('hide');
          setTimeout(speak, reduce ? 400 : 700);
        }, reduce ? 100 : 320);
      }, reduce ? 5000 : 4200);
    }

    setTimeout(speak, reduce ? 400 : 1000);
  },

  mountSpamGuard(form) {
    if (!form || form.dataset.spamGuard === '1') return;
    form.dataset.spamGuard = '1';
    form.dataset.openedAt = String(Date.now());
    const wrap = document.createElement('div');
    wrap.className = 'hp-wrap';
    wrap.setAttribute('aria-hidden', 'true');
    wrap.innerHTML =
      '<label>Website<input type="text" name="website" id="hpWebsite" tabindex="-1" autocomplete="off"></label>';
    form.prepend(wrap);
  },

  isSpamSubmission(form) {
    if (!form) return true;
    const hp = form.querySelector('#hpWebsite, input[name="website"]');
    if (hp && String(hp.value || '').trim()) return true;
    const opened = parseInt(form.dataset.openedAt || '0', 10) || 0;
    if (opened && Date.now() - opened < 2800) return true;
    return false;
  }
};
