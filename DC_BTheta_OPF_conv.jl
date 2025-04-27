using DataFrames, JuMP
using XLSX, Gurobi
using Plots
using Plots.PlotMeasures
using StatsPlots
using DataFrames
using LinearAlgebra
using XLSX, Printf


# include("filepath to_your_functions.jl")
include("/Users/malexandrakis/Documents/Οικονομική και Αξιόπιστη/DC_BTheta_OPF_Functions/get_data_DC_BTheta.jl")
include("/Users/malexandrakis/Documents/Οικονομική και Αξιόπιστη/DC_BTheta_OPF_Functions/create_matrices_DC_BTheta.jl")
include("/Users/malexandrakis/Documents/Οικονομική και Αξιόπιστη/DC_BTheta_OPF_Functions/get_functions_DC_BTheta.jl")


# Load the data (all variables will be available globally)
filename = "case_ieee123_modified.xlsx"
load_power_system_data_dc_btheta_opf(
    "/Users/malexandrakis/Library/CloudStorage/OneDrive-Personal/Diploma_Thesis/Linear_Approximation_OPF/Case_Files", 
    filename,
    Ssystem=1
)
case = splitext(filename)[1] 
println("Case name: ", case)


# Then create matrices
matrices = create_admittance_matrix_dc_btheta_opf()

# # Choose solver
solver = "gurobi"


# # Output file path
#OUTPATH = "" # Name the folder for the results
# OUTPATH = "Results_DC_BTheta" 

# # Create the output folder if it doesn't exist
# if !ispath(OUTPATH)
#     mkpath(OUTPATH)
#     println("New directory created: ", OUTPATH)
# end

# #output_file_name = ""
# ouput_file_name = "DC_BTheta_OPF_Results.xlsx"
# results_path = joinpath(pwd(), OUTPATH, ouput_file_name)

# println("Results path: ", results_path)

setup_results_path("Results_DC_BTheta", "DC_BTheta_OPF_Results.xlsx")


DC_BTheta_OPF_model = create_dc_opf_problem()


create_dc_opf_results(DC_BTheta_OPF_model)

create_active_plot_DC_BTheta(production_df,OUTPATH, case;zoom_out=2, yticks_range=0:1:3)

create_voltage_magnitude_plot_BTheta(results_df,OUTPATH, case;zoom_out=2, yticks_range=0:1:3)

create_voltage_angles_plot_BTheta(results_df,OUTPATH, case;zoom_out=2, yticks_range=-20:0.5:3)

create_nodal_prices_plot_BTheta(price_df,OUTPATH, case;zoom_out=11, yticks_range=5:2:31)


