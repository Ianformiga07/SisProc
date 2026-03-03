<%
Dim conn, strcon

Sub abreConexao
    strcon = "Provider=SQLNCLI11;Server=localhost;Database=SistemaProcessos;Uid=sa;Pwd=123;"
    Set conn = Server.CreateObject("ADODB.Connection")
    conn.Open strcon
End Sub

Sub fechaConexao
    If Not conn Is Nothing Then
        If conn.State = 1 Then conn.Close
        Set conn = Nothing
    End If
End Sub

' ==============================
' EXECUTA SELECT (RETORNA RS)
' ==============================
Function dbQuery(sql)
    Dim rs
    Set rs = Server.CreateObject("ADODB.Recordset")
    rs.Open sql, conn, 1, 1 ' adOpenKeyset, adLockReadOnly
    Set dbQuery = rs
End Function

' ==============================
' EXECUTA INSERT / UPDATE / DELETE
' ==============================
Sub dbExecute(sql)
    conn.Execute sql
End Sub
%>