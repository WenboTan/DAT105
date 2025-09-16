#!/bin/bash
# A robust script to automate Task 2 for varying I-Cache block size.
# Results will be stored inside the Lab1-Task2 parent folder.
# 一个健壮的、用于自动执行任务二、改变指令缓存块大小的脚本。
# 结果将被存放在 Lab1-Task2 父文件夹中。

set -e

echo "Performing pre-flight checks..."
echo "正在进行执行前检查..."
if [ ! -f "base1.txt" ] || [ ! -f "runsim_sim" ] || [ ! -x "bin/sim-outorder" ]; then
    echo "Error: Missing required files!" >&2
    exit 1
fi
echo "Pre-flight checks passed."

# --- Configuration Variables ---
TASK_DIR="Lab1-Task2"

# We fix the size and associativity to observe the effect of block size.
# 我们固定大小和相联度，来观察块大小的影响。
SIZE_KB=16      # Cache size in KB is fixed to 16KB. (缓存大小固定为16KB)
ASSOC=2         # Associativity is fixed to 2-way. (相联度固定为2路)
REPL="l"        # Replacement Policy: LRU (替换策略)

# List of block sizes we want to test, in bytes.
# 要测试的块大小列表 (单位：字节)。
BSIZE_LIST=( 32 128 )

# IMPORTANT NOTE: Lab Manual Table 2 does not specify how latency changes with block size.
# We will assume a constant hit latency for a fixed 16KB, 2-way cache.
# 重要提示：实验手册表格2未指明延迟随块大小的变化。
# 我们假设对于固定的16KB, 2路缓存，命中延迟保持不变。
LATENCY=2       # Hit latency in cycles. (命中延迟周期)

# --- Main Script Logic ---
echo ""
echo "Starting Instruction Cache Block Size Sweep (Size fixed at ${SIZE_KB}KB)..."
echo "开始进行指令缓存块大小的扫描实验 (大小固定为 ${SIZE_KB}KB)..."
mkdir -p "configs/${TASK_DIR}"

for bsize in "${BSIZE_LIST[@]}"
do
    size_bytes=$((SIZE_KB * 1024))
    nsets=$((size_bytes / (bsize * ASSOC)))
    
    EXP_NAME="bsize_${bsize}_size_${SIZE_KB}k_assoc_${ASSOC}"
    RUN_DIR="${TASK_DIR}/${EXP_NAME}"
    CONFIG_FILE_PATH="configs/${RUN_DIR}/${EXP_NAME}.txt"

    echo "----------------------------------------------------"
    echo "Preparing experiment: ${EXP_NAME}"
    mkdir -p "configs/${RUN_DIR}"
    echo "  - Generating config file: ${CONFIG_FILE_PATH}"
    sed \
        -e "s/^-cache:il1.*/-cache:il1 il1:${nsets}:${bsize}:${ASSOC}:${REPL}/" \
        -e "s/^-cache:il1lat.*/-cache:il1lat ${LATENCY}/" \
        < base1.txt > "$CONFIG_FILE_PATH"

    echo "  - Running simulation..."
    ./runsim_sim "${RUN_DIR}" "${EXP_NAME}"
    echo "  - Simulation for ${EXP_NAME} finished."
    echo "----------------------------------------------------"
done

# --- Parse all results into a CSV file ---
OUTPUT_CSV="configs/${TASK_DIR}/results_bsize_sweep.csv"
echo ""
echo "Parsing all block size sweep results into: ${OUTPUT_CSV}"
echo "正在将所有块大小扫描结果解析到: ${OUTPUT_CSV}"
echo "DIR,CFG,BENCHMARK,sim_num_insn,sim_cycle,sim_CPI,mpi_il1,mpi_dl1" > "$OUTPUT_CSV"

for bsize in "${BSIZE_LIST[@]}"
do
    EXP_NAME="bsize_${bsize}_size_${SIZE_KB}k_assoc_${ASSOC}"
    RUN_DIR="${TASK_DIR}/${EXP_NAME}"
    ./stats_parser "${RUN_DIR}" "${EXP_NAME}" >> "$OUTPUT_CSV"
done

echo ""
echo "Results saved to ${OUTPUT_CSV}"
echo "脚本成功运行完毕。"