<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<%
Response.CodePage = 65001
Response.Charset  = "UTF-8"
%>
<!--#include file="../config/app.asp"-->
<!--#include file="../Lib/Conexao.asp"-->
<!--#include file="../includes/seguranca.asp"-->
<!--#include file="../includes/utils.asp"-->
<%
Call abreConexao

Dim idProcesso
If IsNumeric(Request.QueryString("id")) Then
    idProcesso = CLng(Request.QueryString("id"))
Else
    idProcesso = 0
End If

If idProcesso = 0 Then
    Response.Redirect "lista.asp"
    Response.End
End If

' ── DADOS DO PROCESSO ────────────────────────────────────
Dim rsProc
Set rsProc = dbQuery( _
    "SELECT P.IdProcesso, P.NumeroProcesso, P.Assunto, P.Descricao, " & _
    "       P.TipoProcesso, P.DataCriacao, P.Ativo, " & _
    "       U.Nome AS CriadorNome, U.Matricula AS CriadorMatricula, " & _
    "       T.IdTramitacao AS IdTramAtual, T.IdSetor AS IdSetorAtual, " & _
    "       S.NomeSetor AS SetorAtual, T.DataEntrada AS EntradaSetorAtual, " & _
    "       DATEDIFF(DAY, T.DataEntrada, GETDATE()) AS DiasNoSetor " & _
    "FROM Processos P " & _
    "INNER JOIN Usuarios U ON U.Matricula = P.MatriculaCriador " & _
    "OUTER APPLY ( " & _
    "   SELECT TOP 1 * FROM Tramitacoes " & _
    "   WHERE IdProcesso = P.IdProcesso AND DataSaida IS NULL " & _
    "   ORDER BY DataEntrada DESC " & _
    ") T " & _
    "OUTER APPLY ( " & _
    "   SELECT NomeSetor FROM Setores WHERE IdSetor = T.IdSetor " & _
    ") S " & _
    "WHERE P.IdProcesso = " & idProcesso)

If rsProc.EOF Then
    Response.Redirect "lista.asp"
    Response.End
End If

Dim numProcesso, assunto, descricao, tipo
Dim criadorNome, dataCriacao
Dim idSetorAtual, setorAtual, diasNoSetor, idTramAtual
Dim processoAtivo, processoFinalizado, statusAtual

numProcesso   = rsProc("NumeroProcesso")
assunto       = rsProc("Assunto")
descricao     = rsProc("Descricao")
tipo          = rsProc("TipoProcesso")
criadorNome   = rsProc("CriadorNome")
dataCriacao   = rsProc("DataCriacao")
processoAtivo = rsProc("Ativo")

If processoAtivo = False Or IsNull(rsProc("IdSetorAtual")) Then
    statusAtual        = "Finalizado"
    processoFinalizado = True
Else
    statusAtual        = "Em andamento"
    processoFinalizado = False
End If

If IsNull(rsProc("IdSetorAtual")) Then
    idSetorAtual = 0
    setorAtual   = "Finalizado"
    diasNoSetor  = 0
    idTramAtual  = 0
Else
    idSetorAtual = rsProc("IdSetorAtual")
    setorAtual   = rsProc("SetorAtual")
    diasNoSetor  = rsProc("DiasNoSetor")
    idTramAtual  = rsProc("IdTramAtual")
End If

rsProc.Close : Set rsProc = Nothing

' ── PERMISSAO: so o setor atual (ou admin) pode agir ─────
' podeAgir = processo ativo E (usuario e do setor atual OU e admin)
Dim podeAgir
podeAgir = (Not processoFinalizado) And (sessIdSetor = idSetorAtual Or sessIsAdmin)

' ── SETORES DESTINO PERMITIDOS (apenas os do fluxo) ──────
Dim rsDestinos
Set rsDestinos = dbQuery( _
    "SELECT F.IdSetorDestino, S.NomeSetor " & _
    "FROM FluxoSetores F " & _
    "INNER JOIN Setores S ON S.IdSetor = F.IdSetorDestino " & _
    "WHERE F.IdSetorOrigem = " & idSetorAtual & " AND F.Ativo = 1 " & _
    "ORDER BY S.NomeSetor")

