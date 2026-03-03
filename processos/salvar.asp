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

Dim numero, tipo, assunto, descricao
numero    = dbStr(Request.Form("numero_processo"))
tipo      = dbStr(Request.Form("tipo_processo"))
assunto   = dbStr(Request.Form("assunto"))
descricao = dbStr(Request.Form("descricao"))

If numero = "" Or tipo = "" Or assunto = "" Then
    Response.Redirect "novo.asp?erro=" & Server.URLEncode("Preencha todos os campos obrigatorios.")
    Response.End
End If

' Verifica duplicidade
Dim rsDup
Set rsDup = dbQuery("SELECT COUNT(*) AS Total FROM Processos WHERE NumeroProcesso = '" & numero & "'")
If rsDup("Total") > 0 Then
    rsDup.Close : Set rsDup = Nothing
    Response.Redirect "novo.asp?erro=" & Server.URLEncode("Ja existe um processo com este numero.")
    Response.End
End If
rsDup.Close : Set rsDup = Nothing

' PASSO 1: INSERT do processo
dbExecute _
    "INSERT INTO Processos (NumeroProcesso, Assunto, Descricao, TipoProcesso, MatriculaCriador) " & _
    "VALUES ('" & numero & "', '" & assunto & "', '" & descricao & "', '" & tipo & "', '" & sessMatricula & "')"

' PASSO 2: Pega o ID gerado com @@IDENTITY
' @@IDENTITY funciona na mesma conexao independente do provider
Dim rsId, idProcesso
Set rsId = dbQuery("SELECT @@IDENTITY AS Id")

If rsId.EOF Or IsNull(rsId("Id")) Then
    rsId.Close : Set rsId = Nothing
    Response.Redirect "novo.asp?erro=" & Server.URLEncode("Erro ao obter ID do processo. Tente novamente.")
    Response.End
End If

idProcesso = CLng(rsId("Id"))
rsId.Close : Set rsId = Nothing

' PASSO 3: Cria primeira tramitacao no Protocolo (setor 1)
dbExecute _
    "INSERT INTO Tramitacoes (IdProcesso, IdSetor, MatriculaUsuario, Observacao) " & _
    "VALUES (" & idProcesso & ", 1, '" & sessMatricula & "', 'Processo autuado no Protocolo.')"

Call fechaConexao

Response.Redirect "detalhes.asp?id=" & idProcesso & "&novo=1"
%>
