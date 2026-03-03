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

' ── FILTROS ───────────────────────────────────────────────
Dim fNumero, fTipo, fStatus, fSetor
fNumero = Trim(Request.QueryString("numero"))
fTipo   = Trim(Request.QueryString("tipo"))
fStatus = Trim(Request.QueryString("status"))
fSetor  = dbInt(Request.QueryString("setor"))

' ── PAGINAÇÃO ─────────────────────────────────────────────
Dim pagina, limite, offset
limite = 15
pagina = dbInt(Request.QueryString("p"))
If pagina < 1 Then pagina = 1
offset = (pagina - 1) * limite

' ── FILTRO SQL ────────────────────────────────────────────
Dim sqlWhere : sqlWhere = "WHERE 1=1 "

If fNumero <> "" Then
    sqlWhere = sqlWhere & " AND NumeroProcesso LIKE '%" & dbStr(fNumero) & "%'"
End If
If fTipo <> "" Then
    sqlWhere = sqlWhere & " AND TipoProcesso = '" & dbStr(fTipo) & "'"
End If
If fStatus <> "" Then
    sqlWhere = sqlWhere & " AND StatusAtual = '" & dbStr(fStatus) & "'"
End If
If fSetor > 0 Then
    sqlWhere = sqlWhere & " AND IdSetorAtual = " & fSetor
End If

' ── TOTAL ─────────────────────────────────────────────────
Dim rsTotal, totalRegistros, totalPaginas
Set rsTotal = dbQuery("SELECT COUNT(*) AS Total FROM vw_ProcessosLista " & sqlWhere)
totalRegistros = rsTotal("Total")
rsTotal.Close : Set rsTotal = Nothing

If totalRegistros = 0 Then
    totalPaginas = 1
ElseIf (totalRegistros Mod limite) = 0 Then
    totalPaginas = totalRegistros \ limite
Else
    totalPaginas = (totalRegistros \ limite) + 1
End If

' ── LISTA ─────────────────────────────────────────────────
Dim rs
Set rs = dbQuery( _
    "SELECT * FROM vw_ProcessosLista " & sqlWhere & _
    " ORDER BY DataCriacao DESC " & _
    " OFFSET " & offset & " ROWS FETCH NEXT " & limite & " ROWS ONLY")

' ── SETORES PARA O FILTRO ─────────────────────────────────
Dim rsSetoresFiltro
Set rsSetoresFiltro = dbQuery("SELECT IdSetor, NomeSetor FROM Setores WHERE Ativo=1 ORDER BY NomeSetor")

' ── QUERY STRING DE FILTROS (para paginação) ──────────────
Dim qFiltros : qFiltros = ""
If fNumero <> "" Then qFiltros = qFiltros & "&numero=" & Server.URLEncode(fNumero)
If fTipo   <> "" Then qFiltros = qFiltros & "&tipo="   & Server.URLEncode(fTipo)
If fStatus <> "" Then qFiltros = qFiltros & "&status=" & Server.URLEncode(fStatus)
If fSetor  >  0  Then qFiltros = qFiltros & "&setor="  & fSetor

Dim paginaAtiva : paginaAtiva = "processos"
Dim pageTitulo  : pageTitulo  = "Processos"
%>
<!--#include file="../includes/layout.asp"-->

<div class="page-header">
    <h1><i class="fa-solid fa-folder-open"></i> Processos</h1>
    <div class="page-actions">
        <a href="<%=APP_PATH%>/processos/novo.asp" class="btn btn-primary">
            <i class="fa-solid fa-plus"></i> Novo Processo
        </a>
    </div>
</div>

