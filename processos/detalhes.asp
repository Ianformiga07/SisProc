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
    "WHERE P.IdProcesso = " & idProcesso _
)

If rsProc.EOF Then
    Response.Redirect "lista.asp"
    Response.End
End If

' Variáveis do processo
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

' Define status corretamente (SEM coluna fake)
If processoAtivo = False Or IsNull(rsProc("IdSetorAtual")) Then
    statusAtual = "Finalizado"
    processoFinalizado = True
Else
    statusAtual = "Em andamento"
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

' ── SETORES DESTINO PERMITIDOS (do banco, não hard-coded) ─
Dim rsDestinos
Set rsDestinos = dbQuery( _
    "SELECT F.IdSetorDestino, S.NomeSetor " & _
    "FROM FluxoSetores F " & _
    "INNER JOIN Setores S ON S.IdSetor = F.IdSetorDestino " & _
    "WHERE F.IdSetorOrigem = " & idSetorAtual & " AND F.Ativo = 1 " & _
    "ORDER BY S.NomeSetor")

' ── HISTÓRICO DE TRAMITAÇÕES ─────────────────────────────
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

' ── DETALHES DE CADA TRAMITAÇÃO ──────────────────────────
' Monta dicionário: IdTramitacao → array de "campo: valor"
Dim rsDet
Set rsDet = dbQuery( _
    "SELECT TD.IdTramitacao, TD.Campo, TD.Valor " & _
    "FROM TramitacaoDetalhes TD " & _
    "INNER JOIN Tramitacoes T ON T.IdTramitacao = TD.IdTramitacao " & _
    "WHERE T.IdProcesso = " & idProcesso & " " & _
    "ORDER BY TD.IdTramitacao, TD.IdDetalhe")

' Guarda os detalhes em arrays indexados por IdTramitacao
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

' ── PERMISSÕES ───────────────────────────────────────────
Dim podeAgir : podeAgir = Not processoFinalizado

Dim pageTitulo  : pageTitulo  = "Processo " & numProcesso
Dim paginaAtiva : paginaAtiva = "processos"

' ── FUNÇÃO STATUS SETOR ───────────────────────────────────────────
Function badgeStatus(status)
    status = LCase(Trim(status))

    Select Case status
        Case "finalizado"
            badgeStatus = "badge-success"
        Case "em andamento"
            badgeStatus = "badge-primary"
        Case Else
            badgeStatus = "badge-secondary"
    End Select
End Function

' ── FUNÇÃO SLA  ───────────────────────────────────────────
Function badgeSLA(dias)

    If IsNull(dias) Then
        badgeSLA = "badge badge-neutral"
        Exit Function
    End If

    If dias <= SLA_ALERTA_DIAS Then
        badgeSLA = "badge badge-success"
    ElseIf dias <= (SLA_ALERTA_DIAS + 3) Then
        badgeSLA = "badge badge-warning"
    Else
        badgeSLA = "badge badge-danger"
    End If

End Function


Function fmtDataHora(dt)
    If IsNull(dt) Or dt = "" Then
        fmtDataHora = "-"
        Exit Function
    End If

    If Not IsDate(dt) Then
        fmtDataHora = "-"
        Exit Function
    End If

    fmtDataHora = _
        Day(dt) & "/" & _
        Right("0" & Month(dt), 2) & "/" & _
        Year(dt) & " " & _
        Right("0" & Hour(dt), 2) & ":" & _
        Right("0" & Minute(dt), 2)
End Function
%>
<!--#include file="../includes/layout.asp"-->

<!-- ALERT MENSAGEM -->
<% If Request.QueryString("msg") = "criado" Then %>
<div class="alert alert-success"><i class="fa-solid fa-circle-check"></i> Processo criado com sucesso e encaminhado ao Protocolo!</div>
<% End If %>

<!-- HEADER DA PÁGINA -->
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
    Processo parado há <strong><%=diasNoSetor%> dias</strong> no setor <strong><%=setorAtual%></strong>
</div>
<% End If %>

