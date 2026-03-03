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

Dim msgErro : msgErro = Request.QueryString("erro")

Dim rsSetores, rsPerfis
Set rsSetores = dbQuery("SELECT IdSetor, NomeSetor FROM Setores WHERE Ativo=1 ORDER BY NomeSetor")
Set rsPerfis  = dbQuery("SELECT IdPerfil, NomePerfil FROM Perfis ORDER BY IdPerfil")

Dim paginaAtiva : paginaAtiva = "usuarios"
Dim pageTitulo  : pageTitulo  = "Novo Usuario"
%>
<!--#include file="../includes/layout.asp"-->

<div class="page-header">
    <h1>
        <a href="lista.asp" class="btn-back"><i class="fa-solid fa-arrow-left"></i></a>
        <i class="fa-solid fa-user-plus"></i> Novo Usuario
    </h1>
</div>

<% If msgErro <> "" Then %>
<div class="alert alert-danger"><i class="fa-solid fa-circle-xmark"></i> <%=Server.HtmlEncode(msgErro)%></div>
<% End If %>

<div class="card-box" style="max-width:680px">
    <div class="card-box-title"><i class="fa-solid fa-id-card"></i> Dados do Usuario</div>

    <form method="post" action="salvar.asp">
        <input type="hidden" name="acao" value="novo">

        <div class="form-grid">
            <div class="form-group">
                <label>Matricula <span style="color:var(--danger)">*</span></label>
                <input type="text" name="matricula" required maxlength="20"
                       value="<%=Server.HtmlEncode(Request.Form("matricula"))%>"
                       placeholder="Ex: 000123">
                <div class="hint">Matricula funcional do servidor</div>
            </div>
            <div class="form-group">
                <label>Login <span style="color:var(--danger)">*</span></label>
                <input type="text" name="login" required maxlength="50"
                       value="<%=Server.HtmlEncode(Request.Form("login"))%>"
                       placeholder="Ex: joao.silva"
                       autocomplete="off">
            </div>
        </div>

        <div class="form-group">
            <label>Nome Completo <span style="color:var(--danger)">*</span></label>
            <input type="text" name="nome" required maxlength="100"
                   value="<%=Server.HtmlEncode(Request.Form("nome"))%>"
                   placeholder="Nome completo do servidor">
        </div>

        <div class="form-grid">
            <div class="form-group">
                <label>Senha <span style="color:var(--danger)">*</span></label>
                <input type="password" name="senha" required maxlength="255"
                       autocomplete="new-password" placeholder="Minimo 6 caracteres">
            </div>
            <div class="form-group">
                <label>Confirmar Senha <span style="color:var(--danger)">*</span></label>
                <input type="password" name="senha2" required maxlength="255"
                       autocomplete="new-password" placeholder="Repita a senha">
            </div>
        </div>

        <div class="form-grid">
            <div class="form-group">
                <label>Setor <span style="color:var(--danger)">*</span></label>
                <select name="id_setor" required>
                    <option value="">Selecione o setor...</option>
                    <% Do While Not rsSetores.EOF %>
                        <option value="<%=rsSetores("IdSetor")%>"
                            <%If Request.Form("id_setor")=CStr(rsSetores("IdSetor")) Then Response.Write "selected"%>>
                            <%=rsSetores("NomeSetor")%>
                        </option>
                    <% rsSetores.MoveNext : Loop %>
                </select>
            </div>
            <div class="form-group">
                <label>Perfil / Permissao <span style="color:var(--danger)">*</span></label>
                <select name="id_perfil" required>
                    <option value="">Selecione o perfil...</option>
                    <% Do While Not rsPerfis.EOF %>
                        <option value="<%=rsPerfis("IdPerfil")%>"
                            <%If Request.Form("id_perfil")=CStr(rsPerfis("IdPerfil")) Then Response.Write "selected"%>>
                            <%=rsPerfis("NomePerfil")%>
                        </option>
                    <% rsPerfis.MoveNext : Loop %>
                </select>
                <div class="hint">Administrador tem acesso total ao sistema</div>
            </div>
        </div>

        <div style="display:flex;gap:8px;margin-top:8px;padding-top:16px;border-top:1px solid var(--border)">
            <button type="submit" class="btn btn-primary">
                <i class="fa-solid fa-floppy-disk"></i> Salvar Usuario
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
// Validacao de senha no client antes de submeter
document.querySelector('form').addEventListener('submit', function(e) {
    var s1 = document.querySelector('[name=senha]').value;
    var s2 = document.querySelector('[name=senha2]').value;
    if (s1.length < 6) {
        e.preventDefault();
        alert('A senha deve ter pelo menos 6 caracteres.');
        return;
    }
    if (s1 !== s2) {
        e.preventDefault();
        alert('As senhas nao conferem.');
        return;
    }
});
</script>

<!--#include file="../includes/layout_footer.asp"-->
