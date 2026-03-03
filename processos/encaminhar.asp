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
If idProcesso = 0 Or idSetorDestino = 0 Then
    Response.Redirect "lista.asp"
    Response.End
End If

' ── PROCESSO EXISTE E NÃO ESTÁ FINALIZADO ────────────────
Dim rsProc
Set rsProc = dbQuery("SELECT Ativo, StatusAtual FROM Processos WHERE IdProcesso = " & idProcesso)
If rsProc.EOF Or rsProc("Ativo") = False Then
    rsProc.Close : Set rsProc = Nothing
    Response.Redirect "detalhes.asp?id=" & idProcesso & "&erro=processo_finalizado"
    Response.End
End If
rsProc.Close : Set rsProc = Nothing

' ── BUSCA TRAMITAÇÃO ATUAL ────────────────────────────────
Dim rsAtual, idSetorAtual, idTramAtual
Set rsAtual = dbQuery( _
    "SELECT TOP 1 IdTramitacao, IdSetor FROM Tramitacoes " & _
    "WHERE IdProcesso = " & idProcesso & " AND DataSaida IS NULL " & _
    "ORDER BY DataEntrada DESC")

If rsAtual.EOF Then
    rsAtual.Close : Set rsAtual = Nothing
    Response.Redirect "detalhes.asp?id=" & idProcesso
    Response.End
End If

idSetorAtual = rsAtual("IdSetor")
idTramAtual  = rsAtual("IdTramitacao")
rsAtual.Close : Set rsAtual = Nothing

' ── VALIDA FLUXO NO BANCO (único ponto de verdade) ───────
Dim rsFluxo
Set rsFluxo = dbQuery( _
    "SELECT COUNT(*) AS Ok FROM FluxoSetores " & _
    "WHERE IdSetorOrigem = " & idSetorAtual & _
    "  AND IdSetorDestino = " & idSetorDestino & _
    "  AND Ativo = 1")
If rsFluxo("Ok") = 0 Then
    rsFluxo.Close : Set rsFluxo = Nothing
    Response.Redirect "detalhes.asp?id=" & idProcesso & "&erro=fluxo_invalido"
    Response.End
End If
rsFluxo.Close : Set rsFluxo = Nothing

' ── 1. FECHA A TRAMITAÇÃO ATUAL ───────────────────────────
dbExecute "UPDATE Tramitacoes SET DataSaida = GETDATE() WHERE IdTramitacao = " & idTramAtual

' ── 2. INSERE NOVA TRAMITAÇÃO ─────────────────────────────
dbExecute _
    "INSERT INTO Tramitacoes (IdProcesso, IdSetor, IdUsuario, Observacao, TipoMovimento) " & _
    "VALUES (" & idProcesso & ", " & idSetorDestino & ", " & sessId & ", '" & observacao & "', 'Encaminhar')"

Dim idTramNova : idTramNova = dbLastId()

' ── 3. SALVA DETALHES ESPECÍFICOS DO SETOR ───────────────
Sub salvarDetalhe(campo, valor)
    Dim v : v = dbStr(Trim(Request.Form(valor)))
    If v <> "" Then
        dbExecute "INSERT INTO TramitacaoDetalhes (IdTramitacao, Campo, Valor) " & _
                  "VALUES (" & idTramNova & ", '" & campo & "', '" & v & "')"
    End If
End Sub

Select Case idSetorDestino
    Case 2  ' Setor Solicitante
        Call salvarDetalhe("Descrição",  "descricao")
        Call salvarDetalhe("Quantidade", "quantidade")
        Call salvarDetalhe("Urgência",   "urgencia")
    Case 3  ' Compras
        Call salvarDetalhe("Fornecedor",    "fornecedor")
        Call salvarDetalhe("Cotações",      "cotacoes")
        Call salvarDetalhe("Tipo de Compra","tipo_compra")
    Case 4  ' Planejamento
        Call salvarDetalhe("Análise",    "analise_planejamento")
        Call salvarDetalhe("Impacto",    "impacto")
        Call salvarDetalhe("Prioridade", "prioridade")
    Case 5  ' Licitação SCL
        Call salvarDetalhe("Nº Processo Licitatório", "numero_edital")
        Call salvarDetalhe("Modalidade",              "modalidade")
        Call salvarDetalhe("Parecer Jurídico",        "parecer_juridico")
    Case 6  ' Financeiro
        Call salvarDetalhe("Centro de Custo", "centro_custo")
        Call salvarDetalhe("Autorização",     "autorizacao")
    Case 7  ' NAP
        Call salvarDetalhe("Análise NAP",  "providencia_nap")
        Call salvarDetalhe("Status NAP",   "status_nap")
End Select

Call fechaConexao

Response.Redirect "detalhes.asp?id=" & idProcesso
%>
