# Roteiro de Palestra — Aula Inaugural AppSec

> **Público:** Alunos ingressantes no curso de DevOps / Desenvolvimento Seguro  
> **Duração total:** ~90 minutos  
> **Formato:** Expositivo + Demo ao vivo  
> **Ambiente:** Stack rodando localmente (Docker Compose), slides abertos

---

## Estrutura da Aula

| Bloco | Tema | Tempo |
|-------|------|-------|
| 1 | Abertura e apresentação | 5 min |
| 2 | O mundo da Cybersecurity | 15 min |
| 3 | AppSec: a segurança no desenvolvimento | 15 min |
| 4 | DevSecOps: a ponte entre Dev e Sec | 10 min |
| 5 | O projeto: visão geral e arquitetura | 10 min |
| 6 | Demo ao vivo — scans e resultados | 25 min |
| 7 | O que você vai aprender neste curso | 5 min |
| 8 | Encerramento e perguntas | 5 min |

---

## Bloco 1 — Abertura e Apresentação (5 min)

### Fala sugerida
> "Bem-vindos à aula inaugural. Hoje não vamos falar de código novo, não vamos falar de framework,
> não vamos resolver um exercício. Hoje vamos conversar sobre algo que está presente em tudo que
> vocês vão construir ao longo da carreira — e que a maioria dos cursos deixa para o fim: segurança."

### Pontos a cobrir
- Apresentação pessoal e experiência na área
- Objetivo da aula: não ser exaustivo, ser provocador
- O que o aluno vai sair sabendo ao final desta aula inaugural

### Pergunta para engajar a turma
> "Quem aqui já ouviu falar de LGPD? Quem já recebeu e-mail de vazamento de dados?
> Quem nunca pensou em segurança enquanto programava?"

---

## Bloco 2 — O Mundo da Cybersecurity (15 min)

### 2.1 — Contexto e números (5 min)

**Fala sugerida:**
> "Antes de falar de código, vamos falar de contexto. O custo médio de um vazamento de dados
> em 2024 foi de **4,88 milhões de dólares** globalmente. O Brasil está entre os países com
> maior número de incidentes. Isso não é exagero — é o mercado."

**Dados para citar:**
- Relatório IBM Cost of a Data Breach 2024
- LGPD: multas de até 2% do faturamento, limite de R$ 50 milhões por infração
- Ataques ao setor de saúde cresceram 78% em 2023 (setor mais impactado no Brasil)

**Pergunta retórica:**
> "Por que estamos vendo tanto ataque? Porque nunca desenvolvemos tanta coisa tão rápido —
> e muitas vezes segurança ficou de lado."

---

### 2.2 — Os pilares: CIA Triad (5 min)

**Slide / diagrama mental:**

```
Confidencialidade   →  apenas quem deve ver, vê
Integridade         →  os dados não foram alterados sem autorização
Disponibilidade     →  o sistema funciona quando precisa
```

**Exemplos práticos para cada pilar:**

| Pilar | Ataque que viola | Exemplo real |
|-------|-----------------|--------------|
| Confidencialidade | Vazamento de dados | Dados de pacientes expostos em hospital |
| Integridade | SQL Injection, adulteração | Alteração de resultados de exames |
| Disponibilidade | DDoS, ransomware | Sistema hospitalar fora do ar |

**Fala:**
> "Quando vocês construírem qualquer sistema — uma API, um portal, um app mobile —
> devem perguntar: estou protegendo a confidencialidade? Estou garantindo a integridade?
> O sistema vai estar disponível quando precisar?"

---

### 2.3 — Tipos de ameaças e atores (5 min)

**Categorias a mencionar:**
- **Script kiddies** — usam ferramentas prontas sem entender
- **Hacktivistas** — motivação ideológica (Anonymous, etc.)
- **Cibercriminosos** — motivação financeira (ransomware, fraude)
- **APT (Advanced Persistent Threat)** — estados-nação, espionagem
- **Insider threat** — ameaças internas (funcionário mal-intencionado ou negligente)

**Fala:**
> "O atacante mais comum não é um gênio. É alguém com um script pronto que testa
> vulnerabilidades conhecidas em milhares de sistemas por segundo. Sua aplicação
> precisa estar protegida contra esse perfil — que é o mais frequente."

**Transição:**
> "E onde essas vulnerabilidades estão? Em grande parte, no código que nós mesmos escrevemos."

---

