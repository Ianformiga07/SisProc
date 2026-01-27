<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<!--#include file="../config/app.asp" -->
<!--#include file="../Lib/Conexao.asp" -->
<!--#include file="../includes/seguranca.asp" -->

<%
call abreConexao

Dim idProcesso, setorDestino, observacao, setorAtual

idProcesso = CLng(Request.Form("id_processo"))
setorDestino = CLng(Request.Form("setor_destino"))
observacao = Request.Form("observacao")

' Busca o setor atual do processo
Dim rsAtual, sqlAtual
sqlAtual = "SELECT TOP 1 IdSetor FROM Tramitacoes WHERE IdProcesso = " & idProcesso & " ORDER BY DataEntrada DESC"
Set rsAtual = conn.Execute(sqlAtual)
If Not rsAtual.EOF Then
    setorAtual = rsAtual("IdSetor")
Else
    Response.Write "Erro: processo sem setor atual."
    Response.End
End If
rsAtual.Close
Set rsAtual = Nothing

' ===========================
' INSERE A TRAMITACAO DE DEVOLUCAO
' ===========================
Dim sqlInsert
sqlInsert = "INSERT INTO Tramitacoes (IdProcesso, IdSetor, DataEntrada, DataSaida, Observacao, MatriculaUsuario) " & _
            "VALUES (" & idProcesso & ", " & setorDestino & ", GETDATE(), NULL, '" & Replace(observacao, "'", "''") & "', " & Session("Matricula") & ")"
conn.Execute(sqlInsert)

' Redireciona de volta para detalhes
Response.Redirect "detalhes.asp?id=" & idProcesso
%>