<%
' ============================================================
'  SisProc - Rodapé do Layout
'  includes/layout_footer.asp
'  Inclua este arquivo no FINAL de cada página
' ============================================================
%>
    </main>
</div>

<footer class="footer">
    SisProc &copy; <%=Year(Now())%> &mdash; Sistema de Acompanhamento de Processos
</footer>

<script>
function toggleSidebar() {
    document.getElementById('appWrapper').classList.toggle('collapsed');
}
</script>
</body>
</html>
