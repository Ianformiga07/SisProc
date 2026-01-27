
<!--#include file="../config/app.asp" -->
<!--#include file="../Lib/Conexao.asp" -->
<!--#include file="../includes/seguranca.asp" -->

<%
call abreConexao

Dim idProcesso
idProcesso = CLng(Request.QueryString("id"))

' =======================
' DADOS DO PROCESSO
' =======================
Dim sqlProc, rsProc

sqlProc = "SELECT P.IdProcesso, P.NumeroProcesso, P.Assunto, P.Descricao, P.DataCriacao, P.MatriculaCriador, T.IdSetor, SE.NomeSetor, T.DataEntrada, DATEDIFF(DAY, T.DataEntrada, GETDATE()) AS DiasParado FROM Processos P OUTER APPLY (SELECT TOP 1 * FROM Tramitacoes WHERE IdProcesso = P.IdProcesso ORDER BY DataEntrada DESC) T OUTER APPLY (SELECT * FROM Setores WHERE IdSetor = T.IdSetor) SE " & _
          "WHERE P.IdProcesso = " & idProcesso

'response.write sqlProc
Set rsProc = conn.Execute(sqlProc)


If rsProc.EOF Then
    Response.Write "Processo não encontrado."
    Response.End
End If

Dim numeroProcesso, dataAbertura, setorAtual, diasParado
Dim statusProcesso, interessado, assunto, descricao

numeroProcesso = rsProc("NumeroProcesso")
dataAbertura   = FormatDateTime(rsProc("DataCriacao"), 2)
diasParado     = rsProc("DiasParado")
assunto        = rsProc("Assunto")
descricao      = rsProc("Descricao")
interessado    = rsProc("MatriculaCriador")

If IsNull(rsProc("IdSetor")) Then
    setorAtual = "Finalizado"
    statusProcesso = "Finalizado"
Else
    setorAtual = rsProc("NomeSetor")
    statusProcesso = "Em andamento"
End If


' =======================
' LISTA DE SETORES DESTINO
' =======================
Dim sqlSetorDestino, rsSetorDestino

sqlSetorDestino = "SELECT IdSetor, NomeSetor FROM Setores ORDER BY NomeSetor"
Set rsSetorDestino = conn.Execute(sqlSetorDestino)


' =======================
' CAMPOS OBRIGATORIOS POR SETOR
' =======================
Dim camposPorSetor
Set camposPorSetor = Server.CreateObject("Scripting.Dictionary")

' Definição dos campos que cada setor deve preencher
camposPorSetor.Add 1, Array("descricao", "quantidade", "urgencia")          ' Setor Solicitante
camposPorSetor.Add 2, Array("cotacoes", "fornecedor", "tipo_compra")        ' Compras
camposPorSetor.Add 3, Array("impacto", "prioridade")                        ' Planejamento
camposPorSetor.Add 4, Array("parecer_juridico")                             ' Licitação - SCL
camposPorSetor.Add 5, Array("autorizacao", "centro_custo")                  ' Financeiro
camposPorSetor.Add 6, Array("analise_admin")                                ' NAP
camposPorSetor.Add 7, Array("numero_protocolo")                             ' Protocolo


' =======================
' PERMISSÕES DE AÇÃO
' =======================
Dim podeEncaminhar, podeFinalizar

If statusProcesso = "Em andamento" Then
    podeEncaminhar = True
    podeFinalizar  = True
Else
    podeEncaminhar = False
    podeFinalizar  = False
End If

%>

<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="utf-8">
    <title>SisProc - Visualizar Processo</title>
    <link rel="stylesheet" href="<%=APP_PATH%>/assets/css/dashboard.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
</head>

<body>

<!-- ================= TOPO ================= -->
<header class="topbar">
    <div class="top-brand">
        <strong>SisProc</strong>
    </div>

    <div class="top-toggle">
        <button class="btn-menu" onclick="toggleMenu()">☰</button>
    </div>

    <div class="top-right">
        <span class="user"><i class="fa-solid fa-user"></i> <%=Session("Nome")%></span>
        <a href="<%=APP_PATH%>/auth/logout.asp" class="btn-logout">Sair</a>
    </div>
