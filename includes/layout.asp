<%
' ============================================================
'  SisProc - Layout Reutilizável (Header + Sidebar)
'  includes/layout.asp
'
'  Como usar: defina "paginaAtiva" antes de incluir este arquivo
'  Exemplo:
'    Dim paginaAtiva : paginaAtiva = "processos"
'    <!--#include file="../includes/layout.asp"-->
'
'  Valores aceitos em paginaAtiva:
'    "dashboard" | "processos" | "usuarios" | "relatorios"
' ============================================================
%>
<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>SisProc <%If pageTitulo <> "" Then Response.Write "- " & pageTitulo%></title>
    <link rel="stylesheet" href="<%=APP_PATH%>/assets/css/main.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
</head>
<body>

<header class="topbar">
    <div class="top-brand">
        <i class="fa-solid fa-diagram-project"></i>
        <strong>SisProc</strong>
    </div>
    <button class="btn-menu" onclick="toggleSidebar()" title="Menu">
        <i class="fa-solid fa-bars"></i>
    </button>
    <div class="top-right">
        <span class="top-setor">
            <i class="fa-solid fa-building"></i>
            <%=sessSetor%>
        </span>
        <span class="top-user">
            <i class="fa-solid fa-user-circle"></i>
            <%=sessNome%>
        </span>
        <a href="<%=APP_PATH%>/auth/logout.asp" class="btn-logout" title="Sair">
            <i class="fa-solid fa-right-from-bracket"></i>
        </a>
    </div>
</header>

<div class="app-wrapper" id="appWrapper">

    <aside class="sidebar" id="sidebar">
        <nav class="sidebar-nav">

            <a href="<%=APP_PATH%>/index.asp"
               class="nav-item <%If paginaAtiva="dashboard" Then Response.Write "active"%>">
                <span class="nav-icon"><i class="fa-solid fa-house"></i></span>
                <span class="nav-text">Dashboard</span>
            </a>

            <a href="<%=APP_PATH%>/processos/lista.asp"
               class="nav-item <%If paginaAtiva="processos" Then Response.Write "active"%>">
                <span class="nav-icon"><i class="fa-solid fa-folder-open"></i></span>
                <span class="nav-text">Processos</span>
            </a>

            <a href="<%=APP_PATH%>/processos/novo.asp"
               class="nav-item <%If paginaAtiva="novo_processo" Then Response.Write "active"%>">
                <span class="nav-icon"><i class="fa-solid fa-plus-circle"></i></span>
                <span class="nav-text">Novo Processo</span>
            </a>

            <a href="<%=APP_PATH%>/relatorios/gargalos.asp"
               class="nav-item <%If paginaAtiva="relatorios" Then Response.Write "active"%>">
                <span class="nav-icon"><i class="fa-solid fa-chart-bar"></i></span>
                <span class="nav-text">Relatórios</span>
            </a>

            <% If sessIsAdmin Then %>
            <a href="<%=APP_PATH%>/usuarios/lista.asp"
               class="nav-item <%If paginaAtiva="usuarios" Then Response.Write "active"%>">
                <span class="nav-icon"><i class="fa-solid fa-users"></i></span>
                <span class="nav-text">Usuários</span>
            </a>
            <% End If %>

        </nav>

        <div class="sidebar-footer">
            <span>v<%=APP_VERSAO%></span>
        </div>
    </aside>

    <main class="main-content">
