<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<%
Response.CodePage = 65001
Response.Charset  = "UTF-8"
%>
<!--#include file="../config/app.asp"-->
<!--#include file="../Lib/Conexao.asp"-->
<!--#include file="../includes/seguranca.asp"-->
<%
Call abreConexao

' ── DADOS DE GARGALO POR SETOR ───────────────────────────
Dim rsGargalo
Set rsGargalo = dbQuery( _
    "SELECT IdSetor, NomeSetor, Ordem, TotalPassagens, " & _
    "       ROUND(MediaDias,1) AS MediaDias, MaxDias, ProcessosAtivos " & _
    "FROM vw_GargaloSetores " & _
    "ORDER BY Ordem")

' Calcula o máximo de MediaDias para normalizar a barra
Dim maxMedia : maxMedia = 1
Dim rsMax
Set rsMax = dbQuery("SELECT MAX(ROUND(MediaDias,1)) AS M FROM vw_GargaloSetores")
If Not rsMax.EOF And Not IsNull(rsMax("M")) Then
    maxMedia = rsMax("M")
    If maxMedia = 0 Then maxMedia = 1
End If
rsMax.Close : Set rsMax = Nothing

' ── PROCESSOS ATRASADOS (> SLA) ──────────────────────────
Dim rsAtrasados
Set rsAtrasados = dbQuery( _
    "SELECT P.NumeroProcesso, P.Assunto, S.NomeSetor, T.DataEntrada, " & _
    "       DATEDIFF(DAY, T.DataEntrada, GETDATE()) AS Dias, P.IdProcesso " & _
    "FROM Tramitacoes T " & _
    "INNER JOIN Processos P ON P.IdProcesso = T.IdProcesso " & _
    "INNER JOIN Setores S   ON S.IdSetor    = T.IdSetor " & _
    "WHERE T.DataSaida IS NULL " & _
    "  AND DATEDIFF(DAY, T.DataEntrada, GETDATE()) >= " & SLA_ALERTA_DIAS & _
    "  AND P.Ativo = 1 " & _
    "ORDER BY Dias DESC")

Dim paginaAtiva : paginaAtiva = "relatorios"
Dim pageTitulo  : pageTitulo  = "Relatório de Gargalos"
%>
<!--#include file="../includes/layout.asp"-->

<div class="page-header">
    <h1><i class="fa-solid fa-chart-bar"></i> Relatório de Gargalos</h1>
</div>

<!-- TEMPO MÉDIO POR SETOR -->
<div class="card-box">
    <div class="card-box-title"><i class="fa-solid fa-hourglass-half"></i> Tempo Médio por Setor</div>

    <div style="display:flex;flex-direction:column;gap:16px">
    <% Do While Not rsGargalo.EOF %>
        <%
        Dim mediaD  : mediaD = rsGargalo("MediaDias")
        Dim pct     : pct    = Int((mediaD / maxMedia) * 100)
        Dim fillCls : fillCls = ""
        If mediaD >= SLA_ALERTA_DIAS Then
            fillCls = "alto"
        ElseIf mediaD >= 3 Then
            fillCls = "medio"
        End If
        %>
        <div>
            <div style="display:flex;justify-content:space-between;margin-bottom:6px">
                <span style="font-size:13.5px;font-weight:600"><%=rsGargalo("NomeSetor")%></span>
                <span style="font-size:12.5px;color:var(--text-muted)">
                    <%=rsGargalo("ProcessosAtivos")%> ativo(s) &nbsp;·&nbsp;
                    Média <strong class="<%=badgeSLA(mediaD)%>"><%=mediaD%> dias</strong> &nbsp;·&nbsp;
                    Máx <%=rsGargalo("MaxDias")%> dias &nbsp;·&nbsp;
                    <%=rsGargalo("TotalPassagens")%> passagem(ns)
                </span>
            </div>
            <div class="gargalo-bar-wrap">
                <div class="gargalo-bar">
                    <div class="gargalo-fill <%=fillCls%>" style="width:<%=pct%>%"></div>
                </div>
                <span style="font-size:12px;font-weight:700;min-width:50px;text-align:right" class="<%=badgeSLA(mediaD)%>"><%=mediaD%> d</span>
            </div>
        </div>
    <% rsGargalo.MoveNext : Loop %>
    </div>
</div>
<% rsGargalo.Close : Set rsGargalo = Nothing %>

<!-- PROCESSOS ATRASADOS -->
<div class="card-box">
    <div class="card-box-title"><i class="fa-solid fa-triangle-exclamation" style="color:var(--danger)"></i> Processos Atrasados (acima de <%=SLA_ALERTA_DIAS%> dias no setor)</div>

    <div class="table-wrap">
    <table class="data-table">
        <thead>
            <tr>
                <th>Nº Processo</th>
                <th>Assunto</th>
                <th>Setor Atual</th>
                <th>Entrada no Setor</th>
                <th>Dias Parado</th>
                <th class="col-center">Ação</th>
            </tr>
        </thead>
        <tbody>
        <% If rsAtrasados.EOF Then %>
            <tr><td colspan="6" class="empty-table">
                <i class="fa-solid fa-circle-check" style="color:var(--success)"></i>
                Nenhum processo atrasado. Tudo em dia!
            </td></tr>
        <% Else %>
        <% Do While Not rsAtrasados.EOF %>
            <tr>
                <td><span class="num-processo"><%=rsAtrasados("NumeroProcesso")%></span></td>
                <td><%=rsAtrasados("Assunto")%></td>
                <td><span class="badge badge-setor"><%=rsAtrasados("NomeSetor")%></span></td>
                <td><%=fmtData(rsAtrasados("DataEntrada"))%></td>
                <td><span class="sla-critico"><%=rsAtrasados("Dias")%> dias</span></td>
                <td class="col-center">
                    <a href="<%=APP_PATH%>/processos/detalhes.asp?id=<%=rsAtrasados("IdProcesso")%>" class="btn btn-outline btn-sm btn-icon">
                        <i class="fa-solid fa-eye"></i>
                    </a>
                </td>
            </tr>
        <% rsAtrasados.MoveNext : Loop %>
        <% End If %>
        </tbody>
    </table>
    </div>
</div>
<% rsAtrasados.Close : Set rsAtrasados = Nothing %>

<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

<%
Call fechaConexao
%>
<!--#include file="../includes/layout_footer.asp"-->