</header>

<div class="layout" id="layout">

    <!-- ================= SIDEBAR ================= -->
    <aside class="sidebar">
        <nav>
            <a href="<%=APP_PATH%>/index.asp">
                <span class="icon"><i class="fa-solid fa-house"></i></span>
                <span class="text">Dashboard</span>
            </a>

            <a href="<%=APP_PATH%>/processos/lista.asp" class="active">
                <span class="icon"><i class="fa-solid fa-folder-open"></i></span>
                <span class="text">Processos</span>
            </a>

            <% If Session("IdPerfil") = 1 Then %>
                <a href="<%=APP_PATH%>/usuarios/lista.asp">
                    <span class="icon"><i class="fa-solid fa-users"></i></span>
                    <span class="text">Usuários</span>
                </a>
            <% End If %>
        </nav>
    </aside>

    <!-- ================= CONTEÚDO ================= -->
    <main class="content">

        <!-- HEADER DA PÁGINA -->
        <div class="page-header process-header">
            <div class="header-left">
                <a href="javascript:history.back()" class="btn-back">
                    <i class="fa-solid fa-arrow-left"></i>
                </a>

                <h1>
                    <i class="fa-solid fa-file-lines"></i>
                    Processo <%=numeroProcesso%>
                </h1>
            </div>
        </div>

 
        <!-- Botoes de encaminhar -->
        <div class="action-bar">

            <% If podeEncaminhar Then %>
                <button onclick="abrirEncaminhar()" class="btn-action primary">
                    <i class="fa-solid fa-share"></i> Encaminhar
                </button>

                <button onclick="abrirDevolver()" class="btn-action warning">
                    <i class="fa-solid fa-rotate-left"></i> Devolver
                </button>
            <% End If %>

            <% If podeFinalizar Then %>
                <a href="finalizar.asp?id=1"
                class="btn-action success"
                onclick="return confirm('Deseja finalizar este processo?')">
                    <i class="fa-solid fa-check"></i> Finalizar
                </a>
            <% End If %>

            <a href="imprimir.asp?id=1" target="_blank" class="btn-action neutral">
                <i class="fa-solid fa-print"></i> Imprimir
            </a>

        </div>


        <!-- ===== ALERTA SLA ===== -->
        <% If diasParado >= 5 Then %>
            <div class="sla-alert">
                <i class="fa-solid fa-triangle-exclamation"></i>
                Processo parado há <strong><%=diasParado%> dias</strong> no setor atual
            </div>
        <% End If %>


        <!-- ===== DADOS DO PROCESSO ===== -->
        <div class="card-box">

            <div class="card-title">
                <i class="fa-solid fa-circle-info"></i>
                Dados do Processo
            </div>

            <div class="process-grid">
                <div>
                    <strong>Número</strong><br>
                    <%=numeroProcesso%>
                </div>

                <div>
                    <strong>Status</strong><br>
                    <span class="status aberto"><%=statusProcesso%></span>
                </div>

                <div>
                    <strong>Data de Abertura</strong><br>
                    <%=dataAbertura%>
                </div>

                <div>
                    <strong>Setor Atual</strong><br>
                    <%=setorAtual%>
                </div>

                <div>
                    <strong>Interessado</strong><br>
                    <%=interessado%>
                </div>
            </div>

        </div>

        <!-- ===== DESCRIÇÃO ===== -->
        <div class="card-box">
            <h3><%=assunto%></h3>
            <p class="process-text"><%=descricao%></p>
        </div>

        <%
        Dim sqlHist, rsHist

        sqlHist = "SELECT T.IdTramitacao, T.DataEntrada, T.DataSaida, T.Observacao, " & _
          "T.IdSetor, SE.NomeSetor, T.MatriculaUsuario " & _
          "FROM Tramitacoes T " & _
          "INNER JOIN Setores SE ON SE.IdSetor = T.IdSetor " & _
          "WHERE T.IdProcesso = " & idProcesso & " " & _
          "ORDER BY T.DataEntrada ASC"
        'response.write sqlHist 
        'response.end
        Set rsHist = conn.Execute(sqlHist)
        %>

        <!-- ===== HISTÓRICO ===== -->
        <div class="card-box">

            <div class="card-title">
                <i class="fa-solid fa-clock-rotate-left"></i>
                Histórico de Tramitação
            </div>

            <ul class="timeline">

        <%
        Dim dataEntrada, dataSaida, dias

        If rsHist.EOF Then
        %>
            <li>Nenhuma movimentação registrada.</li>
        <%
        Else
            Do While Not rsHist.EOF
                dataEntrada = rsHist("DataEntrada")
                dataSaida = rsHist("DataSaida")

                ' Calcula dias no setor
                If IsNull(dataSaida) Or dataSaida = "" Then
                    dias = DateDiff("d", dataEntrada, Now())
                Else
                    dias = DateDiff("d", dataEntrada, dataSaida)
                End If
        %>
                <li>
                    <span class="date"><%=FormatDateTime(dataEntrada, 2)%></span>
                    <strong>Tramitação</strong><br>

                    Setor <%=rsHist("NomeSetor")%><br>

                    <% If Not IsNull(rsHist("Observacao")) Then %>
                        <em><%=rsHist("Observacao")%></em><br>
                    <% End If %>

                    <%
                    Dim sqlDet, rsDet

                    sqlDet = "SELECT Campo, Valor FROM TramitacaoDetalhes " & _
                            "WHERE IdTramitacao = " & rsHist("IdTramitacao")

                    Set rsDet = conn.Execute(sqlDet)

                    If Not rsDet.EOF Then
                    %>
                        <ul class="detalhes-tramitacao">
                            <% Do While Not rsDet.EOF %>
                                <li>
                                    <strong><%=rsDet("Campo")%>:</strong>
                                    <%=rsDet("Valor")%>
                                </li>
                            <% 
                                rsDet.MoveNext
                            Loop %>
                        </ul>
                    <%
                    End If

                    rsDet.Close
                    Set rsDet = Nothing
                    %>

                    <small>
                        ⏱
                        <% If IsNull(dataSaida) Or dataSaida = "" Then %>
                            em andamento (<%=dias%> dias)
                        <% Else %>
                            <%=dias%> dias no setor
                        <% End If %>
                    </small>
                </li>
        <%
                rsHist.MoveNext
            Loop
        End If

        rsHist.Close
        Set rsHist = Nothing
        %>
                    </ul>

                </div>

            </main>
        </div>



