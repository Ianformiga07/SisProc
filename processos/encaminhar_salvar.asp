<!--#include file="../includes/seguranca.asp" -->
<!--#include file="../config/conn.asp" -->

<%
Dim id, novoSetor, obs
id = Request.Form("id")
novoSetor = Request.Form("IdSetorDestino")
obs = Request.Form("Observacao")

conn.BeginTrans

conn.Execute "
    UPDATE Tramitacoes
    SET DataSaida = GETDATE()
    WHERE IdProcesso = " & id & " AND DataSaida IS NULL
"

conn.Execute "
    INSERT INTO Tramitacoes (IdProcesso, IdSetor, MatriculaUsuario, Observacao)
    VALUES (" & id & ", " & novoSetor & ", '" & Session("Matricula") & "', '" & obs & "')
"

conn.CommitTrans

Response.Redirect(APP_PATH & "/processos/lista.asp")
%>