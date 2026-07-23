

  document.querySelectorAll('.tab').forEach(tab=>{
    tab.addEventListener('click', ()=>{
      document.querySelectorAll('.tab').forEach(t=>{
        t.classList.remove('active');
        t.setAttribute('aria-selected','false');
      });
      document.querySelectorAll('.view').forEach(v=>v.classList.remove('active'));
      tab.classList.add('active');
      tab.setAttribute('aria-selected','true');
      const map = {
        inscricoes:'viewInscricoes',
        servos:'viewServos',
        decurias:'viewDecurias',
        camisas:'viewCamisas'
      };
      const view = document.getElementById(map[tab.dataset.view] || 'viewInscricoes');
      if(view) view.classList.add('active');
      if(tab.dataset.view === 'camisas') renderShirts();
      if(tab.dataset.view === 'servos') renderServos();
    });
  });

  document.getElementById('gateForm').addEventListener('submit', async (e)=>{
    e.preventDefault();
    gateErr.classList.remove('show');
    const email = document.getElementById('gateEmail').value.trim();
    const pass = document.getElementById('gatePass').value;
    const btn = document.getElementById('gateSubmit');
    btn.disabled = true;
    btn.textContent = 'Entrando…';
    try{
      await window.COR_AUTH.login(email, pass);
      openApp();
    }catch(err){
      console.error(err);
      const raw = String(err && err.message || '');
      let msg = 'E-mail ou senha incorretos.';
      if(/confirm|not confirmed/i.test(raw)) msg = 'Confirme o e-mail no Supabase (ou desative a confirmação).';
      else if(/invalid/i.test(raw)) msg = 'E-mail ou senha incorretos.';
      else if(raw) msg = raw;
      showGateError(msg);
    }finally{
      btn.disabled = false;
      btn.textContent = 'Entrar no painel';
    }
  });
  document.getElementById('logoutBtn').addEventListener('click', async ()=>{
    if(window.COR_AUTH) await window.COR_AUTH.logout();
    location.reload();
  });

  document.getElementById('changePassBtn').addEventListener('click', ()=>{
    openPasswordModal(false);
  });

  document.getElementById('pwdForm').addEventListener('submit', async (e)=>{
    e.preventDefault();
    const err = document.getElementById('pwdErr');
    const btn = document.getElementById('pwdSubmit');
    const nova = document.getElementById('pwdNew').value;
    const conf = document.getElementById('pwdConfirm').value;
    err.classList.remove('show');
    if(nova.length < 6){
      err.textContent = 'A senha precisa ter pelo menos 6 caracteres.';
      err.classList.add('show');
      return;
    }
    if(nova !== conf){
      err.textContent = 'As senhas não coincidem.';
      err.classList.add('show');
      return;
    }
    btn.disabled = true;
    btn.textContent = 'Salvando…';
    try{
      await window.COR_AUTH.updatePassword(nova, { must_change_password: false });
      const overlay = document.getElementById('pwdOverlay');
      overlay.dataset.forced = '0';
      overlay.classList.remove('open');
      overlay.setAttribute('aria-hidden','true');
      toast('Senha atualizada!');
    }catch(ex){
      console.error(ex);
      err.textContent = (ex && ex.message) || 'Não foi possível alterar a senha.';
      err.classList.add('show');
    }finally{
      btn.disabled = false;
      btn.textContent = 'Salvar nova senha';
    }
  });
  document.getElementById('closeDrawer').addEventListener('click', closeDetail);
  overlay.addEventListener('click', closeDetail);
  document.addEventListener('keydown', (e)=>{ if(e.key==='Escape') closeDetail(); });

  document.getElementById('editBtn').addEventListener('click', ()=>{
    if(drawerMode === 'servo'){
      const r = servoRows.find(x => x.id === selectedServoId);
      if(!r) return;
      setToolbarEditing(true);
      fillServoDrawerEdit(r);
      return;
    }
    if(drawerMode !== 'inscricao') return;
    const r = rows.find(x => x.id === selectedId);
    if(!r) return;
    setToolbarEditing(true);
    fillDrawerEdit(r);
  });

  document.getElementById('deleteBtn').addEventListener('click', async ()=>{
    if(drawerMode === 'servo'){
      const r = servoRows.find(x => x.id === selectedServoId);
      if(!r) return;
      const ok = confirm('Excluir definitivamente a ficha do servo "' + (r.nome || 'este servo') + '"?\n\nEssa ação não pode ser desfeita.');
      if(!ok) return;
      try{
        await window.COR_API.removeServo(selectedServoId);
        servoRows = servoRows.filter(x => x.id !== selectedServoId);
        selectedServoId = null;
        overlay.classList.remove('open');
        drawer.classList.remove('open');
        drawer.setAttribute('aria-hidden','true');
        renderServos();
        toast('Servo excluído');
      }catch(err){
        console.error(err);
        toast('Erro ao excluir servo.');
      }
      return;
    }
    const r = rows.find(x => x.id === selectedId);
    if(!r) return;
    const ok = confirm('Excluir definitivamente a inscrição de "' + (r.nome || 'este jovem') + '"?\n\nEssa ação não pode ser desfeita.');
    if(!ok) return;
    const ok2 = confirm('Confirma a exclusão?');
    if(!ok2) return;
    try{
      await window.COR_API.remove(selectedId);
      rows = rows.filter(x => x.id !== selectedId);
      setToolbarEditing(false);
      overlay.classList.remove('open');
      drawer.classList.remove('open');
      drawer.setAttribute('aria-hidden','true');
      selectedId = null;
      render();
      toast('Inscrição excluída');
    }catch(err){
      console.error(err);
      toast('Erro ao excluir. Rode o SQL atualizado no Supabase (política de delete).');
    }
  });

  document.getElementById('dStatus').addEventListener('change', async (e)=>{
    if(editing) return;
    const status = e.target.value;
    if(drawerMode === 'servo'){
      if(!selectedServoId) return;
      try{
        await window.COR_API.updateServo(selectedServoId, { status });
        const r = servoRows.find(x => x.id === selectedServoId);
        if(r) r.status = status;
        renderServos();
        toast('Status atualizado: ' + (STATUS_LABEL[status] || status));
      }catch(err){
        console.error(err);
        toast('Não foi possível salvar o status.');
        load(true);
      }
      return;
    }
    if(!selectedId) return;
    try{
      await window.COR_API.update(selectedId, { status });
      const r = rows.find(x => x.id === selectedId);
      if(r) r.status = status;
      render();
      toast('Status atualizado: ' + (STATUS_LABEL[status] || status));
    }catch(err){
      console.error(err);
      toast('Não foi possível salvar o status.');
      load(true);
    }
  });

  document.getElementById('dDecuria').addEventListener('change', async (e)=>{
    if(!selectedId || editing) return;
    const decuria_id = e.target.value || null;
    const r = rows.find(x => x.id === selectedId);
    if(decuria_id && r){
      const d = decuriaById(decuria_id);
      if(d && (r.idade < d.idade_min || r.idade > d.idade_max)){
        toast('Idade '+r.idade+' fora da faixa '+d.idade_min+'-'+d.idade_max+' desta Decúria.');
        e.target.value = r.decuria_id || '';
        return;
      }
    }
    try{
      await window.COR_API.update(selectedId, { decuria_id });
      if(r) r.decuria_id = decuria_id;
      render();
      renderDecurias();
      if(r) fillDrawer(r);
      toast(decuria_id ? 'Adicionado à Decúria' : 'Removido da Decúria');
    }catch(err){
      console.error(err);
      toast('Erro ao atualizar Decúria. Rode o SQL atualizado.');
      load(true);
    }
  });

  document.getElementById('dEquipe').addEventListener('change', async (e)=>{
    if(drawerMode !== 'servo' || !selectedServoId || editing) return;
    let equipe = e.target.value || null;
    if(equipe === '__outro__'){
      const custom = prompt('Nome da equipe:');
      if(!custom || !custom.trim()){
        const cur = servoRows.find(x => x.id === selectedServoId);
        fillEquipeSelect(cur && cur.equipe);
        return;
      }
      equipe = custom.trim();
    }
    try{
      await window.COR_API.updateServo(selectedServoId, { equipe: equipe || '' });
      const r = servoRows.find(x => x.id === selectedServoId);
      if(r) r.equipe = equipe || '';
      fillEquipeSelect(equipe || '');
      fillServoEquipeFilter();
      renderServos();
      if(r && !editing) fillServoDrawer(r);
      toast(equipe ? 'Equipe: ' + equipe : 'Equipe removida');
    }catch(err){
      console.error(err);
      toast('Não foi possível salvar a equipe.');
      load(true);
    }
  });
  document.getElementById('exportOverlay').addEventListener('click', (e)=>{
    if(e.target.id === 'exportOverlay') closeExportModal();
  });
  document.getElementById('exportCloseBtn').addEventListener('click', closeExportModal);
  document.getElementById('exportCloseX').addEventListener('click', closeExportModal);
  document.addEventListener('keydown', (e)=>{
    if(e.key === 'Escape' && document.getElementById('exportOverlay').classList.contains('open')) closeExportModal();
  });
  document.getElementById('doExcelBtn').addEventListener('click', ()=> runExport('excel'));
  document.getElementById('doPdfBtn').addEventListener('click', ()=> runExport('pdf'));
  document.getElementById('doPrintBtn').addEventListener('click', ()=> runExport('print'));
  document.querySelectorAll('.export-presets [data-preset]').forEach(btn=>{
    btn.addEventListener('click', ()=>{
      const key = btn.getAttribute('data-preset');
      renderExportCols(PRESETS[key] || []);
      const presetSelect = document.getElementById('exportPresetSelect');
      if(presetSelect) presetSelect.value = key;
    });
  });
  document.getElementById('exportPresetSelect').addEventListener('change', (e)=>{
    const key = e.target.value;
    renderExportCols(PRESETS[key] || []);
  });

  document.getElementById('shirtExportBtn').addEventListener('click', ()=>{
    openExportModal('camisas');
  });

  ['shirtTipo','shirtSearch','shirtStatus','shirtSize','shirtSort'].forEach(id=>{
    const el = document.getElementById(id);
    el.addEventListener('input', renderShirts);
    el.addEventListener('change', renderShirts);
  });

  document.getElementById('decuriaForm').addEventListener('submit', async (e)=>{
    e.preventDefault();
    const nome = document.getElementById('decNome').value.trim();
    const idade_min = parseInt(document.getElementById('decIdadeMin').value, 10);
    const idade_max = parseInt(document.getElementById('decIdadeMax').value, 10);
    const decurista_nome = document.getElementById('decDecurista').value.trim();
    const cor = (document.getElementById('decCor').value || '').trim().toLowerCase();

    if(!nome || !decurista_nome){ toast('Preencha nome e decurista'); return; }
    if(!/^#[0-9a-f]{6}$/.test(cor)){ toast('Escolha uma cor válida'); return; }
    if(idade_min > idade_max){ toast('Idade mínima não pode ser maior que a máxima'); return; }

    try{
      const saved = await window.COR_API.createDecuria({
        nome, idade_min, idade_max, decurista_nome, cor
      });
      const row = Array.isArray(saved) ? saved[0] : saved;
      if(row) decurias.push(row);
      decurias.sort((a,b)=> String(a.nome).localeCompare(String(b.nome),'pt-BR'));
      fillDecuriaSelects();
      renderDecurias();
      e.target.reset();
      document.getElementById('decIdadeMin').value = 15;
      document.getElementById('decIdadeMax').value = 24;
      document.getElementById('decCor').value = '#c45c26';
      toast('Decúria criada');
    }catch(err){
      console.error(err);
      toast('Erro ao criar. Rode no Supabase: alter table decurias_cor_jovem add column if not exists cor text;');
    }
  });

  document.getElementById('saveNotesBtn').addEventListener('click', async ()=>{
    if(editing) return;
    const observacoes = document.getElementById('dNotes').value.trim() || null;
    if(drawerMode === 'servo'){
      if(!selectedServoId) return;
      try{
        await window.COR_API.updateServo(selectedServoId, { observacoes });
        const r = servoRows.find(x => x.id === selectedServoId);
        if(r) r.observacoes = observacoes;
        toast('Observações salvas');
      }catch(err){
        console.error(err);
        toast('Erro ao salvar observações');
      }
      return;
    }
    if(!selectedId) return;
    try{
      await window.COR_API.update(selectedId, { observacoes });
      const r = rows.find(x => x.id === selectedId);
      if(r) r.observacoes = observacoes;
      toast('Observações salvas');
    }catch(err){
      console.error(err);
      toast('Erro ao salvar observações');
    }
  });
  document.getElementById('printBtn').addEventListener('click', ()=>{
    const sheet = document.getElementById('printSheet');

    if(drawerMode === 'servo'){
      const r = servoRows.find(x => x.id === selectedServoId);
      if(!r){ toast('Abra a ficha do servo para imprimir'); return; }
      sheet.innerHTML = buildFichaPrint('servo', r);
      runBrowserPrint();
      return;
    }

    const r = rows.find(x => x.id === selectedId);
    if(!r){ toast('Abra a ficha do cursista para imprimir'); return; }
    sheet.innerHTML = buildFichaPrint('cursista', r);
    runBrowserPrint();
  });

  document.querySelectorAll('#stats .stat').forEach(el=>{
    el.addEventListener('click', ()=>{
      const st = el.getAttribute('data-status');
      const fl = el.getAttribute('data-filter');
      if(fl){
        statusFilter = '';
        quickFilter = quickFilter === fl ? '' : fl;
      }else{
        quickFilter = '';
        statusFilter = statusFilter === st ? '' : (st || '');
      }
      render();
    });
  });

  ['search','filterCamisa','filterDecuria','filterSort'].forEach(id=>{
    document.getElementById(id).addEventListener('input', render);
    document.getElementById(id).addEventListener('change', render);
  });

  document.getElementById('servoTbody').addEventListener('click', (e)=>{
    const tr = e.target.closest('tr[data-servo-id]');
    if(!tr) return;
    const r = servoRows.find(x => x.id === tr.dataset.servoId);
    if(r) openServoDetail(r);
  });
  document.getElementById('servoSearch').addEventListener('input', renderServos);
  document.getElementById('servoFilterCamisa').addEventListener('change', renderServos);
  document.getElementById('servoFilterEquipe').addEventListener('change', renderServos);
  document.getElementById('servoFilterSort').addEventListener('change', renderServos);
  document.querySelectorAll('#servoStats .stat').forEach(el=>{
    el.addEventListener('click', ()=>{
      document.querySelectorAll('#servoStats .stat').forEach(s=>s.classList.remove('active'));
      el.classList.add('active');
      servoStatusFilter = el.dataset.servoStatus || '';
      renderServos();
    });
  });

  document.getElementById('exportBtn').addEventListener('click', ()=> openExportModal());
  document.getElementById('exportInscBtn').addEventListener('click', ()=> openExportModal('inscricoes'));

  setInterval(()=> load(true), 45000);

bootAuth();