<script>
// Funções para abrir e fechar modais
function abrirEncaminhar() {
    const select = document.querySelector('select[name="setor_destino"]');
    const opcoes = select.querySelectorAll('option');

    // esconde tudo
    opcoes.forEach(opt => {
        if (opt.value !== "") opt.style.display = "none";
    });

    // mostra apenas os permitidos
    if (fluxoSetores[setorAtual]) {
        fluxoSetores[setorAtual].forEach(id => {
            const opt = select.querySelector(`option[value="${id}"]`);
            if (opt) opt.style.display = "block";
        });
    }

    select.value = "";
    mostrarCamposPorDestino();

    document.getElementById("modalEncaminhar").classList.add("active");
}

function fecharModal() {
    document.getElementById("modalEncaminhar").classList.remove("active");
}

function abrirDevolver() {
    document.getElementById("modalDevolver").classList.add("active");
}

function fecharDevolver() {
    document.getElementById("modalDevolver").classList.remove("active");
}

// Função para mostrar/ocultar campos obrigatórios conforme setor selecionado
function mostrarCamposPorDestino() {

    const setorDestino = document.querySelector('select[name="setor_destino"]').value;

    document.querySelectorAll('.campos-setor').forEach(div => {
        div.style.display = 'none';
    });

    if (setorDestino) {
        const bloco = document.querySelector(
            '.campos-setor[data-setor="' + setorDestino + '"]'
        );
        if (bloco) bloco.style.display = 'block';
    }
}

