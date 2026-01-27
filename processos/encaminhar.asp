<!--#include file="../config/app.asp" -->
<!--#include file="../Lib/Conexao.asp" -->
<!--#include file="../includes/seguranca.asp" -->

<%
call abreConexao

' ===============================
' RECEBENDO DADOS DO FORM
' ===============================
Dim idProcesso, idSetorDestino, observacao, matriculaUsuario

idProcesso        = CLng(Request.Form("id_processo"))
idSetorDestino    = CLng(Request.Form("setor_destino"))
observacao        = Trim(Request.Form("observacao"))
matriculaUsuario  = Session("Matricula")

If idProcesso = 0 Or idSetorDestino = 0 Or matriculaUsuario = "" Then
    Response.Write "Dados inválidos."
    Response.End
End If


' ===============================
' BLOQUEIA PROCESSO FINALIZADO
' ===============================
Dim rsStatus, statusProcesso

Set rsStatus = conn.Execute("SELECT Status FROM Processos WHERE IdProcesso = " & idProcesso)

If rsStatus.EOF Then
    Response.Write "Processo não encontrado."
    Response.End
End If

statusProcesso = rsStatus("Status")

rsStatus.Close
Set rsStatus = Nothing

If statusProcesso = "FINALIZADO" Then
    Response.Write "Processo já finalizado. Não é possível encaminhar."
    Response.End
End If


' =====================================================
' 🔒 VALIDAÇÃO DE FLUXO - BACK-END (ENTRA AQUI 👇)
' =====================================================

Dim rsAtual, rsFluxo, idSetorAtual, idTramitacaoAtual
Dim sqlAtual, sqlFluxo

' Busca a tramitação atual aberta
sqlAtual = "SELECT TOP 1 IdTramitacao, IdSetor FROM Tramitacoes WHERE IdProcesso = " & idProcesso & " AND DataSaida IS NULL ORDER BY DataEntrada DESC"

Set rsAtual = conn.Execute(sqlAtual)

If rsAtual.EOF Then
    Response.Write "Processo sem tramitação ativa."
    Response.End
End If

idSetorAtual = rsAtual("IdSetor")
idTramitacaoAtual = rsAtual("IdTramitacao")

rsAtual.Close
Set rsAtual = Nothing


' Verifica se o setor destino é permitido a partir do atual
sqlFluxo = "SELECT 1 FROM FluxoSetores WHERE SetorOrigem = " & idSetorAtual & " AND SetorDestino = " & idSetorDestino & ""

Set rsFluxo = conn.Execute(sqlFluxo)

If rsFluxo.EOF Then
    Response.Write "Encaminhamento não permitido para este setor."
    Response.End
End If

rsFluxo.Close
Set rsFluxo = Nothing


' ===============================
' 1️⃣ FECHA TRAMITAÇÃO ATUAL
' ===============================
Dim sqlFecha
sqlFecha = "UPDATE Tramitacoes " & _
           "SET DataSaida = GETDATE() " & _
           "WHERE IdProcesso = " & idProcesso & " AND DataSaida IS NULL"

conn.Execute sqlFecha

' ===============================
' 2️⃣ INSERE NOVA TRAMITAÇÃO
' ===============================
Dim sqlInsert
sqlInsert = "INSERT INTO Tramitacoes " & _
            "(IdProcesso, IdSetor, MatriculaUsuario, Observacao, DataEntrada) VALUES (" & _
            idProcesso & ", " & _
            idSetorDestino & ", '" & _
            Replace(matriculaUsuario,"'","''") & "', '" & _
            Replace(observacao,"'","''") & "', GETDATE())"

conn.Execute sqlInsert


' ===============================
' FINALIZA PROCESSO SE FOR SETOR FINAL
' ===============================
If CLng(idSetorDestino) = 7 Then

    Dim sqlFinaliza
    sqlFinaliza = "UPDATE Processos " & _
                  "SET Status = 'FINALIZADO', " & _
                  "    DataFinalizacao = GETDATE(), " & _
                  "    Ativo = 0 " & _
                  "WHERE IdProcesso = " & CLng(idProcesso)

    conn.Execute sqlFinaliza

End If

' ===============================
' 3️⃣ PEGA O ID DA TRAMITAÇÃO CRIADA
' ===============================
Dim rsID, idTramitacaoNova

Set rsID = conn.Execute("SELECT @@IDENTITY AS Id")
idTramitacaoNova = rsID("Id")
rsID.Close
Set rsID = Nothing

' ===============================
' 4️⃣ FUNÇÃO PARA SALVAR DETALHES
' ===============================
Sub salvarDetalhe(campo, valor)
    If Trim(valor) <> "" Then
        conn.Execute "INSERT INTO TramitacaoDetalhes (IdTramitacao, Campo, Valor) VALUES (" & _
                     idTramitacaoNova & ", '" & campo & "', '" & Replace(valor,"'","''") & "')"
    End If
End Sub

' ===============================
' 5️⃣ SALVA DETALHES CONFORME SETOR
' ===============================
Dim setorAtual
setorAtual = idSetorDestino

' --- SETOR SOLICITANTE (2)
If setorAtual = 2 Then
    Call salvarDetalhe("Descricao", Request.Form("descricao"))
    Call salvarDetalhe("Quantidade", Request.Form("quantidade"))
    Call salvarDetalhe("Urgencia", Request.Form("urgencia"))
End If

' --- COMPRAS (3)
If setorAtual = 3 Then
    Call salvarDetalhe("Fornecedor", Request.Form("fornecedor"))
    Call salvarDetalhe("Cotacoes", Request.Form("cotacoes"))
    Call salvarDetalhe("TipoCompra", Request.Form("tipo_compra"))
End If

' --- PLANEJAMENTO (4)
If setorAtual = 4 Then
    Call salvarDetalhe("AnalisePlanejamento", Request.Form("analise_planejamento"))
End If

' --- LICITAÇÃO - SCL (5)
If setorAtual = 5 Then
    Call salvarDetalhe("Modalidade", Request.Form("modalidade"))
    Call salvarDetalhe("NumeroEdital", Request.Form("numero_edital"))
End If

' --- FINANCEIRO (6)
If setorAtual = 6 Then
    Call salvarDetalhe("Autorizacao", Request.Form("autorizacao"))
    Call salvarDetalhe("CentroCusto", Request.Form("centro_custo"))
End If

' --- NAP (7)
If setorAtual = 7 Then
    Call salvarDetalhe("ProvidenciaNAP", Request.Form("providencia_nap"))
End If

' ===============================
' 6️⃣ ATUALIZA STATUS DO PROCESSO
' ===============================
'Dim sqlStatus
'sqlStatus = "UPDATE Processos SET Ativo = 1 WHERE IdProcesso = " & idProcesso
'conn.Execute sqlStatus


call fechaConexao

' ===============================
' 7️⃣ REDIRECIONA
' ===============================
Response.Redirect "detalhes.asp?id=" & idProcesso
%>