# Report Service

Microsserviço Rails responsável por analisar diagramas de arquitetura de software usando IA (Google Gemini). Consome eventos do RabbitMQ, processa arquivos (PDF ou imagem) e persiste o resultado estruturado no banco de dados.

## Visão Geral

```
RabbitMQ (reports_queue) → ReportWorker → [Análise com Gemini] → Salva resultado no PostgreSQL
```

O payload consumido da fila segue o formato:

```json
{
  "document_id": "<uuid>",
  "file_url": "<url-assinada>",
  "filename": "diagrama.pdf"
}
```

## Tecnologias

| Componente     | Tecnologia                   |
|----------------|------------------------------|
| Linguagem      | Ruby 3.3.9                   |
| Framework      | Rails 7.2 (API mode)         |
| Banco de dados | PostgreSQL                   |
| Mensageria     | RabbitMQ (gem Sneakers)      |
| IA             | Google Gemini 2.5 Flash      |
| Contêiner      | Docker                       |

## Endpoints

### `GET /reports`

Retorna todos os relatórios em ordem decrescente de criação.

**Resposta de sucesso `200 OK`:**
```json
[
  {
    "id": "uuid",
    "document_id": "uuid",
    "document_name": "diagrama.pdf",
    "status": "completed",
    "result": {},
    "created_at": "...",
    "updated_at": "..."
  }
]
```

---

### `GET /reports/:document_id`

Retorna um relatório específico pelo `document_id`.

**Resposta de sucesso `200 OK`:**
```json
{
  "id": "uuid",
  "document_id": "uuid",
  "document_name": "diagrama.png",
  "status": "completed",
  "result": {
    "summary": "Descrição da arquitetura...",
    "risks": ["Risco 1", "Risco 2"],
    "recommendations": ["Recomendação 1"],
    "confidence": "alta",
    "generated_at": "2026-05-21T..."
  }
}
```

**Resposta de erro `404 Not Found`:**
```json
{ "error": "Relatório não encontrado para o document_id informado" }
```

## Variáveis de Ambiente

| Variável           | Descrição                                      |
|--------------------|------------------------------------------------|
| `DATABASE_URL`     | URL de conexão com o PostgreSQL                |
| `RABBITMQ_URL`     | URL de conexão com o RabbitMQ                  |
| `GEMINI_API_KEY`   | Chave de API do Google Gemini                  |
| `RAILS_MASTER_KEY` | Chave mestra do Rails (produção)               |

## Estrutura Principal

```
app/
├── controllers/
│   └── reports_controller.rb        # Endpoints de consulta de relatórios
├── models/
│   └── report.rb                    # Model com status e resultado da análise
├── workers/
│   └── report_worker.rb             # Consome mensagens do RabbitMQ
└── services/
    └── report_analyzer/
        ├── orchestrator.rb          # Coordena o pipeline de análise
        ├── file_processor.rb        # Extrai texto (PDF) ou bytes (imagem)
        ├── prompt_builder.rb        # Monta o prompt para o Gemini
        ├── ai_client.rb             # Chama a API Gemini 2.5 Flash
        ├── output_validator.rb      # Valida o JSON retornado
        └── report_formatter.rb      # Normaliza o resultado final
```

## Executando com Docker

```shell
docker build -t report-service .
docker run -p 3000:3000 \
  -e RAILS_MASTER_KEY=<chave> \
  -e DATABASE_URL=<url> \
  -e RABBITMQ_URL=amqp://guest:guest@rabbitmq:5672 \
  -e GEMINI_API_KEY=<chave> \
  report-service
```

## Desenvolvimento Local

```shell
# Instalar dependências
bundle install

# Criar e migrar o banco
bin/rails db:create db:migrate

# Iniciar o servidor HTTP
bin/rails server

# Iniciar o worker RabbitMQ (em outro terminal)
WORKERS=ReportWorker bundle exec rake sneakers:run
```

## Testes

```shell
bundle exec rspec
```

Cobertura de testes gerada em `coverage/index.html`.
