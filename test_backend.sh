#!/bin/bash

# CarSync - Backend Connection Test Script
# Use este script para diagnosticar problemas de conexão com o backend

echo "╔════════════════════════════════════════════════╗"
echo "║     CarSync Backend Connection Diagnostic     ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para testar URL
test_url() {
    local url=$1
    local name=$2
    
    echo -n "  Testando $name... "
    
    if timeout 3 curl -s -o /dev/null -w "%{http_code}" "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Online${NC}"
        return 0
    else
        echo -e "${RED}✗ Offline${NC}"
        return 1
    fi
}

# Função para testar porta
test_port() {
    local host=$1
    local port=$2
    
    echo -n "  Testando $host:$port... "
    
    if timeout 2 /bin/bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
        echo -e "${GREEN}✓ Respondendo${NC}"
        return 0
    else
        echo -e "${RED}✗ Não respondeu${NC}"
        return 1
    fi
}

# 1. Verificar conectividade local
echo -e "${BLUE}1. Conectividade Local:${NC}"
test_port localhost 3000

echo ""

# 2. Obter IPs da máquina
echo -e "${BLUE}2. IPs Detectados na Máquina:${NC}"

if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print "  • " $2}'
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    hostname -I | awk '{for(i=1;i<=NF;i++) print "  • " $i}'
else
    # Windows (Git Bash)
    ipconfig | grep "IPv4" | awk '{print "  • " $NF}'
fi

echo ""

# 3. Testar URLs comuns
echo -e "${BLUE}3. Testando URLs Comuns:${NC}"
test_url "http://localhost:3000/api/health" "localhost:3000"
test_url "http://127.0.0.1:3000/api/health" "127.0.0.1:3000"

# Se tem IP fornecido como argumento
if [ ! -z "$1" ]; then
    test_url "http://$1:3000/api/health" "$1:3000"
fi

echo ""

# 4. Verificar se processo Node está rodando
echo -e "${BLUE}4. Processos em Port 3000:${NC}"

if [[ "$OSTYPE" == "darwin"* ]] || [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if lsof -i :3000 > /dev/null 2>&1; then
        echo "  $(lsof -i :3000 | tail -1 | awk '{print "  • PID: " $2 ", Comando: " $1}')"
    else
        echo -e "  ${RED}✗ Nenhum processo em :3000${NC}"
    fi
else
    echo "  (Use: netstat -ano | findstr 3000 no Command Prompt)"
fi

echo ""

# 5. Sugestões
echo -e "${YELLOW}💡 Dicas:${NC}"
echo "  • Se todos os testes falharem: iniciar o backend com"
echo "    npm start  (ou seu comando de inicialização)"
echo ""
echo "  • Se localhost funciona mas IP remoto não:"
echo "    Mudar no backend de 'localhost' para '0.0.0.0'"
echo "    Veja: CONFIG_BACKEND_REMOTO.md"
echo ""
echo "  • Para testar de outro dispositivo:"
echo "    curl http://<SEU_IP>:3000/api/health"
echo ""

# 6. Teste de curl detalhado
echo -e "${BLUE}5. Teste Detalhado de Conexão:${NC}"
echo "  Testando http://localhost:3000/api/health"
echo ""

if curl -v http://localhost:3000/api/health 2>&1 | head -20; then
    echo -e "\n  ${GREEN}✓ Backend respondendo${NC}"
else
    echo -e "\n  ${RED}✗ Backend não respondendo${NC}"
    echo -e "  ${YELLOW}Inicie o backend com: npm start${NC}"
fi

echo ""
echo "╔════════════════════════════════════════════════╗"
echo "║              Diagnóstico Completo             ║"
echo "╚════════════════════════════════════════════════╝"
