<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<!--#include file="../config/app.asp"-->
<!--#include file="../Lib/Conexao.asp"-->
<!--#include file="../includes/seguranca.asp"-->
<!--#include file="../includes/utils.asp"-->
<%
Call abreConexao
Call exigeAdmin

Dim idUsuario, acao
idUsuario = dbInt(Request.QueryString("id"))
acao      = LCase(Trim(Request.QueryString("acao") & ""))

If idUsuario = 0 Then
    Response.Redirect "lista.asp"
    Response.End
End If

' Nao permite desativar o proprio usuario
If idUsuario = sessId And acao = "desativar" Then
    Response.Redirect "lista.asp?erro=self"
    Response.End
End If

If acao = "desativar" Then
    dbExecute "UPDATE Usuarios SET Ativo = 0 WHERE IdUsuario_Int = " & idUsuario
    Call fechaConexao
    Response.Redirect "lista.asp?ok=desativado"
ElseIf acao = "ativar" Then
    dbExecute "UPDATE Usuarios SET Ativo = 1 WHERE IdUsuario_Int = " & idUsuario
    Call fechaConexao
    Response.Redirect "lista.asp?ok=ativado"
Else
    Call fechaConexao
    Response.Redirect "lista.asp"
End If
%>
