#!/bin/bash

# Defina o caminho para o arquivo de log do servidor Minecraft
SERVER_LOG="/home/ubuntu/minecraft-server/logs/latest.log"
LOG_FILE="/home/ubuntu/minecraft-server/monitor.log"

# Comando para verificar o número de jogadores
screen -S minecraft -p 0 -X stuff "list\n"
sleep 2

# Pega o número de jogadores conectados do log do Minecraft
PLAYERS_CONNECTED=$(grep -oP "(?<=There are )\d+" "$SERVER_LOG" | tail -1)

# Registra a data e o número de jogadores conectados
echo "$(date) - Jogadores conectados: $PLAYERS_CONNECTED" >> "$LOG_FILE"

# Verifica se não há jogadores conectados
if [[ -z "$PLAYERS_CONNECTED" || "$PLAYERS_CONNECTED" -eq 0 ]]; then
    echo "$(date) - Nenhum jogador conectado. Desligando em 10 minutos..." >> "$LOG_FILE"
    sleep 600  # Aguardar 10 minutos

    # Verifica novamente após 10 minutos antes de desligar
    screen -S minecraft -p 0 -X stuff "list\n"
    sleep 2
    PLAYERS_CONNECTED=$(grep -oP "(?<=There are )\d+" "$SERVER_LOG" | tail -1)

    if [[ -z "$PLAYERS_CONNECTED" || "$PLAYERS_CONNECTED" -eq 0 ]]; then
        echo "$(date) - Desligando o servidor por inatividade..." >> "$LOG_FILE"

        # Desliga o servidor Minecraft
        screen -S minecraft -p 0 -X stuff "stop\n"

        # Aguarda alguns segundos para garantir que o servidor desligue
        sleep 10

        # Desligar a máquina
        sudo shutdown -h now
    else
        echo "$(date) - Jogadores conectados novamente. Cancelando desligamento." >> "$LOG_FILE"
    fi
fi
