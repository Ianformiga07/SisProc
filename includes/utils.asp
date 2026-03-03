<!-- FUNÇÃO UTILITÁRIA PARA BADGE DE STATUS -->
<%
Function badgeStatus(status)

    If IsNull(status) Or status = "" Then
        badgeStatus = "badge-neutral"
        Exit Function
    End If

    Select Case UCase(status)
        Case "EM ANDAMENTO"
            badgeStatus = "badge-warning"

        Case "FINALIZADO"
            badgeStatus = "badge-success"

        Case "ATRASADO"
            badgeStatus = "badge-danger"

        Case Else
            badgeStatus = "badge-neutral"
    End Select

End Function
%>

<!-- FUNÇÃO UTILITÁRIA PARA FORMATAÇÃO DE DATAS -->
<%
Function fmtData(dt)
    If IsNull(dt) Or dt = "" Then
        fmtData = "-"
    Else
        fmtData = Day(dt) & "/" & Right("0" & Month(dt), 2) & "/" & Year(dt)
    End If
End Function
%>
<!--  FUNÇÃO UTILITÁRIA PARA ESCAPAR STRINGS ANTES DE INSERIR NO BANCO -->
<%
Function dbStr(valor)
    If IsNull(valor) Then
        dbStr = ""
        Exit Function
    End If

    valor = Trim(valor & "")

    ' Escapa aspas simples para SQL
    dbStr = Replace(valor, "'", "''")
End Function
%>

<!--  FUNÇÃO UTILITÁRIA PARA CONVERTER VALORES EM INTEIROS -->
<%
Function dbInt(valor)
    If IsNumeric(valor) Then
        dbInt = CLng(valor)
    Else
        dbInt = 0
    End If
End Function

%>

<!--  FUNÇÃO UTILITÁRIA PARA GERAR BADGE DE SLA -->
<%
Function badgeSLA(dias)

    If IsNull(dias) Then
        badgeSLA = "badge badge-neutral"
        Exit Function
    End If

    If dias <= SLA_ALERTA_DIAS Then
        badgeSLA = "badge badge-success"
    ElseIf dias <= (SLA_ALERTA_DIAS + 3) Then
        badgeSLA = "badge badge-warning"
    Else
        badgeSLA = "badge badge-danger"
    End If

End Function
%>