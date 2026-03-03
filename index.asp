<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<%
Response.CodePage = 65001
Response.Charset  = "UTF-8"
%>
<!--#include file="config/app.asp"-->
<!--#include file="Lib/Conexao.asp"-->
<!--#include file="includes/seguranca.asp"-->
<!--#include file="includes/utils.asp"-->
<%
Call abreConexao

' ── KPIs ──────────────────────────────────────────────────
Dim rsKpi
Set rsKpi = dbQuery( _
    "SELECT " & _
    "  (SELECT COUNT(*) FROM Processos)                              AS Total, " & _
    "  (SELECT COUNT(*) FROM Processos WHERE Ativo = 1)             AS Andamento, " & _
    "  (SELECT COUNT(*) FROM Processos WHERE Ativo = 0)             AS Finalizados, " & _
    "  (SELECT COUNT(DISTINCT IdProcesso) FROM Tramitacoes " & _
    "   WHERE DataSaida IS NULL " & _
    "   AND DATEDIFF(DAY, DataEntrada, GETDATE()) >= " & SLA_ALERTA_DIAS & ") AS Atrasados")

Dim kTotal, kAndamento, kFinalizados, kAtrasados
kTotal       = rsKpi("Total")
kAndamento   = rsKpi("Andamento")
kFinalizados = rsKpi("Finalizados")
kAtrasados   = rsKpi("Atrasados")
rsKpi.Close : Set rsKpi = Nothing

' ── PROCESSOS POR SETOR (gráfico barra) ──────────────────
Dim rsSetor, labelsSetor, valoresSetor, coresSetor
labelsSetor  = ""
valoresSetor = ""
coresSetor   = ""
Dim corArr(7)
corArr(0) = "#1a56db" : corArr(1) = "#0ea5e9" : corArr(2) = "#8b5cf6"
corArr(3) = "#ec4899" : corArr(4) = "#f97316" : corArr(5) = "#16a34a"
corArr(6) = "#dc2626"

Dim iSetor : iSetor = 0
Set rsSetor = dbQuery( _
    "SELECT S.NomeSetor, COUNT(*) AS Total " & _
    "FROM Tramitacoes AS T " & _
    "INNER JOIN Setores AS S ON S.IdSetor = T.IdSetor " & _
    "WHERE T.DataSaida IS NULL " & _
    "GROUP BY S.NomeSetor " & _
    "ORDER BY S.NomeSetor" _
)

Do While Not rsSetor.EOF
    labelsSetor  = labelsSetor  & "'" & rsSetor("NomeSetor") & "',"
    valoresSetor = valoresSetor & rsSetor("Total") & ","
    coresSetor   = coresSetor   & "'" & corArr(iSetor Mod 7) & "',"
    iSetor = iSetor + 1
    rsSetor.MoveNext
Loop
rsSetor.Close : Set rsSetor = Nothing

' ── PROCESSOS POR MÊS (últimos 6) ────────────────────────
Dim rsMes, labelsMes, valoresMes
labelsMes  = ""
valoresMes = ""
Set rsMes = dbQuery( _
    "SELECT FORMAT(DataCriacao,'MM/yyyy') AS Mes, COUNT(*) AS Total " & _
    "FROM Processos " & _
    "WHERE DataCriacao >= DATEADD(MONTH,-5,GETDATE()) " & _
    "GROUP BY FORMAT(DataCriacao,'MM/yyyy') " & _
    "ORDER BY MIN(DataCriacao)")

Do While Not rsMes.EOF
    labelsMes  = labelsMes  & "'" & rsMes("Mes") & "',"
    valoresMes = valoresMes & rsMes("Total") & ","
    rsMes.MoveNext
Loop
rsMes.Close : Set rsMes = Nothing

' ── ÚLTIMOS 5 PROCESSOS ──────────────────────────────────
Dim rsRecentes
Set rsRecentes = dbQuery( _
    "SELECT TOP 5 NumeroProcesso, Assunto, SetorAtual, DiasNoSetor, StatusAtual, IdProcesso " & _
    "FROM vw_ProcessosLista " & _
    "ORDER BY DataCriacao DESC")

' ── Variáveis de layout ──────────────────────────────────
Dim paginaAtiva : paginaAtiva = "dashboard"
Dim pageTitulo  : pageTitulo  = "Dashboard"

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
%>
<!--#include file="includes/layout.asp"-->

<!-- KPIs -->
<div class="kpi-grid">
    <div class="kpi-card">
        <div class="kpi-icon blue"><i class="fa-solid fa-folder"></i></div>
        <div class="kpi-label">Total de Processos</div>
        <div class="kpi-value"><%=kTotal%></div>
    </div>
    <div class="kpi-card">
        <div class="kpi-icon yellow"><i class="fa-solid fa-spinner"></i></div>
        <div class="kpi-label">Em Andamento</div>
        <div class="kpi-value"><%=kAndamento%></div>
    </div>
    <div class="kpi-card">
        <div class="kpi-icon green"><i class="fa-solid fa-check-circle"></i></div>
        <div class="kpi-label">Finalizados</div>
        <div class="kpi-value"><%=kFinalizados%></div>
    </div>
    <div class="kpi-card">
        <div class="kpi-icon red"><i class="fa-solid fa-triangle-exclamation"></i></div>
        <div class="kpi-label">Atrasados (><%=SLA_ALERTA_DIAS%> dias)</div>
        <div class="kpi-value"><%=kAtrasados%></div>
    </div>
