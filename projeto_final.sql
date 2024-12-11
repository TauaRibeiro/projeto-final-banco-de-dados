CREATE DATABASE projeto_final;
USE projeto_final;

/*
FUNÇÕES
*/
-- Encontrar última data de alteração do preco de um produto
DELIMITER //
CREATE FUNCTION encontrar_ultima_alteracao(`id_produto` INT)
RETURNS DATE NOT DETERMINISTIC
BEGIN
	DECLARE `resultado` DATE DEFAULT NULL;
    
    SELECT MAX(`pp`.`data_aplicacao`) INTO `resultado`
    FROM `preco_produto` AS `pp`
    WHERE `id_produto` = `pp`.`id_produto`;
    
    RETURN `resultado`;
END//
DELIMITER;

-- Achar o preco mais atualizado de um produto
DELIMITER //
CREATE FUNCTION achar_preco(`id_produto` INT)
RETURNS INT NOT DETERMINISTIC
BEGIN
	DECLARE `resultado` INT DEFAULT NULL;
    
    SELECT `pp`.`id_produto` INTO `resultado`
	FROM `preco_produto` AS `pp`
    WHERE 
    `pp`.`id_produto` = `id_produto` AND
    `pp`.`data_aplicacao` = encontrar_ultima_alteracao(`id_produto`);
    
    RETURN `resultado`;
END// 
DELIMITER ;

-- Calcular sub total da compra
DELIMITER //
CREATE FUNCTION calcular_subTotal(`id_preco_produto` INT, `quantidade` INT)
RETURNS DECIMAL(10, 2) DETERMINISTIC
BEGIN
	DECLARE `resultado` DECIMAL(10, 2);
    
    SELECT (`pp`.`preco_produto`*`quantidade`) INTO `resultado`
    FROM `preco_produto` AS `pp`
    WHERE `id_preco_produto` = `pp`.`id_preco_produto`;
    
    RETURN `resultado`;
END //
DELIMITER ;


/*
TRIGERS
*/
DELIMITER //
 CREATE TRIGGER tr_insert_item_compra
 AFTER INSERT
 ON `item_compra` FOR EACH ROW
 BEGIN
	 SET @total_antigo = (SELECT `total_compra` FROM `compra` WHERE NEW.`id_compra` = `compra`.`id_compra`); 
     
     UPDATE `compra`
     SET
     `total_compra` = @total_antigo + achar_preco(NEW.`id_produto`);
     
     INSERT INTO `historico`(`tipo_acao`, `id_compra`, `id_item`, `data_registro`)
     VALUE ("ADIÇÃO DE ITEM", NEW.`id_compra`, NEW.`id_item`, NOW());
 END//
DELIMITER ;
/*
PROCEDURES
*/

/*
TABLES
*/
CREATE TABLE `categoria` (
  `id_categoria` int AUTO_INCREMENT NOT NULL,
  `nome_categoria` varchar(50) NOT NULL,
  PRIMARY KEY (`id_categoria`)
);


CREATE TABLE `tipo_interacao`(
	`id_tipo` INT AUTO_INCREMENT NOT NULL,
    `nome_tipo` VARCHAR(50) NOT NULL,
    
    PRIMARY KEY(`id_tipo`)
);


CREATE TABLE `cliente` (
  `id_cliente` int AUTO_INCREMENT NOT NULL,
  `nome_cliente` varchar(150) NOT NULL,
  `cpf_cliente` varchar(11) NOT NULL,
  `id_endereco` int NOT NULL,
  `data_nascimento` date NOT NULL,
  `data_cadastro_cliente` date NOT NULL,
  `email_cliente` varchar(100) NOT NULL,
  PRIMARY KEY (`id_cliente`),
  UNIQUE KEY `cpf_cliente_UNIQUE` (`cpf_cliente`),
  KEY `fk_endereco_cliente_idx` (`id_endereco`),
  CONSTRAINT `fk_endereco_cliente` FOREIGN KEY (`id_endereco`) REFERENCES `endereco` (`id_endereco`) ON DELETE RESTRICT ON UPDATE RESTRICT
);


