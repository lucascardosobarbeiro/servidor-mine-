

# Projeto de Servidor Sob Demanda para Jogos

Este projeto visa criar um servidor de jogos sob demanda, utilizando uma instância EC2 T3.large, configurado principalmente para um servidor Minecraft. A ideia central do projeto é economizar custos operacionais, mantendo o servidor desligado quando não houver jogadores conectados, mas permitindo que ele seja iniciado automaticamente quando necessário. De acordo com a calculadora de preços da AWS, a estimativa de custo mensal para o servidor foi de aproximadamente U$6,00 com uma utilização de 60 horas mensais, saindo em um preço mais em conta em consideração a hosts de jogos vps ou até servidores dedicados do mercado: [Calculadora de Preços AWS](https://calculator.aws/#/createCalculator/ec2-enhancement).

## Funcionalidades

O servidor é configurado com funções serverless para automação de tarefas, como:

- **Backups semanais**: Realizados automaticamente para garantir que os dados do servidor sejam preservados.
- **Ligar/Desligar o servidor**: O servidor pode ser iniciado ou parado com base na demanda, evitando custos extras quando não houver jogadores conectados.
- **Exclusão de backups antigos**: Para não ocupar espaço desnecessário, backups antigos são automaticamente excluídos.
  
## Outras Funcionalidades:
- **Arquivo para puxar versão mais atualizada do paper.mc**: O arquivo download_paper.sh é uma api fornecida pela desenvolvedor no qual conseguimos fazer o download do arquivo do jogo .jar sempre que executarmos, adicionei uma verificação ao arquivo para que toda vez que houver uma nova versão estável lançada seja feita a atualização automática da versão do servidor.
- **Execução do servidor sempre que a máquina for ligada de forma remota**: o arquivo start_server.sh é atrelado ao crontab da máquina que ao ser ligada inicia o servidor automaticamente, possuindo tempo de inicio para aproximadamente 30 segundos após a máquina estar ligada, em caso de falha do início do servidor o script faz inúmeras tentativas até que o servidor esteja ligado

A versão do Minecraft utilizada é a **Paper**, por oferecer melhor desempenho, otimização de memória e maior compatibilidade com mods pesados, em comparação com a versão original fornecida pela Mojang (distribuidora do jogo).

## Objetivo do Projeto

O objetivo principal deste servidor é oferecer uma plataforma de jogo divertida e de alto desempenho para amigos, com custo reduzido. A premissa é que a máquina EC2 seja mantida desligada quando não houver jogadores ativos, permitindo que o servidor e o custo mensal se ajustem conforme a demanda. Após um mês de testes, conseguimos confirmar que o projeto atende à proposta de custo-benefício, oferecendo uma excelente experiência de jogo.

## Observações
O projeto do github não consta com o arquivo .jar do servidor devido ao seu tamanho passar do limite, sendo necessário executar o arquivo download_paper.sh para o download automático do .jar localmente na máquina 

## Contato
Para dúvidas ou sugestões, fico à disposição no email: [lcb.barbeiro@gmail.com](mailto:lcb.barbeiro@gmail.com).

---

1. [Configuração da Instância EC2](#configuração-da-instância-ec2)
2. [Instalação do Servidor Minecraft](#instalação-do-servidor-minecraft)
3. [Backup Semanal do Servidor](#backup-semanal-do-servidor)
4. [Configuração da Função Lambda](#configuração-da-função-lambda)
5. [Configuração da API com API Gateway](#configuração-da-api-com-api-gateway)
6. [Automação do Servidor Minecraft](#automação-do-servidor-minecraft)
7. [Monitoramento de Jogadores](#monitoramento-de-jogadores)

## 1. Configuração da Instância EC2

### Criar Instância EC2:
- Acesse o AWS Management Console e no serviço EC2, clique em "Launch Instance".
- Escolha uma AMI do Ubuntu Server e um tipo de instância (ex. `t3.large`).
- Configure o armazenamento e as configurações de segurança (habilitar portas 25565 e 22).
- Após a instância ser criada, anote o ID da instância e o endereço IP público.

### Conectar à Instância:
Use o comando SSH para acessar sua instância:
```bash
ssh -i "sua-chave.pem" ubuntu@<seu-ip-publico>
```

## 2. Instalação do Servidor Minecraft

### Atualizar o Sistema:
```bash
sudo apt update && sudo apt upgrade -y
```

### Instalar o Java:
```bash
sudo apt install openjdk-17-jre-headless -y
```

### Baixar e Configurar o Servidor:
```bash
mkdir ~/minecraft-server
cd ~/minecraft-server
wget https://papermc.io/downloads#https://papermc.io/ci/job/Paper-1.21.2/latest/download
mv paper-*.jar server.jar
```

### Iniciar o Servidor:
```bash
java -Xmx3G -Xms3G -jar server.jar nogui
```

## 3. Backup Semanal do Servidor

### Script de Backup:
```bash
#!/bin/bash
TIMESTAMP=$(date +"%Y%m%d%H%M")
BACKUP_DIR="/home/ubuntu/minecraft-server/backups"
mkdir -p $BACKUP_DIR
tar -czf $BACKUP_DIR/backup_$TIMESTAMP.tar.gz /home/ubuntu/minecraft-server
```

### Configurar Cron Job para Backup:
Adicione o cron job para executar o backup semanalmente:
```bash
crontab -e
```
Adicione a linha:
```bash
0 2 * * 0 /bin/bash /home/ubuntu/minecraft-server/backup.sh
```

### Função Lambda para Excluir Backups Antigos:
Código Python para excluir backups com mais de 30 dias:
```python
import os
import boto3
from datetime import datetime, timedelta

s3 = boto3.client('s3')
BUCKET_NAME = '<seu-bucket-de-backups>'

def lambda_handler(event, context):
    response = s3.list_objects_v2(Bucket=BUCKET_NAME)
    if 'Contents' in response:
        for obj in response['Contents']:
            last_modified = obj['LastModified']
            if last_modified < datetime.now(tz=last_modified.tzinfo) - timedelta(days=30):
                s3.delete_object(Bucket=BUCKET_NAME, Key=obj['Key'])
    return {'status': 'success'}
```

## 4. Configuração da Função Lambda

### Criar Função Lambda:
Crie uma função Lambda no AWS Management Console. Use o código abaixo para iniciar o servidor Minecraft e verificar seu status.

```javascript
const AWS = require('aws-sdk');
const ec2 = new AWS.EC2();

exports.handler = async (event) => {
    const instanceId = '<seu-id-da-instancia>';

    if (event.httpMethod === 'POST' && event.path === '/start') {
        const params = { InstanceIds: [instanceId] };
        await ec2.startInstances(params).promise();
        return { statusCode: 200, body: JSON.stringify({ message: 'Servidor iniciado' }) };
    } else if (event.httpMethod === 'GET' && event.path === '/status') {
        const params = { InstanceIds: [instanceId] };
        const data = await ec2.describeInstances(params).promise();
        const status = data.Reservations[0].Instances[0].State.Name;
        return { statusCode: 200, body: JSON.stringify({ status }) };
    }
    return { statusCode: 404, body: JSON.stringify({ message: 'Not Found' }) };
};
```

## 5. Configuração da API com API Gateway

### Criar API:
Crie uma API REST no AWS API Gateway, vincule-a à função Lambda criada. Defina os endpoints `/start` (POST) e `/status` (GET).

### Implantar API:
Implemente a API e anote a URL gerada para usá-la na comunicação com o servidor.

## 6. Automação do Servidor Minecraft

### Script de Monitoramento:
Crie o script `check_players.sh` que verifica a quantidade de jogadores no servidor e desliga a instância EC2 se não houver jogadores:
```bash
#!/bin/bash
if [ $(<caminho_do_seu_script_que_verifica_jogadores>) -eq 0 ]; then
    aws ec2 stop-instances --instance-ids <seu-id-da-instancia>
fi
```

### Configurar Cron Job para Monitoramento:
Adicione o cron job para verificar os jogadores a cada 5 minutos:
```bash
crontab -e
```
Adicione a linha:
```bash
*/5 * * * * /bin/bash /home/ubuntu/minecraft-server/check_players.sh
```

### Script para Iniciar o Servidor no Boot:
Crie o script `start_server.sh` para iniciar automaticamente o servidor ao iniciar a instância:
```bash
#!/bin/bash
cd /home/ubuntu/minecraft-server
java -Xmx3G -Xms3G -jar server.jar nogui
```

### Configurar o Script para Executar no Boot:
Adicione ao systemd:
```bash
sudo nano /etc/systemd/system/minecraft.service
```
Conteúdo:
```ini
[Unit]
Description=Minecraft Server

[Service]
WorkingDirectory=/home/ubuntu/minecraft-server
ExecStart=/bin/bash /home/ubuntu/minecraft-server/start_server.sh
Restart=always
User=ubuntu

[Install]
WantedBy=multi-user.target
```
Ative e inicie o serviço:
```bash
sudo systemctl enable minecraft
sudo systemctl start minecraft
```

## 7. Monitoramento de Jogadores

Configure o RCON para monitorar a quantidade de jogadores conectados e automatizar o desligamento do servidor caso necessário.
