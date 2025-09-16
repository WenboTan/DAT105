#!/bin/bash
# A robust script to automate Task 2 for varying I-Cache size.
# This version saves the parsed results to a CSV file.
# 一个健壮的、用于自动执行任务二、改变指令缓存大小的脚本。
# 这个版本会将解析后的结果保存到一个CSV文件中。

set -e

echo "Performing pre-flight checks..."
echo "正在进行执行前检查..."
if [ ! -f "base1.txt" ] || [ ! -f "runsim_sim" ] || [ ! -x "bin/sim-outorder" ]; then
    echo "Error: Missing required files!" >&2
    exit 1
fi
echo "Pre-flight checks passed."
echo "执行前检查通过。"

# --- Configuration Variables ---
TASK_DIR="Lab1-Task2"
BSIZE=32
ASSOC=2
REPL="l"
SIZES_KB=( 4 8 16 32 )

# --- Main Script Logic ---
echo ""
echo "Starting Instruction Cache Size Sweep..."
echo "开始进行指令缓存大小的扫描实验..."
mkdir -p "configs/${TASK_DIR}"

for size_kb in "${SIZES_KB[@]}"
do
    size_bytes=$((size_kb * 1024))
    nsets=$((size_bytes / (BSIZE * ASSOC)))
    latency=0
    case $size_kb in
        4)  latency=1 ;;
        8)  latency=1 ;;
        16) latency=2 ;;
        32) latency=2 ;;
    esac

    EXP_NAME="size_${size_kb}k_assoc_${ASSOC}"
    RUN_DIR="${TASK_DIR}/${EXP_NAME}"
    CONFIG_FILE_PATH="configs/${RUN_DIR}/${EXP_NAME}.txt"

    echo "----------------------------------------------------"
    echo "Preparing experiment: ${EXP_NAME}"
    mkdir -p "configs/${RUN_DIR}"
    echo "  - Generating config file: ${CONFIG_FILE_PATH}"
    sed \
        -e "s/^-cache:il1.*/-cache:il1 il1:${nsets}:${BSIZE}:${ASSOC}:${REPL}/" \
        -e "s/^-cache:il1lat.*/-cache:il1lat ${latency}/" \
        < base1.txt > "$CONFIG_FILE_PATH"

    echo "  - Running simulation..."
    ./runsim_sim "${RUN_DIR}" "${EXP_NAME}"
    echo "  - Simulation for ${EXP_NAME} finished."
    echo "----------------------------------------------------"
done

echo ""
echo "All simulations are complete."
echo "所有模拟已完成。"

# --- Step 4: Parse all results into a CSV file (第四步：将所有结果解析到一个CSV文件中) ---
# --- THIS IS THE NEW/MODIFIED PART ---
OUTPUT_CSV="configs/${TASK_DIR}/results_size_sweep.csv"
echo ""
echo "Parsing all results into a single file: ${OUTPUT_CSV}"
echo "正在将所有结果解析到统一的文件中: ${OUTPUT_CSV}"

# Write the header row to the CSV file, overwriting old file if it exists.
# 将表头写入CSV文件，如果文件已存在则覆盖。
echo "DIR,CFG,BENCHMARK,sim_num_insn,sim_cycle,sim_CPI,mpi_il1,mpi_dl1" > "$OUTPUT_CSV"

for size_kb in "${SIZES_KB[@]}"
do
    EXP_NAME="size_${size_kb}k_assoc_${ASSOC}"
    RUN_DIR="${TASK_DIR}/${EXP_NAME}"
    
    # Append the parsed results for each experiment to the CSV file.
    # 将每次实验的解析结果追加到CSV文件的末尾。
    ./stats_parser "${RUN_DIR}" "${EXP_NAME}" >> "$OUTPUT_CSV"
done

echo ""
echo "Results saved to ${OUTPUT_CSV}"
echo "结果已保存至 ${OUTPUT_CSV}"
echo "Script finished successfully."
echo "脚本成功运行完毕。"