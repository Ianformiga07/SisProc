<!--#include file="config/app.asp" -->
<!--#include file="Lib/Conexao.asp" -->
<!--#include file="includes/seguranca.asp" -->

<%
call abreConexao

' ===============================
' KPIs
' ===============================
Dim rs, totalProcessos, processosAtivos, processosFinalizados

Set rs = conn.Execute("SELECT COUNT(*) AS Total FROM Processos")
totalProcessos = rs("Total") : rs.Close

Set rs = conn.Execute("SELECT COUNT(*) AS Total FROM Processos WHERE Ativo = 1")
processosAtivos = rs("Total") : rs.Close

Set rs = conn.Execute("SELECT COUNT(*) AS Total FROM Processos WHERE Ativo = 0")
processosFinalizados = rs("Total") : rs.Close

' ===============================
' PROCESSOS POR MÊS (6 últimos)
' ===============================
Dim rsMes, labelsMes, valoresMes
labelsMes = ""
valoresMes = ""

Set rsMes = conn.Execute("SELECT FORMAT(DataCriacao,'MM/yyyy') AS Mes, COUNT(*) AS Total FROM Processos WHERE DataCriacao >= DATEADD(MONTH,-5,GETDATE()) GROUP BY FORMAT(DataCriacao,'MM/yyyy') ORDER BY MIN(DataCriacao)")

Do While Not rsMes.EOF
    labelsMes  = labelsMes  & "'" & rsMes("Mes") & "',"
    valoresMes = valoresMes & rsMes("Total") & ","
    rsMes.MoveNext
Loop

rsMes.Close
Set rsMes = Nothing
%>

<!DOCTYPE html>
<html lang="pt-br">
<head>
<meta charset="utf-8">
<title>SisProc - Dashboard</title>

<link rel="stylesheet" href="<%=APP_PATH%>/assets/css/dashboard.css">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>

<body>

<!-- ================= TOPO ================= -->
<header class="topbar">
    <div class="top-brand">
        <strong>SisProc</strong>
    </div>

    <div class="top-toggle">
        <button class="btn-menu" onclick="toggleMenu()">☰</button>
    </div>

    <div class="top-right">
        <span class="user"><i class="fa-solid fa-user"></i> <%=Session("Nome")%></span>
        <a href="<%=APP_PATH%>/auth/logout.asp" class="btn-logout">Sair</a>
    </div>
</header>

<div class="layout" id="layout">

    <!-- ================= SIDEBAR ================= -->
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

<!-- KPIs -->
<div class="cards">
    <div class="card card-primary">
        <h3>Total de Processos</h3>
        <strong><%=totalProcessos%></strong>
    </div>

    <div class="card card-success">
        <h3>Em andamento</h3>
        <strong><%=processosAtivos%></strong>
    </div>

    <div class="card card-neutral">
        <h3>Finalizados</h3>
        <strong><%=processosFinalizados%></strong>
    </div>
</div>

<!-- GRÁFICOS -->
<div class="dashboard-grid">

    <!-- PIZZA -->
    <div class="card-box">
        <h3>Status dos Processos</h3>
        <canvas id="graficoStatus"></canvas>
    </div>

    <!-- BARRAS -->
    <div class="card-box">
        <h3>Processos criados por mês</h3>
        <canvas id="graficoMes"></canvas>
    </div>

</div>

</main>
</div>

<footer class="footer">
SisProc © <%=Year(Now())%>
</footer>

<script>
function toggleMenu(){
    document.getElementById("layout").classList.toggle("collapsed");
}

// Gráfico Pizza (AJUSTADO)
new Chart(document.getElementById('graficoStatus'), {
    type: 'doughnut',
    data: {
        labels: ['Em andamento', 'Finalizados'],
        datasets: [{
            data: [<%=processosAtivos%>, <%=processosFinalizados%>],
            backgroundColor: ['#3498db', '#2ecc71'],
            borderWidth: 0
        }]
    },
    options: {
        responsive: true,
        maintainAspectRatio: false,
        cutout: '70%',   // <<< AQUI resolve o "miolo gigante"
        plugins: {
            legend: {
                position: 'bottom',
                labels: {
                    boxWidth: 12,
                    padding: 15,
                    font: {
                        size: 12
                    }
                }
            }
        }
    }
});


// Gráfico Barras (AJUSTADO)
new Chart(document.getElementById('graficoMes'), {
    type: 'bar',
    data: {
        labels: [<%=labelsMes%>],
        datasets: [{
            label: 'Processos',
            data: [<%=valoresMes%>],
            backgroundColor: '#9b59b6',
            borderRadius: 6,
            maxBarThickness: 40,   // 🔥 limite máximo da largura
            categoryPercentage: 0.6,
            barPercentage: 0.8
        }]
    },
    options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                display: false  }
        },
        scales: {
            x: {
                ticks: {
                    font: { size: 11 }
                }
            },
            y: {
                beginAtZero: true,
                ticks: {
                    font: { size: 11 }
                }
            }
        }
    }
});
</script>

<%
call fechaConexao
%>

</body>
</html>