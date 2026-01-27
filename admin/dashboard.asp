<!--#include file="../config/app.asp" -->
<!--#include file="../Lib/Conexao.asp" -->
<!--#include file="../includes/seguranca.asp" -->
<%
call abreConexao

' ===============================
' CARDS DE RESUMO
' ===============================
Set rsTotal = conn.Execute("SELECT COUNT(*) AS Total FROM Processos")
Set rsAnd = conn.Execute("SELECT COUNT(*) AS Total FROM Processos WHERE Ativo = 1")
Set rsFin = conn.Execute("SELECT COUNT(*) AS Total FROM Processos WHERE Ativo = 0")
Set rsAtr = conn.Execute("SELECT COUNT(DISTINCT IdProcesso) AS Total FROM Tramitacoes WHERE DataSaida IS NULL AND DATEDIFF(DAY, DataEntrada, GETDATE()) > 7")

Total = rsTotal("Total")
Andamento = rsAnd("Total")
Finalizados = rsFin("Total")
Atrasados = rsAtr("Total")

rsTotal.Close: rsAnd.Close: rsFin.Close: rsAtr.Close

' ===============================
' PROCESSOS POR SETOR (GRÁFICO)
' ===============================
sqlSetor = "SELECT S.NomeSetor, COUNT(*) AS Total FROM Tramitacoes T JOIN Setores S ON S.IdSetor = T.IdSetor WHERE T.DataSaida IS NULL GROUP BY S.NomeSetor"
Set rsSetor = conn.Execute(sqlSetor)

labels = ""
data = ""
Do While Not rsSetor.EOF
    labels = labels & "'" & rsSetor("NomeSetor") & "',"
    data = data & rsSetor("Total") & ","
    rsSetor.MoveNext
Loop
rsSetor.Close
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Dashboard Administrativo</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<style>
body { font-family: Arial; background:#f2f4f7; }
.cards { display:grid; grid-template-columns:repeat(4,1fr); gap:15px; margin:20px; }
.card { background:#fff; padding:20px; border-radius:8px; text-align:center; box-shadow:0 2px 6px rgba(0,0,0,.1); }
.alert { background:#ffe5e5; }
.container { margin:20px; background:#fff; padding:20px; border-radius:8px; }
</style>
</head>
<body>

<h2 style="margin-left:20px">📊 Dashboard Administrativo</h2>

<div class="cards">
  <div class="card">📂 Total<br><strong><%=Total%></strong></div>
  <div class="card">⏳ Em andamento<br><strong><%=Andamento%></strong></div>
  <div class="card">✅ Finalizados<br><strong><%=Finalizados%></strong></div>
  <div class="card alert">⚠️ Atrasados<br><strong><%=Atrasados%></strong></div>
</div>

<div class="container">
  <h3>Processos em andamento por setor</h3>
  <canvas id="graficoSetor"></canvas>
</div>

<script>
const ctx = document.getElementById('graficoSetor');
new Chart(ctx, {
    type: 'bar',
    data: {
        labels: [<%=labels%>],
        datasets: [{
            label: 'Processos',
            data: [<%=data%>],
        }]
    }
});
</script>

</body>
</html>
<%
call fechaConexao
%>