<!-- FILTROS -->
<form method="get" class="filters">
    <div class="filter-group">
        <label>Nº Processo</label>
        <input type="text" name="numero" value="<%=fNumero%>" placeholder="ex: 2025/001" style="width:160px">
    </div>
    <div class="filter-group">
        <label>Tipo</label>
        <select name="tipo" style="width:130px">
            <option value="">Todos</option>
            <option value="Compra"  <%If fTipo="Compra"   Then Response.Write "selected"%>>Compra</option>
            <option value="Serviço" <%If fTipo="Serviço"  Then Response.Write "selected"%>>Serviço</option>
        </select>
    </div>
    <div class="filter-group">
        <label>Status</label>
        <select name="status" style="width:150px">
            <option value="">Todos</option>
            <option value="Em andamento" <%If fStatus="Em andamento" Then Response.Write "selected"%>>Em andamento</option>
            <option value="Finalizado"   <%If fStatus="Finalizado"   Then Response.Write "selected"%>>Finalizado</option>
        </select>
    </div>
    <div class="filter-group">
        <label>Setor Atual</label>
        <select name="setor" style="width:180px">
            <option value="">Todos</option>
            <% Do While Not rsSetoresFiltro.EOF %>
                <option value="<%=rsSetoresFiltro("IdSetor")%>"
                    <%If fSetor = rsSetoresFiltro("IdSetor") Then Response.Write "selected"%>>
                    <%=rsSetoresFiltro("NomeSetor")%>
                </option>
            <% rsSetoresFiltro.MoveNext : Loop %>
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
rsSetoresFiltro.Close : Set rsSetoresFiltro = Nothing
%>

<!-- CONTAGEM -->
<div style="margin-bottom:12px;font-size:12.5px;color:var(--text-muted)">
    <%=totalRegistros%> processo(s) encontrado(s)
    <% If totalPaginas > 1 Then %>
     — Página <%=pagina%> de <%=totalPaginas%>
    <% End If %>
</div>

<!-- TABELA -->
<div class="card-box" style="padding:0">
<div class="table-wrap">
<table class="data-table">
    <thead>
        <tr>
            <th>Nº Processo</th>
            <th>Assunto</th>
            <th>Tipo</th>
            <th>Setor Atual</th>
            <th>Dias no Setor</th>
            <th>Abertura</th>
            <th>Status</th>
            <th class="col-center">Ações</th>
        </tr>
    </thead>
    <tbody>
    <% If rs.EOF Then %>
        <tr>
            <td colspan="8" class="empty-table">
                <i class="fa-regular fa-folder-open"></i>
                Nenhum processo encontrado.
            </td>
        </tr>
    <% Else %>
    <% Do While Not rs.EOF %>
        <tr>
            <td><span class="num-processo"><%=rs("NumeroProcesso")%></span></td>
            <td><%=rs("Assunto")%></td>
            <td><span class="badge badge-tipo"><%=rs("TipoProcesso")%></span></td>
            <td><span class="badge badge-setor"><%=rs("SetorAtual")%></span></td>
            <td><span class="<%=badgeSLA(rs("DiasNoSetor"))%>"><%=rs("DiasNoSetor")%> dias</span></td>
            <td><%=fmtData(rs("DataCriacao"))%></td>
            <td><span class="badge <%=badgeStatus(rs("StatusAtual"))%>"><%=rs("StatusAtual")%></span></td>
            <td class="col-center">
                <a href="detalhes.asp?id=<%=rs("IdProcesso")%>" class="btn btn-outline btn-sm btn-icon" title="Visualizar">
                    <i class="fa-solid fa-eye"></i>
                </a>
            </td>
        </tr>
    <% rs.MoveNext : Loop %>
    <% End If %>
    </tbody>
</table>
</div>

<!-- PAGINAÇÃO -->
<% If totalPaginas > 1 Then %>
<div class="pagination">
    <% If pagina > 1 Then %>
        <a href="?p=<%=pagina-1%><%=qFiltros%>" title="Anterior"><i class="fa-solid fa-chevron-left"></i></a>
    <% End If %>
    <%
    Dim i
    For i = 1 To totalPaginas
        If Abs(i - pagina) <= 2 Or i = 1 Or i = totalPaginas Then
    %>
        <a href="?p=<%=i%><%=qFiltros%>" class="<%If i=pagina Then Response.Write "active"%>"><%=i%></a>
    <%
        ElseIf Abs(i - pagina) = 3 Then
    %>
        <span style="padding:0 4px;color:var(--text-light)">…</span>
    <%
        End If
    Next
    %>
    <% If pagina < totalPaginas Then %>
        <a href="?p=<%=pagina+1%><%=qFiltros%>" title="Próxima"><i class="fa-solid fa-chevron-right"></i></a>
    <% End If %>
</div>
<% End If %>
</div>

<%
rs.Close : Set rs = Nothing
Call fechaConexao
%>
<!--#include file="../includes/layout_footer.asp"-->