CREATE TABLE `compra` (
  `id_compra` int AUTO_INCREMENT NOT NULL,
  `id_cliente` int NOT NULL,
  `total_compra` decimal(10,0) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id_compra`),
  KEY `fk_cliente_compra_idx` (`id_cliente`),
  CONSTRAINT `fk_cliente_compra` FOREIGN KEY (`id_cliente`) REFERENCES `cliente` (`id_cliente`) ON DELETE RESTRICT ON UPDATE RESTRICT
);


CREATE TABLE `endereco` (
  `id_endereco` int AUTO_INCREMENT NOT NULL,
  `cep_endereco` varchar(8) NOT NULL,
  `rua_endereco` varchar(150) NOT NULL,
  `logradouro_endereco` varchar(150) NOT NULL,
  `numero_endereco` int NOT NULL,
  PRIMARY KEY (`id_endereco`)
);


CREATE TABLE `funcionario` (
  `id_funcionario` int AUTO_INCREMENT NOT NULL,
  `nome_funcionario` varchar(150) NOT NULL,
  `cpf_funcionario` varchar(11) NOT NULL,
  `salario_funcionario` decimal(10,2) NOT NULL,
  `data_efetivacao_funcionario` date NOT NULL,
  `data_nascimento` date NOT NULL,
  PRIMARY KEY (`id_funcionario`),
  UNIQUE KEY `cpf_funcionario_UNIQUE` (`cpf_funcionario`)
);


CREATE TABLE `interacao_cliente` (
  `id_interacao` int(11) NOT NULL AUTO_INCREMENT,
  `id_funcionario` int(11) NOT NULL,
  `id_cliente` int(11) NOT NULL,
  `transcricao_interacao` text NOT NULL,
  `data_interacao` date NOT NULL,
  `id_tipo` int(11) NOT NULL,
  PRIMARY KEY (`id_interacao`),
  KEY `fk_funcionario_interacao_idx` (`id_funcionario`),
  KEY `fk_cliente_interacao_idx` (`id_cliente`),
  KEY `id_tipo` (`id_tipo`),
  CONSTRAINT `fk_cliente_interacao` FOREIGN KEY (`id_cliente`) REFERENCES `cliente` (`id_cliente`),
  CONSTRAINT `fk_funcionario_interacao` FOREIGN KEY (`id_funcionario`) REFERENCES `funcionario` (`id_funcionario`),
  CONSTRAINT `interacao_cliente_ibfk_1` FOREIGN KEY (`id_tipo`) REFERENCES `tipo_interacao` (`id_tipo`)
);


CREATE TABLE `item_compra` (
  `id_item` int(11) AUTO_INCREMENT NOT NULL,
  `id_compra` int(11) NOT NULL,
  `id_preco_produto` int(11) NOT NULL,
  `quantidade_item` int(11) NOT NULL,
  `sub_total` decimal(10,2) NOT NULL,
  `id_produto` int(11) NOT NULL,
  PRIMARY KEY (`id_item`),
  KEY `fk_compra_item_idx` (`id_compra`),
  KEY `fk_precoProduto_item_idx` (`id_preco_produto`),
  KEY `fk_produto_itemCompra` (`id_produto`),
  CONSTRAINT `fk_compra_item` FOREIGN KEY (`id_compra`) REFERENCES `compra` (`id_compra`),
  CONSTRAINT `fk_precoProduto_item` FOREIGN KEY (`id_preco_produto`) REFERENCES `preco_produto` (`id_preco_produto`),
  CONSTRAINT `fk_produto_itemCompra` FOREIGN KEY (`id_produto`) REFERENCES `preco_produto` (`id_produto`)
);


CREATE TABLE `preco_produto` (
  `id_preco_produto` int AUTO_INCREMENT NOT NULL,
  `id_produto` int NOT NULL,
  `preco_produto` decimal(10,2) NOT NULL,
  `data_aplicacao` date NOT NULL,
  PRIMARY KEY (`id_preco_produto`),
  KEY `fk_produto_precoProduto_idx` (`id_produto`),
  CONSTRAINT `fk_produto_precoProduto` FOREIGN KEY (`id_produto`) REFERENCES `produto` (`id_produto`) ON DELETE RESTRICT ON UPDATE RESTRICT
);


CREATE TABLE `produto` (
  `id_produto` int(11) NOT NULL AUTO_INCREMENT,
  `nome_produto` varchar(150) NOT NULL,
  `estoque_produto` int(11) NOT NULL,
  `id_categoria` int(11) NOT NULL,
  `id_status` int(11) NOT NULL,
  `estoque_minimo_produto` int(11) NOT NULL,
  PRIMARY KEY (`id_produto`),
  KEY `fk_categoria_produto_idx` (`id_categoria`),
  KEY `fk_status_produto_idx` (`id_status`),
  CONSTRAINT `fk_categoria_produto` FOREIGN KEY (`id_categoria`) REFERENCES `categoria` (`id_categoria`),
  CONSTRAINT `fk_status_produto` FOREIGN KEY (`id_status`) REFERENCES `status` (`id_status`)
);


CREATE TABLE `segmentacao_cliente` (
  `id_cliente` int NOT NULL,
  `id_categoria` int NOT NULL,
  PRIMARY KEY (`id_cliente`,`id_categoria`),
  KEY `fk_categoria_segmentacaoCliente_idx` (`id_categoria`),
  CONSTRAINT `fk_categoria_segmentacaoCliente` FOREIGN KEY (`id_categoria`) REFERENCES `categoria` (`id_categoria`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_cliente_segmentacaoCliente` FOREIGN KEY (`id_cliente`) REFERENCES `cliente` (`id_cliente`) ON DELETE RESTRICT ON UPDATE RESTRICT
);


