
  function eligibleForDecuria(d){
    return rows.filter(r =>
      r.status !== 'cancelada' &&
      !r.decuria_id &&
      r.idade >= d.idade_min &&
      r.idade <= d.idade_max
    ).sort((a,b)=> String(a.nome).localeCompare(String(b.nome),'pt-BR'));
  }

  function membersOf(decuriaId){
    return rows.filter(r => r.decuria_id === decuriaId)
      .sort((a,b)=> String(a.nome).localeCompare(String(b.nome),'pt-BR'));
  }

  function renderDecurias(){
    const grid = document.getElementById('decuriaGrid');
    const emptyEl = document.getElementById('decuriaEmpty');
    grid.innerHTML = '';
    emptyEl.hidden = decurias.length > 0;

    decurias.forEach(d=>{
      const members = membersOf(d.id);
      const eligible = eligibleForDecuria(d);
      const cor = /^#[0-9A-Fa-f]{6}$/.test(d.cor || '') ? d.cor : '#c45c26';
      const card = document.createElement('div');
      card.className = 'decuria-card';
      card.style.borderLeftColor = cor;
      card.innerHTML =
        '<div>' +
          '<h4><span class="decuria-swatch" style="background:'+esc(cor)+'" aria-hidden="true"></span>'+esc(d.nome)+'</h4>' +
          '<div class="meta">Idades <strong>'+esc(d.idade_min)+'–'+esc(d.idade_max)+'</strong> · ' +
            members.length + ' membro(s)<br>Decurista: <strong>'+esc(d.decurista_nome)+'</strong></div>' +
        '</div>' +
        '<ul class="members">' +
          (members.length
            ? members.map(m =>
                '<li><span>'+esc(m.nome)+' <span class="muted">'+esc(m.idade)+'a</span></span>' +
                '<button type="button" class="btn btn-ghost btn-sm" data-remove="'+esc(m.id)+'">Tirar</button></li>'
              ).join('')
            : '<li class="muted">Nenhum membro ainda</li>') +
        '</ul>' +
        '<div class="actions-row">' +
          '<select class="add-member" data-add="'+esc(d.id)+'">' +
            '<option value="">Adicionar cursista…</option>' +
            eligible.map(m => '<option value="'+esc(m.id)+'">'+esc(m.nome)+' ('+esc(m.idade)+')</option>').join('') +
          '</select>' +
          '<button type="button" class="btn btn-danger btn-sm" data-del-dec="'+esc(d.id)+'">Excluir</button>' +
        '</div>';

      card.querySelectorAll('[data-remove]').forEach(btn=>{
        btn.addEventListener('click', async ()=>{
          const id = btn.getAttribute('data-remove');
          try{
            await window.COR_API.update(id, { decuria_id: null });
            const r = rows.find(x => x.id === id);
            if(r) r.decuria_id = null;
            render();
            renderDecurias();
            toast('Removido da Decúria');
          }catch(err){
            console.error(err);
            toast('Erro ao remover');
          }
        });
      });

      const sel = card.querySelector('.add-member');
      sel.addEventListener('change', async ()=>{
        const id = sel.value;
        if(!id) return;
        try{
          await window.COR_API.update(id, { decuria_id: d.id });
          const r = rows.find(x => x.id === id);
          if(r) r.decuria_id = d.id;
          render();
          renderDecurias();
          toast('Adicionado a '+d.nome);
        }catch(err){
          console.error(err);
          toast('Erro ao adicionar. Rode o SQL das Decúrias.');
        }
      });

      card.querySelector('[data-del-dec]').addEventListener('click', async ()=>{
        if(!confirm('Excluir a Decúria "'+d.nome+'"? Os membros ficam sem equipe.')) return;
        try{
          await window.COR_API.removeDecuria(d.id);
          rows.forEach(r=>{ if(r.decuria_id === d.id) r.decuria_id = null; });
          decurias = decurias.filter(x => x.id !== d.id);
          fillDecuriaSelects();
          render();
          renderDecurias();
          toast('Decúria excluída');
        }catch(err){
          console.error(err);
          toast('Erro ao excluir Decúria');
        }
      });

      grid.appendChild(card);
    });
  }
