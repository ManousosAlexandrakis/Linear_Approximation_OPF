using Plots
using Plots.PlotMeasures
using StatsPlots
using DataFrames
using LinearAlgebra,Dates
using XLSX, Plots , PlotThemes,Printf


# # Set the file paths and load data
filepath1 = "/Users/malexandrakis/Documents/Results/Paper_nodes_PV/" # Input folder filepath
# Name of each XLSX file in the input folder that we want to plot
filename1 = joinpath(filepath1,"ACOPF_Paper_nodes_PV.xlsx")          
filename2 = joinpath(filepath1,"ACOPF_Paper_nodes_PV_fixed.xlsx")
filename3 = joinpath(filepath1,"BTheta_Paper_nodes_PV.xlsx")
filename4 = joinpath(filepath1,"Decoupled_Paper_nodes_PV.xlsx")
filename5 = joinpath(filepath1,"LINEAR_OPF_Paper_nodes_PV.xlsx")
filename6 = joinpath(filepath1,"LINEAR_OPF_Paper_nodes_PV_fixed_active.xlsx")


base_name = basename(filepath1) 
##################################################################################
production_ACOPF_df = DataFrame(XLSX.readtable(filename1, "prod"))
production_ACOPF_fixed_df = DataFrame(XLSX.readtable(filename2, "prod"))
production_BTheta_df = DataFrame(XLSX.readtable(filename3, "production"))
production_Decoupled_df = DataFrame(XLSX.readtable(filename4, "production"))
production_LINEAR_df = DataFrame(XLSX.readtable(filename5, "production"))
production_LINEAR_fixed_df = DataFrame(XLSX.readtable(filename6, "production"))

##################################################################################
Y_ACOPF = production_ACOPF_df[!, "p"]
Y_ACOPF_fixed = production_ACOPF_fixed_df[!, "p"]
Y_BTheta = production_BTheta_df[!, "production"]
Y_Decoupled = production_Decoupled_df[!, "production"]
Y_LINEAR = production_LINEAR_df[!, "production"]
Y_LINEAR_fixed = production_LINEAR_fixed_df[!, "production"]

X= production_ACOPF_df.bus
##################################################################################

# # https://www.color-hex.com/color-palette/894 <-- This is the colour palette used as a basis



bus_count = length(X)
max_production = maximum([maximum(Y_ACOPF), maximum(Y_BTheta), maximum(Y_Decoupled),maximum(Y_LINEAR)])

# # Data preparation
buses = production_ACOPF_df.bus

# # y_range 
y_min = minimum([minimum(Y_ACOPF), minimum(Y_BTheta), minimum(Y_Decoupled),minimum(Y_LINEAR)])
y_max = maximum([maximum(Y_ACOPF), maximum(Y_BTheta), maximum(Y_Decoupled),maximum(Y_LINEAR)])
y_median = (y_min + y_max)/2
y_range = y_max - y_min


bar_width = 0.2  # Width of each bar
offset = bar_width

# # Convert buses to a string to treat them as categorical
buses_str = string.(buses)
x_indices = 1:(length(buses_str)+2)/length(buses_str):length(buses_str)+2  # Numerical indices for the buses

# # ADJUST ONLY zoom_out AND yticks
fz = 18 # fontsize 
zoom_out = 0.25

# # Create a base bar chart for the ACOPF dataset
production = bar(
    x_indices .- 2offset,  # Center the first group of bars
    Y_ACOPF,  # Values for the first dataset
    ylim = (max(y_median - (y_range + zoom_out)/2, 0), y_median + (y_range + zoom_out)/2),
    xlim = (0.5,bus_count+2.2),
    xlabel = "Buses",
    ylabel = "Active Power Production [p.u.]",
    #title = "Active Power Production",
    label = "ACOPF",  # Label for the legend
    color = RGB(237/255,201/255,81/255),  # Color for the dataset
    bar_width = bar_width,  # Set the width of the bars
    size = (1200, 1000),  # Adjust the size for better spacing
    xticks = (x_indices, buses_str),  # Map numerical x-values to string labels
    yticks = 0:0.5:3,  
    xtickfontsize = fz, ytickfontsize = fz,
    fontfamily = "Courier New" , 
    titlefontsize = fz,
    xguidefontsize = fz,
    yguidefontsize = fz,
    legendfontsize = fz-6,
    legend = :true,
    framestyle = :box,
    margin = 10mm,
    grid = :true,
    minorgrid = :true,
)

bar!(
    x_indices .- 1*offset,  # Center the first group of bars
    Y_LINEAR,  # Values for the first dataset
    label = "Linear_Thesis_OPF",
    color = RGB(204/255,42/255,54/255),
    bar_width = bar_width,  # Set the width of the bars
)

# bar!(
#     x_indices .- 0*offset,  # Center the first group of bars
#     Y_LINEAR_fixed,  # Values for the first dataset
#     label = "Linear_Thesis_OPF_with_fixed_active",
#     color = :green,
#     bar_width = bar_width,  # Set the width of the bars
# )

# bar!(
#     x_indices .+1*offset,  # Center the first group of bars
#     Y_ACOPF_fixed,  # Values for the first dataset
#     label = "ACOPF_modified",
#     color = :purple,
#     bar_width = bar_width,  # Set the width of the bars
# )

 bar!(x_indices .+ 0*offset,  # Center the first group of bars
     Y_BTheta,  # Values for the first dataset
     label = "BTHETA_OPF",
     color = RGB(79/255,55/255,45/255),
     bar_width = bar_width,  # Set the width of the bars
 )

 bar!(x_indices .+ 1*offset,  # Center the first group of bars
     Y_Decoupled,  # Values for the first dataset
     label = "Decoupled_OPF",
     color = RGB(0/255,160/255,176/255),
     bar_width = bar_width,  # Set the width of the bars

 )
display(production)

# # Define output filepath
base_path = "/Users/malexandrakis/Documents/Diploma_Thesis/Plots" # Choose the ouput Folder in which plot will be stored
output_dir = joinpath(base_path, base_name) 
mkpath(output_dir)  # Creates all necessary parent directories

# # Define versioned filename
version = 6

#filename = base_name * "_active_fixed_V$version.pdf"
filename = base_name * "_active_V$version.pdf" # Output file name will start with the name of the input folder
save_path = joinpath(output_dir, filename)  

# # Save the plot
savefig(production, save_path)





 