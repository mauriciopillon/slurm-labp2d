# SLURM HPC Cluster - Guia Completo

Este repositório contém documentação e scripts para uso com o Cluster HPC Babitonga no LABP2D UDESC.

## Índice
- [O que é SLURM](#o-que-é-slurm)
- [Como o SLURM Funciona](#como-o-slurm-funciona)
- [Variáveis de Ambiente do SLURM](#variáveis-de-ambiente-do-slurm)
- [Utilitários do SLURM](#utilitários-do-slurm)
- [Exemplos Práticos](#exemplos-práticos)
- [Boas Práticas](#boas-práticas)

## O que é SLURM

SLURM (Simple Linux Utility for Resource Management) é um sistema de gerenciamento de recursos e agendamento de tarefas para clusters Linux. Ele aloca recursos computacionais exclusivos para usuários por um determinado período, agenda e monitora trabalhos em uma fila de execução, e gerencia contenção de recursos arbitrários.

## Como o SLURM Funciona

O SLURM opera através de uma arquitetura distribuída com os seguintes componentes principais:

### Componentes do SLURM

1. **slurmctld (Daemon Central)**: Controlador central que monitora recursos e agenda trabalhos
2. **slurmd (Daemon dos Nós)**: Executado em cada nó de computação para gerenciar tarefas locais
3. **slurmdbd (Daemon de Banco de Dados)**: Opcional, para contabilidade e relatórios

### Fluxo de Trabalho

1. **Submissão**: Usuário submete um trabalho através de `sbatch`, `salloc` ou `srun`
2. **Enfileiramento**: Trabalho é colocado em uma fila baseada em prioridade e recursos solicitados
3. **Agendamento**: SLURM aloca recursos quando disponíveis conforme políticas configuradas
4. **Execução**: Trabalho é executado nos nós alocados
5. **Finalização**: Recursos são liberados após conclusão

## Variáveis de Ambiente do SLURM

O SLURM disponibiliza diversas variáveis de ambiente durante a execução dos trabalhos:

### Variáveis de Identificação
```bash
SLURM_JOB_ID          # ID único do trabalho
SLURM_JOB_NAME        # Nome do trabalho
SLURM_JOB_USER        # Usuário que submeteu o trabalho
SLURM_JOB_ACCOUNT     # Conta associada ao trabalho
```

### Variáveis de Recursos
```bash
SLURM_CPUS_PER_TASK   # CPUs alocadas por tarefa
SLURM_CPUS_ON_NODE    # Total de CPUs no nó
SLURM_MEM_PER_NODE    # Memória alocada por nó (MB)
SLURM_NTASKS          # Número total de tarefas
SLURM_NTASKS_PER_NODE # Tarefas por nó
SLURM_NNODES          # Número de nós alocados
```

### Variáveis de Localização
```bash
SLURM_NODELIST        # Lista de nós alocados
SLURM_NODE_ALIASES    # Aliases dos nós
SLURM_PROCID          # ID do processo MPI
SLURM_LOCALID         # ID local da tarefa no nó
```

### Variáveis de Diretórios
```bash
SLURM_SUBMIT_DIR      # Diretório de onde o trabalho foi submetido
SLURM_SUBMIT_HOST     # Host de onde o trabalho foi submetido
SLURM_WORKING_DIR     # Diretório de trabalho atual
```

### Variáveis de Tempo
```bash
SLURM_JOB_START_TIME  # Timestamp de início do trabalho
SLURM_JOB_END_TIME    # Timestamp de fim do trabalho (se conhecido)
```

## Utilitários do SLURM

### 1. squeue - Visualizar Fila de Trabalhos

Mostra informações sobre trabalhos na fila.

```bash
# Visualizar todos os trabalhos
squeue

# Visualizar apenas seus trabalhos
squeue -u $USER

# Visualizar trabalhos por estado
squeue -t RUNNING
squeue -t PENDING

# Formato personalizado
squeue -o "%.18i %.9P %.8j %.8u %.2t %.10M %.6D %R"

# Visualizar detalhes de um trabalho específico
squeue -j <job_id> --long
```

### 2. sbatch - Submeter Trabalho em Lote

Submete scripts para execução posterior.

```bash
# Submeter script básico
sbatch meu_script.sh

# Submeter com opções
sbatch --job-name=meu_trabalho --time=01:00:00 --nodes=2 meu_script.sh

# Submeter com dependências
sbatch --dependency=afterok:12345 script_dependente.sh
```

Exemplo de script SLURM:
```bash
#!/bin/bash
#SBATCH --job-name=exemplo
#SBATCH --output=resultado_%j.out
#SBATCH --error=erro_%j.err
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G

echo "Iniciando trabalho no nó: $SLURM_NODELIST"
echo "ID do trabalho: $SLURM_JOB_ID"

# Seus comandos aqui
python meu_programa.py
```

### 3. salloc - Alocação Interativa

Aloca recursos para uso interativo.

```bash
# Alocação básica
salloc

# Alocação com recursos específicos
salloc --nodes=2 --time=02:00:00 --cpus-per-task=4

# Alocação com shell específico
salloc --nodes=1 --time=01:00:00 bash
```

### 4. srun - Executar Comando em Paralelo

Executa comandos nos nós alocados.

```bash
# Executar comando simples
srun hostname

# Executar com recursos específicos
srun --nodes=2 --ntasks=8 meu_programa_mpi

# Executar dentro de uma alocação existente
salloc --nodes=2
srun --nodes=2 hostname
exit
```

### 5. scancel - Cancelar Trabalhos

Cancela trabalhos na fila ou em execução.

```bash
# Cancelar trabalho específico
scancel <job_id>

# Cancelar todos os seus trabalhos
scancel -u $USER

# Cancelar trabalhos por nome
scancel --name=meu_trabalho

# Cancelar trabalhos por estado
scancel --state=PENDING -u $USER
```

### 6. sinfo - Informações do Cluster

Mostra informações sobre partições e nós.

```bash
# Informações básicas
sinfo

# Informações detalhadas
sinfo --long

# Informações por partição
sinfo -p <partição>

# Estado dos nós
sinfo -N

# Formato personalizado
sinfo -o "%.10P %.5a %.10l %.6D %.6t %N"
```

### 7. sacct - Contabilidade de Trabalhos

Mostra histórico de trabalhos executados.

```bash
# Trabalhos do dia atual
sacct

# Trabalhos de um usuário específico
sacct -u $USER

# Trabalhos em um período
sacct --starttime=2023-01-01 --endtime=2023-01-31

# Informações específicas
sacct -j <job_id> --format=JobID,JobName,State,ExitCode,Start,End,Elapsed
```

### 8. scontrol - Controle Administrativo

Mostra e modifica informações detalhadas.

```bash
# Informações de um trabalho
scontrol show job <job_id>

# Informações de um nó
scontrol show node <node_name>

# Informações de uma partição
scontrol show partition <partition_name>

# Modificar trabalho (apenas o proprietário)
scontrol update job <job_id> TimeLimit=02:00:00
```

## Exemplos Práticos

### Trabalho Sequencial Simples
```bash
#!/bin/bash
#SBATCH --job-name=trabalho_sequencial
#SBATCH --output=output_%j.log
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G

python meu_script.py
```

### Trabalho Paralelo com OpenMP
```bash
#!/bin/bash
#SBATCH --job-name=openmp_job
#SBATCH --output=openmp_%j.log
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=8G

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
./programa_openmp
```

### Trabalho MPI
```bash
#!/bin/bash
#SBATCH --job-name=mpi_job
#SBATCH --output=mpi_%j.log
#SBATCH --time=02:00:00
#SBATCH --nodes=2
#SBATCH --ntasks=16
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=1G

module load mpi/openmpi
srun programa_mpi
```

### Array de Trabalhos
```bash
#!/bin/bash
#SBATCH --job-name=array_job
#SBATCH --output=array_%A_%a.log
#SBATCH --time=00:15:00
#SBATCH --array=1-10
#SBATCH --nodes=1
#SBATCH --ntasks=1

echo "Processando tarefa $SLURM_ARRAY_TASK_ID"
python processar.py --input file_${SLURM_ARRAY_TASK_ID}.txt
```

## Boas Práticas

### 1. Estimativa de Recursos
- Sempre estime tempo e recursos necessários adequadamente
- Use `seff <job_id>` para analisar eficiência após execução
- Monitore uso de memória e CPU

### 2. Nomenclatura
- Use nomes descritivos para trabalhos
- Organize arquivos de saída em diretórios específicos
- Use variáveis SLURM nos nomes de arquivos para evitar conflitos

### 3. Debugging
```bash
# Trabalho de teste com recursos mínimos
#SBATCH --time=00:05:00
#SBATCH --nodes=1
#SBATCH --ntasks=1

# Adicione informações de debug
echo "Nó: $SLURM_NODELIST"
echo "Diretório: $PWD"
echo "Usuário: $USER"
module list
```

### 4. Monitoramento
```bash
# Verificar status regularmente
squeue -u $USER

# Monitorar recursos em tempo real
sstat -j <job_id> --format=AveCPU,AveRSS,MaxRSS
```

### 5. Limpeza
- Remova arquivos temporários desnecessários
- Organize logs por data/projeto
- Use `scancel` para cancelar trabalhos desnecessários

## Comandos Úteis para o Cluster Babitonga

### Verificar Disponibilidade
```bash
# Status geral do cluster
sinfo -s

# Nós disponíveis
sinfo -t idle

# Carga atual
squeue -u all | wc -l
```

### Submissão Eficiente
```bash
# Para trabalhos curtos (<1 hora)
sbatch --qos=short --time=00:30:00 script.sh

# Para trabalhos longos
sbatch --qos=long --time=24:00:00 script.sh
```

### Troubleshooting
```bash
# Se trabalho não inicia
scontrol show job <job_id> | grep Reason

# Verificar limites da conta
sacctmgr show assoc user=$USER format=Account,User,MaxJobs,MaxSubmit
```

Este guia fornece uma base sólida para usar o SLURM no cluster Babitonga. Para dúvidas específicas, consulte a documentação oficial do SLURM ou contate os administradores do cluster.
