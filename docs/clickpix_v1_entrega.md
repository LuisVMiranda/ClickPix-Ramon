# ClickPix Ramon V1 — Plano de Implementação Incremental (Executável)

> **Objetivo deste documento:** transformar o escopo do V1 em passos pequenos, verificáveis e com baixo risco de alucinação durante implementação.
> 
> **Fonte de verdade:** seu prompt inicial + limitações explícitas do MVP.

## 1) Escopo consolidado (sem extrapolar)
### 1.1 O que entra no V1
1. Importação/ingestão de fotos por **(A) Pasta de Entrada**, **(B) Compartilhar para o app**, **(C) Importação manual**.
2. Galeria de atendimento rápida (últimas fotos, filtros por tempo, thumbnails, seleção).
3. Checkout com **PIX (QR + copia e cola)**, **cartão (crédito/débito)** e **PayPal**.
4. Confirmação quase real-time (webhook + snapshot, com polling fallback).
5. Entrega por código de 6 dígitos com hash + expiração configurável.
6. Comunicação com cliente por WhatsApp (deep link) e e-mail (transacional/fallback).
7. CRM local + modo offline + sincronização posterior.
8. Configurações admin (idioma, validade, Wi‑Fi only, dados do fotógrafo, exportação).
9. MUST HAVE 2: watermark configurável em previews, pacotes e descontos, tela de alto contraste.

### 1.2 O que NÃO entra no V1 (manter fora)
- Edição avançada de fotos.
- Marketplace público.
- Integração nativa profunda com SDK Canon/Nikon/Sony.
- Automação invisível de WhatsApp sem API Business.

## 2) Arquitetura-alvo e decisões de implementação
### 2.1 Mobile (Flutter Android-first)
- Camadas: `presentation -> domain -> data`.
- Estado: Riverpod.
- Local DB: Drift/SQLite com índices de consulta rápida.
- Execução em background: WorkManager para sync/upload.
- i18n obrigatório via ARB (PT-BR default, EN, ES com fallback PT-BR).

### 2.2 Backend (Firebase)
- Firestore: pedidos, clientes, metadados de fotos, status de pagamento, auditoria.
- Functions: webhooks de pagamento, geração/validação de código, renovação, sincronização de estado.
- Storage: armazenar entregáveis por galeria (`storagePrefix`).
- Hosting + Functions: portal do cliente (link + código).

### 2.3 Pagamentos (abstração)
- Interface única `PaymentProvider`.
- Implementações: Mercado Pago (PIX/cartão) e PayPal.
- Saída convergente: `PaymentIntent` + eventos internos de status.
- `externalReference` único e indexado para conciliação.

## 3) Plano incremental mestre (macro)

## Fase 0 — Preparação e contratos (1 sprint curta)
**Objetivo:** eliminar ambiguidade antes de codar fluxo.

**Entregáveis:**
- Contrato de estados de pedido (`Created`, `AwaitingPayment`, `Paid`, `Delivering`, `Delivered`, `Expired`, `Refunded`, `Canceled`).
- Contrato dos DTOs principais (`Client`, `PhotoAsset`, `Order`, `Gallery`, `PaymentIntent`).
- Definição padrão de `externalReference`: `PFBR-{yyyyMMdd}-{orderShortId}-{random}`.

**Checklist de pronto:**
- [ ] Máquina de estados documentada e testada unitariamente.
- [ ] Regras de idempotência por `externalReference` e `providerEventId` aprovadas.

---

## Fase 1 — Fundação do app (Android-first + i18n + offline base)
**Objetivo:** aplicativo com base estável, local-first e multilíngue.

**Plano de ação executável (passo a passo):**
1. Criar `AppShell` com troca de idioma em runtime (PT/EN/ES).
2. Implementar Drift com tabelas: `clients`, `photo_assets`, `orders`, `order_items`, `app_settings`.
3. Adicionar repositórios locais + casos de uso para CRUD mínimo de cliente/pedido.
4. Implementar tela **Atendimento Rápido** com alto contraste e botões grandes.
5. Implementar modo Sol (fonte maior + contraste elevado).

**Critérios de aceite da fase:**
- [ ] App abre em PT-BR por padrão.
- [ ] Idioma muda sem reinstalar.
- [ ] É possível criar cliente e pedido sem internet.

---

## Fase 2 — Ingestão de fotos + galeria rápida
**Objetivo:** entrada de fotos robusta com performance.

**Plano de ação executável:**
1. Implementar método A (Pasta de Entrada) com varredura incremental por timestamp/checksum.
2. Implementar método C (seletor manual) via API moderna de picker.
3. Implementar método B (Share target) para receber arquivos externos.
4. Gerar thumbnails locais com cache e lazy loading.
5. Filtros rápidos: últimas 10/30/60 min.

**NFR de validação da fase:**
- [ ] Abertura “Últimas fotos” < 1,5s em device intermediário (amostra local).
- [ ] Scroll sem travamento perceptível.
- [ ] Sem decode full-res em lista.

