<!--#include file="config/app.asp" -->
<!--#include file="Lib/Conexao.asp" -->
<!--#include file="includes/seguranca.asp" -->
<%
' === DADOS ESTÁTICOS (APENAS PARA DESIGN) ===
Dim totalPendencias
totalPendencias = 5
%>
<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="utf-8">
    <title>SisProc - Dashboard</title>
    <link rel="stylesheet" href="<%=APP_PATH%>/assets/css/dashboard.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
</head>

<body>

<!-- TOPO -->
<header class="topbar">
    <!-- Área reservada para alinhar com a sidebar -->
    <div class="top-brand">
        <strong>SisProc</strong>
    </div>

    <!-- Botão menu -->
    <div class="top-toggle">
        <button class="btn-menu" onclick="toggleMenu()">☰</button>
    </div>

    <!-- Usuário -->
    <div class="top-right">
        <span class="user">
            <i class="fa-solid fa-user"></i>
            <%=Session("Nome")%>
        </span>
        <a href="<%=APP_PATH%>/auth/logout.asp" class="btn-logout">Sair</a>
    </div>
</header>

<div class="layout" id="layout">

    <!-- MENU LATERAL -->
    <aside class="sidebar">
        <nav>
            <a href="<%=APP_PATH%>/index.asp">
                <span class="icon"><i class="fa-solid fa-house"></i></span>
                <span class="text">Dashboard</span>
            </a>

            <a href="<%=APP_PATH%>/processos/lista.asp">
                <span class="icon"><i class="fa-solid fa-folder-open"></i></span>
                <span class="text">Processos</span>
            </a>

            <% If Session("IdPerfil") = 1 Then %>
                <a href="<%=APP_PATH%>/usuarios/lista.asp">
                    <span class="icon"><i class="fa-solid fa-users"></i></span>
                    <span class="text">Usuários</span>
                </a>
            <% End If %>
        </nav>
    </aside>

    <!-- CONTEÚDO -->
    <main class="content">
        <h1>Dashboard</h1>

        <div class="cards">

            <div class="card card-primary">
                <h3>
                    <i class="fa-solid fa-folder-open"></i>
                    Processos

                    <% If totalPendencias > 0 Then %>
                        <span class="badge"><%=totalPendencias%></span>
                    <% End If %>
                </h3>

                <p>Consultar, acompanhar e tramitar processos</p>

                <a href="<%=APP_PATH%>/processos/lista.asp">Acessar</a>
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