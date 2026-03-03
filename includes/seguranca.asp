<%
' ============================================================
'  SisProc - Controle de Segurança / Sessão
'  includes/seguranca.asp
' ============================================================

' Redireciona para login se não autenticado
If Session("IdUsuario") = "" Or Session("IdUsuario") = 0 Then
    Response.Redirect APP_PATH & "/auth/login.asp"
    Response.End
End If

' Atalhos de sessão (para uso nas páginas)
Dim sessId       : sessId       = CLng(Session("IdUsuario"))
Dim sessNome     : sessNome     = Session("Nome")
Dim sessMatricula: sessMatricula = Session("Matricula")
Dim sessIdPerfil : sessIdPerfil = CLng(Session("IdPerfil"))
Dim sessIsAdmin  : sessIsAdmin  = (sessIdPerfil = 1)
Dim sessIdSetor  : sessIdSetor  = CLng(Session("IdSetor"))
Dim sessSetor    : sessSetor    = Session("NomeSetor")

' Helper: exige perfil Admin, redireciona se não tiver
Sub exigeAdmin()
    If Not sessIsAdmin Then
        Response.Redirect APP_PATH & "/index.asp?erro=acesso_negado"
        Response.End
    End If
End Sub
%>
