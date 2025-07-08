# Load the required packages
using CSV, DataFrames, JuMP, Gurobi, Plots, StatsPlots, GLPK
using Printf, XLSX , LinearAlgebra, Plots, Plots.PlotMeasures

# include("filepath to_your_functions.jl")
# # Example usage:
include("/Users/malexandrakis/Library/CloudStorage/OneDrive-Personal/Diploma_Thesis/Linear_Approximation_OPF/DC_BTheta_OPF_Functions/get_data_DC_BTheta.jl")
include("/Users/malexandrakis/Library/CloudStorage/OneDrive-Personal/Diploma_Thesis/Linear_Approximation_OPF/DC_BTheta_OPF_Functions/create_matrices_DC_BTheta.jl")
include("/Users/malexandrakis/Library/CloudStorage/OneDrive-Personal/Diploma_Thesis/Linear_Approximation_OPF/DC_BTheta_OPF_Functions/get_functions_DC_BTheta.jl")
# include(".../DC_BTheta_OPF_Functions/get_data_DC_BTheta.jl")
# include(".../DC_BTheta_OPF_Functions/create_matrices_DC_BTheta.jl")
# include(".../DC_BTheta_OPF_Functions/get_functions_DC_BTheta.jl")

# # Load the input data
# Choose input filename and path
# Example usage:
filename = "case_ieee123_modified.xlsx"
load_power_system_data_dc_btheta_opf(
    "/Users/malexandrakis/Library/CloudStorage/OneDrive-Personal/Diploma_Thesis/Linear_Approximation_OPF/Case_Files", 
    filename,
    Ssystem=1
)
# filename = "file name of the system studied.xlsx"
# load_power_system_data_thesis_linear_opf("Filepath to your system studied", 
# filename,
#  Ssystem=1
# )
  
case = splitext(filename)[1] 
println("Case name: ", case)

# # Create the bus matrices (Y and B matrices)
matrices = create_admittance_matrix_dc_btheta_opf()

# # Choose solver
solver = "gurobi"

# # Output file path
#setup_results_path("Output folder name", "Output file name.xlsx")
# Example usage:
setup_results_path("Results_DC_BTheta", "DC_BTheta_OPF_Results.xlsx")
# setup_results_path("", "")

DC_BTheta_OPF_model = create_dc_opf_problem()
# # Objective value
println("Objective value: ", objective_value(DC_BTheta_OPF_model))

# # Printing the results
create_dc_opf_results(DC_BTheta_OPF_model)

#################################################### CREATE PLOTS ####################################################
create_active_plot_DC_BTheta(production_df,OUTPATH, case;zoom_out=2, yticks_range=0:1:3)

create_voltage_magnitude_plot_BTheta(results_df,OUTPATH, case;zoom_out=2, yticks_range=0:1:3)

create_voltage_angles_plot_BTheta(results_df,OUTPATH, case;zoom_out=2, yticks_range=-20:0.5:3)

create_nodal_prices_plot_BTheta(price_df,OUTPATH, case;zoom_out=11, yticks_range=5:2:31)