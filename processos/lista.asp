<%
Response.CodePage = 65001
Response.Charset = "UTF-8"
Session.CodePage = 65001
%>
<!--#include file="../config/app.asp" -->
<!--#include file="../Lib/Conexao.asp" -->
<!--#include file="../includes/seguranca.asp" -->
<%
call abreConexao

' ===============================
' FILTROS
' ===============================
Dim fNumero, fTipo, fStatus
fNumero = Trim(Request.QueryString("numero"))
fTipo   = Trim(Request.QueryString("tipo"))
fStatus = Trim(Request.QueryString("status"))

' ===============================
' PAGINAÇÃO
' ===============================
Dim pagina, limite, offset
limite = 10
pagina = Request.QueryString("p")
If pagina = "" Then pagina = 1
pagina = CLng(pagina)
If pagina < 1 Then pagina = 1

offset = (pagina - 1) * limite

' ===============================
' SQL BASE
' ===============================
Dim sqlBase, sqlWhere
sqlBase = "FROM vw_ProcessosLista WHERE 1=1 "
sqlWhere = ""

If fNumero <> "" Then
    sqlWhere = sqlWhere & " AND NumeroProcesso LIKE '%" & Replace(fNumero,"'","''") & "%'"
End If

If fTipo <> "" Then
    sqlWhere = sqlWhere & " AND TipoProcesso = '" & Replace(fTipo,"'","''") & "'"
End If

If fStatus <> "" Then
    sqlWhere = sqlWhere & " AND StatusAtual = '" & Replace(fStatus,"'","''") & "'"
End If

' ===============================
' TOTAL REGISTROS
' ===============================
Dim rsTotal, totalRegistros, totalPaginas
Set rsTotal = conn.Execute("SELECT COUNT(*) AS Total " & sqlBase & sqlWhere)
totalRegistros = rsTotal("Total")
rsTotal.Close

If totalRegistros = 0 Then
    totalPaginas = 1
ElseIf (totalRegistros Mod limite) = 0 Then
    totalPaginas = totalRegistros \ limite
Else
    totalPaginas = (totalRegistros \ limite) + 1
End If

' ===============================
' LISTA PAGINADA
' ===============================
Dim sql, rs
sql = "SELECT * " & sqlBase & sqlWhere & _
      " ORDER BY DataCriacao DESC " & _
      " OFFSET " & offset & " ROWS FETCH NEXT " & limite & " ROWS ONLY"

Set rs = conn.Execute(sql)
%>
<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="utf-8">
    <title>SisProc - Processos</title>
    <link rel="stylesheet" href="../assets/css/dashboard.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
</head>

<body>

<!-- TOPO -->
<header class="topbar">
    <div class="top-brand">
        <strong>SisProc</strong>
    </div>

    <div class="top-toggle">
        <button class="btn-menu" onclick="toggleMenu()">☰</button>
    </div>

    <div class="top-right">
        <span class="user">
            <i class="fa-solid fa-user"></i>
            <%=Session("Nome")%>
        </span>
        <a href="<%=APP_PATH%>/auth/logout.asp" class="btn-logout">Sair</a>
    </div>
</header>

<div class="layout" id="layout">

    <!-- SIDEBAR -->
    <aside class="sidebar">
        <nav>
            <a href="<%=APP_PATH%>/index.asp">
                <span class="icon"><i class="fa-solid fa-house"></i></span>
                <span class="text">Dashboard</span>
            </a>

            <a href="<%=APP_PATH%>/processos/lista.asp" class="active">
                <span class="icon"><i class="fa-solid fa-folder-open"></i></span>
                <span class="text">Processos</span>
            </a>
        </nav>
    </aside>

    <!-- CONTEÚDO -->
    <main class="content">
        <div class="page-header">
            <h1>
                <i class="fa-solid fa-folder-open"></i>
                Processos
            </h1>

            <!-- espaço reservado para ações futuras -->
            <!--
            <div class="page-actions">
                <a href="#" class="btn-primary">
                    <i class="fa-solid fa-plus"></i> Novo Processo
                </a>
            </div>
            -->
        </div>

