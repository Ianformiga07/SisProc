<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<%
Response.CodePage = 65001
Response.Charset  = "UTF-8"
%>
<!--#include file="../config/app.asp"-->
<!--#include file="../Lib/Conexao.asp"-->
<!--#include file="../includes/seguranca.asp"-->
<!--#include file="../includes/utils.asp"-->
<%
Call abreConexao
Call exigeAdmin

Dim idUsuario : idUsuario = dbInt(Request.QueryString("id"))
If idUsuario = 0 Then
    Response.Redirect "lista.asp"
    Response.End
End If

Dim msgErro : msgErro = Request.QueryString("erro")

' Carrega dados do usuario
Dim rsUser
Set rsUser = dbQuery( _
    "SELECT IdUsuario_Int, Matricula, Nome, Login, IdPerfil, IdSetor, Ativo " & _
    "FROM Usuarios WHERE IdUsuario_Int = " & idUsuario)

If rsUser.EOF Then
    Response.Redirect "lista.asp"
    Response.End
End If

' Usa dados do form se houver postback de erro, senao usa banco
Dim vMatricula, vNome, vLogin, vIdPerfil, vIdSetor, vAtivo
If Request.Form("acao") = "editar" Then
    vMatricula = Request.Form("matricula")
    vNome      = Request.Form("nome")
    vLogin     = Request.Form("login")
    vIdPerfil  = dbInt(Request.Form("id_perfil"))
    vIdSetor   = dbInt(Request.Form("id_setor"))
    vAtivo     = Request.Form("ativo")
Else
    vMatricula = rsUser("Matricula")
    vNome      = rsUser("Nome")
    vLogin     = rsUser("Login")
    vIdPerfil  = rsUser("IdPerfil")
    vIdSetor   = rsUser("IdSetor")
    vAtivo     = rsUser("Ativo")
End If
rsUser.Close : Set rsUser = Nothing

Dim rsSetores, rsPerfis
Set rsSetores = dbQuery("SELECT IdSetor, NomeSetor FROM Setores WHERE Ativo=1 ORDER BY NomeSetor")
Set rsPerfis  = dbQuery("SELECT IdPerfil, NomePerfil FROM Perfis ORDER BY IdPerfil")

Dim paginaAtiva : paginaAtiva = "usuarios"
Dim pageTitulo  : pageTitulo  = "Editar Usuario"
%>
<!--#include file="../includes/layout.asp"-->

<div class="page-header">
    <h1>
        <a href="lista.asp" class="btn-back"><i class="fa-solid fa-arrow-left"></i></a>
        <i class="fa-solid fa-user-pen"></i> Editar Usuario
    </h1>
</div>

<% If msgErro <> "" Then %>
<div class="alert alert-danger"><i class="fa-solid fa-circle-xmark"></i> <%=Server.HtmlEncode(msgErro)%></div>
<% End If %>

<div class="card-box" style="max-width:680px">
    <div class="card-box-title"><i class="fa-solid fa-id-card"></i> Dados do Usuario</div>

    <form method="post" action="salvar.asp">
        <input type="hidden" name="acao"      value="editar">
        <input type="hidden" name="id_usuario" value="<%=idUsuario%>">

        <div class="form-grid">
            <div class="form-group">
                <label>Matricula <span style="color:var(--danger)">*</span></label>
                <input type="text" name="matricula" required maxlength="20"
                       value="<%=Server.HtmlEncode(vMatricula)%>">
            </div>
            <div class="form-group">
                <label>Login <span style="color:var(--danger)">*</span></label>
                <input type="text" name="login" required maxlength="50"
                       value="<%=Server.HtmlEncode(vLogin)%>"
                       autocomplete="off">
            </div>
        </div>

        <div class="form-group">
            <label>Nome Completo <span style="color:var(--danger)">*</span></label>
            <input type="text" name="nome" required maxlength="100"
                   value="<%=Server.HtmlEncode(vNome)%>">
        </div>

        <!-- Senha: so preenche se quiser alterar -->
        <div class="card-box" style="background:var(--bg);box-shadow:none;border-style:dashed;padding:16px;margin-bottom:16px">
            <div style="font-size:12px;font-weight:600;color:var(--text-muted);margin-bottom:12px;text-transform:uppercase;letter-spacing:.5px">
                <i class="fa-solid fa-key"></i> Alterar Senha (opcional)
            </div>
            <div class="form-grid">
                <div class="form-group" style="margin-bottom:0">
                    <label>Nova Senha</label>
                    <input type="password" name="senha" maxlength="255"
                           autocomplete="new-password" placeholder="Deixe em branco para manter">
                </div>
                <div class="form-group" style="margin-bottom:0">
                    <label>Confirmar Nova Senha</label>
                    <input type="password" name="senha2" maxlength="255"
                           autocomplete="new-password" placeholder="Confirme a nova senha">
                </div>
            </div>
        </div>

        <div class="form-grid">
            <div class="form-group">
                <label>Setor <span style="color:var(--danger)">*</span></label>
                <select name="id_setor" required>
                    <option value="">Selecione...</option>
                    <% Do While Not rsSetores.EOF %>
                        <option value="<%=rsSetores("IdSetor")%>"
                            <%If CStr(vIdSetor)=CStr(rsSetores("IdSetor")) Then Response.Write "selected"%>>
                            <%=rsSetores("NomeSetor")%>
                        </option>
                    <% rsSetores.MoveNext : Loop %>
                </select>
            </div>
            <div class="form-group">
                <label>Perfil / Permissao <span style="color:var(--danger)">*</span></label>
                <select name="id_perfil" required>
                    <option value="">Selecione...</option>
                    <% Do While Not rsPerfis.EOF %>
                        <option value="<%=rsPerfis("IdPerfil")%>"
                            <%If CStr(vIdPerfil)=CStr(rsPerfis("IdPerfil")) Then Response.Write "selected"%>>
                            <%=rsPerfis("NomePerfil")%>
                        </option>
                    <% rsPerfis.MoveNext : Loop %>
                </select>
            </div>
        </div>

        <div class="form-group">
            <label>Situacao</label>
            <select name="ativo">
                <option value="1" <%If CStr(vAtivo)="True" Or CStr(vAtivo)="1" Then Response.Write "selected"%>>Ativo</option>
                <option value="0" <%If CStr(vAtivo)="False" Or CStr(vAtivo)="0" Then Response.Write "selected"%>>Inativo</option>
            </select>
        </div>

        <div style="display:flex;gap:8px;margin-top:8px;padding-top:16px;border-top:1px solid var(--border)">
            <button type="submit" class="btn btn-primary">
                <i class="fa-solid fa-floppy-disk"></i> Salvar Alteracoes
            </button>
            <a href="lista.asp" class="btn btn-ghost">Cancelar</a>
        </div>
    </form>
</div>

<%
rsSetores.Close : Set rsSetores = Nothing
rsPerfis.Close  : Set rsPerfis  = Nothing
Call fechaConexao
%>

<script>
document.querySelector('form').addEventListener('submit', function(e) {
    var s1 = document.querySelector('[name=senha]').value;
    var s2 = document.querySelector('[name=senha2]').value;
    // So valida senha se o usuario digitou algo
    if (s1 !== '' || s2 !== '') {
        if (s1.length < 6) {
            e.preventDefault();
            alert('A nova senha deve ter pelo menos 6 caracteres.');
            return;
        }
        if (s1 !== s2) {
            e.preventDefault();
            alert('As senhas nao conferem.');
            return;
        }
    }
});
</script>

<!--#include file="../includes/layout_footer.asp"-->
