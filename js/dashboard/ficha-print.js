
  function runBrowserPrint(){

    requestAnimationFrame(()=>{
      setTimeout(()=> window.print(), 50);
    });
  }

  function fichaPrintStyles(){
    return '<style>' +
      '.ficha{font-family:Georgia,"Times New Roman",serif;color:#152029;line-height:1.35;}' +
      '.ficha *{box-sizing:border-box;}' +
      '.ficha-top{display:flex;align-items:center;justify-content:space-between;gap:16px;padding-bottom:14px;border-bottom:2.5px solid #152029;margin-bottom:18px;}' +
      '.ficha-brand{display:flex;align-items:center;gap:12px;min-width:0;}' +
      '.ficha-brand img{width:52px;height:52px;object-fit:contain;}' +
      '.ficha-brand .t{font-family:"Segoe UI",system-ui,sans-serif;}' +
      '.ficha-brand .t strong{display:block;font-size:15px;letter-spacing:.04em;text-transform:uppercase;}' +
      '.ficha-brand .t span{display:block;font-size:11px;color:#4d5c68;margin-top:2px;font-weight:600;}' +
      '.ficha-badge{text-align:right;font-family:"Segoe UI",system-ui,sans-serif;}' +
      '.ficha-badge .kind{display:inline-block;font-size:10px;font-weight:800;letter-spacing:.12em;text-transform:uppercase;color:#c45c26;border:1.5px solid #c45c26;padding:4px 9px;border-radius:4px;}' +
      '.ficha-badge .proto{display:block;margin-top:8px;font-size:11px;font-weight:700;color:#4d5c68;font-variant-numeric:tabular-nums;}' +
      '.ficha-name{font-family:"Segoe UI",system-ui,sans-serif;font-size:26px;font-weight:800;margin:0 0 6px;letter-spacing:-.02em;line-height:1.15;}' +
      '.ficha-meta{font-family:"Segoe UI",system-ui,sans-serif;display:flex;flex-wrap:wrap;gap:6px;margin:0 0 20px;}' +
      '.ficha-meta i{font-style:normal;font-size:11px;font-weight:700;background:#eef3f7;color:#152029;padding:5px 10px;border-radius:999px;}' +
      '.ficha-meta i.ok{background:#e6f4ea;color:#1e6b3a;}' +
      '.ficha-meta i.warn{background:#f8ebe4;color:#9c4a3a;}' +
      '.ficha-sec{margin:0 0 16px;page-break-inside:avoid;}' +
      '.ficha-sec h2{font-family:"Segoe UI",system-ui,sans-serif;font-size:11px;font-weight:800;letter-spacing:.14em;text-transform:uppercase;color:#c45c26;margin:0 0 8px;padding:0 0 6px;border-bottom:1px solid #d4dde5;}' +
      '.ficha-grid{display:grid;grid-template-columns:1fr 1fr;gap:0;border:1px solid #d4dde5;border-radius:6px;overflow:hidden;}' +
      '.ficha-grid .cell{padding:9px 12px;border-bottom:1px solid #e8eef3;border-right:1px solid #e8eef3;font-family:"Segoe UI",system-ui,sans-serif;}' +
      '.ficha-grid .cell:nth-child(2n){border-right:none;}' +
      '.ficha-grid .cell:nth-last-child(-n+2){border-bottom:none;}' +
      '.ficha-grid .cell.full{grid-column:1 / -1;border-right:none;}' +
      '.ficha-grid .cell .l{display:block;font-size:9.5px;font-weight:800;letter-spacing:.08em;text-transform:uppercase;color:#6b7a86;margin-bottom:3px;}' +
      '.ficha-grid .cell .v{display:block;font-size:13px;font-weight:600;color:#152029;word-break:break-word;}' +
      '.ficha-grid .cell .v.empty{color:#9aa6b0;font-weight:500;}' +
      '.ficha-foot{margin-top:22px;padding-top:10px;border-top:1px solid #d4dde5;font-family:"Segoe UI",system-ui,sans-serif;font-size:10px;color:#6b7a86;display:flex;justify-content:space-between;gap:12px;}' +
      '@media print{.ficha-grid{border-color:#bbb;}.ficha-sec h2{border-color:#bbb;}}' +
    '</style>';
  }

  function fichaCell(label, value, full){
    const empty = val(value) == null;
    const text = empty ? '—' : (Array.isArray(value) ? value.join(', ') : value);
    return '<div class="cell'+(full?' full':'')+'"><span class="l">'+esc(label)+'</span><span class="v'+(empty?' empty':'')+'">'+esc(text)+'</span></div>';
  }

  function buildFichaPrint(kind, r){
    const isServo = kind === 'servo';
    const st = STATUS_LABEL[r.status||'nova'] || r.status;
    const stClass = (r.status==='confirmada') ? 'ok' : ((r.status==='cancelada'||r.status==='lista_espera') ? 'warn' : '');
    let body = '';

    if(isServo){
      body =
        '<section class="ficha-sec"><h2>Dados</h2><div class="ficha-grid">' +
          fichaCell('Nome completo', r.nome, true) +
          fichaCell('Nascimento', fmtDay(r.nascimento)) +
          fichaCell('Idade', r.idade) +
          fichaCell('Telefone', r.telefone) +
          fichaCell('Endereço', r.endereco, true) +
        '</div></section>' +
        '<section class="ficha-sec"><h2>Serviço</h2><div class="ficha-grid">' +
          fichaCell('Equipe', r.equipe) +
          fichaCell('Ano COR Jovem', r.ano_cor_jovem) +
          fichaCell('Quer camisa', simNao(r.camisa)) +
          fichaCell('Tamanho', r.tamanho_camisa || '—') +
        '</div></section>' +
        '<section class="ficha-sec"><h2>Fé</h2><div class="ficha-grid">' +
          fichaCell('O que mais marcou', r.marco_cor, true) +
          fichaCell('Oração e sacramentos', r.oracao_sacramentos, true) +
          fichaCell('Sacramentos', r.sacramentos, true) +
        '</div></section>' +
        '<section class="ficha-sec"><h2>Observações da equipe</h2><div class="ficha-grid">' +
          fichaCell('Notas', r.observacoes, true) +
        '</div></section>';
    }else{
      body =
        '<section class="ficha-sec"><h2>Dados</h2><div class="ficha-grid">' +
          fichaCell('Nome completo', r.nome, true) +
          fichaCell('Nascimento', fmtDay(r.nascimento)) +
          fichaCell('Idade', r.idade) +
          fichaCell('WhatsApp', r.whatsapp) +
          fichaCell('Cidade / UF', (r.cidade||'') + (r.uf ? ' / '+r.uf : '')) +
          fichaCell('Bairro', r.bairro) +
          fichaCell('Endereço', r.endereco, true) +
        '</div></section>' +
        (r.menor_idade ? (
          '<section class="ficha-sec"><h2>Responsável</h2><div class="ficha-grid">' +
            fichaCell('Nome', r.responsavel_nome, true) +
            fichaCell('Telefone', r.responsavel_telefone) +
            fichaCell('CPF', r.responsavel_cpf) +
          '</div></section>'
        ) : '') +
        '<section class="ficha-sec"><h2>Saúde</h2><div class="ficha-grid">' +
          fichaCell('Comorbidade', r.comorbidade==='sim'?(r.comorbidade_qual||'Sim'):simNao(r.comorbidade), true) +
          fichaCell('Medicamento', r.medicamento==='sim'?(r.medicamento_qual||'Sim'):simNao(r.medicamento), true) +
          fichaCell('Alergia', r.alergia==='sim'?(r.alergia_qual||'Sim'):simNao(r.alergia), true) +
          fichaCell('Urgência', [r.urgencia_nome, r.urgencia_parentesco ? '('+r.urgencia_parentesco+')' : '', r.urgencia_telefone].filter(Boolean).join(' · '), true) +
        '</div></section>' +
        '<section class="ficha-sec"><h2>Retiro</h2><div class="ficha-grid">' +
          fichaCell('Decúria', decuriaName(r.decuria_id) || '—') +
          fichaCell('Camisa', r.camisa==='sim'?('Sim · '+(r.tamanho_camisa||'')):simNao(r.camisa)) +
          fichaCell('Sacramentos', r.sacramentos, true) +
          fichaCell('Expectativa', r.expectativa, true) +
          fichaCell('Obs. equipe', r.observacoes, true) +
        '</div></section>';
    }

    return fichaPrintStyles() +
      '<article class="ficha">' +
        '<header class="ficha-top">' +
          '<div class="ficha-brand">' +
            '<img src="image/logos/geracao-eucaristica.png" alt="">' +
            '<div class="t"><strong>XVI C.O.R Jovem</strong><span>Paróquia Santo Antônio — Bacaxá</span></div>' +
          '</div>' +
          '<div class="ficha-badge">' +
            '<span class="kind">'+(isServo ? 'Ficha de servo' : 'Ficha de cursista')+'</span>' +
            '<span class="proto">Protocolo '+esc(protocol(r.id))+'</span>' +
          '</div>' +
        '</header>' +
        '<h1 class="ficha-name">'+esc(r.nome || '—')+'</h1>' +
        '<div class="ficha-meta">' +
          '<i class="'+stClass+'">'+esc(st)+'</i>' +
          '<i>'+esc(fmtDate(r.created_at))+'</i>' +
          (isServo && r.equipe ? '<i>'+esc(r.equipe)+'</i>' : '') +
          (!isServo && r.decuria_id ? '<i>'+esc(decuriaName(r.decuria_id))+'</i>' : '') +
          (!isServo && r.menor_idade ? '<i class="warn">Menor de idade</i>' : '') +
        '</div>' +
        body +
        '<footer class="ficha-foot">' +
          '<span>Documento interno da equipe · XVI C.O.R Jovem</span>' +
          '<span>Gerado em '+esc(new Date().toLocaleString('pt-BR'))+'</span>' +
        '</footer>' +
      '</article>';
  }