## Bloco 3 — AppSec: Segurança no Desenvolvimento (15 min)

### 3.1 — OWASP e as vulnerabilidades mais comuns (7 min)

**Fala:**
> "A OWASP — Open Web Application Security Project — é uma fundação sem fins lucrativos
> que cataloga as vulnerabilidades mais críticas em aplicações. O OWASP Top 10 é a
> referência da indústria."

**OWASP Top 10 (2021) — resumo didático:**

| # | Vulnerabilidade | Exemplo simples |
|---|----------------|----------------|
| A01 | Broken Access Control | Usuário comum acessando dados de admin |
| A02 | Cryptographic Failures | Senha salva em texto plano |
| A03 | Injection | SQL Injection: `' OR 1=1 --` |
| A04 | Insecure Design | Sistema sem validação de negócio |
| A05 | Security Misconfiguration | Porta 22 aberta publicamente |
| A06 | Vulnerable Components | Biblioteca npm com CVE crítico |
| A07 | Auth Failures | Sem limite de tentativas de login |
| A08 | Software Integrity Failures | Dependência comprometida (supply chain) |
| A09 | Logging Failures | Sem registro de acesso indevido |
| A10 | SSRF | App fazendo request para rede interna |

**Exemplo ao vivo (opcional):**
> Mostrar um formulário simples e demonstrar como um campo de texto sem validação
> pode aceitar `<script>alert(1)</script>` (XSS básico).

---

### 3.2 — Shift-Left Security (5 min)

**Slide conceitual:**

```
[TRADICIONAL]
Desenvolve → Testa → Homologa → Produção → Descobre vulnerabilidade → Volta tudo

[SHIFT-LEFT]
Sec → Desenvolve → Sec → Testa → Sec → Homologa → Produção
```

**Fala:**
> "Shift-left significa empurrar a segurança para o início do processo.
> Quanto mais tarde você descobre uma vulnerabilidade, mais cara ela é para corrigir.
> Uma falha encontrada em produção pode custar 100x mais do que a mesma falha
> encontrada durante o desenvolvimento."

**Referência:** NIST — custo relativo de correção por fase do SDLC.

---

### 3.3 — Tipos de análise de segurança (3 min)

| Sigla | Nome | O que faz | Quando roda |
|-------|------|-----------|-------------|
| SAST | Static Application Security Testing | Analisa o código-fonte | No commit / PR |
| DAST | Dynamic Application Security Testing | Ataca a aplicação em execução | Após deploy |
| SCA | Software Composition Analysis | Verifica dependências com CVEs | No commit / PR |
| Container Scan | — | CVEs nas imagens Docker | No build |

**Fala:**
> "Nenhuma dessas técnicas sozinha é suficiente. SAST não vê o que só aparece em runtime.
> DAST não vê o que está no código mas nunca é chamado. Por isso usamos todas em conjunto."

---

## Bloco 4 — DevSecOps: A Ponte (10 min)

### 4.1 — O que é DevSecOps (3 min)

**Fala:**
> "DevOps resolveu a barreira entre Desenvolvimento e Operações.
> DevSecOps traz Segurança para dentro desse ciclo — não como uma fase no final,
> mas como uma responsabilidade compartilhada e automatizada."

**Os três pilares práticos de DevSecOps:**
1. **Cultura** — segurança é responsabilidade de todos, não só do time de segurança
2. **Automação** — testes de segurança no pipeline, não apenas manuais
3. **Feedback rápido** — o desenvolvedor sabe da vulnerabilidade antes do merge

---

### 4.2 — O pipeline seguro (4 min)

**Diagrama do pipeline que construímos:**

```
git push
    │
    ▼
┌─────────────┐
│  GitHub     │
│  Actions    │
└──────┬──────┘
       │
       ├──► Testes unitários (Jest / Vitest)
       │
       ├──► SAST — SonarQube (análise estática do código)
       │
       ├──► SCA  — OWASP Dependency Check (CVEs nas libs)
       │
       ├──► Container Scan — Trivy (CVEs nas imagens Docker)
       │
       └──► DAST — OWASP ZAP (ataque à app em execução)
                │
                ▼
         ┌─────────────┐
         │  DefectDojo │  ← centraliza todos os findings
         └─────────────┘
```

**Fala:**
> "Cada push de código dispara esse pipeline. Nenhum ser humano precisa lembrar
> de rodar um scan. A segurança acontece automaticamente."

