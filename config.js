/* Config compartilhada — XVI C.O.R Jovem */
window.COR_CONFIG = {
  supabaseUrl: 'https://bpsznzsgalubbltvcdrh.supabase.co',
  supabaseKey: 'sb_publishable_VWI7ct07ZZN0J-Y9s9D9dQ_XzXNlxkY',
  table: 'inscricoes_cor_jovem',
  decuriasTable: 'decurias_cor_jovem',
  /* Limite de vagas (inscrições ativas, sem canceladas) */
  maxInscricoes: 70,
  /* Troque esta senha antes de compartilhar a dashboard */
  dashPassword: 'corjovem2025',
  event: {
    name: 'XVI C.O.R Jovem',
    parish: 'Paróquia Santo Antônio — Bacaxá · Arquidiocese de Niterói',
    dates: '12 e 13 de setembro',
    deadline: 'até acabarem as vagas',
    ageMin: 15,
    ageMax: 24
  }
};

window.COR_API = {
  headers(extra) {
    const c = window.COR_CONFIG;
    return Object.assign({
      apikey: c.supabaseKey,
      Authorization: 'Bearer ' + c.supabaseKey,
      'Content-Type': 'application/json'
    }, extra || {});
  },

  url(pathQuery) {
    const c = window.COR_CONFIG;
    return c.supabaseUrl + '/rest/v1/' + c.table + (pathQuery || '');
  },

  decuriasUrl(pathQuery) {
    const c = window.COR_CONFIG;
    return c.supabaseUrl + '/rest/v1/' + c.decuriasTable + (pathQuery || '');
  },

  async list() {
    const res = await fetch(this.url('?select=*&order=created_at.desc'), {
      headers: this.headers()
    });
    if (!res.ok) throw new Error(await res.text());
    return res.json();
  },

  /** Conta inscrições ativas (tudo exceto cancelada). */
  async countActive() {
    const q = '?select=id&status=neq.cancelada';
    try {
      const res = await fetch(this.url(q), {
        headers: this.headers({ Prefer: 'count=exact', Range: '0-0' })
      });
      if (res.ok) {
        const range = res.headers.get('content-range');
        if (range) {
          const total = parseInt(String(range).split('/')[1], 10);
          if (Number.isFinite(total)) return total;
        }
      }
    } catch (_) { /* fallback abaixo */ }

    const res = await fetch(this.url(q), { headers: this.headers() });
    if (!res.ok) throw new Error(await res.text());
    const rows = await res.json();
    return Array.isArray(rows) ? rows.length : 0;
  },

  async insert(row) {
    const res = await fetch(this.url(), {
      method: 'POST',
      headers: this.headers({ Prefer: 'return=representation' }),
      body: JSON.stringify(row)
    });
    if (!res.ok) throw new Error(await res.text());
    return res.json();
  },

  async update(id, patch) {
    const res = await fetch(this.url('?id=eq.' + encodeURIComponent(id)), {
      method: 'PATCH',
      headers: this.headers({ Prefer: 'return=representation' }),
      body: JSON.stringify(patch)
    });
    if (!res.ok) throw new Error(await res.text());
    return res.json();
  },

  async remove(id) {
    const res = await fetch(this.url('?id=eq.' + encodeURIComponent(id)), {
      method: 'DELETE',
      headers: this.headers({ Prefer: 'return=minimal' })
    });
    if (!res.ok) throw new Error(await res.text());
    return true;
  },

  async findByWhatsapp(whatsapp) {
    const digits = String(whatsapp || '').replace(/\D/g, '');
    if (digits.length < 10) return [];
    const res = await fetch(
      this.url('?select=id,nome,whatsapp,status&whatsapp=ilike.*' + digits.slice(-8) + '*'),
      { headers: this.headers() }
    );
    if (!res.ok) return [];
    const rows = await res.json();
    return rows.filter(r => String(r.whatsapp || '').replace(/\D/g, '').endsWith(digits.slice(-8)));
  },

  async listDecurias() {
    const res = await fetch(this.decuriasUrl('?select=*&order=nome.asc'), {
      headers: this.headers()
    });
    if (!res.ok) throw new Error(await res.text());
    return res.json();
  },

  async createDecuria(row) {
    const res = await fetch(this.decuriasUrl(), {
      method: 'POST',
      headers: this.headers({ Prefer: 'return=representation' }),
      body: JSON.stringify(row)
    });
    if (!res.ok) throw new Error(await res.text());
    return res.json();
  },

  async updateDecuria(id, patch) {
    const res = await fetch(this.decuriasUrl('?id=eq.' + encodeURIComponent(id)), {
      method: 'PATCH',
      headers: this.headers({ Prefer: 'return=representation' }),
      body: JSON.stringify(patch)
    });
    if (!res.ok) throw new Error(await res.text());
    return res.json();
  },

  async removeDecuria(id) {
    /* libera membros antes de apagar */
    await fetch(this.url('?decuria_id=eq.' + encodeURIComponent(id)), {
      method: 'PATCH',
      headers: this.headers({ Prefer: 'return=minimal' }),
      body: JSON.stringify({ decuria_id: null })
    });
    const res = await fetch(this.decuriasUrl('?id=eq.' + encodeURIComponent(id)), {
      method: 'DELETE',
      headers: this.headers({ Prefer: 'return=minimal' })
    });
    if (!res.ok) throw new Error(await res.text());
    return true;
  }
};