<!-- BOTÕES DE AÇÃO -->
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
       onclick="return confirm('Confirmar finalização deste processo?')">
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
            <label>Número</label>
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
        <% If processoFinalizado Then %>
        <div class="detail-item">
            <label>Data de Finalização</label>
            <span><%=fmtData(dataFinaliz)%></span>
        </div>
        <% End If %>
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
        <div style="font-size:11px;font-weight:600;color:var(--text-muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:6px">Descrição</div>
        <div style="color:var(--text-muted)"><%=Server.HtmlEncode(descricao)%></div>
    </div>
    <% End If %>
</div>

<!-- HISTÓRICO DE TRAMITAÇÕES -->
<div class="card-box">
    <div class="card-box-title"><i class="fa-solid fa-timeline"></i> Histórico de Tramitações</div>
    <div class="timeline">
    <% Dim primeiroItem : primeiroItem = True %>
    <% Do While Not rsHist.EOF %>
        <%
        Dim tipoMov
        Dim tramIdH  : tramIdH  = CStr(rsHist("IdTramitacao"))
        Dim isAtual  : isAtual  = IsNull(rsHist("DataSaida"))

        ' Define o tipo do movimento SEM coluna no banco
        If isAtual Then
            tipoMov = "encaminhar"
        Else
            tipoMov = "finalizar"
        End If

        Dim dotClass : dotClass = tipoMov
        If isAtual And primeiroItem Then dotClass = "atual"
        primeiroItem = False
        %>
        <div class="timeline-item">
            <div class="timeline-dot <%=dotClass%>"></div>
            <div class="timeline-card <%If isAtual And dotClass="atual" Then Response.Write "atual"%>">
                <div class="timeline-header">
                    <div>
                        <div class="timeline-setor">
                            <% If tipoMov = "devolver" Then %>
                                <i class="fa-solid fa-rotate-left" style="color:var(--warning)"></i>
                            <% ElseIf tipoMov = "finalizar" Then %>
                                <i class="fa-solid fa-check-circle" style="color:var(--success)"></i>
                            <% Else %>
                                <i class="fa-solid fa-share" style="color:var(--primary)"></i>
                            <% End If %>
                            <%=rsHist("NomeSetor")%>
                            <% If isAtual And dotClass="atual" Then %>
                                <span class="badge badge-andamento" style="font-size:10px">Atual</span>
                            <% End If %>
                        </div>
                        <div class="timeline-data">
                            <i class="fa-regular fa-calendar"></i>
                            <%=fmtDataHora(rsHist("DataEntrada"))%>
                            <% If Not IsNull(rsHist("DataSaida")) Then %>
                                → <%=fmtDataHora(rsHist("DataSaida"))%>
                            <% End If %>
                            &nbsp;·&nbsp; <%=rsHist("UsuarioNome")%>
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
                ' Exibe detalhes da tramitação se existirem
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
        <form method="post" action="encaminhar.asp" id="formEncaminhar">
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
                    <label>Observação</label>
                    <textarea name="observacao" rows="3" placeholder="Observações sobre o encaminhamento..."></textarea>
                </div>

                <!-- Campos dinâmicos por setor destino -->

                <!-- SETOR SOLICITANTE (2) -->
                <div class="campos-setor" id="campos-2">
                    <div class="campos-setor-titulo">Informações do Setor Solicitante</div>
                    <div class="form-group">
                        <label>Descrição do Pedido</label>
                        <textarea name="descricao" rows="3"></textarea>
                    </div>
                    <div class="form-grid">
                        <div class="form-group">
                            <label>Quantidade</label>
                            <input type="number" name="quantidade" min="1">
                        </div>
                        <div class="form-group">
                            <label>Urgência</label>
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
                    <div class="campos-setor-titulo">Informações de Compras</div>
                    <div class="form-group">
                        <label>Fornecedor</label>
                        <input type="text" name="fornecedor">
                    </div>
                    <div class="form-grid">
                        <div class="form-group">
                            <label>Nº de Cotações</label>
                            <input type="number" name="cotacoes" min="0">
                        </div>
                        <div class="form-group">
                            <label>Tipo de Compra</label>
                            <select name="tipo_compra">
                                <option value="">Selecione</option>
                                <option>Licitação</option>
                                <option>Dispensa</option>
                            </select>
                        </div>
                    </div>
                </div>

                <!-- PLANEJAMENTO (4) -->
                <div class="campos-setor" id="campos-4">
                    <div class="campos-setor-titulo">Informações de Planejamento</div>
                    <div class="form-group">
                        <label>Análise de Planejamento</label>
                        <textarea name="analise_planejamento" rows="3"></textarea>
                    </div>
                    <div class="form-grid">
                        <div class="form-group">
                            <label>Impacto</label>
                            <select name="impacto">
                                <option value="">Selecione</option>
                                <option>Baixo</option>
                                <option>Médio</option>
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

                <!-- LICITAÇÃO SCL (5) -->
                <div class="campos-setor" id="campos-5">
                    <div class="campos-setor-titulo">Informações da Licitação (SCL)</div>
                    <div class="form-grid">
                        <div class="form-group">
                            <label>Nº do Processo Licitatório</label>
                            <input type="text" name="numero_edital">
                        </div>
                        <div class="form-group">
                            <label>Modalidade</label>
                            <select name="modalidade">
                                <option value="">Selecione</option>
                                <option>Pregão Eletrônico</option>
                                <option>Pregão Presencial</option>
                                <option>Concorrência</option>
                                <option>Dispensa</option>
                            </select>
                        </div>
                    </div>
                    <div class="form-group">
                        <label>Parecer Jurídico</label>
                        <textarea name="parecer_juridico" rows="2"></textarea>
                    </div>
                </div>

                <!-- FINANCEIRO (6) -->
                <div class="campos-setor" id="campos-6">
                    <div class="campos-setor-titulo">Informações do Financeiro</div>
                    <div class="form-grid">
                        <div class="form-group">
                            <label>Centro de Custo</label>
                            <input type="text" name="centro_custo">
                        </div>
                        <div class="form-group">
                            <label>Autorização</label>
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
                    <div class="campos-setor-titulo">Informações do NAP</div>
                    <div class="form-group">
                        <label>Análise / Providência</label>
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

                <%
                ' Busca o setor anterior (último com DataSaida preenchida, diferente do atual)
                Dim rsAnterior
                Set rsAnterior = dbQuery( _
                    "SELECT TOP 1 T.IdSetor, S.NomeSetor " & _
                    "FROM Tramitacoes T " & _
                    "INNER JOIN Setores S ON S.IdSetor = T.IdSetor " & _
                    "WHERE T.IdProcesso = " & idProcesso & _
                    "  AND T.IdSetor <> " & idSetorAtual & _
                    "  AND T.DataSaida IS NOT NULL " & _
                    "ORDER BY T.DataEntrada DESC")

                Dim idSetorAnterior, nomeSetorAnterior
                If Not rsAnterior.EOF Then
                    idSetorAnterior   = rsAnterior("IdSetor")
                    nomeSetorAnterior = rsAnterior("NomeSetor")
                Else
                    idSetorAnterior   = idSetorAtual
                    nomeSetorAnterior = setorAtual & " (sem histórico anterior)"
                End If
                rsAnterior.Close : Set rsAnterior = Nothing
                %>

                <div class="form-group">
                    <label>Devolver para</label>
                    <input type="text" value="<%=nomeSetorAnterior%>" disabled style="background:var(--bg)">
                    <input type="hidden" name="setor_destino" value="<%=idSetorAnterior%>">
                </div>

                <div class="form-group">
                    <label>Motivo da Devolução <span style="color:var(--danger)">*</span></label>
                    <textarea name="observacao" rows="4" required placeholder="Descreva o motivo da devolução..."></textarea>
                </div>

            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-ghost" onclick="fecharModal('modalDevolver')">Cancelar</button>
                <button type="submit" class="btn btn-warning">
                    <i class="fa-solid fa-rotate-left"></i> Confirmar Devolução
                </button>
            </div>
        </form>
    </div>
</div>

<script>
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

// Mostrar campos dinâmicos conforme setor destino selecionado
function mostrarCampos(idSetor) {
    document.querySelectorAll('.campos-setor').forEach(el => el.classList.remove('ativo'));
    if (idSetor) {
        var el = document.getElementById('campos-' + idSetor);
        if (el) el.classList.add('ativo');
    }
}
</script>

<%
Call fechaConexao
%>
<!--#include file="../includes/layout_footer.asp"-->