---

### 4.3 — Por que DefectDojo? (3 min)

**Fala:**
> "Cada ferramenta gera seu relatório em um formato diferente — JSON, XML, HTML.
> O DefectDojo é o agregador: ele recebe todos esses relatórios, deduplica findings,
> prioriza por severidade e cria um histórico. É o painel de controle da segurança."

**O que o DefectDojo resolve:**
- Vulnerabilidade apareceu no Trivy E no Dep Check? Deduplica automaticamente
- CVE corrigido na semana passada? O histórico mostra
- Qual é o risco real agora? O dashboard responde

---

## Bloco 5 — O Projeto: Visão Geral (10 min)

### 5.1 — Apresentar a aplicação (3 min)

**Fala:**
> "Para tornar tudo isso concreto, construímos uma aplicação real — simples o suficiente
> para entendermos todo o código, mas com a mesma arquitetura usada em produção."

**Mostrar no browser:**
- http://localhost — calculadora de IMC funcionando
- Preencher os campos, calcular, ver o resultado

**Stack apresentada:**
- Backend: **NestJS** (Node.js / TypeScript) — API REST com Swagger
- Frontend: **Vue.js 3** — SPA servida por nginx
- Observabilidade: **Jaeger** (traces) + **Prometheus** (métricas)
- Contêineres: **Docker Compose**

---

### 5.2 — Arquitetura dos serviços (4 min)

**Mostrar o diagrama Mermaid do README ou o slide correspondente.**

**Pontos a destacar:**
- Frontend não fala diretamente com o banco — passa pela API
- Cada serviço tem uma responsabilidade única
- Observabilidade está integrada desde o início (não é adicionada depois)

**Fala:**
> "Reparem que segurança e observabilidade foram pensadas desde o início.
> Não foram adicionadas como patch depois que algo deu errado."

---

### 5.3 — Os testes como base da segurança (3 min)

**Fala:**
> "Antes de falar de scans, precisamos falar de testes. Um pipeline de segurança
> que quebra os testes deve travar o deploy. Temos testes unitários e de integração
> cobrindo a lógica de negócio."

**Mostrar (opcional):**
```bash
cd backend && npm test
cd frontend && npm test
```

---

## Bloco 6 — Demo ao Vivo: Scans e Resultados (25 min)

> **Pré-condição:** Stack rodando (`make up`), DefectDojo configurado (`make setup-dojo`),
> variáveis exportadas.

---

### 6.1 — Trivy: Container Scan (5 min)

**Fala:**
> "Começamos pelo mais simples de visualizar: nossa imagem Docker tem vulnerabilidades?
> O Trivy varre a imagem e cruza com os bancos de CVEs do NVD e da GHSA."

**Rodar ao vivo:**
```bash
make trivy
```

**O que mostrar:**
- Saída no terminal com CRITICAL / HIGH / MEDIUM
- Abrir `reports/trivy-backend.json` e mostrar a estrutura
- Abrir DefectDojo → engagement "Container Scan - Trivy" → findings

**Pergunta para turma:**
> "Por que uma imagem 'oficial' do Node.js tem vulnerabilidades?
> Porque ela inclui o sistema operacional base — e esse sistema tem pacotes antigos."

---

### 6.2 — OWASP Dependency Check: SCA (7 min)

**Fala:**
> "Agora vamos olhar para as dependências do nosso código. Quantas bibliotecas
> um projeto Node.js típico tem? Centenas. Alguma delas tem CVE crítico?"

**Rodar ao vivo:**
```bash
make dep-check
# ou com SKIP_UPDATE=1 se o banco já foi baixado
SKIP_UPDATE=1 bash infra/scripts/dependency-check.sh
```

**O que mostrar:**
- Saída com total de vulnerabilidades
- Abrir `reports/dependency-check-report.html` no browser
- Mostrar um CVE específico: nome da lib, versão vulnerável, versão corrigida, CVSS score
- DefectDojo → engagement "SCA - Dependency Check"

**Conceito a reforçar:**
> "Supply chain attack — em 2021 o ataque ao SolarWinds comprometeu milhares de empresas
> injetando código malicioso em uma biblioteca legítima. SCA é sua defesa contra isso."

---

### 6.3 — OWASP ZAP: DAST (8 min)

**Fala:**
> "Até agora analisamos coisas estáticas — imagem, código, dependências.
> O ZAP é diferente: ele ataca a aplicação em execução. É um 'hacker automatizado'."

