<%
' ============================================================
'  SisProc - Configurações Globais
'  config/app.asp
' ============================================================

' Caminho base da aplicação no IIS
Const APP_PATH = "/SisProc"

' String de conexão com o SQL Server
' ATENÇÃO: ajuste Server, Database, User e Password para seu ambiente
Const DB_SERVER   = "localhost"
Const DB_DATABASE = "SistemaProcessos"
Const DB_USER     = "sisproc_user"
Const DB_PASSWORD = "suaSenhaAqui"

' Configurações de SLA (dias antes de alertar)
Const SLA_ALERTA_DIAS = 5

' Versão do sistema
Const APP_VERSAO = "2.0"
%>
