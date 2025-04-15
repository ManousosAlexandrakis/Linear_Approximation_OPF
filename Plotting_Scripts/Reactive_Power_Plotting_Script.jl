using Plots
using Plots.PlotMeasures
using StatsPlots
using DataFrames
using LinearAlgebra,Dates
using XLSX, Plots , PlotThemes,Printf





# # Set the file paths and load data
#  filepath1 = "/Users/malexandrakis/Documents/Results/Paper_nodes_PV"
#  filename1 = joinpath(filepath1,"ACOPF_Paper_nodes_PV.xlsx")
#  filename2 = joinpath(filepath1,"ACOPF_Paper_nodes_PV_fixed.xlsx")
#  filename3 = joinpath(filepath1,"BTheta_Paper_nodes_PV.xlsx")
#  filename4 = joinpath(filepath1,"Decoupled_Paper_nodes_PV.xlsx")
#  filename5 = joinpath(filepath1,"LINEAR_OPF_Paper_nodes_PV.xlsx")

#   filepath1 = "/Users/malexandrakis/Documents/Results/Paper_nodes_PV_no_flows_constraints/"
#   filename1 = joinpath(filepath1,"ACOPF_Paper_nodes_PV.xlsx")
#   filename2 = joinpath(filepath1,"ACOPF_Paper_nodes_PV_fixed.xlsx")
#   filename3 = joinpath(filepath1,"BTheta_Paper_nodes_PV.xlsx")
#   filename4 = joinpath(filepath1,"Decoupled_Paper_nodes_PV.xlsx")
#   filename5 = joinpath(filepath1,"LINEAR_OPF_Paper_nodes_PV.xlsx")
#   filename6 = joinpath(filepath1,"LINEAR_OPF_Paper_nodes_PV_fixed_active.xlsx")


#    filepath1 = "/Users/malexandrakis/Documents/Results/ehv1"
#    filename1 = joinpath(filepath1,"ACOPF_ehv1.xlsx")
#    filename2 = joinpath(filepath1,"ACOPF_ehv1_fixed.xlsx")
#    filename3 = joinpath(filepath1,"BTheta_ehv1.xlsx")
#    filename4 = joinpath(filepath1,"Decoupled_ehv1.xlsx")
#    filename5 = joinpath(filepath1,"LINEAR_OPF_ehv1.xlsx")


#   filepath1 = "/Users/malexandrakis/Documents/Results/ehv5"
#   filename1 = joinpath(filepath1,"ACOPF_ehv5.xlsx")
#   filename2 = joinpath(filepath1,"ACOPF_ehv5_fixed.xlsx")
#   filename3 = joinpath(filepath1,"BTheta_ehv5.xlsx")
#   filename4 = joinpath(filepath1,"Decoupled_ehv5.xlsx")
#   filename5 = joinpath(filepath1,"LINEAR_OPF_ehv5.xlsx")

#   filepath1 = "/Users/malexandrakis/Documents/Results/ehv4"
#   filename1 = joinpath(filepath1,"ACOPF_ehv4.xlsx")
#   filename2 = joinpath(filepath1,"ACOPF_ehv4_fixed.xlsx")
#   filename3 = joinpath(filepath1,"BTheta_ehv4.xlsx")
#   filename4 = joinpath(filepath1,"Decoupled_ehv4.xlsx")
#   filename5 = joinpath(filepath1,"LINEAR_OPF_ehv4.xlsx")


base_name = basename(filepath1) 
##################################################################################
reactive_ACOPF_df = DataFrame(XLSX.readtable(filename1, "reactive"))
reactive_ACOPF_fixed_df = DataFrame(XLSX.readtable(filename2,"reactive"))
reactive_Decoupled_df = DataFrame(XLSX.readtable(filename4, "production"))
reactive_LINEAR_df = DataFrame(XLSX.readtable(filename5, "Reactive_Production"))
reactive_LINEAR_fixed_df = DataFrame(XLSX.readtable(filename6,"Reactive_Production"))
##################################################################################
Y_reactive_ACOPF = reactive_ACOPF_df[!, "q_pu"]
Y_reactive_ACOPF_fixed = reactive_ACOPF_fixed_df[!, "q_pu"]
Y_reactive_Decoupled = reactive_Decoupled_df[!, "q"]
Y_reactive_LINEAR = reactive_LINEAR_df[!, "q_pu"]
Y_reactive_fixed_LINEAR = reactive_LINEAR_fixed_df[!, "q_pu"]

X= reactive_ACOPF_df.Bus


