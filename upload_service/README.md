# Upload Service

Microsserviço Rails responsável pelo upload de documentos. Armazena arquivos no MinIO (compatível com S3) via Active Storage e publica eventos no RabbitMQ para processamento assíncrono por outros serviços.

## Visão Geral

```
Cliente → POST /documents → [Salva no PostgreSQL + MinIO] → Publica em reports_queue (RabbitMQ)
```

Após o upload, o payload publicado na fila contém:

```json
{
  "document_id": "<uuid>",
  "file_url": "<url-assinada-15min>",
  "filename": "documento.pdf"
}
```

## Tecnologias

| Componente      | Tecnologia                      |
|-----------------|---------------------------------|
| Linguagem       | Ruby 3.3.9                      |
| Framework       | Rails 7.2 (API mode)            |
| Banco de dados  | PostgreSQL                      |
| Armazenamento   | MinIO / AWS S3 (Active Storage) |
| Mensageria      | RabbitMQ (gem Bunny)            |
| Contêiner       | Docker                          |

## Endpoints

### `POST /documents`

Faz o upload de um novo documento.

**Parâmetros (multipart/form-data):**

| Campo   | Tipo   | Descrição             |
|---------|--------|-----------------------|
| `title` | string | Título do documento   |
| `file`  | file   | Arquivo a ser enviado |

**Resposta de sucesso `201 Created`:**
```json
{
  "message": "Upload realizado e enviado para processamento.",
  "document_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Resposta de erro `422 Unprocessable Entity`:**
```json
{
  "errors": ["..."]
}
```

---

### `GET /documents/:document_id`

Recupera os dados de um documento pelo ID.

**Resposta de sucesso `200 OK`:**
```json
{
  "document_id": "550e8400-e29b-41d4-a716-446655440000",
  "file_url": "https://...",
  "filename": "documento.pdf"
}
```

## Variáveis de Ambiente

| Variável            | Padrão              | Descrição                         |
|---------------------|---------------------|-----------------------------------|
| `POSTGRES_USER`     | `postgres`          | Usuário do banco de dados         |
| `POSTGRES_PASSWORD` | `password123`       | Senha do banco de dados           |
| `POSTGRES_HOST`     | `db_upload`         | Host do banco de dados            |
| `RAILS_MAX_THREADS` | `5`                 | Número máximo de threads do Puma  |
| `MINIO_ACCESS_KEY`  | `minioadmin`        | Access key do MinIO               |
| `MINIO_SECRET_KEY`  | `minioadmin`        | Secret key do MinIO               |
| `MINIO_ENDPOINT`    | `http://minio:9000` | Endpoint do MinIO                 |
| `RABBITMQ_URL`      | —                   | URL de conexão com o RabbitMQ     |
| `RAILS_MASTER_KEY`  | —                   | Chave mestra do Rails (produção)  |

## Estrutura Principal

```
app/
├── controllers/
│   └── documents_controller.rb   # Endpoints de upload e consulta
├── models/
│   └── document.rb               # Model com anexo via Active Storage
└── services/
    └── rabbit_mq_publisher.rb    # Publica mensagens no RabbitMQ
```

## Executando com Docker

```bash
docker build -t upload-service .
docker run -p 3000:3000 \
  -e RAILS_MASTER_KEY=<chave> \
  -e POSTGRES_HOST=<host> \
  -e POSTGRES_USER=<usuario> \
  -e POSTGRES_PASSWORD=<senha> \
  -e RABBITMQ_URL=amqp://guest:guest@rabbitmq:5672 \
  -e MINIO_ENDPOINT=http://minio:9000 \
  upload-service
```

## Desenvolvimento Local

```bash
# Instalar dependências
bundle install

# Criar e migrar o banco
bin/rails db:create db:migrate

# Iniciar o servidor
bin/rails server
```

## Testes

```bash
bundle exec rspec
```

Cobertura de testes gerada em `coverage/index.html`.
