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

' Executa SELECT e retorna Recordset
' adOpenStatic (3) + adLockReadOnly (1) funciona com SQLNCLI11
Function dbQuery(sql)
    Dim rs
    Set rs = Server.CreateObject("ADODB.Recordset")
    rs.Open sql, conn, 3, 1
    Set dbQuery = rs
End Function

' Executa INSERT / UPDATE / DELETE
Sub dbExecute(sql)
    conn.Execute sql
End Sub

' Utilitarios
Function dbStr(val)
    If IsNull(val) Then
        dbStr = ""
    Else
        dbStr = Replace(Trim(val & ""), "'", "''")
    End If
End Function

Function dbInt(val)
    If IsNumeric(val) Then
        dbInt = CLng(val)
    Else
        dbInt = 0
    End If
End Function

Function fmtData(d)
    If IsNull(d) Or d = "" Then
        fmtData = "-"
    Else
        fmtData = Right("0" & Day(d), 2) & "/" & Right("0" & Month(d), 2) & "/" & Year(d)
    End If
End Function

Function fmtDataHora(d)
    If IsNull(d) Or d = "" Then
        fmtDataHora = "-"
    Else
        fmtDataHora = Right("0" & Day(d), 2) & "/" & Right("0" & Month(d), 2) & "/" & Year(d) & _
                      " " & Right("0" & Hour(d), 2) & ":" & Right("0" & Minute(d), 2)
    End If
End Function

Function badgeStatus(status)
    Select Case LCase(Trim(status & ""))
        Case "em andamento" : badgeStatus = "badge-andamento"
        Case "finalizado"   : badgeStatus = "badge-finalizado"
        Case "cancelado"    : badgeStatus = "badge-cancelado"
        Case Else           : badgeStatus = "badge-default"
    End Select
End Function

Function badgeSLA(dias)
    If IsNull(dias) Then dias = 0
    If dias >= SLA_ALERTA_DIAS Then
        badgeSLA = "sla-critico"
    ElseIf dias >= 3 Then
        badgeSLA = "sla-atencao"
    Else
        badgeSLA = "sla-ok"
    End If
End Function
%>