' ── HISTORICO DE TRAMITACOES ─────────────────────────────
Dim rsHist
Set rsHist = dbQuery( _
    "SELECT T.IdTramitacao, T.IdSetor, S.NomeSetor, T.MatriculaUsuario, " & _
    "       U.Nome AS UsuarioNome, T.Observacao, " & _
    "       T.DataEntrada, T.DataSaida, " & _
    "       DATEDIFF(DAY, T.DataEntrada, ISNULL(T.DataSaida, GETDATE())) AS DiasNoSetor " & _
    "FROM Tramitacoes T " & _
    "INNER JOIN Setores S ON T.IdSetor = S.IdSetor " & _
    "INNER JOIN Usuarios U ON U.Matricula = T.MatriculaUsuario " & _
    "WHERE T.IdProcesso = " & idProcesso & " " & _
    "ORDER BY T.DataEntrada DESC")

' ── DETALHES POR TRAMITACAO ──────────────────────────────
Dim rsDet
Set rsDet = dbQuery( _
    "SELECT TD.IdTramitacao, TD.Campo, TD.Valor " & _
    "FROM TramitacaoDetalhes TD " & _
    "INNER JOIN Tramitacoes T ON T.IdTramitacao = TD.IdTramitacao " & _
    "WHERE T.IdProcesso = " & idProcesso & " " & _
    "ORDER BY TD.IdTramitacao, TD.IdDetalhe")

Dim dicDetalhes
Set dicDetalhes = Server.CreateObject("Scripting.Dictionary")
Do While Not rsDet.EOF
    Dim tramId : tramId = CStr(rsDet("IdTramitacao"))
    Dim linha  : linha  = rsDet("Campo") & ": " & rsDet("Valor")
    If dicDetalhes.Exists(tramId) Then
        dicDetalhes(tramId) = dicDetalhes(tramId) & "||" & linha
    Else
        dicDetalhes.Add tramId, linha
    End If
    rsDet.MoveNext
Loop
rsDet.Close : Set rsDet = Nothing

' ── SETOR ANTERIOR PARA DEVOLVER ─────────────────────────
Dim rsAnterior, idSetorAnterior, nomeSetorAnterior
Set rsAnterior = dbQuery( _
    "SELECT TOP 1 T.IdSetor, S.NomeSetor " & _
    "FROM Tramitacoes T " & _
    "INNER JOIN Setores S ON S.IdSetor = T.IdSetor " & _
    "WHERE T.IdProcesso = " & idProcesso & _
    "  AND T.IdSetor <> " & idSetorAtual & _
    "  AND T.DataSaida IS NOT NULL " & _
    "ORDER BY T.DataEntrada DESC")

If Not rsAnterior.EOF Then
    idSetorAnterior   = rsAnterior("IdSetor")
    nomeSetorAnterior = rsAnterior("NomeSetor")
Else
    idSetorAnterior   = idSetorAtual
    nomeSetorAnterior = setorAtual & " (sem historico anterior)"
End If
rsAnterior.Close : Set rsAnterior = Nothing

' ── Parametros de layout ─────────────────────────────────
Dim pageTitulo  : pageTitulo  = "Processo " & numProcesso
Dim paginaAtiva : paginaAtiva = "processos"

' ── Captura flags de retorno ─────────────────────────────
Dim flagNovo        : flagNovo        = (Request.QueryString("novo")  = "1")
Dim flagEncaminhado : flagEncaminhado = (Request.QueryString("ok")    = "encaminhado")
Dim flagDevolvido   : flagDevolvido   = (Request.QueryString("ok")    = "devolvido")
Dim flagSemPerm     : flagSemPerm     = (Request.QueryString("erro")  = "sem_permissao")
Dim flagFluxo       : flagFluxo       = (Request.QueryString("erro")  = "fluxo_invalido")
%>
<!--#include file="../includes/layout.asp"-->

<!-- SweetAlert2 -->
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

<!-- HEADER DA PAGINA -->
<div class="page-header">
    <h1>
        <a href="lista.asp" class="btn-back"><i class="fa-solid fa-arrow-left"></i></a>
        <i class="fa-solid fa-file-lines"></i>
        Processo <%=numProcesso%>
    </h1>
    <div class="page-actions">
        <a href="imprimir.asp?id=<%=idProcesso%>" target="_blank" class="btn btn-ghost btn-sm">
            <i class="fa-solid fa-print"></i> Imprimir
        </a>
    </div>
