<!--#include file="../config/app.asp"-->
<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="utf-8">
    <title>Login | SisProc</title>
    <link rel="stylesheet" href="<%=APP_PATH%>/assets/css/main.css">
</head>
<body>

<div class="login-wrapper">
    <div class="login-box">

        <div class="login-brand">
            <div class="logo-icon">
                <i class="fa-solid fa-diagram-project"></i>
            </div>
            <h1>SisProc</h1>
            <p>Sistema de Acompanhamento de Processos</p>
        </div>

        <% If Request.QueryString("erro") = "1" Then %>
        <div class="alert alert-danger" style="margin-bottom:16px">
            <i class="fa-solid fa-circle-xmark"></i> Usuario ou senha invalidos.
        </div>
        <% End If %>

        <form method="post" action="valida_login.asp">
            <div class="form-group">
                <label>Usuario</label>
                <input type="text" name="login" required autofocus autocomplete="username">
            </div>
            <div class="form-group">
                <label>Senha</label>
                <input type="password" name="senha" required autocomplete="current-password">
            </div>
            <button type="submit" class="btn btn-primary" style="width:100%;justify-content:center;margin-top:8px">
                <i class="fa-solid fa-right-to-bracket"></i> Entrar
            </button>
        </form>

    </div>
</div>

<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
</body>
</html>
