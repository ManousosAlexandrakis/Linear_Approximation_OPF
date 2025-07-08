using Plots
using Plots.PlotMeasures
using DataFrames
using LinearAlgebra, Dates
using XLSX, Printf


# # Set the file paths and load data
# filepath1 = "/Users/malexandrakis/Documents/Results/Paper_nodes_PV"
# filename1 = joinpath(filepath1,"ACOPF_Paper_nodes_PV.xlsx")
# filename2 = joinpath(filepath1,"ACOPF_Paper_nodes_PV_fixed.xlsx")
# filename3 = joinpath(filepath1,"BTheta_Paper_nodes_PV.xlsx")
# filename4 = joinpath(filepath1,"Decoupled_Paper_nodes_PV.xlsx")
# filename5 = joinpath(filepath1,"LINEAR_OPF_Paper_nodes_PV.xlsx")


# filepath1 = "/Users/malexandrakis/Documents/Results/ehv1"
# filename1 = joinpath(filepath1,"ACOPF_ehv1.xlsx")
# filename2 = joinpath(filepath1,"ACOPF_ehv1_fixed.xlsx")
# filename3 = joinpath(filepath1,"BTheta_ehv1.xlsx")
# filename4 = joinpath(filepath1,"Decoupled_ehv1.xlsx")
# filename5 = joinpath(filepath1,"LINEAR_OPF_ehv1.xlsx")


# filepath1 = "/Users/malexandrakis/Documents/Results/ehv5"
# filename1 = joinpath(filepath1,"ACOPF_ehv5.xlsx")
# filename2 = joinpath(filepath1,"ACOPF_ehv5_fixed.xlsx")
# filename3 = joinpath(filepath1,"BTheta_ehv5.xlsx")
# filename4 = joinpath(filepath1,"Decoupled_ehv5.xlsx")
# filename5 = joinpath(filepath1,"LINEAR_OPF_ehv5.xlsx")

# filepath1 = "/Users/malexandrakis/Documents/Results/ehv4"
# filename1 = joinpath(filepath1,"ACOPF_ehv4.xlsx")
# filename2 = joinpath(filepath1,"ACOPF_ehv4_fixed.xlsx")
# filename3 = joinpath(filepath1,"BTheta_ehv4.xlsx")
# filename4 = joinpath(filepath1,"Decoupled_ehv4.xlsx")
# filename5 = joinpath(filepath1,"LINEAR_OPF_ehv4.xlsx")


base_name = basename(filepath1) 

##################################################################################
prices_ACOPF_df = DataFrame(XLSX.readtable(filename1, "LMP"))
prices_BTheta_df = DataFrame(XLSX.readtable(filename3, "LMP"))
prices_Decoupled_df = DataFrame(XLSX.readtable(filename4, "LMP"))
prices_LINEAR_df = DataFrame(XLSX.readtable(filename5, "LMP"))
##################################################################################
Y_prices_ACOPF = prices_ACOPF_df[!, "nodal_price_euro/MWh"]
Y_prices_BTheta = prices_BTheta_df[!, "nodal_price_euro/MWh"]
Y_prices_Decoupled = prices_Decoupled_df[!, "nodal_price_euro/MWh"]
Y_prices_LINEAR = prices_LINEAR_df[!, "nodal_price_euro/MWh"]

# # https://www.color-hex.com/color-palette/894 <- The colour palette 


max_price = maximum([maximum(Y_prices_ACOPF),  maximum(Y_prices_BTheta), maximum(Y_prices_Decoupled), maximum(Y_prices_LINEAR)])
 min_price = minimum([minimum(abs.(Y_prices_ACOPF)),  minimum(abs.(Y_prices_BTheta)), minimum(abs.(Y_prices_Decoupled)), minimum(abs.(Y_prices_LINEAR))])
#min_price = 0
zoom_out = 7

fz = 18 # fontsize 
buses = prices_ACOPF_df.Bus
bus_count = length(buses)

y_min = min_price
y_max = max_price
y_median = (y_min + y_max)/2
y_range = y_max - y_min
ylim = (y_median - (y_range+ zoom_out)/2, y_median + (y_range+ zoom_out)/2)

buses_str = string.(buses)
xticks_values_prices = 0:5:bus_count
xticks_labels_prices = buses_str[1:5:end]


prices = scatter(buses_str,
            Y_prices_ACOPF,
            ylim = (y_median - (y_range+ zoom_out)/2, y_median + (y_range+ zoom_out)/2),
            xlim = (0,bus_count),
            xlabel = "Buses",
            ylabel = "Price [€/MWh]",
            legend = :topleft,
            label = "ACOPF",
            markersize = 11,
            color = RGB(237/255,201/255,81/255),
            yticks = 1140:5:1170,
            xticks = (xticks_values_prices,xticks_labels_prices),  # Set xticks and labels
            markershape = :circle,
            size = (2000, 1000),  # Adjust the size for better spacing
            xtickfontsize = fz, ytickfontsize = fz,
            fontfamily = "Courier New" , # Better Unicode support
            titlefontsize = fz+1,
            xguidefontsize = fz+1,
            yguidefontsize = fz+1,
            legendfontsize = fz-2,
            framestyle = :box,
            margin = 16mm,
            grid = :true,
            minorgrid = :true,

    )
    
hline!([0], linestyle = :dash, color = :black, label = "",alpha = 0.4)
    
plot!(buses_str, Y_prices_ACOPF, color=RGB(237/255,201/255,81/255), lw=2,label = false)  # Add line plot to connect points


scatter!(
    buses_str,
    Y_prices_BTheta,
    label = "BTHETA_OPF",
    color = RGB(79/255,55/255,45/255),
    markersize = 12,
    markerstrokewidth = 1,
    markershape =:xcross

)
#plot!(buses_str, Y_prices_BTheta, color=RGB(162/255,0/255,255/255), lw=2,label = false)  # Add line plot to connect points

scatter!(
    buses_str,
    Y_prices_Decoupled,
    label = "DECOUPLED_OPF",
    color = RGB(0/255,160/255,176/255),
    markersize = 10,
    markerstrokewidth = 1,

)

plot!(buses_str, Y_prices_Decoupled, color=RGB(0/255,160/255,176/255), lw=2,label = false)  # Add line plot to connect points
scatter!(
    buses_str,
    Y_prices_LINEAR,
    label = "Linear_Thesis_OPF",
    color = RGB(204/255,42/255,54/255),
    markersize = 10,
    markerstrokewidth = 1,
)

display(prices)

base_path = "/Users/malexandrakis/Documents/Diploma_Thesis/Plots"
output_dir = joinpath(base_path, base_name)
mkpath(output_dir)  # Creates all necessary parent directories

# # Define versioned filename
version = 4
filename = base_name * "_priced_V$version.pdf"
save_path = joinpath(output_dir, filename)

# # Save the plot
#savefig(prices, save_path)
