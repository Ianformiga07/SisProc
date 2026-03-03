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

' ── RECEBE DADOS ─────────────────────────────────────────
Dim numero, tipo, assunto, descricao
numero   = dbStr(Request.Form("numero_processo"))
tipo     = dbStr(Request.Form("tipo_processo"))
assunto  = dbStr(Request.Form("assunto"))
descricao = dbStr(Request.Form("descricao"))

' ── VALIDAÇÕES ───────────────────────────────────────────
If numero = "" Or tipo = "" Or assunto = "" Then
    Response.Redirect "novo.asp?erro=" & Server.URLEncode("Preencha todos os campos obrigatórios.")
    Response.End
End If

' ── VERIFICA DUPLICIDADE ──────────────────────────────────
Dim rsDup
Set rsDup = dbQuery("SELECT COUNT(*) AS Total FROM Processos WHERE NumeroProcesso = '" & numero & "'")
If rsDup("Total") > 0 Then
    rsDup.Close : Set rsDup = Nothing
    Response.Redirect "novo.asp?erro=" & Server.URLEncode("Já existe um processo com este número.")
    Response.End
End If
rsDup.Close : Set rsDup = Nothing

' ── INSERE O PROCESSO ────────────────────────────────────
Dim sqlInsert
sqlInsert = "INSERT INTO Processos (NumeroProcesso, Assunto, Descricao, TipoProcesso, MatriculaCriador) " & _
            "VALUES ('" & numero & "', '" & assunto & "', '" & descricao & "', '" & tipo & "', " & sessId & ")"

dbExecute sqlInsert

' ── PEGA O ID GERADO DO PROCESSO ─────────────────────────
Dim rsId, idProcesso
Set rsId = dbQuery( _
    "INSERT INTO Processos (NumeroProcesso, Assunto, Descricao, TipoProcesso, MatriculaCriador) " & _
    "VALUES ('" & numero & "', '" & assunto & "', '" & descricao & "', '" & tipo & "', " & sessId & "); " & _
    "SELECT SCOPE_IDENTITY() AS Id" _
)

If rsId.EOF Or IsNull(rsId("Id")) Then
    Response.Write "Erro ao obter ID do processo."
    Response.End
End If

idProcesso = CLng(rsId("Id"))
rsId.Close : Set rsId = Nothing

' ── CRIA A PRIMEIRA TRAMITAÇÃO (Protocolo = setor 1) ─────
Dim sqlTram
sqlTram = "INSERT INTO Tramitacoes (IdProcesso, IdSetor, IdUsuario, Observacao, TipoMovimento) " & _
          "VALUES (" & idProcesso & ", 1, " & sessId & ", 'Processo autuado no Protocolo.', 'Encaminhar')"
dbExecute sqlTram

Call fechaConexao

Response.Redirect "detalhes.asp?id=" & idProcesso & "&msg=criado"
%>