</div>

<!-- ALERTA SLA -->
<% If diasNoSetor >= SLA_ALERTA_DIAS And Not processoFinalizado Then %>
<div class="sla-alert-bar">
    <i class="fa-solid fa-triangle-exclamation"></i>
    Processo parado ha <strong><%=diasNoSetor%> dias</strong> no setor <strong><%=setorAtual%></strong>
</div>
<% End If %>

<!-- AVISO DE SOMENTE VISUALIZACAO (usuario de outro setor) -->
<% If Not processoFinalizado And Not podeAgir Then %>
<div class="alert alert-info" style="margin-bottom:16px">
    <i class="fa-solid fa-circle-info"></i>
    Este processo esta no setor <strong><%=setorAtual%></strong>. Apenas usuarios desse setor podem encaminhar ou devolver.
</div>
<% End If %>

<!-- BOTOES DE ACAO (so aparece para quem pode agir) -->
<% If podeAgir Then %>
<div class="action-bar">
    <% If Not rsDestinos.EOF Then %>
    <button onclick="abrirModal('modalEncaminhar')" class="btn btn-primary">
        <i class="fa-solid fa-share"></i> Encaminhar
    </button>
    <% End If %>

    <button onclick="abrirModal('modalDevolver')" class="btn btn-warning">
        <i class="fa-solid fa-rotate-left"></i> Devolver
    </button>

    <% If sessIsAdmin Then %>
    <a href="finalizar.asp?id=<%=idProcesso%>"
       class="btn btn-success"
       onclick="return confirm('Confirmar finalizacao deste processo?')">
        <i class="fa-solid fa-check-circle"></i> Finalizar
    </a>
    <% End If %>
</div>
<% End If %>

<!-- DADOS DO PROCESSO -->
<div class="card-box">
    <div class="card-box-title"><i class="fa-solid fa-circle-info"></i> Dados do Processo</div>
    <div class="detail-grid">
        <div class="detail-item">
            <label>Numero</label>
            <span style="font-family:var(--font-mono);color:var(--primary);font-weight:700"><%=numProcesso%></span>
        </div>
        <div class="detail-item">
            <label>Tipo</label>
            <span><span class="badge badge-tipo"><%=tipo%></span></span>
        </div>
        <div class="detail-item">
            <label>Status</label>
            <span><span class="badge <%=badgeStatus(statusAtual)%>"><%=statusAtual%></span></span>
        </div>
        <div class="detail-item">
            <label>Setor Atual</label>
            <span><span class="badge badge-setor"><%=setorAtual%></span></span>
        </div>
        <div class="detail-item">
            <label>Dias no Setor</label>
            <span class="<%=badgeSLA(diasNoSetor)%>"><%=diasNoSetor%> dias</span>
        </div>
        <div class="detail-item">
            <label>Data de Abertura</label>
            <span><%=fmtData(dataCriacao)%></span>
        </div>
        <div class="detail-item">
            <label>Criado por</label>
            <span><%=criadorNome%></span>
        </div>
    </div>
    <% If Not IsNull(assunto) And assunto <> "" Then %>
    <div style="margin-top:16px;padding-top:16px;border-top:1px solid var(--border)">
        <div style="font-size:11px;font-weight:600;color:var(--text-muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:6px">Assunto</div>
        <div><%=Server.HtmlEncode(assunto)%></div>
    </div>
    <% End If %>
    <% If Not IsNull(descricao) And descricao <> "" Then %>
    <div style="margin-top:12px">
        <div style="font-size:11px;font-weight:600;color:var(--text-muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:6px">Descricao</div>
        <div style="color:var(--text-muted)"><%=Server.HtmlEncode(descricao)%></div>
    </div>
    <% End If %>
</div>

