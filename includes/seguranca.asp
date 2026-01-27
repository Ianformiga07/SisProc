<%
If Session("Matricula") = "" Then
    Response.Redirect(APP_PATH & "/auth/login.asp")
End If
%>