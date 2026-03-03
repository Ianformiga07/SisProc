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

Dim idProcesso : idProcesso = dbInt(Request.QueryString("id"))
If idProcesso = 0 Then Response.Redirect "lista.asp" : Response.End

' Dados do processo
Dim rsProc
Set rsProc = dbQuery( _
    "SELECT P.*, U.Nome AS CriadorNome, " & _
    "       ISNULL(S.NomeSetor,'Finalizado') AS SetorAtual, " & _
    "       DATEDIFF(DAY, P.DataCriacao, GETDATE()) AS DiasTotal " & _
    "FROM Processos P " & _
    "INNER JOIN Usuarios U ON P.IdUsuarioCriador = U.IdUsuario " & _
    "OUTER APPLY (SELECT TOP 1 SE.NomeSetor FROM Tramitacoes T INNER JOIN Setores SE ON SE.IdSetor = T.IdSetor WHERE T.IdProcesso = P.IdProcesso AND T.DataSaida IS NULL) S " & _
    "WHERE P.IdProcesso = " & idProcesso)

If rsProc.EOF Then Response.Redirect "lista.asp" : Response.End

' Histórico
Dim rsHist
Set rsHist = dbQuery( _
    "SELECT T.*, S.NomeSetor, U.Nome AS UsuarioNome, " & _
    "       DATEDIFF(DAY, T.DataEntrada, ISNULL(T.DataSaida,GETDATE())) AS Dias " & _
    "FROM Tramitacoes T " & _
    "INNER JOIN Setores S  ON T.IdSetor   = S.IdSetor " & _
    "INNER JOIN Usuarios U ON T.IdUsuario = U.IdUsuario " & _
    "WHERE T.IdProcesso = " & idProcesso & " ORDER BY T.DataEntrada ASC")
%>
<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="utf-8">
    <title>Processo <%=rsProc("NumeroProcesso")%> — Impressão</title>
    <link rel="stylesheet" href="<%=APP_PATH%>/assets/css/main.css">
    <style>
        @media print { .no-print { display:none !important } body { font-size:12px; } }
        body { padding: 24px; max-width: 900px; margin: 0 auto; }
        .print-header { text-align:center; margin-bottom:24px; border-bottom:2px solid var(--border); padding-bottom:16px; }
        .print-header h1 { font-size:18px; margin-bottom:4px; }
        .print-header p { font-size:12px; color:var(--text-muted); }
    </style>
</head>
<body>

<div class="no-print" style="margin-bottom:16px">
    <button onclick="window.print()" class="btn btn-primary"><i class="fa-solid fa-print"></i> Imprimir</button>
    <a href="detalhes.asp?id=<%=idProcesso%>" class="btn btn-ghost" style="margin-left:8px">Voltar</a>
</div>

<div class="print-header">
    <h1>SisProc — Ficha de Acompanhamento de Processo</h1>
    <p>Gerado em <%=fmtDataHora(Now())%> por <%=sessNome%></p>
</div>

<div class="card-box">
    <div class="card-box-title">Dados do Processo</div>
    <div class="detail-grid">
        <div class="detail-item"><label>Número</label><span><%=rsProc("NumeroProcesso")%></span></div>
        <div class="detail-item"><label>Tipo</label><span><%=rsProc("TipoProcesso")%></span></div>
        <div class="detail-item"><label>Status</label><span><%=rsProc("StatusAtual")%></span></div>
        <div class="detail-item"><label>Setor Atual</label><span><%=rsProc("SetorAtual")%></span></div>
        <div class="detail-item"><label>Data de Abertura</label><span><%=fmtData(rsProc("DataCriacao"))%></span></div>
        <div class="detail-item"><label>Dias em Trâmite</label><span><%=rsProc("DiasTotal")%> dias</span></div>
        <div class="detail-item"><label>Criado por</label><span><%=rsProc("CriadorNome")%></span></div>
    </div>
    <div style="margin-top:12px"><strong>Assunto:</strong> <%=Server.HtmlEncode(rsProc("Assunto"))%></div>
    <% If Not IsNull(rsProc("Descricao")) And rsProc("Descricao") <> "" Then %>
    <div style="margin-top:8px"><strong>Descrição:</strong> <%=Server.HtmlEncode(rsProc("Descricao"))%></div>
    <% End If %>
</div>

<div class="card-box">
    <div class="card-box-title">Histórico de Tramitações</div>
    <table class="data-table" style="font-size:12px">
        <thead>
            <tr>
                <th>#</th>
                <th>Setor</th>
                <th>Tipo</th>
                <th>Usuário</th>
                <th>Entrada</th>
                <th>Saída</th>
                <th>Dias</th>
                <th>Observação</th>
            </tr>
        </thead>
        <tbody>
        <%
        Dim seq : seq = 1
        Do While Not rsHist.EOF
        %>
        <tr>
            <td><%=seq%></td>
            <td><%=rsHist("NomeSetor")%></td>
            <td><%=rsHist("TipoMovimento")%></td>
            <td><%=rsHist("UsuarioNome")%></td>
            <td><%=fmtData(rsHist("DataEntrada"))%></td>
            <td><%=fmtData(rsHist("DataSaida"))%></td>
            <td><%=rsHist("Dias")%></td>
            <td style="font-size:11px"><%=Server.HtmlEncode(rsHist("Observacao"))%></td>
        </tr>
        <%
        seq = seq + 1
        rsHist.MoveNext
        Loop
        %>
        </tbody>
    </table>
</div>

<%
rsProc.Close : Set rsProc = Nothing
rsHist.Close : Set rsHist = Nothing
Call fechaConexao
%>
</body>
</html>
