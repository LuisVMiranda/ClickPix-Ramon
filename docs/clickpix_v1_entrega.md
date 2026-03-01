# ClickPix Ramon V1 — Entrega Técnica

## 1) Documento de Arquitetura
### 1.1 Decisões principais
- **Mobile:** Flutter (Android-first) + Riverpod + Drift (SQLite) + WorkManager.
- **Backend:** Firebase (Auth, Firestore, Storage, Functions) para reduzir time-to-market.
- **Pagamentos:** camada de abstração `PaymentProvider` com Mercado Pago (PIX/cartão) e PayPal.
- **Entrega:** portal web em Firebase Hosting com validação de código de 6 dígitos por hash.
- **Offline-first:** pedido e CRM local no Drift, sincronização eventual com fila resiliente.

### 1.2 Trade-offs
- **Firebase vs backend próprio:** Firebase acelera MVP, porém cria lock-in moderado.
- **Upload pós-pagamento:** economiza dados/bateria; risco: atraso na entrega se rede ruim.
- **WhatsApp via deep link:** confiável/legal no V1, mas não totalmente automático.
- **Importação por pasta/share/manual:** maior compatibilidade; sem SDKs de fabricante no V1.

### 1.3 Fluxo macro
Importar/selecionar → criar pedido local → checkout → webhook confirma → app atualiza status → upload em fila → gera acesso e entrega via WhatsApp/email.

## 2) Backlog detalhado
### Épico A — Fundação mobile e domínio
- **História A1:** Como fotógrafo, quero ver últimas fotos rápido.
  - Implementar `ImportService` (folder scan/share/manual).
  - Criar cache de thumbnails e filtros 10/30/60 min.
  - Tela Atendimento Rápido alto contraste.
- **História A2:** Como fotógrafo, quero criar pedido em segundos.
  - Entidades de domínio (`Client`, `PhotoAsset`, `Order`).
  - Carrinho com pacotes e desconto automático.
  - Watermark configurável (JPG/JPEG/PNG/SVG/BMP) nos previews.

### Épico B — Pagamentos
- **História B1:** PIX com QR + copia e cola.
  - `PaymentProvider.createPixIntent`.
  - UI com estado em tempo quase real.
- **História B2:** Cartão + PayPal.
  - `PaymentProvider.createCardIntent` e `createPayPalIntent`.
  - Persistir `externalReference` único.

### Épico C — Backend e entrega
- **História C1:** Confirmar pagamento via webhook.
  - Functions idempotentes por `externalReference`.
  - Atualizar status no Firestore.
- **História C2:** Entregar galeria com código.
  - Gerar código 6 dígitos com RNG seguro.
  - Persistir hash (argon2/bcrypt), expiração configurável.
  - Renovação de código com auditoria.

### Épico D — Portal cliente
- Validação de código, listagem de arquivos, download com URL assinada.

### Épico E — Observabilidade e hardening
- Crashlytics + logs estruturados sem PII.
- Testes unitários backend e domínio + widget test checkout.

## 3) Especificação de dados
### 3.1 Drift (SQLite local)
- `clients(id PK, name, whatsapp, email?, created_at INDEX)`
- `photo_assets(id PK, local_path, thumbnail_key INDEX, captured_at INDEX, checksum UNIQUE, upload_status, storage_path?)`
- `orders(id PK, client_id INDEX, created_at INDEX, total_amount, currency, status INDEX, payment_method, external_reference UNIQUE, provider_data_json, gallery_id?, access_code_expires_at?, delivered_at?)`
- `order_items(order_id INDEX, photo_asset_id INDEX, price_cents, PRIMARY KEY(order_id, photo_asset_id))`
- `app_settings(id=singleton, code_expiration_days, wifi_only_upload, locale, watermark_path?, watermark_enabled)`

### 3.2 Firestore
- `orders/{orderId}`
  - status, externalReference (indexed), paymentMethod, totalAmount, createdAt, updatedAt
  - delivery: galleryId, accessCodeHash, accessCodeExpiresAt, deliveredAt
- `clients/{clientId}`
- `galleries/{galleryId}`: orderId, storagePrefix, expiresAt
- `payment_events/{providerEventId}` para idempotência

### 3.3 Índices Firestore
- `orders`: `externalReference ASC` (único lógico)
- `orders`: `status ASC, createdAt DESC`
- `orders`: `clientId ASC, createdAt DESC`

## 4) Especificação de APIs / Functions
- `POST /payments/webhook/mercadopago`
  - Entrada: payload do provedor
  - Ação: validar assinatura, mapear status, atualizar `orders`
- `POST /payments/webhook/paypal`
- `POST /orders/{orderId}/generate-access-code`
  - Input: `{ expirationDays }`
  - Output: `{ maskedCode, expiresAt }` (código claro só em memória de envio)
- `POST /portal/validate-access`
  - Input: `{ galleryId, code }`
  - Output: `{ valid, files[] }`
- `POST /orders/{orderId}/renew-code`

Estados de pedido:
`Created -> AwaitingPayment -> Paid -> Delivering -> Delivered -> Expired`
Ramos: `Refunded | Canceled`.

## 5) Esqueleto do repositório e padrões
```text
mobile_flutter/
  lib/
    app/
    core/i18n/
    data/local/
    domain/entities/
    domain/value_objects/
    presentation/
  test/
functions/
  src/orders/
  src/payments/
  src/shared/
  test/
portal_web/
docs/
```
Padrões:
- Camadas limpas: presentation -> domain -> data.
- Sem texto hardcoded na UI; usar `AppLocalizations`.
- Casos de uso puros para transição de status e regras de código.

## 6) Código inicial (skeleton)
Arquivos no repositório:
- Flutter com i18n PT/EN/ES e fluxo mock galeria→pedido→pagamento→entrega.
- Drift com tabelas principais.
- Functions skeleton webhook/gerar/validar código.
- Portal web skeleton para validar código e listar mock.

## 7) Checklist de segurança e LGPD
- [x] Código de acesso armazenado só como hash.
- [x] Expiração configurável e renovação auditável.
- [x] Logs sem código em claro/sem dados sensíveis.
- [x] Segredos em env/Secret Manager.
- [x] Minimização de dados pessoais no CRM.
- [x] Consentimento e justificativa de permissões Android.
- [x] Links de download com expiração.

## 8) Critérios de aceite (resumo)
- Importação via ao menos 1 método funcional (pasta/share/manual).
- Seleção de fotos e criação de pedido local offline.
- PIX com QR + copia e cola (sandbox) e 1 método adicional.
- Confirmação por webhook + atualização em quase tempo real.
- Geração de galeria + código 6 dígitos expirável.
- Entrega por WhatsApp deep link e email (auto/fallback).
- Portal valida código e libera download.
