#!/bin/bash
# A robust script to automate Task 2 for varying I-Cache associativity.
# Results will be stored inside the Lab1-Task2 parent folder.
# 一个健壮的、用于自动执行任务二、改变指令缓存相联度的脚本。
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

# We fix the size and block size to observe the effect of associativity.
# 我们固定大小和块大小，来观察相联度的影响。
SIZE_KB=16      # Cache size in KB is fixed to 16KB for this example. (缓存大小固定为16KB)
BSIZE=32        # Block size in bytes is fixed to 32B. (块大小固定为32B)
REPL="l"        # Replacement Policy: LRU (替换策略)

# List of associativities we want to test.
# 要测试的相联度列表。
ASSOC_LIST=( 1 2 4 8 )

# --- Main Script Logic ---
echo ""
echo "Starting Instruction Cache Associativity Sweep (Size fixed at ${SIZE_KB}KB)..."
echo "开始进行指令缓存相联度的扫描实验 (大小固定为 ${SIZE_KB}KB)..."
mkdir -p "configs/${TASK_DIR}"

for assoc in "${ASSOC_LIST[@]}"
do
    size_bytes=$((SIZE_KB * 1024))
    nsets=$((size_bytes / (BSIZE * assoc)))
    
    # Look up latency for a 16KB cache from Lab Manual Table 2.
    # 根据实验手册表格2，查找16KB缓存的延迟。
    latency=0
    case $assoc in
        1)  latency=2 ;;
        2)  latency=2 ;;
        4)  latency=3 ;;
        8)  latency=3 ;;
    esac

    EXP_NAME="assoc_${assoc}_size_${SIZE_KB}k_bsize_${BSIZE}"
    RUN_DIR="${TASK_DIR}/${EXP_NAME}"
    CONFIG_FILE_PATH="configs/${RUN_DIR}/${EXP_NAME}.txt"

    echo "----------------------------------------------------"
    echo "Preparing experiment: ${EXP_NAME}"
    mkdir -p "configs/${RUN_DIR}"
    echo "  - Generating config file: ${CONFIG_FILE_PATH}"
    sed \
        -e "s/^-cache:il1.*/-cache:il1 il1:${nsets}:${BSIZE}:${assoc}:${REPL}/" \
        -e "s/^-cache:il1lat.*/-cache:il1lat ${latency}/" \
        < base1.txt > "$CONFIG_FILE_PATH"

    echo "  - Running simulation..."
    ./runsim_sim "${RUN_DIR}" "${EXP_NAME}"
    echo "  - Simulation for ${EXP_NAME} finished."
    echo "----------------------------------------------------"
done

# --- Parse all results into a CSV file ---
OUTPUT_CSV="configs/${TASK_DIR}/results_assoc_sweep.csv"
echo ""
echo "Parsing all associativity sweep results into: ${OUTPUT_CSV}"
echo "正在将所有相联度扫描结果解析到: ${OUTPUT_CSV}"
echo "DIR,CFG,BENCHMARK,sim_num_insn,sim_cycle,sim_CPI,mpi_il1,mpi_dl1" > "$OUTPUT_CSV"

for assoc in "${ASSOC_LIST[@]}"
do
    EXP_NAME="assoc_${assoc}_size_${SIZE_KB}k_bsize_${BSIZE}"
    RUN_DIR="${TASK_DIR}/${EXP_NAME}"
    ./stats_parser "${RUN_DIR}" "${EXP_NAME}" >> "$OUTPUT_CSV"
done

echo ""
echo "Results saved to ${OUTPUT_CSV}"
echo "脚本成功运行完毕。"