<!--#include file="../config/app.asp"-->
<!--#include file="../Lib/Conexao.asp"-->
<%
Call abreConexao

Dim login, senha
login = Trim(Request.Form("login"))
senha = Trim(Request.Form("senha"))

' Busca usuario com JOIN no CadFunc para pegar o Nome
' E popula tambem IdSetor e NomeSetor para o layout funcionar
Dim sql
sql = "SELECT U.Matricula, U.IdPerfil, U.IdSetor, " & _
      "       S.NomeSetor, C.Nome " & _
      "FROM Usuarios U " & _
      "INNER JOIN Setores S ON S.IdSetor = U.IdSetor " & _
      "INNER JOIN Adapec.dbo.CadFunc C ON C.Matricula = U.Matricula " & _
      "WHERE U.Login = ? AND U.Senha = ? AND U.Ativo = 1"

Dim cmd
Set cmd = Server.CreateObject("ADODB.Command")
Set cmd.ActiveConnection = conn
cmd.CommandText = sql
cmd.CommandType = 1

cmd.Parameters.Append cmd.CreateParameter("@login", 200, 1, 50,  login)
cmd.Parameters.Append cmd.CreateParameter("@senha", 200, 1, 255, senha)

Dim rs
Set rs = cmd.Execute

If Not rs.EOF Then
    Session.Timeout = 30

    ' Popula todas as variaveis de sessao que o sistema usa
    Session("Matricula")  = rs("Matricula")
    Session("IdPerfil")   = rs("IdPerfil")
    Session("IdSetor")    = rs("IdSetor")
    Session("NomeSetor")  = rs("NomeSetor")
    Session("Nome")       = rs("Nome")

    ' IdUsuario: busca o ID interno (pode ser IdUsuario_Int ou campo numerico da tabela)
    Dim rsId
    Set rsId = conn.Execute("SELECT IdUsuario_Int AS Id FROM Usuarios WHERE Matricula = '" & Replace(rs("Matricula"),"'","''") & "'")
    If Not rsId.EOF Then
        Session("IdUsuario") = rsId("Id")
    Else
        Session("IdUsuario") = 0
    End If
    rsId.Close : Set rsId = Nothing

    rs.Close : Set rs = Nothing
    Set cmd = Nothing
    Call fechaConexao

    Response.Redirect APP_PATH & "/index.asp"
Else
    rs.Close : Set rs = Nothing
    Set cmd = Nothing
    Call fechaConexao

    Response.Redirect "login.asp?erro=1"
End If
%>
