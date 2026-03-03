<!--#include file="../config/app.asp"-->
<!--#include file="../Lib/Conexao.asp"-->
<%
Call abreConexao

Dim login, senha
login = Trim(Request.Form("login"))
senha = Trim(Request.Form("senha"))

If login = "" Or senha = "" Then
    Response.Redirect "login.asp?erro=1"
    Response.End
End If

' Converte a senha digitada para SHA2_256 antes de comparar
' Mesmo hash usado no cadastro (salvar.asp dos usuarios)
Dim rsHash, senhaHash
Set rsHash = conn.Execute( _
    "SELECT CONVERT(VARCHAR(255), HASHBYTES('SHA2_256', '" & Replace(senha,"'","''") & "'), 2) AS H")
senhaHash = rsHash("H")
rsHash.Close : Set rsHash = Nothing

' Busca o usuario pelo login + hash da senha
' Nome vem da propria tabela Usuarios (nao depende de CadFunc)
Dim rs
Set rs = conn.Execute( _
    "SELECT U.IdUsuario_Int, U.Matricula, U.Nome, U.IdPerfil, U.IdSetor, S.NomeSetor " & _
    "FROM Usuarios U " & _
    "INNER JOIN Setores S ON S.IdSetor = U.IdSetor " & _
    "WHERE U.Login = '" & Replace(login,"'","''") & "' " & _
    "  AND U.Senha = '" & senhaHash & "' " & _
    "  AND U.Ativo = 1")

If Not rs.EOF Then
    Session.Timeout = 30
    Session("IdUsuario") = rs("IdUsuario_Int")
    Session("Matricula") = rs("Matricula")
    Session("Nome")      = rs("Nome")
    Session("IdPerfil")  = rs("IdPerfil")
    Session("IdSetor")   = rs("IdSetor")
    Session("NomeSetor") = rs("NomeSetor")

    rs.Close : Set rs = Nothing
    Call fechaConexao

    Response.Redirect APP_PATH & "/index.asp"
Else
    rs.Close : Set rs = Nothing
    Call fechaConexao

    Response.Redirect "login.asp?erro=1"
End If
%>