**O que o ZAP faz:**
- Faz crawling da aplicação
- Testa cada endpoint com payloads de ataque (XSS, SQLi, headers inseguros, etc.)
- Classifica os alertas por risco

**Rodar ao vivo:**
```bash
make zap
```

**O que mostrar:**
- Terminal com o ZAP varrendo os endpoints
- `reports/zap-report.html` no browser — mostrar os alertas com descrição e solução
- DefectDojo → engagement "DAST - OWASP ZAP"

**Fala:**
> "Reparem que o ZAP encontra coisas que o código não revela: headers HTTP ausentes,
> configurações do servidor web, comportamento em runtime."

---

### 6.4 — DefectDojo: visão consolidada (5 min)

**Mostrar ao vivo:**
1. Dashboard geral → total de findings por severidade
2. Produto "BMI AppSec" → os três engagements
3. Abrir um finding crítico → mostrar CVE, descrição, referências, remediação
4. Mostrar que o mesmo CVE pode aparecer em Trivy e Dep Check (deduplicação)

**Fala:**
> "Agora temos uma visão 360° da postura de segurança da aplicação.
> Em um time real, o Dev Lead abre o DefectDojo toda manhã — não espera um auditor
> aparecer para descobrir o problema."

---

## Bloco 7 — O Que Você Vai Aprender Neste Curso (5 min)

**Fala:**
> "O que fizemos hoje é uma visão do destino. Ao longo do curso vocês vão
> entender como cada peça funciona por dentro."

**Tópicos do curso a apresentar:**

```
Módulo 1 — Fundamentos de Segurança
  ├── CIA Triad, OWASP Top 10, threat modeling
  └── Boas práticas de desenvolvimento seguro

Módulo 2 — SAST e Qualidade de Código
  ├── SonarQube: configuração, regras, quality gates
  └── Análise de código TypeScript / Java / Python

Módulo 3 — SCA e Gestão de Dependências
  ├── OWASP Dependency Check na prática
  └── Políticas de atualização e triagem de CVEs

Módulo 4 — Container Security
  ├── Trivy, imagens base, least privilege
  └── Dockerfile seguro

Módulo 5 — DAST
  ├── OWASP ZAP: full scan, API scan, autenticado
  └── Interpretação de alertas e remediação

Módulo 6 — Pipeline DevSecOps
  ├── GitHub Actions: integração de todas as ferramentas
  └── DefectDojo: gestão de vulnerabilidades em escala

Módulo 7 — Projeto Final
  └── Aplicação real com pipeline DevSecOps completo
```

---

## Bloco 8 — Encerramento (5 min)

### Mensagem final

**Fala:**
> "Segurança não é uma feature que se adiciona no final. É uma disciplina que se pratica
> desde a primeira linha de código. O profissional que entende segurança tem uma perspectiva
> diferente — enxerga o sistema como um atacante e como um defensor ao mesmo tempo."

> "Vocês estão começando um curso que vai colocar segurança no centro do desenvolvimento.
> Isso é raro. Aproveitem."

### Três perguntas para reflexão (deixar no slide final)

1. Qual a última vez que você verificou as dependências do seu projeto?
2. Se alguém obtivesse seu token de banco de dados agora, o que aconteceria?
3. Seu sistema estaria disponível se recebesse 10x o tráfego normal?

---

## Recursos e Referências

| Recurso | Link |
|---------|------|
| OWASP Top 10 | https://owasp.org/Top10 |
| IBM Cost of a Data Breach 2024 | https://www.ibm.com/reports/data-breach |
| CVE Database (NVD) | https://nvd.nist.gov |
| DefectDojo Docs | https://defectdojo.github.io/django-DefectDojo |
| CWE — Common Weakness Enumeration | https://cwe.mitre.org |
| LGPD (Lei 13.709/2018) | https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm |

---

## Checklist pré-palestra

- [ ] Stack rodando: `make up`
- [ ] DefectDojo acessível: http://localhost:8081
- [ ] `make setup-dojo` executado e variáveis exportadas
- [ ] Relatórios gerados: `make scan-all`
- [ ] Browser aberto em: http://localhost (app), http://localhost:8081 (dojo)
- [ ] Slides abertos no bloco correto
- [ ] Terminal limpo e com fonte legível (tamanho ≥ 20)
- [ ] Modo "não perturbe" ativado
