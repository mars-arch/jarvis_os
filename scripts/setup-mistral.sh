#!/bin/bash
# Z.I.M.A Project - Mistral 7B Setup Script
# This script downloads and sets up the Mistral 7B Instruct model
# with llama.cpp for the Z.I.M.A project in your existing repository

set -e  # Exit on error

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Go to the project root directory (parent of scripts)
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Text colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}                     Z.I.M.A                        ${NC}"
echo -e "${BLUE}            Zero-dependency Integrated              ${NC}"
echo -e "${BLUE}                  Machine Agent                     ${NC}"
echo -e "${BLUE}====================================================${NC}"

# Create additional project directories
echo -e "\n${GREEN}[1/7] Setting up Z.I.M.A project directories...${NC}"
mkdir -p "$PROJECT_ROOT/models"
mkdir -p "$PROJECT_ROOT/src/llm"
mkdir -p "$PROJECT_ROOT/src/speech/{stt,tts}"
mkdir -p "$PROJECT_ROOT/src/hardware/{raspberry,esp32}"
mkdir -p "$PROJECT_ROOT/src/ui"
mkdir -p "$PROJECT_ROOT/data/{conversations,speech,db}"
mkdir -p "$PROJECT_ROOT/logs"

# Check for required tools
echo -e "\n${GREEN}[2/7] Checking for required tools...${NC}"
if ! command -v wget &> /dev/null; then
    echo -e "${YELLOW}Installing wget...${NC}"
    sudo apt-get update && sudo apt-get install -y wget
fi

if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}Installing git...${NC}"
    sudo apt-get update && sudo apt-get install -y git
fi

if ! command -v cmake &> /dev/null; then
    echo -e "${YELLOW}Installing cmake and build tools...${NC}"
    sudo apt-get update && sudo apt-get install -y cmake build-essential
fi

# Add some swap memory to help with model loading
echo -e "\n${GREEN}[3/7] Checking swap space...${NC}"
if [[ $(sudo swapon --show | wc -l) -lt 1 || $(sudo swapon --show | awk 'NR>1 {sum+=$3} END {print sum}') -lt 1500 ]]; then
    echo -e "${YELLOW}Insufficient swap detected, creating additional swap file...${NC}"
    sudo fallocate -l 2G /swapfile.zima
    sudo chmod 600 /swapfile.zima
    sudo mkswap /swapfile.zima
    sudo swapon /swapfile.zima
    echo '/swapfile.zima none swap sw 0 0' | sudo tee -a /etc/fstab
    echo -e "${GREEN}Created 2GB swap file${NC}"
else
    echo -e "${YELLOW}Sufficient swap already exists, skipping...${NC}"
fi

# Download Mistral 7B model
echo -e "\n${GREEN}[4/7] Downloading Mistral 7B Instruct Q4_K_M model...${NC}"
MODEL_URL="https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf"
MODEL_PATH="$PROJECT_ROOT/models/mistral-7b-instruct-v0.2.Q4_K_M.gguf"

if [ -f "$MODEL_PATH" ]; then
    echo -e "${YELLOW}Model already exists. Skipping download...${NC}"
else
    echo -e "${YELLOW}Downloading model (this may take a while)...${NC}"
    wget -q --show-progress "$MODEL_URL" -O "$MODEL_PATH"
    echo -e "${GREEN}Model download complete!${NC}"
fi

# Clone and build llama.cpp
echo -e "\n${GREEN}[5/7] Setting up llama.cpp...${NC}"
if [ -d "$PROJECT_ROOT/src/llm/llama.cpp" ]; then
    echo -e "${YELLOW}llama.cpp already exists. Updating...${NC}"
    cd "$PROJECT_ROOT/src/llm/llama.cpp"
    git pull
else
    echo -e "${YELLOW}Cloning llama.cpp...${NC}"
    cd "$PROJECT_ROOT/src/llm"
    git clone https://github.com/ggerganov/llama.cpp.git
    cd llama.cpp
fi

echo -e "${YELLOW}Building llama.cpp...${NC}"
mkdir -p build
cd build
cmake .. -DLLAMA_BLAS=ON -DLLAMA_BLAS_VENDOR=OpenBLAS
cmake --build . --config Release -j4
echo -e "${GREEN}llama.cpp build complete!${NC}"