<!-- HISTORICO -->
<div class="card-box">
    <div class="card-box-title"><i class="fa-solid fa-timeline"></i> Historico de Tramitacoes</div>
    <div class="timeline">
    <% Dim primeiroItem : primeiroItem = True %>
    <% Do While Not rsHist.EOF %>
        <%
        Dim tramIdH  : tramIdH  = CStr(rsHist("IdTramitacao"))
        Dim isAtual  : isAtual  = IsNull(rsHist("DataSaida"))
        Dim dotClass
        If isAtual And primeiroItem Then
            dotClass = "atual"
        Else
            dotClass = "encaminhar"
        End If
        primeiroItem = False
        %>
        <div class="timeline-item">
            <div class="timeline-dot <%=dotClass%>"></div>
            <div class="timeline-card <%If dotClass="atual" Then Response.Write "atual"%>">
                <div class="timeline-header">
                    <div>
                        <div class="timeline-setor">
                            <i class="fa-solid fa-share" style="color:var(--primary)"></i>
                            <%=rsHist("NomeSetor")%>
                            <% If dotClass = "atual" Then %>
                                <span class="badge badge-andamento" style="font-size:10px">Atual</span>
                            <% End If %>
                        </div>
                        <div class="timeline-data">
                            <i class="fa-regular fa-calendar"></i>
                            <%=fmtDataHora(rsHist("DataEntrada"))%>
                            <% If Not IsNull(rsHist("DataSaida")) Then %>
                                &rarr; <%=fmtDataHora(rsHist("DataSaida"))%>
                            <% End If %>
                            &nbsp;&middot;&nbsp; <%=rsHist("UsuarioNome")%>
                        </div>
                    </div>
                    <span class="timeline-dias"><%=rsHist("DiasNoSetor")%> dia(s)</span>
                </div>
                <% If Not IsNull(rsHist("Observacao")) And rsHist("Observacao") <> "" Then %>
                <div class="timeline-obs">
                    <i class="fa-regular fa-comment"></i> <%=Server.HtmlEncode(rsHist("Observacao"))%>
                </div>
                <% End If %>
                <%
                If dicDetalhes.Exists(tramIdH) Then
                    Dim detArr : detArr = Split(dicDetalhes(tramIdH), "||")
                    Dim det
                %>
                <div style="margin-top:10px;padding-top:8px;border-top:1px dashed var(--border);display:flex;flex-wrap:wrap;gap:8px">
                <% For Each det In detArr %>
                    <span style="font-size:11.5px;background:var(--neutral-bg);padding:2px 8px;border-radius:4px;color:var(--text-muted)">
                        <%=Server.HtmlEncode(det)%>
                    </span>
                <% Next %>
                </div>
                <% End If %>
            </div>
        </div>
    <% rsHist.MoveNext : Loop %>
    </div>
</div>

<%
rsHist.Close : Set rsHist = Nothing
%>