</div>

<!-- GRÁFICOS -->
<div class="charts-grid">
    <div class="card-box">
        <div class="card-box-title"><i class="fa-solid fa-chart-pie"></i> Status</div>
        <div class="chart-wrap">
            <canvas id="graficoStatus"></canvas>
        </div>
    </div>
    <div class="card-box">
        <div class="card-box-title"><i class="fa-solid fa-chart-bar"></i> Processos por Mês</div>
        <div class="chart-wrap">
            <canvas id="graficoMes"></canvas>
        </div>
    </div>
</div>

<div class="card-box">
    <div class="card-box-title"><i class="fa-solid fa-sitemap"></i> Processos por Setor (ativos)</div>
    <div class="chart-wrap">
        <canvas id="graficoSetor"></canvas>
    </div>
</div>

<!-- RECENTES -->
<div class="card-box">
    <div class="card-box-title">
        <i class="fa-solid fa-clock-rotate-left"></i> Últimos Processos
        <a href="<%=APP_PATH%>/processos/lista.asp" class="btn btn-ghost btn-sm" style="margin-left:auto">Ver todos</a>
    </div>
    <div class="table-wrap">
        <table class="data-table">
            <thead>
                <tr>
                    <th>Nº Processo</th>
                    <th>Assunto</th>
                    <th>Setor Atual</th>
                    <th>Dias no Setor</th>
                    <th>Status</th>
                    <th class="col-center">Ação</th>
                </tr>
            </thead>
            <tbody>
            <% If rsRecentes.EOF Then %>
                <tr><td colspan="6" class="empty-table"><i class="fa-regular fa-folder-open"></i>Nenhum processo cadastrado.</td></tr>
            <% Else %>
            <% Do While Not rsRecentes.EOF %>
                <tr>
                    <td><span class="num-processo"><%=rsRecentes("NumeroProcesso")%></span></td>
                    <td><%=rsRecentes("Assunto")%></td>
                    <td><span class="badge badge-setor"><%=rsRecentes("SetorAtual")%></span></td>
                    <td><span class="<%=badgeSLA(rsRecentes("DiasNoSetor"))%>"><%=rsRecentes("DiasNoSetor")%> dias</span></td>
                    <td><span class="badge <%=badgeStatus(rsRecentes("StatusAtual"))%>"><%=rsRecentes("StatusAtual")%></span></td>
                    <td class="col-center">
                        <a href="<%=APP_PATH%>/processos/detalhes.asp?id=<%=rsRecentes("IdProcesso")%>" class="btn btn-outline btn-sm">
                            <i class="fa-solid fa-eye"></i>
                        </a>
                    </td>
                </tr>
            <% rsRecentes.MoveNext : Loop %>
            <% End If %>
            </tbody>
        </table>
    </div>
</div>

<%
rsRecentes.Close : Set rsRecentes = Nothing
Call fechaConexao
%>

<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<script>
Chart.defaults.font.family = "'IBM Plex Sans', sans-serif";
Chart.defaults.font.size   = 12;

// Doughnut - Status
new Chart(document.getElementById('graficoStatus'), {
    type: 'doughnut',
    data: {
        labels: ['Em andamento', 'Finalizados'],
        datasets: [{
            data: [<%=kAndamento%>, <%=kFinalizados%>],
            backgroundColor: ['#1a56db', '#16a34a'],
            borderWidth: 0
        }]
    },
    options: {
        responsive: true, maintainAspectRatio: false,
        cutout: '68%',
        plugins: { legend: { position: 'bottom', labels: { boxWidth: 10, padding: 14 } } }
    }
});

// Barras - Por Mês
new Chart(document.getElementById('graficoMes'), {
    type: 'bar',
    data: {
        labels: [<%=labelsMes%>],
        datasets: [{ label: 'Processos', data: [<%=valoresMes%>],
            backgroundColor: '#1a56db', borderRadius: 5, maxBarThickness: 40 }]
    },
    options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: { y: { beginAtZero: true, ticks: { stepSize: 1 } } }
    }
});

// Barras - Por Setor
new Chart(document.getElementById('graficoSetor'), {
    type: 'bar',
    data: {
        labels: [<%=labelsSetor%>],
        datasets: [{ label: 'Processos', data: [<%=valoresSetor%>],
            backgroundColor: [<%=coresSetor%>], borderRadius: 5, maxBarThickness: 50 }]
    },
    options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: { y: { beginAtZero: true, ticks: { stepSize: 1 } } }
    }
});
</script>

<!--#include file="includes/layout_footer.asp"-->
