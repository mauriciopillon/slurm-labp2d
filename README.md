# SLURM HPC Cluster — Guia Completo

Documentação para utilização do **Cluster HPC Babitonga** do **LABP2D — UDESC**, incluindo o uso tradicional do SLURM e a execução de aplicações Docker utilizando os utilitários `dsrun` e `dsbatch`.

---

## Índice

* [Sobre este documento](#sobre-este-documento)
* [O que é SLURM](#o-que-é-slurm)
* [Como o SLURM funciona](#como-o-slurm-funciona)
* [Arquitetura do cluster](#arquitetura-do-cluster)
* [Variáveis de ambiente do SLURM](#variáveis-de-ambiente-do-slurm)
* [Principais utilitários do SLURM](#principais-utilitários-do-slurm)

  * [`sinfo`](#sinfo)
  * [`squeue`](#squeue)
  * [`sbatch`](#sbatch)
  * [`salloc`](#salloc)
  * [`srun`](#srun)
  * [`scancel`](#scancel)
  * [`sacct`](#sacct)
  * [`scontrol`](#scontrol)
* [Exemplos de uso do SLURM](#exemplos-de-uso-do-slurm)

  * [Trabalho sequencial](#trabalho-sequencial)
  * [OpenMP](#openmp)
  * [MPI](#mpi)
  * [Array de trabalhos](#array-de-trabalhos)
* [Docker no cluster](#docker-no-cluster)

  * [Arquitetura Docker + SLURM](#arquitetura-docker--slurm)
  * [Por que utilizar `dsrun` e `dsbatch`](#por-que-utilizar-dsrun-e-dsbatch)
  * [`dsrun`](#dsrun)
  * [`dsbatch`](#dsbatch)
  * [Comparação entre os comandos](#comparação-entre-os-comandos)
  * [Docker com GPU](#docker-com-gpu)
* [Monitoramento e diagnóstico](#monitoramento-e-diagnóstico)
* [Boas práticas](#boas-práticas)
* [Limitações e comportamento](#limitações-e-comportamento)
* [Resumo dos comandos](#resumo-dos-comandos)

---

# Sobre este documento

Este documento apresenta os procedimentos básicos para utilização do SLURM no Cluster HPC Babitonga.

O ambiente suporta dois modelos principais de utilização:

1. **execução tradicional pelo SLURM**, utilizando `srun`, `sbatch` e `salloc`;
2. **execução de aplicações Docker utilizando `dsrun` e `dsbatch`**, ferramentas auxiliares desenvolvidas para o ambiente do LABP2D.

O SLURM é responsável pelo **agendamento e pela reserva dos recursos computacionais**. Para aplicações Docker, o LABP2D utiliza uma arquitetura na qual a aplicação é executada em uma sessão SSH independente no nó que recebeu a alocação.

> **Importante:** `dsrun` e `dsbatch` não são comandos nativos do SLURM. São ferramentas auxiliares específicas do ambiente do LABP2D.

---

# O que é SLURM

SLURM (*Simple Linux Utility for Resource Management*) é um sistema de gerenciamento de recursos e de escalonamento de trabalhos utilizado em clusters computacionais.

No cluster, o SLURM é responsável principalmente por:

* receber solicitações de recursos;
* manter os trabalhos em uma fila;
* selecionar os recursos disponíveis;
* alocar nós, CPUs, memória e outros recursos;
* iniciar e controlar trabalhos;
* acompanhar o estado das execuções;
* liberar os recursos quando os trabalhos terminam ou são cancelados;
* fornecer informações para monitoramento e contabilização.

Os recursos solicitados por um trabalho devem ser compatíveis com os recursos disponíveis no cluster e com as políticas configuradas pelos administradores.

---

# Como o SLURM funciona

## Componentes principais

O SLURM utiliza uma arquitetura distribuída.

### `slurmctld`

É o daemon central do SLURM.

É responsável por:

* receber solicitações;
* manter a fila de trabalhos;
* realizar o escalonamento;
* controlar as partições;
* acompanhar os nós;
* gerenciar o estado dos trabalhos.

### `slurmd`

É executado nos nós computacionais.

É responsável pela execução e pelo gerenciamento local das tarefas solicitadas pelo SLURM.

### `slurmdbd`

É o daemon utilizado para contabilização e armazenamento de informações históricas dos trabalhos quando essa funcionalidade está configurada.

---

## Fluxo básico de execução

De forma simplificada:

```text
Usuário
   │
   │  sbatch / srun / salloc
   ▼
SLURM
   │
   ├── trabalho PENDING
   │
   ├── seleção de recursos
   │
   ├── trabalho RUNNING
   │
   ▼
Nó(s) computacional(is)
   │
   │ execução
   ▼
Finalização
   │
   ▼
Recursos liberados
```

Quando os recursos solicitados estão disponíveis e o trabalho pode ser executado de acordo com as políticas do cluster, o SLURM altera o estado do trabalho para `RUNNING`.

---

# Arquitetura do cluster

O Cluster HPC Babitonga é composto por uma infraestrutura gerenciada pelo SLURM.

Um trabalho pode utilizar um ou mais nós, dependendo dos recursos solicitados.

As informações do cluster podem ser consultadas com:

```bash
sinfo
```

Por exemplo:

```bash
sinfo -N
```

mostra informações por nó.

Para consultar um trabalho:

```bash
squeue -j <JOBID>
```

Para obter informações detalhadas:

```bash
scontrol show job <JOBID>
```

---

# Variáveis de ambiente do SLURM

Durante a execução de um trabalho, o SLURM disponibiliza diversas variáveis de ambiente.

A disponibilidade exata de uma variável depende do tipo de execução e dos recursos solicitados.

## Identificação do trabalho

Algumas variáveis importantes:

```bash
echo "$SLURM_JOB_ID"
echo "$SLURM_JOB_NAME"
echo "$SLURM_JOB_USER"
```

As principais são:

| Variável            | Descrição                           |
| ------------------- | ----------------------------------- |
| `SLURM_JOB_ID`      | Identificador numérico do trabalho  |
| `SLURM_JOB_NAME`    | Nome do trabalho                    |
| `SLURM_JOB_USER`    | Usuário responsável pelo trabalho   |
| `SLURM_JOB_ACCOUNT` | Conta associada, quando configurada |

`SLURM_JOBID` também pode aparecer como alias de `SLURM_JOB_ID`.

---

## Recursos

Exemplos:

```bash
echo "$SLURM_CPUS_ON_NODE"
echo "$SLURM_CPUS_PER_TASK"
echo "$SLURM_NTASKS"
echo "$SLURM_NNODES"
```

Variáveis comuns:

| Variável                | Descrição                                   |
| ----------------------- | ------------------------------------------- |
| `SLURM_CPUS_PER_TASK`   | CPUs solicitadas para cada tarefa           |
| `SLURM_CPUS_ON_NODE`    | CPUs disponibilizadas no nó para o trabalho |
| `SLURM_NTASKS`          | Número de tarefas                           |
| `SLURM_NNODES`          | Número de nós alocados                      |
| `SLURM_NTASKS_PER_NODE` | Número de tarefas por nó, quando aplicável  |

Variáveis relacionadas à memória também podem estar disponíveis, dependendo da forma como a solicitação foi realizada.

---

## Localização do trabalho

```bash
echo "$SLURM_NODELIST"
echo "$SLURM_JOB_NODELIST"
```

Essas variáveis permitem identificar os nós associados ao trabalho.

Também podem existir variáveis relacionadas à identificação da tarefa, como:

```bash
SLURM_PROCID
SLURM_LOCALID
SLURM_NODEID
```

Essas variáveis são particularmente relevantes para trabalhos paralelos.

---

## Diretório de submissão

Variáveis como:

```bash
echo "$SLURM_SUBMIT_DIR"
echo "$SLURM_SUBMIT_HOST"
```

podem ser utilizadas para identificar o diretório e o host a partir dos quais o trabalho foi submetido.

---

## Inspecionando o ambiente

Durante um trabalho, uma forma simples de visualizar as variáveis SLURM é:

```bash
env | grep '^SLURM_' | sort
```

---

# Principais utilitários do SLURM

## `sinfo`

Mostra informações sobre partições e nós.

### Informações gerais

```bash
sinfo
```

### Informações detalhadas

```bash
sinfo --long
```

### Informações por partição

```bash
sinfo -p <partição>
```

### Informações por nó

```bash
sinfo -N
```

### Formato personalizado

```bash
sinfo -o "%.10P %.5a %.10l %.6D %.6t %N"
```

---

# `squeue`

Mostra os trabalhos atualmente conhecidos pelo SLURM.

### Todos os trabalhos

```bash
squeue
```

### Trabalhos do usuário atual

```bash
squeue -u $USER
```

### Trabalhos em execução

```bash
squeue -t RUNNING
```

### Trabalhos aguardando execução

```bash
squeue -t PENDING
```

### Trabalho específico

```bash
squeue -j <JOBID>
```

### Formato personalizado

```bash
squeue -o "%.18i %.9P %.20j %.12u %.2t %.10M %.6D %R"
```

---

# `sbatch`

`sbatch` submete um script para execução em lote.

Exemplo:

```bash
sbatch meu_script.sh
```

Com recursos:

```bash
sbatch \
    --job-name=meu_trabalho \
    --time=01:00:00 \
    --nodes=1 \
    --cpus-per-task=4 \
    --mem=8G \
    meu_script.sh
```

## Exemplo de script

```bash
#!/usr/bin/env bash

#SBATCH --job-name=exemplo
#SBATCH --output=resultado_%j.out
#SBATCH --error=erro_%j.err
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G

echo "Nó: $SLURM_JOB_NODELIST"
echo "Job: $SLURM_JOB_ID"

./meu_programa
```

---

# `salloc`

`salloc` cria uma alocação interativa de recursos.

Exemplo:

```bash
salloc --nodes=1 --cpus-per-task=4 --mem=8G --time=01:00:00
```

Depois que os recursos forem alocados, comandos podem ser executados dentro da alocação.

Por exemplo:

```bash
srun hostname
```

Ao terminar:

```bash
exit
```

---

# `srun`

`srun` é utilizado para executar comandos sob controle do SLURM.

Exemplo:

```bash
srun hostname
```

Solicitando recursos:

```bash
srun \
    --nodes=2 \
    --ntasks=8 \
    meu_programa
```

Também pode ser utilizado dentro de uma alocação criada com `salloc`:

```bash
salloc --nodes=2
srun hostname
exit
```

Para trabalhos MPI, por exemplo:

```bash
srun programa_mpi
```

---

# `scancel`

Cancela trabalhos.

### Cancelar um trabalho

```bash
scancel <JOBID>
```

### Cancelar todos os trabalhos do usuário

```bash
scancel -u $USER
```

### Cancelar pelo nome

```bash
scancel --name=meu_trabalho
```

> Utilize o cancelamento de trabalhos com cuidado, principalmente quando houver vários trabalhos ativos.

---

# `sacct`

Consulta informações históricas dos trabalhos.

```bash
sacct
```

Por usuário:

```bash
sacct -u $USER
```

Por período:

```bash
sacct \
    --starttime=2026-01-01 \
    --endtime=2026-01-31
```

Para um trabalho específico:

```bash
sacct \
    -j <JOBID> \
    --format=JobID,JobName,State,ExitCode,Start,End,Elapsed
```

---

# `scontrol`

Fornece informações detalhadas sobre trabalhos, nós e partições.

### Trabalho

```bash
scontrol show job <JOBID>
```

### Nó

```bash
scontrol show node <NODE>
```

### Partição

```bash
scontrol show partition <PARTITION>
```

---

# Exemplos de uso do SLURM

## Trabalho sequencial

```bash
#!/usr/bin/env bash

#SBATCH --job-name=trabalho_sequencial
#SBATCH --output=output_%j.log
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G

python meu_script.py
```

Submissão:

```bash
sbatch trabalho_sequencial.sh
```

---

# OpenMP

Para um programa OpenMP:

```bash
#!/usr/bin/env bash

#SBATCH --job-name=openmp_job
#SBATCH --output=openmp_%j.log
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=8G

export OMP_NUM_THREADS="$SLURM_CPUS_PER_TASK"

./programa_openmp
```

---

# MPI

Exemplo:

```bash
#!/usr/bin/env bash

#SBATCH --job-name=mpi_job
#SBATCH --output=mpi_%j.log
#SBATCH --time=02:00:00
#SBATCH --nodes=2
#SBATCH --ntasks=16
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=1G

srun programa_mpi
```

A configuração de MPI disponível depende do ambiente instalado no cluster.

---

# Array de trabalhos

Exemplo:

```bash
#!/usr/bin/env bash

#SBATCH --job-name=array_job
#SBATCH --output=array_%A_%a.log
#SBATCH --time=00:15:00
#SBATCH --array=1-10
#SBATCH --nodes=1
#SBATCH --ntasks=1

echo "Processando tarefa $SLURM_ARRAY_TASK_ID"

python processar.py \
    --input "file_${SLURM_ARRAY_TASK_ID}.txt"
```

Submissão:

```bash
sbatch array_job.sh
```

---

# Docker no cluster

## Arquitetura Docker + SLURM

O LABP2D utiliza uma arquitetura específica para executar aplicações Docker utilizando recursos gerenciados pelo SLURM.

O princípio é:

```text
                  SLURM
                    │
                    │ reserva recursos
                    ▼
              NÓ COMPUTACIONAL
                    │
                    │ SSH independente
                    ▼
                  DOCKER
                    │
             ┌──────┴──────┐
             ▼             ▼
        Container      Container
```

O SLURM continua sendo responsável pela **alocação dos recursos**.

O Docker, por sua vez, é executado em uma sessão SSH independente no nó alocado.

Isso permite utilizar a instalação convencional do Docker no nó computacional, sem executar o processo Docker diretamente como um processo filho do `srun`.

---

# Por que utilizar `dsrun` e `dsbatch`?

Uma execução tradicional poderia ser:

```bash
srun docker run ...
```

No ambiente do LABP2D, entretanto, optou-se por separar as duas responsabilidades:

```text
SLURM
  │
  └── reserva recursos
          │
          ▼
       SSH
          │
          └── executa Docker
```

Essa abordagem é particularmente útil porque o ambiente Docker do laboratório é administrado pelo próprio sistema operacional do nó.

Os utilitários `dsrun` e `dsbatch` automatizam esse fluxo.

---

# `dsrun`

O `dsrun` é destinado ao uso **interativo**.

Ele solicita uma alocação de recursos ao SLURM e mantém o trabalho ativo enquanto o usuário decide quando abrir a sessão de trabalho.

## Sintaxe

```bash
dsrun [opções do srun]
```

Exemplo:

```bash
dsrun \
    --cpus-per-task=4 \
    --mem=8G \
    --time=01:00:00
```

O comando cria uma alocação e informa o `JOBID`.

Exemplo:

```text
JOBID : 123
Node  : baia1
State : RUNNING
```

---

## Abrindo o shell

Depois que o job estiver em execução:

```bash
dsrun shell 123
```

O `dsrun`:

1. verifica o estado do job;
2. identifica o nó alocado;
3. recupera as informações da alocação;
4. reconstrói o ambiente SLURM relevante;
5. abre uma sessão SSH independente;
6. inicia um shell interativo.

O usuário estará no nó computacional:

```text
mpillon@flores:~$
```

O ambiente continua contendo informações da alocação:

```bash
echo "$SLURM_JOB_ID"
echo "$SLURM_JOB_NODELIST"
echo "$SLURM_JOB_PARTITION"
echo "$SLURM_CPUS_ON_NODE"
```

---

## Executando Docker com `dsrun`

Dentro da sessão:

```bash
docker info
```

ou:

```bash
docker run --rm hello-world
```

Exemplo:

```bash
docker run --rm ubuntu:24.04 \
    bash -c 'echo "Executando no host $(hostname)"'
```

---

## Exemplo completo

Solicitar recursos:

```bash
dsrun \
    --cpus-per-task=8 \
    --mem=32G \
    --time=02:00:00
```

Consultar o job:

```bash
squeue -u $USER
```

Abrir a sessão:

```bash
dsrun shell <JOBID>
```

Executar o Docker:

```bash
docker run --rm \
    -v /mnt/prj/mpillon:/workspace \
    ubuntu:24.04 \
    bash -c 'cd /workspace && ls -lah'
```

Ao terminar:

```bash
dsrun cancel <JOBID>
```

---

## Consultando jobs do `dsrun`

```bash
dsrun ls
```

Também é possível utilizar o comando nativo:

```bash
squeue -u $USER
```

---

# `dsbatch`

O `dsbatch` é destinado à execução **não interativa** de scripts que utilizam Docker.

Ele possui comportamento semelhante ao `sbatch`, mas utiliza a arquitetura SSH independente adotada no LABP2D.

## Sintaxe

```bash
dsbatch [opções do sbatch] -- script.sh [argumentos...]
```

O delimitador `--` separa as opções destinadas ao SLURM do script e seus argumentos.

---

## Exemplo básico

Script:

```bash
#!/usr/bin/env bash

echo "Host: $(hostname)"
echo "Job: $SLURM_JOB_ID"
echo "Node: $SLURM_JOB_NODELIST"

docker info
```

Salve como:

```text
docker-test.sh
```

e torne executável:

```bash
chmod +x docker-test.sh
```

Execute:

```bash
dsbatch \
    --cpus-per-task=4 \
    --mem=8G \
    --time=01:00:00 \
    -- \
    ./docker-test.sh
```

O `dsbatch` realiza automaticamente:

```text
sbatch
  │
  ▼
alocação SLURM
  │
  ▼
aguarda RUNNING
  │
  ▼
identifica o nó
  │
  ▼
recupera ambiente
  │
  ▼
SSH independente
  │
  ▼
executa script
  │
  ▼
script termina
  │
  ▼
libera alocação
```

---

# `dsbatch` com argumentos

Exemplo:

```bash
dsbatch \
    --cpus-per-task=8 \
    --mem=16G \
    --time=02:00:00 \
    -- \
    ./processa.sh entrada.dat resultado.dat
```

Script:

```bash
#!/usr/bin/env bash

entrada="$1"
saida="$2"

echo "Entrada: $entrada"
echo "Saída:   $saida"
echo "Host:    $(hostname)"

docker run --rm \
    -v "$PWD":/workspace \
    minha-imagem:latest \
    processa \
    "/workspace/$entrada" \
    "/workspace/$saida"
```

---

# `dsrun` × `dsbatch`

| Comando   | Finalidade                                                  | Execução           |
| --------- | ----------------------------------------------------------- | ------------------ |
| `srun`    | Executar comandos sob controle direto do SLURM              | Interativa/comando |
| `sbatch`  | Submeter scripts ao SLURM                                   | Não interativa     |
| `salloc`  | Reservar recursos para uso interativo                       | Interativa         |
| `dsrun`   | Reservar recursos e fornecer shell independente para Docker | Interativa         |
| `dsbatch` | Executar scripts Docker através de SSH independente         | Não interativa     |

A diferença fundamental é:

### SLURM tradicional

```text
srun / sbatch
       │
       ▼
 execução sob controle direto
       │
       ▼
     tarefa
```

### Docker no LABP2D

```text
dsrun / dsbatch
       │
       ▼
 SLURM reserva recursos
       │
       ▼
 SSH independente
       │
       ▼
 Docker / aplicação
```

---

# Verificando a alocação

Dentro de uma sessão criada pelo `dsrun` ou durante a execução de um `dsbatch`:

```bash
env | grep '^SLURM_' | sort
```

Variáveis importantes:

```bash
echo "$SLURM_JOB_ID"
echo "$SLURM_JOB_NAME"
echo "$SLURM_JOB_NODELIST"
echo "$SLURM_JOB_PARTITION"
echo "$SLURM_CPUS_ON_NODE"
echo "$SLURM_NTASKS"
echo "$SLURM_NNODES"
```

O `dsrun` e o `dsbatch` reconstruem o ambiente referente à **alocação do job**.

Variáveis transitórias relacionadas à execução de um *step* do `srun` não são transportadas para a sessão SSH independente.

---

# Docker com GPU

Quando uma aplicação necessita de GPU, a GPU deve ser solicitada ao SLURM juntamente com os demais recursos.

Por exemplo:

```bash
dsbatch \
    --gres=gpu:1 \
    --cpus-per-task=8 \
    --mem=32G \
    --time=02:00:00 \
    -- \
    ./gpu-job.sh
```

No script:

```bash
#!/usr/bin/env bash

echo "Host: $(hostname)"
echo "Job:  $SLURM_JOB_ID"

nvidia-smi

docker run --rm \
    --gpus all \
    nvidia/cuda:latest \
    nvidia-smi
```

O SLURM é responsável pela reserva do recurso de GPU. O Docker utiliza a GPU disponibilizada no nó.

A sintaxe para solicitar GPUs depende da configuração do cluster.

Consulte:

```bash
sinfo
```

e:

```bash
scontrol show node <NODE>
```

para verificar os recursos disponíveis.

---

# Monitoramento e diagnóstico

## Verificar o estado de um job

```bash
squeue -j <JOBID>
```

## Informações detalhadas

```bash
scontrol show job <JOBID>
```

## Histórico

```bash
sacct -j <JOBID>
```

## Verificar o nó

```bash
echo "$SLURM_JOB_NODELIST"
hostname
```

## Verificar o ambiente

```bash
env | grep '^SLURM_' | sort
```

## Verificar Docker

```bash
docker info
```

## Verificar GPU

```bash
nvidia-smi
```

---

# Boas práticas

## 1. Solicite somente os recursos necessários

Evite solicitar recursos muito acima da necessidade real.

Exemplo:

```bash
dsrun \
    --cpus-per-task=8 \
    --mem=32G \
    --time=02:00:00
```

---

## 2. Defina um limite de tempo

Sempre que possível, informe:

```bash
--time=HH:MM:SS
```

Isso permite ao SLURM planejar melhor a utilização dos recursos.

---

## 3. Libere alocações que não são mais necessárias

Para uma alocação criada pelo `dsrun
