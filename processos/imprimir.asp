<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="utf-8">
    <title>Processo 2025/000123</title>

    <style>
        @page {
            size: A4;
            margin: 2cm;
        }

        body {
            font-family: "Segoe UI", Arial, sans-serif;
            font-size: 12px;
            color: #111;
        }

        .header {
            text-align: center;
            border-bottom: 2px solid #000;
            padding-bottom: 10px;
            margin-bottom: 20px;
        }

        .header h2 {
            margin: 0;
            font-size: 16px;
            text-transform: uppercase;
        }

        .header small {
            font-size: 11px;
            color: #555;
        }

        h1 {
            text-align: center;
            font-size: 18px;
            margin: 25px 0;
        }

        .section {
            margin-bottom: 20px;
        }

        .section-title {
            font-weight: bold;
            text-transform: uppercase;
            font-size: 12px;
            border-bottom: 1px solid #000;
            margin-bottom: 8px;
            padding-bottom: 4px;
        }

        .grid {
            width: 100%;
            border-collapse: collapse;
        }

        .grid td {
            padding: 6px 8px;
            vertical-align: top;
        }

        .grid td strong {
            display: block;
            font-size: 11px;
            color: #444;
        }

        .text-box {
            line-height: 1.5;
            text-align: justify;
        }

        .timeline {
            width: 100%;
            border-collapse: collapse;
            font-size: 11px;
        }

        .timeline th,
        .timeline td {
            border: 1px solid #000;
            padding: 6px;
            text-align: left;
        }

        .timeline th {
            background: #f0f0f0;
            font-weight: bold;
        }

        .footer {
            position: fixed;
            bottom: 1.5cm;
            left: 2cm;
            right: 2cm;
            text-align: center;
            font-size: 10px;
            color: #555;
            border-top: 1px solid #000;
            padding-top: 6px;
        }
    </style>
</head>

<body onload="window.print()">

    <!-- CABEÇALHO -->
    <div class="header">
        <h2>ADAPEC</h2>
        <small>Sistema de Acompanhamento de Processos – SisProc</small>
    </div>

    <!-- TÍTULO -->
    <h1>Processo Administrativo nº 2025/000123</h1>

    <!-- DADOS GERAIS -->
    <div class="section">
        <div class="section-title">Dados Gerais</div>

        <table class="grid">
            <tr>
                <td>
                    <strong>Status</strong>
                    Em andamento
                </td>
                <td>
                    <strong>Data de Abertura</strong>
                    10/01/2026
                </td>
                <td>
                    <strong>Setor Atual</strong>
                    Setor Jurídico
                </td>
            </tr>
            <tr>
                <td colspan="3">
                    <strong>Interessado</strong>
                    João da Silva
                </td>
            </tr>
        </table>
    </div>

    <!-- DESCRIÇÃO -->
    <div class="section">
        <div class="section-title">Assunto / Descrição</div>

        <div class="text-box">
            Solicitação de análise documental referente ao processo administrativo interno,
            conforme normas vigentes da instituição.
        </div>
    </div>

    <!-- HISTÓRICO -->
    <div class="section">
        <div class="section-title">Histórico de Tramitação</div>

        <table class="timeline">
            <thead>
                <tr>
                    <th>Período</th>
                    <th>Setor</th>
                    <th>Tempo no Setor</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>10/01/2026 → 12/01/2026</td>
                    <td>Protocolo</td>
                    <td>2 dias</td>
                </tr>
                <tr>
                    <td>12/01/2026 → 18/01/2026</td>
                    <td>Jurídico</td>
                    <td>6 dias</td>
                </tr>
                <tr>
                    <td>Desde 18/01/2026</td>
                    <td>Técnico</td>
                    <td>4 dias</td>
                </tr>
            </tbody>
        </table>
    </div>

    <!-- RODAPÉ -->
    <div class="footer">
        Documento gerado em <%=Day(Now()) & "/" & Month(Now()) & "/" & Year(Now())%>
        – SisProc
    </div>

</body>
</html>