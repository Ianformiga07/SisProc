CREATE TABLE Setores (
    IdSetor INT IDENTITY PRIMARY KEY,
    NomeSetor VARCHAR(100)
);
CREATE TABLE Perfis (
    IdPerfil INT IDENTITY PRIMARY KEY,
    NomePerfil VARCHAR(50)
);
CREATE TABLE Usuarios (
    IdUsuario INT IDENTITY PRIMARY KEY,
    Nome VARCHAR(100),
    Login VARCHAR(50),
    Senha VARCHAR(100),
    IdPerfil INT,
    IdSetor INT,
    Ativo BIT
);
CREATE TABLE Processos (
    IdProcesso INT IDENTITY PRIMARY KEY,
    NumeroProcesso VARCHAR(30),
    Solicitante VARCHAR(100),
    SetorSolicitante VARCHAR(100),
    Objeto TEXT,
    Classificacao VARCHAR(50),
    DataAbertura DATETIME,
    StatusAtual VARCHAR(50)
);
CREATE TABLE Tramitacoes (
    IdTramitacao INT IDENTITY PRIMARY KEY,
    IdProcesso INT,
    IdSetor INT,
    DataEntrada DATETIME,
    DataSaida DATETIME NULL,
    Observacao TEXT
);
