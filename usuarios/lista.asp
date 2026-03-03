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

Dim fNome, fSetor, fPerfil, fAtivo
fNome   = dbStr(Request.QueryString("nome"))
fSetor  = dbInt(Request.QueryString("setor"))
fPerfil = dbInt(Request.QueryString("perfil"))
fAtivo  = Request.QueryString("ativo")
If fAtivo = "" Then fAtivo = "1"

Dim pagina, limite, offset
limite = 15
pagina = dbInt(Request.QueryString("p"))
If pagina < 1 Then pagina = 1
offset = (pagina - 1) * limite

Dim sqlWhere : sqlWhere = "WHERE 1=1 "
If fNome  <> "" Then sqlWhere = sqlWhere & " AND (U.Nome LIKE '%" & fNome & "%' OR U.Login LIKE '%" & fNome & "%' OR U.Matricula LIKE '%" & fNome & "%')"
If fSetor  > 0  Then sqlWhere = sqlWhere & " AND U.IdSetor = "  & fSetor
If fPerfil > 0  Then sqlWhere = sqlWhere & " AND U.IdPerfil = " & fPerfil
If fAtivo = "0" Then
    sqlWhere = sqlWhere & " AND U.Ativo = 0"
ElseIf fAtivo = "todos" Then
    ' sem filtro
Else
    sqlWhere = sqlWhere & " AND U.Ativo = 1"
End If

Dim rsTotal, totalReg, totalPag
Set rsTotal = dbQuery("SELECT COUNT(*) AS Total FROM Usuarios U " & sqlWhere)
totalReg = rsTotal("Total")
rsTotal.Close : Set rsTotal = Nothing
If totalReg = 0 Then
    totalPag = 1
ElseIf (totalReg Mod limite) = 0 Then
    totalPag = totalReg \ limite
Else
    totalPag = (totalReg \ limite) + 1
End If

Dim rs
Set rs = dbQuery( _
    "SELECT U.IdUsuario_Int, U.Matricula, U.Nome, U.Login, U.Ativo, " & _
    "       P.NomePerfil, P.IsAdmin, S.NomeSetor " & _
    "FROM Usuarios U " & _
    "INNER JOIN Perfis P  ON P.IdPerfil = U.IdPerfil " & _
    "INNER JOIN Setores S ON S.IdSetor  = U.IdSetor " & _
    sqlWhere & _
    " ORDER BY U.Nome " & _
    " OFFSET " & offset & " ROWS FETCH NEXT " & limite & " ROWS ONLY")

Dim rsSetores, rsPerfis
Set rsSetores = dbQuery("SELECT IdSetor, NomeSetor FROM Setores WHERE Ativo=1 ORDER BY NomeSetor")
Set rsPerfis  = dbQuery("SELECT IdPerfil, NomePerfil FROM Perfis ORDER BY IdPerfil")

Dim qFiltros : qFiltros = ""
If fNome   <> "" Then qFiltros = qFiltros & "&nome="   & Server.URLEncode(fNome)
If fSetor   > 0  Then qFiltros = qFiltros & "&setor="  & fSetor
If fPerfil  > 0  Then qFiltros = qFiltros & "&perfil=" & fPerfil
qFiltros = qFiltros & "&ativo=" & fAtivo

Dim msgOk : msgOk = Request.QueryString("ok")

Dim paginaAtiva : paginaAtiva = "usuarios"
Dim pageTitulo  : pageTitulo  = "Usuarios"
%>
<!--#include file="../includes/layout.asp"-->

<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
<% If msgOk = "criado" Then %>
<script>window.addEventListener('DOMContentLoaded',function(){Swal.fire({icon:'success',title:'Usuario criado!',confirmButtonColor:'#1a56db',timer:3000,timerProgressBar:true});});</script>
<% ElseIf msgOk = "editado" Then %>
<script>window.addEventListener('DOMContentLoaded',function(){Swal.fire({icon:'success',title:'Usuario atualizado!',confirmButtonColor:'#1a56db',timer:3000,timerProgressBar:true});});</script>
<% ElseIf msgOk = "ativado" Then %>
<script>window.addEventListener('DOMContentLoaded',function(){Swal.fire({icon:'success',title:'Usuario reativado!',confirmButtonColor:'#1a56db',timer:2500,timerProgressBar:true});});</script>
<% ElseIf msgOk = "desativado" Then %>
<script>window.addEventListener('DOMContentLoaded',function(){Swal.fire({icon:'warning',title:'Usuario desativado!',confirmButtonColor:'#d97706',timer:2500,timerProgressBar:true});});</script>
<% End If %>

<div class="page-header">
    <h1><i class="fa-solid fa-users"></i> Usuarios</h1>
    <div class="page-actions">
        <a href="novo.asp" class="btn btn-primary"><i class="fa-solid fa-user-plus"></i> Novo Usuario</a>
    </div>
</div>

