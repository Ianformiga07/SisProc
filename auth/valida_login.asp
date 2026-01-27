<!--#include file="../Lib/Conexao.asp" -->
<!--#include file="../config/app.asp" -->

<%
call abreConexao

Dim login, senha, sql, rs, cmd

login = Trim(Request.Form("login"))
senha = Trim(Request.Form("senha"))

sql = "SELECT U.IdUsuario_Int AS IdUsuario, U.Matricula, U.IdPerfil, C.Nome " & _
      "FROM Usuarios U " & _
      "INNER JOIN Adapec.dbo.CadFunc C ON C.Matricula = U.Matricula " & _
      "WHERE U.Login = ? AND U.Senha = ? AND U.Ativo = 1"

'response.write sql
'response.end
Set cmd = Server.CreateObject("ADODB.Command")
Set cmd.ActiveConnection = conn
cmd.CommandText = sql
cmd.CommandType = 1 ' adCmdText

cmd.Parameters.Append cmd.CreateParameter("@login", 200, 1, 50, login)
cmd.Parameters.Append cmd.CreateParameter("@senha", 200, 1, 255, senha)

Set rs = cmd.Execute

If Not rs.EOF Then
    Session.Timeout = 30
    Session("IdUsuario") = rs("IdUsuario")
    Session("Matricula") = rs("Matricula")
    Session("Nome") = rs("Nome")
    Session("IdPerfil") = rs("IdPerfil")

    Response.Redirect(APP_PATH & "/index.asp")
Else
    Response.Redirect("login.asp?erro=1")
End If

rs.Close
Set rs = Nothing
Set cmd = Nothing

call fechaConexao
%>