CREATE TABLE `status` (
  `id_status` int AUTO_INCREMENT NOT NULL,
  `nome_status` varchar(50) NOT NULL,
  PRIMARY KEY (`id_status`)
);


CREATE TABLE `tarefa` (
  `id_tarefa` int AUTO_INCREMENT NOT NULL,
  `id_funcionario` int NOT NULL,
  `nome_tarefa` varchar(150) NOT NULL,
  `descricao_tarefa` varchar(300) NOT NULL,
  `data_inicio_tarefa` date NOT NULL,
  `data_fim_tarefa` date DEFAULT NULL,
  `id_status` int DEFAULT NULL,
  PRIMARY KEY (`id_tarefa`),
  KEY `fk_funcionario_tarefa_idx` (`id_funcionario`),
  KEY `fk_status_tarefa_idx` (`id_status`),
  CONSTRAINT `fk_funcionario_tarefa` FOREIGN KEY (`id_funcionario`) REFERENCES `funcionario` (`id_funcionario`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_status_tarefa` FOREIGN KEY (`id_status`) REFERENCES `status` (`id_status`) ON DELETE RESTRICT ON UPDATE RESTRICT
);


CREATE TABLE `historico` (
	`id_historico` INT AUTO_INCREMENT NOT NULL,
    `tipo_acao` VARCHAR(50) NOT NULL,
    `id_compra` INT NOT NULL,
    `id_item` INT,
    `data_registro` DATETIME NOT NULL,
    
    PRIMARY KEY(`id_historico`),
    CONSTRAINT `fk_compra_historico` FOREIGN KEY(`id_compra`) REFERENCES `compra`(`id_compra`)
		ON DELETE RESTRICT
        ON UPDATE RESTRICT,
	CONSTRAINT `fk_item_historico` FOREIGN KEY(`id_item`) REFERENCES `item_compra`(`id_item`)
		ON DELETE RESTRICT
        ON UPDATE RESTRICT
);

/*
SELECTS
*/
SELECT * FROM `projeto_final`.`categoria`;

SELECT * FROM `projeto_final`.`cliente`;

SELECT * FROM `projeto_final`.`compra`;

SELECT * FROM `projeto_final`.`endereco`;

SELECT * FROM `projeto_final`.`funcionario`;

SELECT * FROM `projeto_final`.`historico`;

SELECT * FROM `projeto_final`.`interacao_cliente`;

SELECT * FROM `projeto_final`.`item_compra`;

SELECT * FROM `projeto_final`.`preco_produto`;

SELECT * FROM `projeto_final`.`produto`;

SELECT * FROM `projeto_final`.`segmentacao_cliente`;

SELECT * FROM `projeto_final`.`status`;

SELECT * FROM `projeto_final`.`tarefa`;

SELECT * FROM `projeto_final`.`tipo_interacao`;


/*
VIEWS
*/


/*
ALTER TABLES
*/

ALTER TABLE `item_compra`
	ADD COLUMN `id_produto` INT NOT NULL,
    ADD CONSTRAINT `fk_produto_itemCompra` FOREIGN KEY (`id_produto`) REFERENCES `preco_produto`(`id_produto`)
		ON DELETE RESTRICT
        ON UPDATE RESTRICT;
        
ALTER TABLE `interacao_cliente`
	ADD COLUMN `id_tipo` INT NOT NULL,
    
    ADD CONSTRAINT FOREIGN KEY(`id_tipo`) REFERENCES `tipo_interacao`(`id_tipo`)
		ON DELETE RESTRICT
		ON UPDATE RESTRICT;
        
ALTER TABLE `produto`
	ADD COLUMN `estoque_minimo_produto` INT NOT NULL,
    CHANGE COLUMN `quantidade_produto` `estoque_produto` INT NOT NULL;
/*
UPDATES
*/


/*
INSERTS
*/

INSERT INTO categoria (id_categoria, nome_categoria) VALUES 
(1, 'Eletrônicos'),
(2, 'Roupas'),
(3, 'Alimentos'),
(4, 'Móveis');

INSERT INTO tipo_interacao (id_tipo, nome_tipo) VALUES 
(1, 'Reclamação'),
(2, 'Elogio'),
(3, 'Dúvida'),
(4, 'Sugestão');

INSERT INTO endereco (id_endereco, cep_endereco, rua_endereco, logradouro_endereco, numero_endereco) VALUES 
(1, '12345678', 'Rua A', 'Bairro Centro', 101),
(2, '23456789', 'Rua B', 'Bairro Sul', 202),
(3, '34567890', 'Rua C', 'Bairro Norte', 303),
(4, '45678901', 'Rua D', 'Bairro Leste', 404);

INSERT INTO cliente (id_cliente, nome_cliente, cpf_cliente, id_endereco, data_nascimento, data_cadastro_cliente, email_cliente) VALUES 
(1, 'João Silva', '11111111111', 1, '1990-01-01', '2024-12-01', 'joao@email.com'),
(2, 'Maria Oliveira', '22222222222', 2, '1985-05-05', '2024-12-02', 'maria@email.com'),
(3, 'Carlos Santos', '33333333333', 3, '1995-07-15', '2024-12-03', 'carlos@email.com'),
(4, 'Ana Costa', '44444444444', 4, '2000-03-25', '2024-12-04', 'ana@email.com');

INSERT INTO compra (id_compra, id_cliente, total_compra) VALUES 
(1, 1, 200),
(2, 2, 450),
(3, 3, 120),
(4, 4, 350);

INSERT INTO funcionario (id_funcionario, nome_funcionario, cpf_funcionario, salario_funcionario, data_efetivacao_funcionario, data_nascimento) VALUES 
(1, 'Pedro Almeida', '55555555555', 3000.50, '2020-01-01', '1980-02-01'),
(2, 'Carla Souza', '66666666666', 3500.00, '2018-03-01', '1985-06-15'),
(3, 'Luiz Barreto', '77777777777', 4000.75, '2022-05-01', '1990-09-25'),
(4, 'Sofia Mendes', '88888888888', 2800.00, '2019-07-01', '1995-11-10');

INSERT INTO produto (id_produto, nome_produto, estoque_produto, id_categoria, id_status, estoque_minimo_produto) VALUES 
(1, 'Notebook', 50, 1, 1, 10),
(2, 'Camiseta', 100, 2, 1, 20),
(3, 'Arroz', 200, 3, 1, 30),
(4, 'Sofá', 15, 4, 1, 5);

INSERT INTO preco_produto (id_preco_produto, id_produto, preco_produto, data_aplicacao) VALUES 
(1, 1, 3500.00, '2024-12-01'),
(2, 2, 50.00, '2024-12-01'),
(3, 3, 20.00, '2024-12-01'),
(4, 4, 1500.00, '2024-12-01');

INSERT INTO interacao_cliente (id_funcionario, id_cliente, transcricao_interacao, data_interacao, id_tipo) VALUES 
(1, 1, 'Cliente reclamou sobre atraso na entrega.', '2024-12-01', 1),
(2, 2, 'Cliente elogiou o atendimento.', '2024-12-02', 2),
(3, 3, 'Cliente perguntou sobre prazo de garantia.', '2024-12-03', 3),
(4, 4, 'Cliente sugeriu melhoria no site.', '2024-12-04', 4);

INSERT INTO item_compra (id_compra, id_preco_produto, quantidade_item, sub_total, id_produto) VALUES 
(1, 1, 1, 3500.00, 1),
(2, 2, 3, 150.00, 2),
(3, 3, 10, 200.00, 3),
(4, 4, 1, 1500.00, 4);

INSERT INTO segmentacao_cliente (id_cliente, id_categoria) VALUES 
(1, 1),
(2, 2),
(3, 3),
(4, 4);

INSERT INTO `status` (id_status, nome_status) VALUES 
(1, 'Ativo'),
(2, 'Inativo'),
(3, 'Em Manutenção'),
(4, 'Suspenso');

INSERT INTO tarefa (id_funcionario, nome_tarefa, descricao_tarefa, data_inicio_tarefa, data_fim_tarefa, id_status) VALUES 
(1, 'Organizar Estoque', 'Reorganizar o estoque do armazém principal.', '2024-12-01', '2024-12-03', 1),
(2, 'Atualizar Site', 'Incluir novos produtos no site.', '2024-12-02', '2024-12-04', 1),
(3, 'Realizar Treinamento', 'Treinar novos funcionários.', '2024-12-05', NULL, 1),
(4, 'Manutenção de Equipamentos', 'Verificar e reparar computadores.', '2024-12-06', NULL, 2);

/*
DELETES
*/
DELETE FROM `projeto_final`.`categoria`;

DELETE FROM `projeto_final`.`cliente`;

DELETE FROM `projeto_final`.`compra`;

DELETE FROM `projeto_final`.`endereco`;

DELETE FROM `projeto_final`.`funcionario`;

DELETE FROM `projeto_final`.`historico`;

DELETE FROM `projeto_final`.`interacao_cliente`;

DELETE FROM `projeto_final`.`item_compra`;

DELETE FROM `projeto_final`.`preco_produto`;

DELETE FROM `projeto_final`.`produto`;

DELETE FROM `projeto_final`.`segmentacao_cliente`;

DELETE FROM `projeto_final`.`status`;

DELETE FROM `projeto_final`.`tarefa`;

DELETE FROM `projeto_final`.`tipo_interacao`;


COMMIT;
