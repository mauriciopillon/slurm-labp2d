#!/bin/bash

# Estando no Servidor de Controle do Cluster com SLURM configurado (No LabP2D: Logar na baia0 da Babitonga):
# bash slurm-script.bash

# SUBSTITUIR O QUE ESTIVER ENTRE < >

# Configuração de logging
LOG_DIR="<LOG-DIR>"
mkdir -p $LOG_DIR
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/<LOG-NAME>_$TIMESTAMP.log"

# Função para logging
log() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

# Diretório do projeto
PROJ_DIR="<PROJ-DIR>"

# EXEMPLO DE LOG
log "Iniciando tarefa X e Y"

# Aloca um nó do cluster usando salloc
ALLOC_OUT=$(salloc -N1 --no-shell 2>&1)
SLURM_JOB_ID=$(echo "$ALLOC_OUT" | grep -oP 'Granted job allocation \K[0-9]+')
if [ -z "$SLURM_JOB_ID" ]; then
    log "Erro: Falha ao alocar nó via salloc"
    exit 1
fi
log "Alocação realizada com job ID: $SLURM_JOB_ID"

# Aguarda o nó ser alocado e captura o nome do nó
for i in {1..10}; do
    NODE_NAME=$(squeue -j $SLURM_JOB_ID -h -o '%N')
    if [ -n "$NODE_NAME" ] && [ "$NODE_NAME" != "(null)" ]; then
        break
    fi
    sleep 1
done

if [ -z "$NODE_NAME" ] || [ "$NODE_NAME" = "(null)" ]; then
    log "Erro: Falha ao capturar nome do nó alocado"
    scancel $SLURM_JOB_ID
    exit 1
fi
log "Nó alocado: $NODE_NAME"

# Aguarda um momento para garantir que a alocação está pronta
sleep 5

# Executa o script via SSH no nó alocado
log "Executando script via SSH no nó $NODE_NAME..."
ssh $NODE_NAME "cd ${PROJ_DIR} && <TAREFA/SCRIPT>" 2>&1 | while IFS= read -r line; do
    log "$line"
done

# EXEMPLO
# log "Executando script via SSH no nó $NODE_NAME..."
# ssh $NODE_NAME "cd ${PROJ_DIR} &&  docker load -i docker/rapidsai_base25.06_cuda12.8_py3.13.tar && python3 entrypoint.py" 2>&1 | while IFS= read -r line; do
#     log "$line"
# done

exit_status=$?

# Cancela a alocação após terminar
log "Cancelando alocação do job $SLURM_JOB_ID..."
scancel $SLURM_JOB_ID

if [ $exit_status -eq 0 ]; then
    log "Retreinamento concluído com sucesso"
else
    log "Erro durante o retreinamento. Código de saída: $exit_status"
fi

log "Processo finalizado"
