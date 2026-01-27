<!--#include file="../config/app.asp" -->
<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="utf-8">
    <title>Login | SisProc</title>

    <link rel="stylesheet" href="<%=APP_PATH%>/assets/css/login.css">
</head>
<body>

<div class="login-container">
    <div class="login-box">

        <div class="logo">
            <img src="<%=APP_PATH%>/assets/img/sisproc3.png" alt="SisProc">
        </div>

        <% If Request.QueryString("erro") = "1" Then %>
            <div class="erro">Usuário ou senha inválidos</div>
        <% End If %>

        <form method="post" action="valida_login.asp">
            <label>Usuário</label>
            <input type="text" name="login" required>

            <label>Senha</label>
            <input type="password" name="senha" required>

            <button type="submit">Entrar</button>
        </form>

    </div>
</div>

</body>
</html>