/*/ Função para mostrar/ocultar campos obrigatórios conforme setor selecionado
function mostrarCamposSetorAtual() {
    document.querySelectorAll('.campos-setor').forEach(div => {
        div.style.display = 'none';
    });

    if (setorAtual) {
        const bloco = document.querySelector(
            '.campos-setor[data-setor="' + setorAtual + '"]'
        );
        if (bloco) bloco.style.display = 'block';
    }
}*/


// Variável para o setor atual do processo
const setorAtual = "<%=rsProc("IdSetor")%>";

const fluxoSetores = {
    1: [2],            // Protocolo → Setor Solicitante
    2: [3],            // Solicitante → Compras
    3: [4, 5, 6],      // Compras → Planejamento / Licitação / Financeiro
    4: [3],            // Planejamento → Compras
    5: [3],            // Licitação → Compras
    6: [7],            // Financeiro → NAP
    7: [6]             // NAP → Financeiro
};

</script>

<!-- ===== MODAL DE ENCAMINHAR ===== -->
<div id="modalEncaminhar" class="modal" onclick="fecharModal()">
    <div class="modal-box" onclick="event.stopPropagation()">

        <div class="modal-header">
            <h3>Encaminhar Processo</h3>
            <button type="button" class="modal-close" onclick="fecharModal()">
                <i class="fa-solid fa-xmark"></i>
            </button>
        </div>

        <form method="post" action="encaminhar.asp">

            <input type="hidden" name="id_processo" value="<%=idProcesso%>">

            <!-- ================= SELECT DE DESTINO ================= -->
            <label>Encaminhar para</label>
            <select name="setor_destino" class="styled-input" required onchange="mostrarCamposPorDestino()">
                <option value="">Selecione um setor</option>
                <% Do While Not rsSetorDestino.EOF %>
                    <option value="<%=rsSetorDestino("IdSetor")%>">
                        <%=rsSetorDestino("NomeSetor")%>
                    </option>
                <% 
                    rsSetorDestino.MoveNext
                Loop %>
            </select>

            <!-- ================= PROTOCOLO ================= -->
            <div class="campos-setor" data-setor="1" style="display:none">
                <label>Observação do Protocolo</label>
                <textarea name="obs_protocolo"></textarea>
            </div>

            <!-- ================= SETOR SOLICITANTE ================= -->
            <div class="campos-setor" data-setor="2" style="display:none">
                <label>Descrição do Pedido</label>
                <textarea name="descricao"></textarea>

                <label>Quantidade</label>
                <input type="number" name="quantidade">

                <label>Urgência</label>
                <select name="urgencia">
                    <option value="">Selecione</option>
                    <option>Normal</option>
                    <option>Urgente</option>
                </select>
            </div>

            <!-- ================= COMPRAS ================= -->
            <div class="campos-setor" data-setor="3" style="display:none">
                <label>Fornecedor</label>
                <input type="text" name="fornecedor">

                <label>Cotações</label>
                <input type="number" name="cotacoes">

                <label>Tipo de Compra</label>
                <select name="tipo_compra">
                    <option value="">Selecione</option>
                    <option>Licitação</option>
                    <option>Dispensa</option>
                </select>
            </div>
            <!-- ================= PLANEJAMENTO ================= -->
            <div class="campos-setor" data-setor="4" style="display:none">
                <label>Fornecedor</label>
                <input type="text" name="fornecedor">

                <label>Cotações</label>
                <textarea name="cotacoes"></textarea>

                <label>Tipo de Compra</label>
                <select name="tipo_compra">
                    <option value="">Selecione</option>
                    <option>Dispensa</option>
                    <option>Licitação</option>
                </select>

            </div>

            <!-- ================= FINANCEIRO ================= -->
            <div class="campos-setor" data-setor="5" style="display:none">
                <label>Autorização Financeira</label>
                <select name="autorizacao">
                    <option value="">Selecione</option>
                    <option>Aprovado</option>
                    <option>Reprovado</option>
                </select>

                <label>Centro de Custo</label>
                <input type="text" name="centro_custo">
            </div>

            <!-- ================= LICITAÇÃO (SCL) ================= -->
            <div class="campos-setor" data-setor="6" style="display:none">
                <label>Número do Processo Licitatório</label>
                <input type="text" name="num_licitacao">

                <label>Modalidade</label>
                <select name="modalidade">
                    <option value="">Selecione</option>
                    <option>Pregão</option>
                    <option>Concorrência</option>
                    <option>Dispensa</option>
                </select>
            </div>

            <!-- ================= NAP ================= -->
            <div class="campos-setor" data-setor="7" style="display:none">
                <label>Análise do NAP</label>
                <textarea name="analise_nap"></textarea>

                <label>Status</label>
                <select name="status_nap">
                    <option value="">Selecione</option>
                    <option>Aprovado</option>
                    <option>Pendente</option>
                </select>
            </div>

            <!-- ================= BOTÕES ================= -->
            <div class="modal-actions">
                <button type="submit" class="btn-action primary">
                    <i class="fa-solid fa-share"></i> Confirmar Encaminhamento
                </button>

                <button type="button" class="btn-action secondary" onclick="fecharModal()">
                    Cancelar
                </button>
            </div>

        </form>
    </div>