<!-- ===== MODAL ENCAMINHAR ===== -->
<div id="modalEncaminhar" class="modal-overlay" onclick="fecharSeOverlay(event,'modalEncaminhar')">
    <div class="modal-box">
        <div class="modal-header">
            <h3><i class="fa-solid fa-share" style="color:var(--primary)"></i> Encaminhar Processo</h3>
            <button class="modal-close" onclick="fecharModal('modalEncaminhar')"><i class="fa-solid fa-xmark"></i></button>
        </div>
        <form method="post" action="encaminhar.asp">
            <div class="modal-body">
                <input type="hidden" name="id_processo" value="<%=idProcesso%>">

                <div class="form-group">
                    <label>Encaminhar para <span style="color:var(--danger)">*</span></label>
                    <select name="setor_destino" required id="selDestino" onchange="mostrarCampos(this.value)">
                        <option value="">Selecione o setor...</option>
                        <%
                        Do While Not rsDestinos.EOF
                        %>
                            <option value="<%=rsDestinos("IdSetorDestino")%>"><%=rsDestinos("NomeSetor")%></option>
                        <% rsDestinos.MoveNext : Loop %>
                    </select>
                </div>

                <div class="form-group">
                    <label>Observacao</label>
                    <textarea name="observacao" rows="3" placeholder="Observacoes sobre o encaminhamento..."></textarea>
                </div>

                <!-- SETOR SOLICITANTE (2) -->
                <div class="campos-setor" id="campos-2">
                    <div class="campos-setor-titulo">Informacoes do Setor Solicitante</div>
                    <div class="form-group">
                        <label>Descricao do Pedido</label>
                        <textarea name="descricao" rows="3"></textarea>
                    </div>
                    <div class="form-grid">
                        <div class="form-group">
                            <label>Quantidade</label>
                            <input type="number" name="quantidade" min="1">
                        </div>
                        <div class="form-group">
                            <label>Urgencia</label>
                            <select name="urgencia">
                                <option value="">Selecione</option>
                                <option>Normal</option>
                                <option>Urgente</option>
                            </select>
                        </div>
                    </div>
                </div>

                <!-- COMPRAS (3) -->
                <div class="campos-setor" id="campos-3">
                    <div class="campos-setor-titulo">Informacoes de Compras</div>
                    <div class="form-group">
                        <label>Fornecedor</label>
                        <input type="text" name="fornecedor">
                    </div>
                    <div class="form-grid">
                        <div class="form-group">
                            <label>Cotacoes</label>
                            <input type="number" name="cotacoes" min="0">
                        </div>
                        <div class="form-group">
                            <label>Tipo de Compra</label>
                            <select name="tipo_compra">
                                <option value="">Selecione</option>
                                <option>Licitacao</option>
                                <option>Dispensa</option>
                            </select>
                        </div>
                    </div>
                </div>

                <!-- PLANEJAMENTO (4) -->
                <div class="campos-setor" id="campos-4">
                    <div class="campos-setor-titulo">Informacoes de Planejamento</div>
                    <div class="form-group">
                        <label>Analise de Planejamento</label>
                        <textarea name="analise_planejamento" rows="3"></textarea>
                    </div>
                    <div class="form-grid">
                        <div class="form-group">
                            <label>Impacto</label>
                            <select name="impacto">
                                <option value="">Selecione</option>
                                <option>Baixo</option>
                                <option>Medio</option>
                                <option>Alto</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label>Prioridade</label>
                            <select name="prioridade">
                                <option value="">Selecione</option>
                                <option>Normal</option>
                                <option>Alta</option>
                                <option>Urgente</option>
                            </select>
                        </div>
                    </div>
                </div>

                <!-- LICITACAO SCL (5) -->
                <div class="campos-setor" id="campos-5">
                    <div class="campos-setor-titulo">Informacoes da Licitacao (SCL)</div>
                    <div class="form-grid">
                        <div class="form-group">
                            <label>Num do Processo Licitatorio</label>
                            <input type="text" name="numero_edital">
                        </div>
                        <div class="form-group">
                            <label>Modalidade</label>
                            <select name="modalidade">
                                <option value="">Selecione</option>
                                <option>Pregao Eletronico</option>
                                <option>Pregao Presencial</option>
                                <option>Concorrencia</option>
                                <option>Dispensa</option>
                            </select>
                        </div>
                    </div>
                    <div class="form-group">
                        <label>Parecer Juridico</label>
                        <textarea name="parecer_juridico" rows="2"></textarea>
                    </div>
                </div>

                <!-- FINANCEIRO (6) -->
                <div class="campos-setor" id="campos-6">
                    <div class="campos-setor-titulo">Informacoes do Financeiro</div>
                    <div class="form-grid">
                        <div class="form-group">
                            <label>Centro de Custo</label>
                            <input type="text" name="centro_custo">
                        </div>
                        <div class="form-group">
                            <label>Autorizacao</label>
                            <select name="autorizacao">
                                <option value="">Selecione</option>
                                <option>Aprovado</option>
                                <option>Reprovado</option>
                                <option>Pendente</option>
                            </select>
                        </div>
                    </div>
                </div>

                <!-- NAP (7) -->
                <div class="campos-setor" id="campos-7">
                    <div class="campos-setor-titulo">Informacoes do NAP</div>
                    <div class="form-group">
                        <label>Analise / Providencia</label>
                        <textarea name="providencia_nap" rows="3"></textarea>
                    </div>
                    <div class="form-group">
                        <label>Status NAP</label>
                        <select name="status_nap">
                            <option value="">Selecione</option>
                            <option>Aprovado</option>
                            <option>Pendente</option>
                            <option>Devolvido</option>
                        </select>
                    </div>
                </div>

            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-ghost" onclick="fecharModal('modalEncaminhar')">Cancelar</button>
                <button type="submit" class="btn btn-primary">
                    <i class="fa-solid fa-share"></i> Confirmar Encaminhamento
                </button>
            </div>
        </form>
    </div>
