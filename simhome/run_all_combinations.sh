#!/bin/bash
# A robust script to automate Task 2 for all combinations of size and associativity.
# This script is configured by changing the BSIZE variable below.

# --- Safety Feature: Exit Immediately on Error ---
set -e

# --- Pre-flight Checks ---
echo "Performing pre-flight checks..."
if [ ! -f "base1.txt" ] || [ ! -f "runsim_sim" ] || [ ! -x "bin/sim-outorder" ]; then
    echo "Error: Missing required files (base1.txt, runsim_sim, or bin/sim-outorder)!" >&2
    exit 1
fi
echo "Pre-flight checks passed."


# --- ###################### CONFIGURATION ###################### ---
# Set the Block Size for this entire run (32 or 128).
# <-- RUN ONCE WITH 32, THEN CHANGE TO 128 AND RUN AGAIN -->
BSIZE=128
# --- ################### END OF CONFIGURATION ################## ---


# --- Static Variables ---
TASK_DIR="Lab1-Task2"
REPL="l"
SIZES_KB=( 4 8 16 32 )
ASSOC_LIST=( 1 2 4 8 )
OUTPUT_CSV="configs/${TASK_DIR}/results_bsize_${BSIZE}.csv"

# --- Main Script Logic ---
echo ""
echo "Starting exhaustive sweep for Block Size: ${BSIZE}B..."
mkdir -p "configs/${TASK_DIR}"

# Write the header row to the CSV file, overwriting the old file.
echo "DIR,CFG,BENCHMARK,sim_num_insn,sim_cycle,sim_CPI,mpi_il1,mpi_dl1" > "$OUTPUT_CSV"

# Outer loop for cache sizes.
for size_kb in "${SIZES_KB[@]}"
do
    # Inner loop for associativities.
    for assoc in "${ASSOC_LIST[@]}"
    do
        # --- Step 1: Calculate parameters ---
        size_bytes=$((size_kb * 1024))
        nsets=$((size_bytes / (BSIZE * assoc)))
        
        # Comprehensive latency lookup based on Lab Manual Table 2.
        latency=0
        case $size_kb in
            4)
                case $assoc in
                    1) latency=1 ;; 2) latency=1 ;; 4) latency=2 ;; 8) latency=2 ;;
                esac
                ;;
            8)
                case $assoc in
                    1) latency=1 ;; 2) latency=2 ;; 4) latency=2 ;; 8) latency=3 ;;
                esac
                ;;
            16)
                case $assoc in
                    1) latency=2 ;; 2) latency=2 ;; 4) latency=3 ;; 8) latency=3 ;;
                esac
                ;;
            32)
                case $assoc in
                    1) latency=2 ;; 2) latency=3 ;; 4) latency=3 ;; 8) latency=4 ;;
                esac
                ;;
        esac

        EXP_NAME="bsize${BSIZE}_size${size_kb}k_assoc${assoc}"
        RUN_DIR="${TASK_DIR}/${EXP_NAME}"
        CONFIG_FILE_PATH="configs/${RUN_DIR}/${EXP_NAME}.txt"

        echo "----------------------------------------------------"
        echo "Preparing experiment: ${EXP_NAME}"
        
        # --- Step 2: Create the configuration file ---
        mkdir -p "configs/${RUN_DIR}"
        
        sed \
            -e "s/^-cache:il1.*/-cache:il1 il1:${nsets}:${BSIZE}:${assoc}:${REPL}/" \
            -e "s/^-cache:il1lat.*/-cache:il1lat ${latency}/" \
            < base1.txt > "$CONFIG_FILE_PATH"

        # --- Step 3: Run the simulation ---
        echo "  - Running simulation for ${EXP_NAME}..."
        ./runsim_sim "${RUN_DIR}" "${EXP_NAME}"
        
        # --- Step 4: Parse results and append to CSV ---
        ./stats_parser "${RUN_DIR}" "${EXP_NAME}" >> "$OUTPUT_CSV"

        echo "  - Experiment ${EXP_NAME} finished and results appended."
        echo "----------------------------------------------------"

    done
done

echo ""
echo "All simulations for BSIZE=${BSIZE} are complete."
echo "Results have been saved to ${OUTPUT_CSV}"
echo "Script finished successfully."