</div>

<!-- ===== MODAL DE DEVOLVER ===== -->
<div id="modalDevolver" class="modal" onclick="fecharDevolver()">
    <div class="modal-box" onclick="event.stopPropagation()">

        <div class="modal-header">
            <h3>Devolver Processo</h3>
            <button type="button" class="modal-close" onclick="fecharDevolver()">
                <i class="fa-solid fa-xmark"></i>
            </button>
        </div>

        <form method="post" action="devolver.asp">

            <input type="hidden" name="id_processo" value="<%=idProcesso%>">

            <%
            ' Busca o último setor antes do atual
            Dim sqlUltimoSetor, rsUltimoSetor, setorAnterior, nomeSetorAnterior

            sqlUltimoSetor = "SELECT TOP 1 T.IdSetor, SE.NomeSetor FROM Tramitacoes T " & _
                              "INNER JOIN Setores SE ON SE.IdSetor = T.IdSetor " & _
                              "WHERE T.IdProcesso = " & idProcesso & " AND T.IdSetor <> " & rsProc("IdSetor") & " " & _
                              "ORDER BY T.DataEntrada DESC"
            Set rsUltimoSetor = conn.Execute(sqlUltimoSetor)

            If Not rsUltimoSetor.EOF Then
                setorAnterior = rsUltimoSetor("IdSetor")
                nomeSetorAnterior = rsUltimoSetor("NomeSetor")
            Else
                setorAnterior = ""
                nomeSetorAnterior = "Protocolo" ' default caso não tenha histórico
            End If

            rsUltimoSetor.Close
            Set rsUltimoSetor = Nothing
            %>

            <label>Devolver para</label>
            <input type="text" class="styled-input" value="<%=nomeSetorAnterior%>" disabled>
            <input type="hidden" name="setor_destino" value="<%=setorAnterior%>">

            <label>Motivo da devolução</label>
            <textarea name="observacao" rows="4" required placeholder="Informe o motivo da devolução..."></textarea>

            <div class="modal-actions">
                <button type="submit" class="btn-action warning">
                    <i class="fa-solid fa-rotate-left"></i> Devolver
                </button>
                <button type="button" class="btn-action secondary" onclick="fecharDevolver()">Cancelar</button>
            </div>

        </form>
    </div>
</div>
<!-- ================= FOOTER ================= -->
<footer class="footer">
    SisProc © <%=Year(Now())%> - Sistema de Acompanhamento de Processos
</footer>
<%
If Not rsSetorDestino Is Nothing Then
    rsSetorDestino.Close
    Set rsSetorDestino = Nothing
End If
%>
</body>
</html>