<!--#include file="../config/app.asp" -->
<!--#include file="../Lib/Conexao.asp" -->
<!--#include file="../includes/seguranca.asp" -->
<%
call abreConexao
Dim sql, rs

sql = "SELECT * FROM vw_ProcessosLista ORDER BY DataCriacao DESC"
Set rs = conn.Execute(sql)
%>
<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="utf-8">
    <title>SisProc - Processos</title>
    <link rel="stylesheet" href="<%=APP_PATH%>/assets/css/dashboard.css">
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
        <div class="table-container">
            <table class="table">
                <thead>
                    <tr>
                        <th>Nº Processo</th>
                        <th>Interessado</th>
                        <th>Tipo</th>
                        <th>Data</th>
                        <th>Status</th>
                        <th>Ações</th>
                    </tr>
                </thead>
                <tbody>

                <% If rs.EOF Then %>

                    <tr>
                        <td colspan="6" style="text-align:center; padding:20px;">
                            Nenhum processo cadastrado.
                        </td>
                    </tr>

                <% Else %>

                    <% Do While Not rs.EOF %>

                        <tr>
                            <td><%=rs("NumeroProcesso")%></td>

                            <td><%=rs("Assunto")%></td>

                            <td><%=rs("TipoProcesso")%></td>

                            <td>
                                <%=Day(rs("DataCriacao")) & "/" & Month(rs("DataCriacao")) & "/" & Year(rs("DataCriacao"))%>
                            </td>

                            <td>
                                <span class="status <%=LCase(Replace(rs("StatusAtual"), " ", "-"))%>">
                                    <%=rs("StatusAtual")%>
                                    (<%=rs("DiasNoSetor")%> dias)
                                </span>
                            </td>

                            <td>
                                <a href="detalhes.asp?id=<%=rs("IdProcesso")%>"
                                class="btn-action"
                                title="Visualizar">
                                    <i class="fa-solid fa-eye"></i>
                                </a>
                            </td>
                        </tr>

                        <% rs.MoveNext %>
                    <% Loop %>

                <% End If 
                call fechaConexao
                %>

                </tbody>
            </table>
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