# Create a simple test script
echo -e "\n${GREEN}[6/7] Creating test script...${NC}"
cat > "$PROJECT_ROOT/scripts/test-zima.sh" << EOL
#!/bin/bash
# Simple test script for Z.I.M.A
PROJECT_ROOT="$PROJECT_ROOT"
MODEL_PATH="\$PROJECT_ROOT/models/mistral-7b-instruct-v0.2.Q4_K_M.gguf"
LLAMA_CPP="\$PROJECT_ROOT/src/llm/llama.cpp/build/bin/main"

echo "Testing Z.I.M.A with Mistral 7B..."
echo "Sending a test prompt to the model..."

\$LLAMA_CPP -m \$MODEL_PATH \\
    -n 256 \\
    --repeat_penalty 1.1 \\
    --color \\
    --ctx_size 2048 \\
    -ngl 32 \\
    -p "<s>[INST] Hello, I am Z.I.M.A, the Zero-dependency Integrated Machine Agent. What can I help you with today? [/INST]"

echo "Test complete. If you see a response above, your model is working!"
EOL

chmod +x "$PROJECT_ROOT/scripts/test-zima.sh"

# Create a basic server script
echo -e "\n${GREEN}[7/7] Creating Z.I.M.A server script...${NC}"
cat > "$PROJECT_ROOT/scripts/start-zima-server.sh" << EOL
#!/bin/bash
# Z.I.M.A Server startup script
PROJECT_ROOT="$PROJECT_ROOT"
MODEL_PATH="\$PROJECT_ROOT/models/mistral-7b-instruct-v0.2.Q4_K_M.gguf"
LLAMA_SERVER="\$PROJECT_ROOT/src/llm/llama.cpp/build/bin/server"

echo "Starting Z.I.M.A server with Mistral 7B model..."
echo "The server will be available at http://localhost:8080"
echo "Press Ctrl+C to stop the server"

\$LLAMA_SERVER \\
    -m \$MODEL_PATH \\
    --host 0.0.0.0 \\
    --port 8080 \\
    -c 2048 \\
    --threads 4
EOL

chmod +x "$PROJECT_ROOT/scripts/start-zima-server.sh"

# Add some basic information to the README
cat > "$PROJECT_ROOT/README.md" << EOL
# Z.I.M.A Project

**Z**ero-dependency **I**ntegrated **M**achine **A**gent

A local LLM implementation with speech-to-text and text-to-speech capabilities running on Raspberry Pi 4B with ESP32 integration.

## Features

- Local LLM inference using Mistral 7B
- Speech-to-text (STT) processing
- Text-to-speech (TTS) output
- ESP32 hardware integration
- User-friendly chat interface

## Setup

1. Run the setup script to download the model and build llama.cpp:
   \`\`\`
   bash scripts/setup-mistral.sh
   \`\`\`

2. Test the model:
   \`\`\`
   bash scripts/test-zima.sh
   \`\`\`

3. Start the Z.I.M.A server:
   \`\`\`
   bash scripts/start-zima-server.sh
   \`\`\`

## Project Structure

- \`models/\`: LLM model files
- \`src/\`: Source code
  - \`llm/\`: LLM integration code
  - \`speech/\`: Speech processing (STT/TTS)
  - \`hardware/\`: Hardware integration
  - \`ui/\`: User interface
- \`data/\`: Application data
- \`scripts/\`: Utility scripts
- \`docs/\`: Documentation

## License

[MIT License](LICENSE)
EOL

echo -e "\n${GREEN}=============================================${NC}"
echo -e "${GREEN} Z.I.M.A Setup Complete!                      ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo -e "${YELLOW}To test your LLM setup, run:${NC}"
echo -e "   ${BLUE}bash scripts/test-zima.sh${NC}"
echo -e ""
echo -e "${YELLOW}To start the Z.I.M.A server:${NC}"
echo -e "   ${BLUE}bash scripts/start-zima-server.sh${NC}"
echo -e ""
echo -e "${YELLOW}Your Mistral 7B model is located at:${NC}"
echo -e "   ${BLUE}$PROJECT_ROOT/models/mistral-7b-instruct-v0.2.Q4_K_M.gguf${NC}"
echo -e ""
echo -e "${YELLOW}Happy building with Z.I.M.A!${NC}"