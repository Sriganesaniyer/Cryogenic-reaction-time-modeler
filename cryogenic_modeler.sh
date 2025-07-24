#!/bin/bash
# cryogenic_modeler.sh - Simulates cryogenic cooling + energy lost with shape & multi-stage TA + terminal outputs

# Set input file path
INPUT_FILE="cryodata.txt"

# Check if file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found!"
    exit 1
fi

# Check if gnuplot is installed
if ! command -v gnuplot &> /dev/null; then
    echo "Error: gnuplot is not installed."
    exit 1
fi

# Function to adjust cooling constant based on shape
adjust_k_for_shape() {
    BASE_K=$1
    SHAPE=$2
    case $SHAPE in
        sphere) echo "$(echo "$BASE_K * 0.8" | bc -l)" ;;
        cube) echo "$BASE_K" ;;
        plate) echo "$(echo "$BASE_K * 1.2" | bc -l)" ;;
        *) echo "$BASE_K" ;;
    esac
}

# Read and simulate for each material
tail -n +2 "$INPUT_FILE" | while read -r MATERIAL Ti Tf TA_INIT K STEP MASS C SHAPE MULTI_STAGE_TA; do
    echo "--------------------------------"
    echo "   Simulating: $MATERIAL"
    echo "   Shape         : $SHAPE"
    echo "   Initial Temp  : $Ti K"
    echo "   Final Temp    : $Tf K"
    echo "   Ambient TA(s) : $MULTI_STAGE_TA"
    echo "   Mass          : $MASS kg"
    echo "   Specific Heat : $C J/kg·K"

    OUTFILE="cooling_${MATERIAL}.dat"
    > "$OUTFILE"
    echo "# Time(s) Temp(K) EnergyLost(J)" > "$OUTFILE"

    # Step 3: Shape-based K adjustment
    ORIGINAL_K=$K
    K=$(adjust_k_for_shape "$K" "$SHAPE")
    echo "   Cooling Constant Adjusted for Shape:"
    echo "   Base K  = $ORIGINAL_K"
    echo "   Shape   = $SHAPE → Adjusted K = $K"

    # Step 4: Parse multi-stage ambient temperatures
    IFS=',' read -ra TA_LIST <<< "$MULTI_STAGE_TA"
    [ ${#TA_LIST[@]} -eq 0 ] && TA_LIST=($TA_INIT)

    STAGE_LENGTH=100  # seconds per stage
    TIME=0
    TEMP=$Ti
    TA_CURRENT=${TA_LIST[0]}
    STAGE_INDEX=0

    # Cooling loop
    while (( $(echo "$TEMP > $Tf" | bc -l) )); do
        if (( TIME > 0 && TIME % STAGE_LENGTH == 0 && STAGE_INDEX + 1 < ${#TA_LIST[@]} )); then
            ((STAGE_INDEX++))
            TA_CURRENT=${TA_LIST[$STAGE_INDEX]}
            echo "Ambient Temp Stage Change at $TIME s → TA = $TA_CURRENT K"
        fi

        DELTA_T_STEP=$(echo "$Ti - $TEMP" | bc -l)
        Q_STEP=$(echo "$MASS * $C * $DELTA_T_STEP" | bc -l)
        printf "%d %.2f %.2f\n" "$TIME" "$TEMP" "$Q_STEP" >> "$OUTFILE"

        TEMP=$(echo "$TA_CURRENT + ($Ti - $TA_CURRENT) * e(-1 * $K * $TIME)" | bc -l)
        TIME=$((TIME + STEP))
    done

    # Final point
    DELTA_T_STEP=$(echo "$Ti - $TEMP" | bc -l)
    Q_STEP=$(echo "$MASS * $C * $DELTA_T_STEP" | bc -l)
    printf "%d %.2f %.2f\n" "$TIME" "$TEMP" "$Q_STEP" >> "$OUTFILE"

    # Step 1: Show final temperature drop
    DELTA_T_TOTAL=$(echo "$Ti - $Tf" | bc -l)
    echo "Total Temperature Drop ΔT = $DELTA_T_TOTAL K"

    # Step 2: Show final energy loss
    Q_TOTAL=$(echo "$MASS * $C * $DELTA_T_TOTAL" | bc -l)
    echo "Total Energy Lost Q = $Q_TOTAL J"

    echo "Data written to: $OUTFILE"

    # Step 5: Generate plot
    GNUPLOT_SCRIPT="plot_${MATERIAL}.gp"
    cat <<EOF > "$GNUPLOT_SCRIPT"
set terminal pngcairo size 800,600 enhanced font 'Arial,10'
set output 'plot_${MATERIAL}.png'
set title 'Cooling Curve + Energy Loss - ${MATERIAL} ($SHAPE)'
set xlabel 'Time (s)'
set ylabel 'Temperature (K)'
set y2label 'Energy Lost (J)'
set y2tics
set ytics nomirror
set grid
plot '$OUTFILE' using 1:2 with lines lw 2 title 'Temperature', \
     '$OUTFILE' using 1:3 axes x1y2 with lines lw 2 dt 2 lc rgb 'red' title 'Energy Lost'
EOF

    gnuplot "$GNUPLOT_SCRIPT"
    echo "Plot saved as: plot_${MATERIAL}.png"
done
