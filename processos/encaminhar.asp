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

Dim idProcesso, idSetorDestino, observacao
idProcesso     = dbInt(Request.Form("id_processo"))
idSetorDestino = dbInt(Request.Form("setor_destino"))
observacao     = dbStr(Request.Form("observacao"))

If idProcesso = 0 Or idSetorDestino = 0 Then
    Response.Redirect "lista.asp"
    Response.End
End If

' Verifica se processo esta ativo
Dim rsProc
Set rsProc = dbQuery("SELECT Ativo FROM Processos WHERE IdProcesso = " & idProcesso)
If rsProc.EOF Or rsProc("Ativo") = False Then
    rsProc.Close : Set rsProc = Nothing
    Response.Redirect "detalhes.asp?id=" & idProcesso & "&erro=processo_finalizado"
    Response.End
End If
rsProc.Close : Set rsProc = Nothing

' Busca tramitacao atual aberta
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

idSetorAtual = CLng(rsAtual("IdSetor"))
idTramAtual  = rsAtual("IdTramitacao")
rsAtual.Close : Set rsAtual = Nothing

' Regra: so o setor atual (ou admin) pode encaminhar
If CLng(sessIdSetor) <> idSetorAtual And Not sessIsAdmin Then
    Response.Redirect "detalhes.asp?id=" & idProcesso & "&erro=sem_permissao"
    Response.End
End If

' Valida fluxo no banco
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

' 1. Fecha tramitacao atual
dbExecute "UPDATE Tramitacoes SET DataSaida = GETDATE() WHERE IdTramitacao = " & idTramAtual

' 2. Insere nova tramitacao
dbExecute _
    "INSERT INTO Tramitacoes (IdProcesso, IdSetor, MatriculaUsuario, Observacao) " & _
    "VALUES (" & idProcesso & ", " & idSetorDestino & ", '" & sessMatricula & "', '" & observacao & "')"

' 3. Pega o ID da tramitacao recem criada
Dim rsId, idTramNova
Set rsId = dbQuery("SELECT @@IDENTITY AS Id")
idTramNova = CLng(rsId("Id"))
rsId.Close : Set rsId = Nothing

' 4. Salva detalhes baseado no SETOR ATUAL (quem encaminhou)
'    Cada setor registra suas proprias informacoes ao encaminhar
Sub salvarDetalhe(campo, formField)
    Dim v : v = dbStr(Trim(Request.Form(formField) & ""))
    If v <> "" Then
        dbExecute "INSERT INTO TramitacaoDetalhes (IdTramitacao, Campo, Valor) " & _
                  "VALUES (" & idTramNova & ", '" & campo & "', '" & v & "')"
    End If
End Sub

Select Case idSetorAtual
    Case 2 ' Setor Solicitante encaminhou
        Call salvarDetalhe("Descricao",  "descricao")
        Call salvarDetalhe("Quantidade", "quantidade")
        Call salvarDetalhe("Urgencia",   "urgencia")

    Case 3 ' Compras encaminhou
        Call salvarDetalhe("Fornecedor",     "fornecedor")
        Call salvarDetalhe("Cotacoes",       "cotacoes")
        Call salvarDetalhe("Tipo de Compra", "tipo_compra")

    Case 4 ' Planejamento encaminhou
        Call salvarDetalhe("Analise",    "analise_planejamento")
        Call salvarDetalhe("Impacto",    "impacto")
        Call salvarDetalhe("Prioridade", "prioridade")

    Case 5 ' Licitacao (SCL) encaminhou
        Call salvarDetalhe("Num Licitatorio", "numero_edital")
        Call salvarDetalhe("Modalidade",      "modalidade")
        Call salvarDetalhe("Parecer",         "parecer_juridico")

    Case 6 ' Financeiro encaminhou
        Call salvarDetalhe("Centro de Custo", "centro_custo")
        Call salvarDetalhe("Autorizacao",     "autorizacao")

    Case 7 ' NAP encaminhou
        Call salvarDetalhe("Analise NAP", "providencia_nap")
        Call salvarDetalhe("Status NAP",  "status_nap")

    ' Case 1 (Protocolo): sem campos extras, so observacao
End Select

Call fechaConexao

Response.Redirect "detalhes.asp?id=" & idProcesso & "&ok=encaminhado"
%>