# #  https://www.color-hex.com/color-palette/894 <-- This is the colour palette that we will be used as a basis





buses = reactive_ACOPF_df.Bus
# # Convert buses to a string to treat them as categorical

bus_count = length(X)

max_reactive = maximum([maximum(Y_reactive_ACOPF),  maximum(Y_reactive_Decoupled), maximum(Y_reactive_LINEAR)])
min_reactive = minimum([minimum(Y_reactive_ACOPF),  minimum(Y_reactive_Decoupled), minimum(Y_reactive_LINEAR)])

max_reactive = maximum([maximum(Y_reactive_ACOPF),  maximum(Y_reactive_ACOPF_fixed), maximum(Y_reactive_LINEAR), maximum(Y_reactive_fixed_LINEAR)])
min_reactive = minimum([minimum(Y_reactive_ACOPF),  minimum(Y_reactive_ACOPF_fixed), minimum(Y_reactive_LINEAR),minimum(Y_reactive_fixed_LINEAR)])



fz = 18 # fontsize 
zoom_out = -0.2
y_min = max_reactive
y_max = min_reactive
y_median = (y_min + y_max)/2
y_range = y_max - y_min
ylim = (y_median - abs((y_range + zoom_out)/2), 
        y_median + abs((y_range + zoom_out)/2))
xlim = (0.5,bus_count+2.2)




bar_width = 0.2  # Width of each bar
offset = bar_width

# # Convert buses to a string to treat them as categorical
buses_str = string.(buses)
x_indices = 1:(length(buses_str)+2)/length(buses_str):length(buses_str)+2  # Numerical indices for the buses






# # Create a base bar chart for the first dataset
reactive = bar(
    x_indices .- 2offset,  # Center the first group of bars
    Y_reactive_ACOPF,  # Values for the first dataset
    ylim = (y_median - abs((y_range + zoom_out)/2), 
        y_median + abs((y_range + zoom_out)/2)),
    xlim = (0.5,bus_count+1.6),
    xlabel = "Buses",
    ylabel = "Reactive Power Production [p.u.]",
    #title = "Reactive Power Production",
    label = "ACOPF",  # Label for the legend
    color = RGB(237/255,201/255,81/255),  # Color for the dataset
    legend = :bottomright,
    bar_width = bar_width,  # Set the width of the bars
    size = (1000, 1000),  # Adjust the size for better spacing
    xticks = (x_indices, buses_str),  # Map numerical x-values to string labels
    yticks = -2:0.2:2,  
    xtickfontsize = fz, ytickfontsize = fz,
    fontfamily = "Courier New" , # Better Unicode support
    titlefontsize = fz,
    xguidefontsize = fz,
    yguidefontsize = fz,
    legendfontsize = fz-6,
    framestyle = :box,
    margin = 10mm,
    grid = :true,
    minorgrid = :true,
)

bar!(
    x_indices .- 1*offset,  # Center the first group of bars
    Y_reactive_LINEAR,  # Values for the first dataset
    label = "Linear_Thesis_OPF",
    color = RGB(204/255,42/255,54/255),
    bar_width = bar_width,  # Set the width of the bars

)

# bar!(
#     x_indices .- 0*offset,  # Center the first group of bars
#     Y_reactive_fixed_LINEAR,  # Values for the first dataset
#     label = "Linear_Thesis_OPF_with_fixed_active",
#     color = :green,
#     bar_width = bar_width,  # Set the width of the bars

# )

# bar!(
#     x_indices .+ 1*offset,  # Center the first group of bars
#     Y_reactive_ACOPF_fixed,  # Values for the first dataset
#     label = "ACOPF_modified",
#     color = :purple,
#     bar_width = bar_width,  # Set the width of the bars

# )


 bar!(x_indices .+ 0*offset,  # Center the first group of bars
     Y_reactive_Decoupled,  # Values for the first dataset
     label = "Decoupled_OPF",
     color = RGB(0/255,160/255,176/255),
     bar_width = bar_width,  # Set the width of the bars


 )

hline!([0], linestyle = :dash, color = :black, label = "",alpha = 0.5)
display(reactive)

base_path = "/Users/malexandrakis/Documents/Diploma_Thesis/Plots"
output_dir = joinpath(base_path, base_name)
mkpath(output_dir)  # Creates all necessary parent directories

# # Define versioned filename
version = 3
#filename = base_name * "_reactive_fixed_V$version.pdf"
filename = base_name * "_reactive_V$version.pdf"
save_path = joinpath(output_dir, filename)

# # Save the plot
savefig(reactive, save_path)