---

## Fase 3 — Carrinho, pacotes, desconto e watermark
**Objetivo:** transformar seleção em pedido vendável.

**Plano de ação executável:**
1. Criar composição de pacotes (1/5/10 fotos) configuráveis no admin.
2. Aplicar desconto automático por pacote.
3. Implementar preview com watermark configurável (adicionar/alterar/remover).
4. Restringir watermark aos formatos permitidos: JPG/JPEG/PNG/SVG/BMP.
5. Persistir configurações em `app_settings`.

**Critérios de aceite da fase:**
- [ ] Total do pedido reflete pacote + desconto.
- [ ] Preview exibe watermark antes do pagamento.
- [ ] Admin consegue alterar a marca d’água sem recompilar app.

---

## Fase 4 — Checkout e pagamentos
**Objetivo:** cobrança real com rastreabilidade.

**Plano de ação executável:**
1. Criar interface `PaymentProvider` e adapters (Mercado Pago / PayPal).
2. Implementar fluxo PIX com QR dinâmico + copia e cola (1 toque).
3. Implementar cartão (crédito/débito) pelo mesmo provider quando possível.
4. Implementar PayPal alternativo.
5. Persistir `externalReference` único e metadados mínimos de provider.

**Critérios de aceite da fase:**
- [ ] Pedido entra em `AwaitingPayment` após criação do intent.
- [ ] PIX mostra QR + copia e cola.
- [ ] Existe ao menos 1 método adicional além do PIX ativo no sandbox.

---

## Fase 5 — Webhooks + confirmação quase real-time
**Objetivo:** status confiável e consistente.

**Plano de ação executável:**
1. Subir endpoints de webhook (Mercado Pago/PayPal) com validação de assinatura.
2. Tratar idempotência com coleção `payment_events`.
3. Atualizar pedido no Firestore por `externalReference`.
4. App observa status por snapshot.
5. Fallback de polling com backoff e limite temporal (economia de bateria).

**Critérios de aceite da fase:**
- [ ] Webhook duplicado não duplica efeito.
- [ ] App reflete `Paid` sem refresh manual na maioria dos casos.
- [ ] Polling só ativa em falha de webhook/snapshot.

---

## Fase 6 — Entrega automática (galeria + código)
**Objetivo:** pós-pagamento com mínimo atrito.

**Plano de ação executável:**
1. Ao confirmar pagamento, enfileirar upload (WorkManager).
2. Criar `galleryId` + `storagePrefix` por pedido.
3. Gerar código de 6 dígitos com RNG criptográfico.
4. Bloquear padrões triviais (ex.: 000000, 123456).
5. Armazenar somente hash + `expiresAt` configurável.
6. Implementar renovação do código (novo código invalida anterior).

**Critérios de aceite da fase:**
- [ ] Acesso expira em X dias configurado no admin.
- [ ] Código nunca é persistido em texto puro no backend.
- [ ] Renovação auditável.

---

## Fase 7 — Comunicação (WhatsApp + e-mail)
**Objetivo:** entrega assistida e rápida no atendimento.

**Plano de ação executável:**
1. Template de mensagem i18n com Focus-Flow (curta + link/código).
2. Botão WhatsApp via `wa.me` com texto pré-preenchido.
3. Envio de e-mail transacional (ou intent fallback).
4. Botões “copiar link” e “copiar código” na tela de entrega.

**Limites explícitos do V1:**
- WhatsApp exige ação final do usuário para envio quando via app comum.

---

## Fase 8 — CRM, histórico, estatísticas e exportação
**Objetivo:** operação diária e visão de negócio.

**Plano de ação executável:**
1. Tela CRM/histórico com filtros por data/status/método.
2. Métricas V1: receita, pedidos pagos, ticket médio, conversão.
3. Gráficos leves (sem animação pesada).
4. Exportação local CSV/JSON + backup opcional em nuvem.

---

## Fase 9 — Portal do cliente + hardening
**Objetivo:** fechar ponta web com segurança mínima adequada ao V1.

**Plano de ação executável:**
1. Página responsiva com input de código.
2. Endpoint `validate-access` valida hash + expiração.
3. Listagem de fotos por `galleryId`.
4. Download via URL assinada/temporária.
5. Rate limit básico + logs de tentativa sem dados sensíveis.

**Critérios de aceite da fase:**
- [ ] Link abre em celular comum sem login.
- [ ] Código inválido/expirado retorna mensagem clara.
- [ ] Download funcional para códigos válidos.

## 4) Microplanos executáveis (anti-alucinação)

## Microplano A — “1 tarefa por commit”
- Commit 1: modelo de dados + migração Drift.
- Commit 2: i18n e troca de idioma.
- Commit 3: galeria com filtro e seleção.
- Commit 4: carrinho/pacotes/desconto.
- Commit 5: PIX UI (QR + copia e cola).
- Commit 6: webhook + sincronização de status.
- Commit 7: código 6 dígitos (hash + expiração).
- Commit 8: entrega WhatsApp/e-mail.
- Commit 9: portal validação + download.

