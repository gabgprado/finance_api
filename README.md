# Finance API

Uma API RESTful moderna para gestão de finanças pessoais, construída com **Ruby on Rails 8** e seguindo os padrões **JSON:API**.

## 🚀 Tecnologias

- **Ruby** 3.3.10
- **Rails** 8.1.2
- **PostgreSQL** 16 (Alpine)
- **Autenticação**: JWT (JSON Web Token) e BCrypt
- **Autorização**: Pundit
- **Serialização**: JSON:API (Active Model Serializers)
- **Padrão de API**: JSON:API Compliance
- **Documentação**: Rswag (Swagger UI)
- **Testes**: RSpec, FactoryBot, Shoulda Matchers
- **Infraestrutura**: Docker & Docker Compose
- **Rails 8 Built-ins**: Solid Cache, Solid Queue, Solid Cable, Thruster

## 🛠️ Configuração e Instalação

### Pré-requisitos

- [Docker](https://www.docker.com/) e [Docker Compose](https://docs.docker.com/compose/) instalados.

### Passo a passo

1. **Clone o repositório**:

   ```bash
   git clone <repo-url>
   cd finance_api
   ```

2. **Configuração de Ambiente**:
   O projeto já possui configurações padrão no `docker-compose.yml` e `docker-entrypoint.sh`. Certifique-se de que as portas `3000` (API) e `5438` (Postgres) estejam livres no seu host.

3. **Inicie a aplicação**:
   ```bash
   docker compose up server
   ```
   _Nota: O script de entrypoint cuidará automaticamente do `bundle install`, `db:create`, `db:migrate` e `db:seed` no primeiro acesso em ambiente de desenvolvimento._

## 📖 Documentação da API

A documentação interativa da API está disponível via Swagger UI. Com o servidor rodando, acesse:

[http://localhost:3000/api-docs](http://localhost:3000/api-docs)

## 🧪 Testes

Os testes são executados em um container isolado com seu próprio banco de dados e ambiente:

```bash
docker compose up test
```

Este comando executa:

1. Configuração do ambiente de teste.
2. Limpeza e migração do banco de teste.
3. Geração automática da documentação Swagger (`rswag:specs:swaggerize`).
4. Execução da suíte de testes RSpec com formato de documentação.

## 👤 Autenticação e Autorização

- **Autenticação**: JWT (Baseado em Token).
  1. Registre-se em `POST /api/v1/users`.
  2. Autentique-se em `POST /api/v1/login` para receber seu `token`.
  3. Use o header `Authorization: Bearer <seu_token>` em todas as rotas protegidas.
- **Autorização**: Pundit.
  - Um usuário só pode visualizar, editar ou excluir seus próprios dados (`Accounts` e `Categories`).

## 📁 Entidades Principais

### Contas (`Accounts`)

Representam contas bancárias ou carteiras.

- **Tipos**: `checking`, `savings`, `credit`, `investment`.
- **Atributos**: Nome, Tipo, Moeda e Saldo.

### Categorias (`Categories`)

Utilizadas para classificar transações.

- **Tipos**: `income` (Receita), `expense` (Despesa).
- **Atributos**: Nome, Tipo e Cor (Hex).
- **Categorias Iniciais**: Ao criar uma conta, as seguintes categorias são geradas automaticamente: Salário, Alimentação, Transporte, Moradia, Lazer e Saúde.

## 🚀 Próximos Passos

- Implementação de Transações (Lançamentos).
- Dashboard e Relatórios.
- Filtros avançados e busca.
