#!/usr/bin/env bash
# ==============================================================================
# CUDA-Lite Linux: Interactive / Automated Professor Demonstration Script
# Track C: Application-Specific Linux Distribution for NVIDIA CUDA Computing
# ==============================================================================

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

pause_step() {
    echo -e "\n${YELLOW}Press [ENTER] to continue to next step...${NC}"
    read -r
}

clear
echo -e "${BOLD}${CYAN}====================================================================${NC}"
echo -e "${BOLD}${CYAN}        CUDA-Lite Linux: Live Professor Demonstration Suite        ${NC}"
echo -e "${BOLD}${CYAN}  Track C: Application-Specific Linux Distribution for CUDA Compute  ${NC}"
echo -e "${BOLD}${CYAN}====================================================================${NC}"

# Step 1
echo -e "\n${GREEN}[Step 1/8] Setting Project Working Directory & Checking Git Status...${NC}"
cd /mnt/c/Users/shilo/OneDrive/OS_Project
git status
git log --oneline -n 3
pause_step

# Step 2
echo -e "\n${GREEN}[Step 2/8] Inspecting NVIDIA GPU Hardware & Driver State...${NC}"
nvidia-smi
pause_step

# Step 3
echo -e "\n${GREEN}[Step 3/8] Compiling CUDA Benchmark Applications (sm_89 Ada Lovelace)...${NC}"
cd /mnt/c/Users/shilo/OneDrive/OS_Project/cuda
make clean
make
pause_step

# Step 4
echo -e "\n${GREEN}[Step 4/8] Running CUDA Device Query (Hardware SM & Bandwidth Discovery)...${NC}"
./device_query
pause_step

# Step 5
echo -e "\n${GREEN}[Step 5/8] Running Primary Matrix Multiplication Benchmark (N=1024)...${NC}"
./matrix_mul 1024 5
pause_step

# Step 6
echo -e "\n${GREEN}[Step 6/8] Running Scaled Compute Stress Benchmark (N=2048)...${NC}"
./matrix_mul 2048 5
pause_step

# Step 7
echo -e "\n${GREEN}[Step 7/8] Demonstrating OS Footprint Reduction, OverlayFS & Hardening...${NC}"
cd /mnt/c/Users/shilo/OneDrive/OS_Project
echo -e "${CYAN}--- Package Exclusions (Removed Stock Bloat) ---${NC}"
head -n 25 packages/exclusions.txt
echo -e "\n${CYAN}--- Read-Only Root + OverlayFS Architecture ---${NC}"
cat system/fstab.overlay
echo -e "\n${CYAN}--- 4-Point Security Hardening Policies ---${NC}"
cat system/hardening.conf
pause_step

# Step 8
echo -e "\n${GREEN}[Step 8/8] Academic Deliverables & Final Report Summary...${NC}"
head -n 40 documentation/REPORT.md

echo -e "\n${BOLD}${GREEN}====================================================================${NC}"
echo -e "${BOLD}${GREEN}            DEMONSTRATION COMPLETE - ALL TESTS PASSED!              ${NC}"
echo -e "${BOLD}${GREEN}====================================================================${NC}"