## Microplano B — “Definição de pronto por PR”
Cada PR deve conter:
1. Escopo fechado (somente 1 fatia de valor).
2. Testes mínimos da fatia.
3. Evidência funcional (log/screenshot quando UI perceptível).
4. Atualização de documentação da fatia.

## Microplano C — “Sequência para você executar manualmente”
1. Rodar app e validar idioma.
2. Importar fotos por 1 método ativo.
3. Criar pedido e aplicar pacote.
4. Simular pagamento sandbox.
5. Confirmar transição de status.
6. Gerar código e validar expiração.
7. Abrir portal e baixar arquivo.

## 5) Especificação de dados (operacional)
### 5.1 Drift (local)
- `clients`: cadastro mínimo de CRM.
- `photo_assets`: índice por `capturedAt` e `checksum` único.
- `orders`: índice por `status`, `createdAt` e `externalReference` único.
- `order_items`: relação N:N pedido-fotos.
- `app_settings`: idioma, Wi‑Fi only, validade do código, watermark.

### 5.2 Firestore (nuvem)
- `orders/{orderId}` + subobjeto `delivery`.
- `clients/{clientId}`.
- `galleries/{galleryId}`.
- `payment_events/{providerEventId}` (idempotência).

### 5.3 Índices mínimos obrigatórios
- `orders.externalReference`.
- `orders.status + createdAt`.
- `orders.clientId + createdAt`.

## 6) Especificação de APIs/Functions (mínimo V1)
1. `POST /payments/webhook/mercadopago`
2. `POST /payments/webhook/paypal`
3. `POST /orders/{orderId}/generate-access-code`
4. `POST /orders/{orderId}/renew-code`
5. `POST /portal/validate-access`

**Regras obrigatórias:**
- Funções idempotentes.
- Código em claro não persistido.
- Estados de pedido validados por máquina de estados.

## 7) Matriz de integração (o que é automático vs manual)
- **PIX:** criação automática do intent/QR; cliente paga manualmente.
- **Cartão:** checkout guiado; autorização depende do provedor.
- **PayPal:** redirecionamento/fluxo do provedor.
- **Webhook:** automático (backend).
- **WhatsApp (wa.me):** pré-preenchimento automático + envio manual pelo operador.
- **E-mail transacional:** automático se provedor configurado; fallback manual via intent.

## 8) Plano de testes mínimo por fase
- Unit (domínio): transição de status.
- Unit (backend): geração/hash/validação de código + expiração.
- Widget (mobile): fluxo básico galeria -> pedido -> pagamento mock -> entrega mock.
- Integração (backend): webhook idempotente.

## 9) Segurança e LGPD (checklist objetivo)
- [ ] Mínimo de PII no CRM.
- [ ] Segredos somente em Secret Manager/env.
- [ ] Logs sem código de acesso, sem cartão, sem token sensível.
- [ ] Código 6 dígitos somente hash + validade.
- [ ] Permissões Android com justificativa clara e granular.
- [ ] Exportação com consentimento e escopo claro.

## 10) Critérios de aceite finais do V1
1. Importação funcional por ao menos 1 via (A/B/C).
2. Seleção + pedido + pacote/desconto.
3. PIX QR + copia e cola e pelo menos 1 método adicional.
4. Confirmação de pagamento por webhook/snapshot (sandbox aceito).
5. Geração de galeria + código 6 dígitos com expiração configurável.
6. Entrega por WhatsApp deep link e/ou e-mail.
7. Portal cliente funcional para validar código e baixar fotos.

## 11) Feedback completo do planejamento
### 11.1 Pontos fortes do plano
- Escopo está travado no que você pediu para V1 (sem features paralelas).
- Fases pequenas e verificáveis reduzem retrabalho.
- Microplanos por commit/PR diminuem risco de alucinação do agente.
- Critérios de aceite claros por fase e no fechamento do produto.

### 11.2 Riscos mapeados e mitigação
- **Risco:** integração de pagamento atrasar.
  - **Mitigação:** manter adapters isolados e validar primeiro no sandbox.
- **Risco:** performance da galeria em aparelhos médios.
  - **Mitigação:** thumbnail cache + filtro temporal + lazy loading.
- **Risco:** inconsistência de estado em falha de webhook.
  - **Mitigação:** snapshot + polling fallback com backoff.
- **Risco:** expectativa incorreta em WhatsApp.
  - **Mitigação:** UX explícita: envio final depende de toque do operador.

### 11.3 Recomendação prática de execução
- Executar exatamente na ordem das fases.
- Evitar PRs grandes (máximo 1 fatia de valor por PR).
- Só avançar de fase com checklist da fase 100% concluído.
- Registrar evidência funcional de cada etapa para facilitar validação manual.
