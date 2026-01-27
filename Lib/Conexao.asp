<%
	dim conn, strcon
sub abreConexao

	'Criando a conexão com o BD
	strcon =  "Provider=SQLNCLI11;Server=localhost;Database=SistemaProcessos;Uid=sa;Pwd=123;"
	set conn = Server.CreateObject("ADODB.Connection")
	conn.open(strcon)	
end sub


sub fechaConexao
	'Fechando a conexão com o BD
	conn.Close()
	Set conn = Nothing
end sub
%>