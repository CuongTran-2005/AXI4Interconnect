# ==========================================
# MODELSIM SIMULATION SCRIPT (run_sim.do)
# Location: ./testbench/run_sim.do
# ==========================================

# 1. Exit any simulation currently running in memory
quit -sim

# 2. Create the working library 'work' if it does not already exist
if {[file exists work] == 0} {
    vlib work
    vmap work work
}

# 3. Compile all RTL design files first (from sibling '../rtl' directory)
# -sv enables SystemVerilog features (needed for interfaces and modern logic)
# +incdir+ allows `include statements to find header files in the rtl folder
echo "--- Compiling RTL Design Modules ---"
vlog -sv +incdir+../rtl ../rtl/*.v

# 4. Compile all Testbench files in the current directory
echo "--- Compiling Testbench Modules ---"
vlog -sv +incdir+. ./*.v
vlog -sv +incdir+. ./*.sv
# 5. Load the top-level testbench for simulation
# -voptargs=+acc prevents ModelSim from optimizing away internal WDATA/AWVALID signals
# so your monitor block and waveform viewer can capture them
echo "--- Loading Top-Level Simulation ---"
vsim -voptargs=+acc work.axi_interconnect_tb

# 6. Record all signals recursively across all module hierarchies
log -r /*

# Optional: Automatically pull all signals into the GUI wave window
# Uncomment the line below if you are running in GUI mode
# add wave -hex -r /axi_interconnect_tb/*

# 7. Run the simulation until the $finish statement in your watchdog/main block
echo "--- Running Simulation ---"
run -all