</div>

<!-- ===== MODAL DEVOLVER ===== -->
<div id="modalDevolver" class="modal-overlay" onclick="fecharSeOverlay(event,'modalDevolver')">
    <div class="modal-box">
        <div class="modal-header">
            <h3><i class="fa-solid fa-rotate-left" style="color:var(--warning)"></i> Devolver Processo</h3>
            <button class="modal-close" onclick="fecharModal('modalDevolver')"><i class="fa-solid fa-xmark"></i></button>
        </div>
        <form method="post" action="devolver.asp">
            <div class="modal-body">
                <input type="hidden" name="id_processo" value="<%=idProcesso%>">
                <input type="hidden" name="setor_destino" value="<%=idSetorAnterior%>">

                <div class="form-group">
                    <label>Devolver para</label>
                    <input type="text" value="<%=nomeSetorAnterior%>" disabled style="background:var(--bg)">
                </div>

                <div class="form-group">
                    <label>Motivo da Devolucao <span style="color:var(--danger)">*</span></label>
                    <textarea name="observacao" rows="4" required placeholder="Descreva o motivo da devolucao..."></textarea>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-ghost" onclick="fecharModal('modalDevolver')">Cancelar</button>
                <button type="submit" class="btn btn-warning">
                    <i class="fa-solid fa-rotate-left"></i> Confirmar Devolucao
                </button>
            </div>
        </form>
    </div>
</div>

<script>
// ── MODAIS ───────────────────────────────────────────────
function abrirModal(id) {
    document.getElementById(id).classList.add('open');
    document.body.style.overflow = 'hidden';
}
function fecharModal(id) {
    document.getElementById(id).classList.remove('open');
    document.body.style.overflow = '';
}
function fecharSeOverlay(e, id) {
    if (e.target === document.getElementById(id)) fecharModal(id);
}

// ── CAMPOS DINAMICOS POR SETOR ───────────────────────────
function mostrarCampos(idSetor) {
    document.querySelectorAll('.campos-setor').forEach(function(el) {
        el.classList.remove('ativo');
    });
    if (idSetor) {
        var el = document.getElementById('campos-' + idSetor);
        if (el) el.classList.add('ativo');
    }
}

// ── SWEETALERT: dispara conforme flag da URL ─────────────
<%
If flagNovo Then
%>
window.addEventListener('DOMContentLoaded', function() {
    Swal.fire({
        icon: 'success',
        title: 'Processo criado!',
        text: 'O processo foi autuado e encaminhado ao Protocolo.',
        confirmButtonColor: '#1a56db',
        confirmButtonText: 'OK'
    });
});
<%
ElseIf flagEncaminhado Then
%>
window.addEventListener('DOMContentLoaded', function() {
    Swal.fire({
        icon: 'success',
        title: 'Encaminhado!',
        text: 'O processo foi encaminhado com sucesso.',
        confirmButtonColor: '#1a56db',
        timer: 3000,
        timerProgressBar: true
    });
});
<%
ElseIf flagDevolvido Then
%>
window.addEventListener('DOMContentLoaded', function() {
    Swal.fire({
        icon: 'warning',
        title: 'Processo devolvido',
        text: 'O processo foi devolvido ao setor anterior.',
        confirmButtonColor: '#d97706',
        timer: 3000,
        timerProgressBar: true
    });
});
<%
ElseIf flagSemPerm Then
%>
window.addEventListener('DOMContentLoaded', function() {
    Swal.fire({
        icon: 'error',
        title: 'Sem permissao',
        text: 'Apenas usuarios do setor atual podem movimentar este processo.',
        confirmButtonColor: '#dc2626'
    });
});
<%
ElseIf flagFluxo Then
%>
window.addEventListener('DOMContentLoaded', function() {
    Swal.fire({
        icon: 'error',
        title: 'Encaminhamento invalido',
        text: 'Este setor de destino nao e permitido a partir do setor atual.',
        confirmButtonColor: '#dc2626'
    });
});
<%
End If
%>
</script>

<%
Call fechaConexao
%>
<!--#include file="../includes/layout_footer.asp"-->
