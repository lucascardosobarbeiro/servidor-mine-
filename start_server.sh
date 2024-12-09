#!/bin/bash

# Caminho para o diretório do servidor Minecraft
SERVER_DIR="/home/ubuntu/minecraft-server"

# Caminho para o arquivo de log
LOG_FILE="$SERVER_DIR/startup_log.txt"

# Navega até o diretório do servidor
cd "$SERVER_DIR" || exit

# Comando para iniciar o servidor Minecraft usando screen com logs
#!/usr/bin/env sh

# Iniciar uma nova sessão do screen chamada 'minecraft' e rodar o servidor
screen -dmS minecraft java -Xms3072M -Xmx6144M -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1HeapRegionSize=8M -XX:G1HeapWastePercent=5 -XX:G1MaxNewSizePercent=40 -XX:G1MixedGCCountTarget=4 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1NewSizePercent=30 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=15 -XX:MaxGCPauseMillis=200 -XX:MaxTenuringThreshold=1 -XX:SurvivorRatio=32 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar server.jar nogui
# Espera até que o servidor esteja pronto
echo "Aguardando o servidor Minecraft iniciar..."
until nc -z 127.0.0.1 25565; do
    echo "Servidor ainda não está pronto, aguardando..."
    sleep 5
done

# Exibe uma mensagem de confirmação
echo "Servidor Minecraft iniciado com sucesso!"

