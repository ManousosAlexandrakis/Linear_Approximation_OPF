# Load the required packages
using CSV, DataFrames, JuMP, Gurobi, Plots, StatsPlots
using Printf, XLSX
using Plots
using Plots.PlotMeasures
using LinearAlgebra


# include("filepath to_your_functions.jl")
include("/Users/malexandrakis/Documents/Οικονομική και Αξιόπιστη/Decoupled_OPF_Functions/get_data_Decoupled.jl")
include("/Users/malexandrakis/Documents/Οικονομική και Αξιόπιστη/Decoupled_OPF_Functions/create_matrices_Decoupled.jl")
include("/Users/malexandrakis/Documents/Οικονομική και Αξιόπιστη/Decoupled_OPF_Functions/get_functions_Decoupled.jl")


# Load the data (all variables will be available globally)
filename = "case_ieee123_modified.xlsx"
load_power_system_data_decoupled_opf(
    "/Users/malexandrakis/Library/CloudStorage/OneDrive-Personal/Diploma_Thesis/Linear_Approximation_OPF/Case_Files", 
    filename,
    Ssystem=1
)
case = splitext(filename)[1] 
println("Case name: ", case)



matrices = create_admittance_matrix_decoupled_opf()

# Access global variables:
println("Sample Y matrix element: ", Y[1,1])
println("Sample B matrix element: ", B[1,2])


# # Choose solver
solver = "gurobi"

# # # Output file path
# #OUTPATH = "" # Name the folder for the results
# OUTPATH = "Results_Decoupled" 

# # Create the output folder if it doesn't exist
# if !ispath(OUTPATH)
#     mkpath(OUTPATH)
#     println("New directory created: ", OUTPATH)
# end

# #output_file_name = ""
# ouput_file_name = "Decoupled_OPF_Results.xlsx"
# results_path = joinpath(pwd(), OUTPATH, ouput_file_name)

# println("Results path: ", results_path)

setup_results_path("Results_Decoupled", "Decoupled_OPF_Results.xlsx")


DC_BTheta_OPF_model = create_decoupled_opf_problem()


create_decoupled_opf_results(DC_BTheta_OPF_model)

create_active_plot_Decoupled(production_df,OUTPATH, case;zoom_out=2, yticks_range=0:1:3)

create_reactive_plot_Decoupled(production_df,OUTPATH, case;zoom_out=-0.3, yticks_range=0:0.5:4)

create_voltage_magnitude_plot_Decoupled(results_df,OUTPATH, case;zoom_out=2, yticks_range=0:1:3)

create_voltage_angles_plot_Decoupled(results_df,OUTPATH, case;zoom_out=2, yticks_range=-20:0.5:3)

create_nodal_prices_plot_Decoupled(price_df,OUTPATH, case;zoom_out=11, yticks_range=5:2:40)