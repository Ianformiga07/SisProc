<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<%
Response.CodePage = 65001
Response.Charset  = "UTF-8"
%>
<!--#include file="../config/app.asp"-->
<!--#include file="../Lib/Conexao.asp"-->
<!--#include file="../includes/seguranca.asp"-->
<%
Call abreConexao

Dim msgErro : msgErro = Request.QueryString("erro")
Dim msgInfo : msgInfo = Request.QueryString("msg")

Dim paginaAtiva : paginaAtiva = "novo_processo"
Dim pageTitulo  : pageTitulo  = "Novo Processo"
%>
<!--#include file="../includes/layout.asp"-->

<div class="page-header">
    <h1>
        <a href="lista.asp" class="btn-back"><i class="fa-solid fa-arrow-left"></i></a>
        <i class="fa-solid fa-plus-circle"></i> Novo Processo
    </h1>
</div>

<% If msgErro <> "" Then %>
<div class="alert alert-danger"><i class="fa-solid fa-circle-xmark"></i> <%=Server.HtmlEncode(msgErro)%></div>
<% End If %>

<div class="card-box" style="max-width:720px">
    <div class="card-box-title"><i class="fa-solid fa-file-circle-plus"></i> Dados do Processo</div>

    <form method="post" action="salvar.asp">

        <div class="form-grid">
            <div class="form-group">
                <label>Número do Processo <span style="color:var(--danger)">*</span></label>
                <input type="text" name="numero_processo"
                       placeholder="ex: 2025/001"
                       required maxlength="30"
                       value="<%=Server.HtmlEncode(Request.Form("numero_processo"))%>">
                <div class="hint">Número de autuação do protocolo</div>
            </div>

            <div class="form-group">
                <label>Tipo de Processo <span style="color:var(--danger)">*</span></label>
                <select name="tipo_processo" required>
                    <option value="">Selecione...</option>
                    <option value="Compra"  <%If Request.Form("tipo_processo")="Compra"  Then Response.Write "selected"%>>Compra</option>
                    <option value="Serviço" <%If Request.Form("tipo_processo")="Serviço" Then Response.Write "selected"%>>Serviço</option>
                </select>
            </div>
        </div>

        <div class="form-group">
            <label>Assunto <span style="color:var(--danger)">*</span></label>
            <input type="text" name="assunto"
                   placeholder="Descreva o assunto resumidamente"
                   required maxlength="255"
                   value="<%=Server.HtmlEncode(Request.Form("assunto"))%>">
        </div>

        <div class="form-group">
            <label>Descrição / Observações</label>
            <textarea name="descricao" rows="4" placeholder="Detalhes adicionais (opcional)"><%=Server.HtmlEncode(Request.Form("descricao"))%></textarea>
        </div>

        <div style="display:flex;gap:8px;margin-top:8px">
            <button type="submit" class="btn btn-primary">
                <i class="fa-solid fa-floppy-disk"></i> Salvar Processo
            </button>
            <a href="lista.asp" class="btn btn-ghost">Cancelar</a>
        </div>

    </form>
</div>

<%
Call fechaConexao
%>
<!--#include file="../includes/layout_footer.asp"-->
