<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<!--#include file="../config/app.asp"-->
<!--#include file="../Lib/Conexao.asp"-->
<!--#include file="../includes/seguranca.asp"-->
<%
Call abreConexao

' Apenas admins podem finalizar
If Not sessIsAdmin Then
    Response.Redirect "lista.asp"
    Response.End
End If

Dim idProcesso : idProcesso = dbInt(Request.QueryString("id"))
If idProcesso = 0 Then
    Response.Redirect "lista.asp"
    Response.End
End If

' Fecha a tramitação atual
dbExecute _
    "UPDATE Tramitacoes SET DataSaida = GETDATE() " & _
    "WHERE IdProcesso = " & idProcesso & " AND DataSaida IS NULL"

' Finaliza o processo
dbExecute _
    "UPDATE Processos " & _
    "SET StatusAtual = 'Finalizado', DataFinalizacao = GETDATE(), Ativo = 0 " & _
    "WHERE IdProcesso = " & idProcesso

' Insere tramitação de finalização
dbExecute _
    "INSERT INTO Tramitacoes (IdProcesso, IdSetor, IdUsuario, Observacao, TipoMovimento, DataSaida) " & _
    "SELECT " & idProcesso & ", IdSetor, " & sessId & ", 'Processo finalizado.', 'Finalizar', GETDATE() " & _
    "FROM Tramitacoes WHERE IdProcesso = " & idProcesso & " AND DataSaida = GETDATE()"

Call fechaConexao

Response.Redirect "detalhes.asp?id=" & idProcesso & "&msg=finalizado"
%>
