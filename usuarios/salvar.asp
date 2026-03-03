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
Call exigeAdmin

Dim acao : acao = Request.Form("acao")

Dim matricula, nome, login, senha, senha2, idSetor, idPerfil
matricula = dbStr(Request.Form("matricula"))
nome      = dbStr(Request.Form("nome"))
login     = dbStr(Request.Form("login"))
senha     = Trim(Request.Form("senha") & "")
senha2    = Trim(Request.Form("senha2") & "")
idSetor   = dbInt(Request.Form("id_setor"))
idPerfil  = dbInt(Request.Form("id_perfil"))

If matricula = "" Or nome = "" Or login = "" Or idSetor = 0 Or idPerfil = 0 Then
    Dim errBack
    If acao = "editar" Then
        errBack = "editar.asp?id=" & dbInt(Request.Form("id_usuario"))
    Else
        errBack = "novo.asp"
    End If
    Response.Redirect errBack & "&erro=" & Server.URLEncode("Preencha todos os campos obrigatorios.")
    Response.End
End If

' ════════════════════════════════════════════════════════
' NOVO USUARIO
' ════════════════════════════════════════════════════════
If acao = "novo" Then

    If senha = "" Then
        Response.Redirect "novo.asp?erro=" & Server.URLEncode("A senha e obrigatoria para novo usuario.")
        Response.End
    End If
    If Len(senha) < 6 Then
        Response.Redirect "novo.asp?erro=" & Server.URLEncode("A senha deve ter pelo menos 6 caracteres.")
        Response.End
    End If
    If senha <> senha2 Then
        Response.Redirect "novo.asp?erro=" & Server.URLEncode("As senhas nao conferem.")
        Response.End
    End If

    ' Verifica login duplicado
    Dim rsDupLogin
    Set rsDupLogin = dbQuery("SELECT COUNT(*) AS Total FROM Usuarios WHERE Login = '" & login & "'")
    If rsDupLogin("Total") > 0 Then
        rsDupLogin.Close : Set rsDupLogin = Nothing
        Response.Redirect "novo.asp?erro=" & Server.URLEncode("Este login ja esta em uso. Escolha outro.")
        Response.End
    End If
    rsDupLogin.Close : Set rsDupLogin = Nothing

    ' Verifica matricula duplicada
    Dim rsDupMat
    Set rsDupMat = dbQuery("SELECT COUNT(*) AS Total FROM Usuarios WHERE Matricula = '" & matricula & "'")
    If rsDupMat("Total") > 0 Then
        rsDupMat.Close : Set rsDupMat = Nothing
        Response.Redirect "novo.asp?erro=" & Server.URLEncode("Esta matricula ja esta cadastrada.")
        Response.End
    End If
    rsDupMat.Close : Set rsDupMat = Nothing

    ' INSERT: IdUsuario (varchar) = matricula
    '         IdUsuario_Int e IDENTITY — banco gera automaticamente, nao incluir no INSERT
    dbExecute _
        "INSERT INTO Usuarios (IdUsuario, Matricula, Nome, Login, Senha, IdPerfil, IdSetor, Ativo) " & _
        "VALUES (" & _
        "'" & matricula & "', " & _
        "'" & matricula & "', " & _
        "'" & nome      & "', " & _
        "'" & login     & "', " & _
        "CONVERT(VARCHAR(255), HASHBYTES('SHA2_256', '" & dbStr(senha) & "'), 2), " & _
        idPerfil & ", " & _
        idSetor  & ", " & _
        "1)"

    Call fechaConexao
    Response.Redirect "lista.asp?ok=criado"

' ════════════════════════════════════════════════════════
' EDITAR USUARIO
' ════════════════════════════════════════════════════════
ElseIf acao = "editar" Then

    Dim idUsuario : idUsuario = dbInt(Request.Form("id_usuario"))
    If idUsuario = 0 Then
        Response.Redirect "lista.asp"
        Response.End
    End If

    ' Verifica login duplicado (exceto o proprio)
    Dim rsDupLoginE
    Set rsDupLoginE = dbQuery( _
        "SELECT COUNT(*) AS Total FROM Usuarios WHERE Login = '" & login & "' AND IdUsuario_Int <> " & idUsuario)
    If rsDupLoginE("Total") > 0 Then
        rsDupLoginE.Close : Set rsDupLoginE = Nothing
        Response.Redirect "editar.asp?id=" & idUsuario & "&erro=" & Server.URLEncode("Este login ja esta em uso.")
        Response.End
    End If
    rsDupLoginE.Close : Set rsDupLoginE = Nothing

    ' Verifica matricula duplicada (exceto o proprio)
    Dim rsDupMatE
    Set rsDupMatE = dbQuery( _
        "SELECT COUNT(*) AS Total FROM Usuarios WHERE Matricula = '" & matricula & "' AND IdUsuario_Int <> " & idUsuario)
    If rsDupMatE("Total") > 0 Then
        rsDupMatE.Close : Set rsDupMatE = Nothing
        Response.Redirect "editar.asp?id=" & idUsuario & "&erro=" & Server.URLEncode("Esta matricula ja esta em uso.")
        Response.End
    End If
    rsDupMatE.Close : Set rsDupMatE = Nothing

    Dim ativoVal : ativoVal = dbInt(Request.Form("ativo"))

    If senha <> "" Then
        If Len(senha) < 6 Then
            Response.Redirect "editar.asp?id=" & idUsuario & "&erro=" & Server.URLEncode("A senha deve ter pelo menos 6 caracteres.")
            Response.End
        End If
        If senha <> senha2 Then
            Response.Redirect "editar.asp?id=" & idUsuario & "&erro=" & Server.URLEncode("As senhas nao conferem.")
            Response.End
        End If
        dbExecute _
            "UPDATE Usuarios SET " & _
            "  IdUsuario = '" & matricula & "', " & _
            "  Matricula = '" & matricula & "', " & _
            "  Nome      = '" & nome      & "', " & _
            "  Login     = '" & login     & "', " & _
            "  Senha     = CONVERT(VARCHAR(255), HASHBYTES('SHA2_256', '" & dbStr(senha) & "'), 2), " & _
            "  IdPerfil  = "  & idPerfil  & ", " & _
            "  IdSetor   = "  & idSetor   & ", " & _
            "  Ativo     = "  & ativoVal  & " " & _
            "WHERE IdUsuario_Int = " & idUsuario
    Else
        dbExecute _
            "UPDATE Usuarios SET " & _
            "  IdUsuario = '" & matricula & "', " & _
            "  Matricula = '" & matricula & "', " & _
            "  Nome      = '" & nome      & "', " & _
            "  Login     = '" & login     & "', " & _
            "  IdPerfil  = "  & idPerfil  & ", " & _
            "  IdSetor   = "  & idSetor   & ", " & _
            "  Ativo     = "  & ativoVal  & " " & _
            "WHERE IdUsuario_Int = " & idUsuario
    End If

    Call fechaConexao
    Response.Redirect "lista.asp?ok=editado"

Else
    Response.Redirect "lista.asp"
End If
%>