<form method="get" class="filters">
    <div class="filter-group">
        <label>Nome / Login / Matricula</label>
        <input type="text" name="nome" value="<%=fNome%>" placeholder="Buscar..." style="width:200px">
    </div>
    <div class="filter-group">
        <label>Setor</label>
        <select name="setor" style="width:170px">
            <option value="">Todos</option>
            <% Do While Not rsSetores.EOF %>
                <option value="<%=rsSetores("IdSetor")%>" <%If fSetor=rsSetores("IdSetor") Then Response.Write "selected"%>><%=rsSetores("NomeSetor")%></option>
            <% rsSetores.MoveNext : Loop %>
        </select>
    </div>
    <div class="filter-group">
        <label>Perfil</label>
        <select name="perfil" style="width:140px">
            <option value="">Todos</option>
            <% Do While Not rsPerfis.EOF %>
                <option value="<%=rsPerfis("IdPerfil")%>" <%If fPerfil=rsPerfis("IdPerfil") Then Response.Write "selected"%>><%=rsPerfis("NomePerfil")%></option>
            <% rsPerfis.MoveNext : Loop %>
        </select>
    </div>
    <div class="filter-group">
        <label>Situacao</label>
        <select name="ativo" style="width:110px">
            <option value="1"    <%If fAtivo="1"    Then Response.Write "selected"%>>Ativos</option>
            <option value="0"    <%If fAtivo="0"    Then Response.Write "selected"%>>Inativos</option>
            <option value="todos"<%If fAtivo="todos"Then Response.Write "selected"%>>Todos</option>
        </select>
    </div>
    <div class="filter-group" style="justify-content:flex-end">
        <label>&nbsp;</label>
        <div style="display:flex;gap:6px">
            <button type="submit" class="btn btn-primary"><i class="fa-solid fa-filter"></i> Filtrar</button>
            <a href="lista.asp" class="btn btn-ghost">Limpar</a>
        </div>
    </div>
</form>
<%
rsSetores.Close : Set rsSetores = Nothing
rsPerfis.Close  : Set rsPerfis  = Nothing
%>

<div style="margin-bottom:12px;font-size:12.5px;color:var(--text-muted)">
    <%=totalReg%> usuario(s) encontrado(s)<% If totalPag > 1 Then %> &mdash; Pagina <%=pagina%> de <%=totalPag%><% End If %>
</div>

<div class="card-box" style="padding:0">
<div class="table-wrap">
<table class="data-table">
    <thead>
        <tr>
            <th>Matricula</th>
            <th>Nome</th>
            <th>Login</th>
            <th>Setor</th>
            <th>Perfil</th>
            <th class="col-center">Situacao</th>
            <th class="col-center">Acoes</th>
        </tr>
    </thead>
    <tbody>
    <% If rs.EOF Then %>
        <tr><td colspan="7" class="empty-table"><i class="fa-solid fa-users-slash"></i> Nenhum usuario encontrado.</td></tr>
    <% Else %>
    <% Do While Not rs.EOF %>
        <tr>
            <td><span style="font-family:var(--font-mono);font-size:12.5px;color:var(--text-muted)"><%=rs("Matricula")%></span></td>
            <td>
                <div style="font-weight:500"><%=rs("Nome")%></div>
                <% If rs("IsAdmin") Then %>
                <div style="font-size:11px;color:var(--primary);margin-top:2px"><i class="fa-solid fa-shield-halved"></i> Administrador</div>
                <% End If %>
            </td>
            <td style="color:var(--text-muted)"><%=rs("Login")%></td>
            <td><span class="badge badge-setor"><%=rs("NomeSetor")%></span></td>
            <td><span class="badge" style="background:#f3f4f6;color:#374151"><%=rs("NomePerfil")%></span></td>
            <td class="col-center">
                <% If rs("Ativo") Then %>
                    <span class="badge badge-finalizado"><i class="fa-solid fa-circle" style="font-size:7px"></i> Ativo</span>
                <% Else %>
                    <span class="badge badge-cancelado"><i class="fa-solid fa-circle" style="font-size:7px"></i> Inativo</span>
                <% End If %>
            </td>
            <td class="col-center">
                <div style="display:flex;gap:4px;justify-content:center">
                    <a href="editar.asp?id=<%=rs("IdUsuario_Int")%>" class="btn btn-outline btn-sm btn-icon" title="Editar usuario">
                        <i class="fa-solid fa-pen"></i>
                    </a>
                    <% If rs("Ativo") Then %>
                    <a href="toggle.asp?id=<%=rs("IdUsuario_Int")%>&acao=desativar"
                       class="btn btn-sm btn-icon" style="background:var(--danger-bg);color:var(--danger);border:1px solid #fca5a5"
                       title="Desativar"
                       onclick="return confirm('Desativar o usuario <%=Replace(rs("Nome"),"'","\'")%>?')">
                        <i class="fa-solid fa-user-slash"></i>
                    </a>
                    <% Else %>
                    <a href="toggle.asp?id=<%=rs("IdUsuario_Int")%>&acao=ativar"
                       class="btn btn-sm btn-icon" style="background:var(--success-bg);color:var(--success);border:1px solid #bbf7d0"
                       title="Reativar"
                       onclick="return confirm('Reativar o usuario <%=Replace(rs("Nome"),"'","\'")%>?')">
                        <i class="fa-solid fa-user-check"></i>
                    </a>
                    <% End If %>
                </div>
            </td>
        </tr>
    <% rs.MoveNext : Loop %>
    <% End If %>
    </tbody>
</table>
</div>

<% If totalPag > 1 Then %>
<div class="pagination">
    <% If pagina > 1 Then %><a href="?p=<%=pagina-1%><%=qFiltros%>"><i class="fa-solid fa-chevron-left"></i></a><% End If %>
    <%
    Dim i
    For i = 1 To totalPag
        If Abs(i-pagina)<=2 Or i=1 Or i=totalPag Then
    %>
        <a href="?p=<%=i%><%=qFiltros%>" class="<%If i=pagina Then Response.Write "active"%>"><%=i%></a>
    <%  ElseIf Abs(i-pagina)=3 Then %><span style="padding:0 4px;color:var(--text-light)">…</span><%
        End If
    Next
    %>
    <% If pagina < totalPag Then %><a href="?p=<%=pagina+1%><%=qFiltros%>"><i class="fa-solid fa-chevron-right"></i></a><% End If %>
</div>
<% End If %>
</div>

<%
rs.Close : Set rs = Nothing
Call fechaConexao
%>
<!--#include file="../includes/layout_footer.asp"-->
