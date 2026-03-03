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

' ── RECEBE DADOS ─────────────────────────────────────────
Dim idProcesso, idSetorDestino, observacao
idProcesso     = dbInt(Request.Form("id_processo"))
idSetorDestino = dbInt(Request.Form("setor_destino"))
observacao     = dbStr(Request.Form("observacao"))

' ── VALIDAÇÃO BÁSICA ─────────────────────────────────────
If idProcesso = 0 Or observacao = "" Then
    Response.Redirect "lista.asp"
    Response.End
End If

' ── PROCESSO NÃO FINALIZADO ───────────────────────────────
Dim rsProc
Set rsProc = dbQuery("SELECT Ativo FROM Processos WHERE IdProcesso = " & idProcesso)
If rsProc.EOF Or rsProc("Ativo") = False Then
    rsProc.Close : Set rsProc = Nothing
    Response.Redirect "detalhes.asp?id=" & idProcesso
    Response.End
End If
rsProc.Close : Set rsProc = Nothing

' ── BUSCA TRAMITAÇÃO ATUAL ABERTA ────────────────────────
Dim rsAtual, idTramAtual, idSetorAtual
Set rsAtual = dbQuery( _
    "SELECT TOP 1 IdTramitacao, IdSetor FROM Tramitacoes " & _
    "WHERE IdProcesso = " & idProcesso & " AND DataSaida IS NULL " & _
    "ORDER BY DataEntrada DESC")

If rsAtual.EOF Then
    rsAtual.Close : Set rsAtual = Nothing
    Response.Redirect "detalhes.asp?id=" & idProcesso
    Response.End
End If

idTramAtual  = rsAtual("IdTramitacao")
idSetorAtual = rsAtual("IdSetor")
rsAtual.Close : Set rsAtual = Nothing

' ── SE NÃO VEIO SETOR DESTINO, USA O ANTERIOR ─────────────
If idSetorDestino = 0 Then
    Dim rsAnterior
    Set rsAnterior = dbQuery( _
        "SELECT TOP 1 IdSetor FROM Tramitacoes " & _
        "WHERE IdProcesso = " & idProcesso & _
        "  AND IdSetor <> " & idSetorAtual & _
        "  AND DataSaida IS NOT NULL " & _
        "ORDER BY DataEntrada DESC")

    If Not rsAnterior.EOF Then
        idSetorDestino = rsAnterior("IdSetor")
    Else
        idSetorDestino = 1  ' fallback: Protocolo
    End If
    rsAnterior.Close : Set rsAnterior = Nothing
End If

' ── 1. FECHA TRAMITAÇÃO ATUAL ────────────────────────────
' BUG CORRIGIDO: versão anterior não fechava a tramitação atual
dbExecute "UPDATE Tramitacoes SET DataSaida = GETDATE() WHERE IdTramitacao = " & idTramAtual

' ── 2. INSERE NOVA TRAMITAÇÃO (devolução) ────────────────
dbExecute _
    "INSERT INTO Tramitacoes (IdProcesso, IdSetor, IdUsuario, Observacao, TipoMovimento) " & _
    "VALUES (" & idProcesso & ", " & idSetorDestino & ", " & sessId & ", '" & observacao & "', 'Devolver')"

Call fechaConexao

Response.Redirect "detalhes.asp?id=" & idProcesso
%>
