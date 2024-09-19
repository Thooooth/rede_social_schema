CREATE DATABASE IF NOT EXISTS rede_social;
USE rede_social;

CREATE TABLE usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    senha VARCHAR(255) NOT NULL,
    data_nascimento DATE,
    bio TEXT,
    foto_perfil VARCHAR(255),
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP,
    ultimo_acesso DATETIME
);

CREATE TABLE posts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT,
    conteudo TEXT NOT NULL,
    midia VARCHAR(255),
    data_publicacao DATETIME DEFAULT CURRENT_TIMESTAMP,
    visibilidade ENUM('publico', 'amigos', 'privado') DEFAULT 'publico',
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

CREATE TABLE amizades (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id1 INT,
    usuario_id2 INT,
    status ENUM('pendente', 'aceita', 'bloqueada') DEFAULT 'pendente',
    data_solicitacao DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao DATETIME,
    FOREIGN KEY (usuario_id1) REFERENCES usuarios(id),
    FOREIGN KEY (usuario_id2) REFERENCES usuarios(id)
);

CREATE TABLE comentarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT,
    usuario_id INT,
    conteudo TEXT NOT NULL,
    data_comentario DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(id),
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

CREATE TABLE curtidas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT,
    post_id INT,
    data_curtida DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
    FOREIGN KEY (post_id) REFERENCES posts(id)
);

CREATE TABLE mensagens (
    id INT AUTO_INCREMENT PRIMARY KEY,
    remetente_id INT,
    destinatario_id INT,
    conteudo TEXT NOT NULL,
    data_envio DATETIME DEFAULT CURRENT_TIMESTAMP,
    lida BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (remetente_id) REFERENCES usuarios(id),
    FOREIGN KEY (destinatario_id) REFERENCES usuarios(id)
);

CREATE TABLE grupos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    criador_id INT,
    data_criacao DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (criador_id) REFERENCES usuarios(id)
);

CREATE TABLE membros_grupo (
    id INT AUTO_INCREMENT PRIMARY KEY,
    grupo_id INT,
    usuario_id INT,
    data_entrada DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (grupo_id) REFERENCES grupos(id),
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

-- Índices
CREATE INDEX idx_posts_usuario ON posts(usuario_id);
CREATE INDEX idx_amizades_usuarios ON amizades(usuario_id1, usuario_id2);
CREATE INDEX idx_comentarios_post ON comentarios(post_id);
CREATE INDEX idx_curtidas_post ON curtidas(post_id);
CREATE INDEX idx_mensagens_usuarios ON mensagens(remetente_id, destinatario_id);

-- Triggers
DELIMITER //

CREATE TRIGGER atualiza_ultimo_acesso 
AFTER UPDATE ON usuarios
FOR EACH ROW
BEGIN
    IF NEW.ultimo_acesso != OLD.ultimo_acesso THEN
        INSERT INTO log_acessos (usuario_id, data_acesso)
        VALUES (NEW.id, NEW.ultimo_acesso);
    END IF;
END;
//

DELIMITER ;

-- Views
CREATE VIEW posts_populares AS
SELECT p.id, p.conteudo, p.data_publicacao, u.nome AS autor,
       COUNT(DISTINCT c.id) AS num_comentarios,
       COUNT(DISTINCT l.id) AS num_curtidas
FROM posts p
JOIN usuarios u ON p.usuario_id = u.id
LEFT JOIN comentarios c ON p.id = c.post_id
LEFT JOIN curtidas l ON p.id = l.post_id
GROUP BY p.id
ORDER BY (COUNT(DISTINCT c.id) + COUNT(DISTINCT l.id)) DESC
LIMIT 10;
