# Cheat Sheet — Docker e Docker Swarm

## Imagens

| Comando | Para quê |
|---|---|
| `docker build -t app:1.0 .` | build com o Dockerfile do diretório |
| `docker build -f path/Dockerfile --target builder -t app:dev ctx/` | Dockerfile alternativo, parar em um stage |
| `docker build --no-cache --pull ...` | ignorar o cache e baixar a base de novo |
| `docker build --build-arg NODE_VERSION=22 ...` | passar um `ARG` |
| `docker build --secret id=npmrc,src=$HOME/.npmrc ...` | secret no build sem gravar em camada |
| `docker buildx build --platform linux/amd64,linux/arm64 -t repo/app:1.0 --push .` | multi-arquitetura |
| `docker images` / `docker image ls --filter dangling=true` | listar / listar órfãs |
| `docker history --no-trunc app:1.0` | camadas e o comando que gerou cada uma |
| `docker image inspect -f '{{.Config.User}} {{.Size}}' app:1.0` | metadados (usuário, tamanho, env, entrypoint) |
| `docker buildx imagetools inspect node:22-alpine` | digest e plataformas de uma imagem remota |
| `docker pull node:22-alpine@sha256:<digest>` | pull imutável por digest |
| `docker tag app:1.0 registry.local/app:1.0 && docker push registry.local/app:1.0` | publicar |
| `docker save app:1.0 \| gzip > app.tar.gz` / `docker load < app.tar.gz` | transportar sem registry |

## Containers

| Comando | Para quê |
|---|---|
| `docker run -d --name api -p 3000:3000 -e KEY=val app:1.0` | subir em background |
| `docker run --rm -it --entrypoint sh app:1.0` | entrar numa imagem com shell |
| `docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'` | listar, formato enxuto |
| `docker logs -f --tail 100 api` | acompanhar logs |
| `docker exec -it api sh` | shell num container rodando |
| `docker debug api` | shell de debug em imagens sem shell (distroless/scratch) — Docker Desktop |
| `docker inspect api` / `docker inspect -f '{{.State.Health.Status}}' api` | detalhes / healthcheck |
| `docker stats` / `docker top api` | CPU/memória ao vivo / processos |
| `docker cp api:/app/file .` | copiar arquivos |
| `docker diff api` | o que mudou no filesystem do container |
| `docker stop api` / `docker kill api` / `docker rm -f api` | parar (SIGTERM) / matar (SIGKILL) / remover |
| `docker update --memory 256m --cpus 0.5 api` | ajustar limites a quente |

## Redes, volumes e limpeza

| Comando | Para quê |
|---|---|
| `docker network ls` / `docker network inspect appsec_appsec` | redes e containers conectados |
| `docker network create --driver bridge minha-rede` | rede isolada com DNS interno |
| `docker volume ls` / `docker volume inspect postgres_data` | volumes |
| `docker system df` | espaço por imagens/containers/volumes/cache |
| `docker system prune` | remove parados, redes órfãs, imagens dangling e cache |
| `docker image prune -a` | remove todas as imagens sem container |
| `docker builder prune` | limpa o cache do BuildKit |
| `docker volume prune` | ⚠️ remove volumes sem uso (dados!) |

## Docker Compose

| Comando | Para quê |
|---|---|
| `docker compose up -d --build` | subir (rebuildando) |
| `docker compose ps` / `docker compose logs -f backend` | status / logs de um serviço |
| `docker compose exec backend sh` | shell num serviço |
| `docker compose restart backend` / `docker compose up -d --no-deps backend` | reiniciar / recriar um só serviço |
| `docker compose config` | ver o YAML final (com variáveis resolvidas) |
| `docker compose down` / `docker compose down -v` | derrubar / derrubar apagando volumes |

## Docker Swarm

| Comando | Para quê |
|---|---|
| `docker swarm init --advertise-addr <ip>` | criar o cluster (vira manager) |
| `docker swarm join-token worker` / `manager` | mostrar o comando de join |
| `docker node ls` / `docker node inspect self --pretty` | nós do cluster |
| `docker node update --availability drain <nó>` | tirar o nó de serviço (manutenção) |
| `docker node update --availability active <nó>` | devolver o nó |
| `docker node update --label-add zona=a <nó>` | label para `placement.constraints` |
| `docker stack deploy -c stack.yml bmi` | deploy / atualização de stack |
| `docker stack ls` / `docker stack services bmi` / `docker stack ps bmi` | stacks, serviços, tasks |
| `docker service ls` / `docker service ps bmi_backend --no-trunc` | serviços / tasks (com erro completo) |
| `docker service logs -f bmi_backend` | logs agregados de todas as réplicas |
| `docker service scale bmi_backend=4` | escalar |
| `docker service update --image app:2.0 bmi_backend` | rolling update |
| `docker service update --env-add KEY=val --limit-memory 256M bmi_backend` | alterar config (também é rolling) |
| `docker service update --force bmi_backend` | redistribuir tasks entre os nós |
| `docker service rollback bmi_backend` | voltar para a spec anterior |
| `printf 's3cr3t' \| docker secret create db_pass -` | criar secret (fica em `/run/secrets/db_pass`) |
| `docker secret ls` / `docker config create nginx_conf ./nginx.conf` | secrets / configs |
| `docker stack rm bmi` | remover a stack |
| `docker swarm leave --force` | sair do cluster |

## Troubleshooting rápido

| Sintoma | Primeiro comando |
|---|---|
| Container reiniciando em loop | `docker logs api` e `docker inspect -f '{{.State.ExitCode}} {{.State.OOMKilled}}' api` |
| Exit code 137 | OOMKilled ou SIGKILL → revise `--memory` |
| `exec format error` | arquitetura errada (arm64 x amd64) → `--platform` / buildx |
| `no such file or directory` com o binário presente | binário glibc em alpine/scratch → `CGO_ENABLED=0` ou base glibc |
| Service com réplicas `0/2` | `docker service ps --no-trunc bmi_backend` (erro de pull, constraint ou healthcheck) |
| Disco cheio | `docker system df` e depois `docker builder prune` / `docker image prune -a` |