<div class="filters">
    <form method="get" class="filter-form">
        <input type="text" name="numero" placeholder="Nº Processo"
               value="<%=fNumero%>">

        <select name="tipo">
            <option value="">Tipo</option>
            <option value="Compra" <% If fTipo="Compra" Then Response.Write("selected") %>>Compra</option>
            <option value="Serviço" <% If fTipo="Serviço" Then Response.Write("selected") %>>Serviço</option>
        </select>

        <select name="status">
            <option value="">Status</option>
            <option value="Em andamento" <% If fStatus="Em andamento" Then Response.Write("selected") %>>Em andamento</option>
            <option value="Finalizado" <% If fStatus="Finalizado" Then Response.Write("selected") %>>Finalizado</option>
        </select>

        <button class="btn-primary">
            <i class="fa-solid fa-filter"></i> Filtrar
        </button>

        <a href="lista.asp" class="btn-secondary">
            Limpar
        </a>
    </form>
</div>

<div class="table-responsive">
<table class="table-modern">
    <thead>
        <tr>
            <th>Nº Processo</th>
            <th>Assunto</th>
            <th>Tipo</th>
            <th>Setor Atual</th>
            <th>Data</th>
            <th>Status</th>
            <th class="center">Ações</th>
        </tr>
    </thead>
    <tbody>

    <% If rs.EOF Then %>
        <tr>
            <td colspan="6" class="empty">
                Nenhum processo encontrado.
            </td>
        </tr>
    <% Else %>
        <% Do While Not rs.EOF %>
        <tr>
            <td><strong><%=rs("NumeroProcesso")%></strong></td>
            <td><%=rs("Assunto")%></td>
            <td><span class="tag"><%=rs("TipoProcesso")%></span></td>
            <td><span class="tag"><%=rs("SetorAtual")%></span></td>
            <td><%=FormatDateTime(rs("DataCriacao"), 2)%></td>
            <td>
                <span class="status-badge <%=LCase(Replace(rs("StatusAtual")," ","-"))%>">
                    <%=rs("StatusAtual")%>
                    <small>(<%=rs("DiasNoSetor")%> dias)</small>
                </span>
            </td>
            <td class="center">
                <a href="detalhes.asp?id=<%=rs("IdProcesso")%>" class="btn-view"> <i class="fa fa-eye"></i> Visualizar </a>
            </td>
        </tr>
        <% rs.MoveNext : Loop %>
    <% End If %>

    </tbody>
</table>
<%
Dim queryFiltros
queryFiltros = ""

If fNumero <> "" Then queryFiltros = queryFiltros & "&numero=" & Server.URLEncode(fNumero)
If fTipo <> "" Then queryFiltros = queryFiltros & "&tipo=" & Server.URLEncode(fTipo)
If fStatus <> "" Then queryFiltros = queryFiltros & "&status=" & Server.URLEncode(fStatus)
%>
<div class="pagination">

    <% ' Botão anterior
    If pagina > 1 Then
    %>
    <a href="?p=<%=pagina-1%><%=queryFiltros%>" title="Página anterior">
        <i class="fa fa-chevron-left"></i>
    </a>
    <%
    End If
    %>

    <%
    Dim i, classe
    For i = 1 To totalPaginas

        If i = pagina Then
            classe = "active"
        Else
            classe = ""
        End If
    %>
        <a href="?p=<%=i%><%=queryFiltros%>" class="<%=classe%>"><%=i%></a>
    <%
    Next
    %>

    <% ' Botão próximo
    If pagina < totalPaginas Then
    %>
    <a href="?p=<%=pagina+1%><%=queryFiltros%>" title="Próxima página">
        <i class="fa fa-chevron-right"></i>
    </a>
    <%
    End If
    %>

</div>
</div>
    </main>

</div>

<script>
function toggleMenu() {
    document.getElementById("layout").classList.toggle("collapsed");
}
</script>

<footer class="footer">
    SisProc © <%=Year(Now())%> - Sistema de Acompanhamento de Processos
</footer>

</body>
</html>