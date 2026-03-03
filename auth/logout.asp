<!--#include file="../config/app.asp"-->
<%
Session.Abandon
Response.Redirect APP_PATH & "/auth/login.asp"
%>
