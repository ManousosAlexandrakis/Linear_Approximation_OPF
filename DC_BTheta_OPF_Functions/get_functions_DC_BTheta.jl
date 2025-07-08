function create_dc_opf_problem()
    # Create Gurobi environment and model
    if solver == "gurobi"
        GUROBI_ENV = Gurobi.Env()
        model = Model(() -> Gurobi.Optimizer(GUROBI_ENV))
    else
        model = Model(GLPK.Optimizer)
    end

    set_silent(model) ### Variables (will be stored globally)

    ### Variables
    @variable(model, f[1:n,1:n])   # Active Power flow (both directions)
    @variable(model, p[Nodes] >= 0) # Active Power production
    @variable(model, delta[Nodes])  # Voltage angles
    @variable(model, V[Nodes])      # Voltage magnitudes

# # Real Power Flow calculation for each edge
@constraint(model,[m in Nodes,n in connected_buses_dict[m]],B[bus_id_to_index[m], bus_id_to_index[n]] *(delta[m] - delta[n])==f[bus_id_to_index[m], bus_id_to_index[n]]) 

# # Voltage for all buses is considered 1
@constraint(model,[m in Nodes], V[m] == 1)

# # Voltage angle for slack bus is considered 0
@constraint(model, delta[slack_bus] == 0)

# # Real Power Limits for Generators
@constraint(model,PowerProductionLimits[i=Upward_set] , MinQ[i] <= p[i]  <= MaxQ[i])

# #Real Power Limit for Edges' Flows
@constraint(model,[m in Nodes,n in connected_buses_dict[m]] ,  f[bus_id_to_index[m], bus_id_to_index[n]] <= Flowmax_dict[m,n])  

# # Real Power Production of non Generators is 0
@constraint(model, [n in buses_except_upward], p[n]==0)

# # Power injection of node n = Sum of ejected power flows from node n
@constraint(model, power_injection[n in Nodes], sum(f[bus_id_to_index[n], bus_id_to_index[m]] for m in connected_buses_dict[n]) ==p[n] - Load[n] )

### Objective Function
@objective(model, Min,  sum(PU[i]*p[i] for i in Upward_set))

    ### Solve
    println("Starting optimization...")
    start_time = time()
    optimize!(model)
    solve_time = time() - start_time
    println("Optimization completed in $(round(solve_time, digits=3)) seconds")

     global price = Dict{Int, Float64}()
     for k in Nodes
         price[k] = -dual(power_injection[k])
     end
     model[:prices] = Dict(k => -dual(power_injection[k]) for k in Nodes)

    return model

end


########################################################################################################################################
########################################################################################################################################
########################################################################################################################################
########################################################################################################################################

function create_dc_opf_results(model, case="case_ieee123_modified")
    ## Results Analysis 
    println("")
    println("############################################")
    println("#### $case: Ανάλυση Αποτελεσμάτων")
    println("############################################")
    println("")

    # Extract model variables
    V = model[:V]
    delta = model[:delta]
    p = model[:p]
    f = model[:f]

    println("")
    println("Voltage magnitudes [p.u.] and Voltage angles [°]:")
    println("")
    # Voltage Magnitude and Angle Results
    global results_df = DataFrame(
        Bus = buses,
        vm_pu = [value(V[i]) for i in buses],
        va_degrees = [rad2deg(value(delta[i])) for i in buses]
    )
    println(results_df)

    println("")
    println("Active power production [p.u.]:")
    println("")
    # Active Power Production Results
    global production_df = DataFrame(
        "Bus" => Upward_set,
        "p_pu" => [value(p[i]) for i in Upward_set],
        "pmax_pu" => [MaxQ[i] for i in Upward_set],  # Assuming maxQ exists
        "pmin_pu" => [MinQ[i] for i in Upward_set],  # Assuming minQ exists
        "PU_euro/MWh" => [PU[i] for i in Upward_set],
    )
    println(production_df)

    println("")
    println("Nodal prices [€/MWh]:")
    println("")
    # Nodal Price Results
    global price_df = DataFrame(
    "Bus" => Nodes,
    "nodal_price_euro/MWh" => [price[j] for j in Nodes]
    )
     println(price_df)

    println("")
    println("Active power flows for lines [p.u.]:")
    println("")
    # Power Flow Results
    global flows_df = DataFrame(
        Edge = edges_index,
        from_bus = [Edges.from_bus[i] for i in Edges_leng],
        flows_to = [Edges.to_bus[i] for i in Edges_leng],
        Flow_p_pu_from = [value(f[bus_id_to_index[Edges.from_bus[i]], bus_id_to_index[Edges.to_bus[i]]]) for i in Edges_leng], 
        Flow_p_pu_to = [value(f[bus_id_to_index[Edges.to_bus[i]], bus_id_to_index[Edges.from_bus[i]]]) for i in Edges_leng], 
        Flowmax_pu = [Flowmax_edge_dict[i] for i in Edges_leng ]
    )
    println(flows_df)

    # Objective value
    println("")
    println("Objective value: ", objective_value(model))



    println("")
    println("Termination Status:", termination_status(model))
   # Check if file exists before writing
   if !isfile(results_path)
    XLSX.writetable(
        results_path,
        "Results" => results_df,
        "Production" => production_df,
        "LMP" => price_df,
        "Flows" => flows_df
    )
    print("")
    println("Data written to Excel file successfully in path:" ,results_path)

    print("")
else
    println("Excel file already exists. Data not written.")
end 

println("")
println("Termination Status:", termination_status(model))

end


function setup_results_path(folder_name::String, file_name::String)
    global OUTPATH = folder_name  # Update globals with input values
    global output_file_name = file_name
    
    # Create directory if needed
    if !ispath(OUTPATH)
        mkpath(OUTPATH)
        println("Created directory: ", OUTPATH)
    end
    
    # Construct full path
    global results_path = joinpath(pwd(), OUTPATH, output_file_name)
    println("Results will be saved at: ", results_path)
    
    return results_path
end


########################################################################################################################################
########################################################################################################################################
########################################################################################################################################
########################################################################################################################################

function create_active_plot_DC_BTheta(
    result_df,
    OUTPATH="",
    case="";
    zoom_out=0.25,
    yticks_range::Union{StepRangeLen,Vector,AbstractRange}=0:5:50,  # Proper yticks parameter
    # OUTPATH=joinpath(pwd(), "Results"))
)
    # Τα plots χρειάζονται ως δεδομένα εισόδου arrays ή matrices. 
    # Εδώ δημιουργώ από το result_df ένα Matrix με όλες τοσ στήλες εκτός από την πρώτη Time. 
    production_BTheta_df = result_df   # Δημιουργώ μια λίστα με τα ονόματα των γεννητριών 
    Y_BTheta = production_BTheta_df[!, "p_pu"]
    X= production_BTheta_df.Bus
    # που αντιστοιχούν στα ονόματα στις στήλες μου στο result_df.
    bus_count = length(X)
    max_production = maximum(Y_BTheta)
    min_production = minimum(Y_BTheta)
    
    # # Data preparation
    buses = production_BTheta_df.Bus
    
    # # y_range 
    y_min = min_production
    y_max = max_production
    y_median = (y_min + y_max)/2
    y_range = y_max - y_min
    
    
    bar_width = 0.2  # Width of each bar
    offset = bar_width
    
    # # Convert buses to a string to treat them as categorical
    buses_str = string.(buses)
    x_indices = 1:(length(buses_str)+2)/length(buses_str):length(buses_str)+2  # Numerical indices for the buses
    
    # # ADJUST ONLY zoom_out AND yticks
    fz = 18 # fontsize 
    #zoom_out = 0.25

    # # Create a base bar chart for the ACOPF dataset
    production = bar(
        x_indices .- 0*offset,  # Center the first group of bars
        Y_BTheta,  # Values for the first dataset
        ylim = (max(y_median - (y_range + zoom_out)/2, 0), y_median + (y_range + zoom_out)/2),
        xlim = (0.5,bus_count+2.2),
        xlabel = "Buses",
        ylabel = "Active Power Production [p.u.]",
        #title = "Active Power Production",
        label = "DC_BTheta_OPF",  # Label for the legend
        color = RGB(79/255,55/255,45/255),  # Color for the dataset
        bar_width = bar_width,  # Set the width of the bars
        size = (1000, 1000),  # Adjust the size for better spacing
        xticks = (x_indices, buses_str),  # Map numerical x-values to string labels
        yticks = yticks_range,  
        xtickfontsize = fz, ytickfontsize = fz,
        fontfamily = "Courier New" , 
        titlefontsize = fz,
        xguidefontsize = fz,
        yguidefontsize = fz,
        legendfontsize = fz-6,
        legend_size= 16,
        legend = :true,
        framestyle = :box,
        margin = 10mm,
        grid = :true,
        minorgrid = :true,
    )
    
    #Για περισσότερα attributes https://docs.juliaplots.org/latest/attributes/
    display(production)
    # # Save the plot
    savefig(production,joinpath(OUTPATH,"Active_power_$case.pdf") )
end
########################################################################################################################################
########################################################################################################################################
########################################################################################################################################
########################################################################################################################################



function create_voltage_magnitude_plot_BTheta(
    result_df,
    OUTPATH="",
    case="";
    zoom_out=-0.25,
    yticks_range::Union{StepRangeLen,Vector,AbstractRange}=0:5:2,  # Proper yticks parameter
)


    VD_BTheta_df = result_df
    Y_V_BTheta = VD_BTheta_df[!, "vm_pu"]

    max_voltage = maximum(Y_V_BTheta)
    min_voltage = minimum(Y_V_BTheta)
    
    
    fz = 18 # fontsize 
    
    y_min = min_voltage
    y_max = max_voltage
    y_median = (y_min + y_max)/2
    y_range = y_max - y_min
    
    
    # # Data preparation
    buses = VD_BTheta_df.Bus
    bus_count = length(buses)

    # # Convert buses to a string to treat them as categorical
    buses_str = string.(buses)
    xticks_values_V = 0:1:bus_count+20
    xticks_values_V = 0:5:bus_count
    xticks_labels_V = buses_str[1:5:end]
    


    V = scatter(
      buses_str,
      Y_V_BTheta,
      ylim = (y_median - (y_range+ zoom_out)/2, y_median + (y_range+ zoom_out)/2),
      xlim = (0,bus_count),
      xlabel = "Buses",
      ylabel = "Voltage Magnitude [p.u.]",
      #title = "Voltage Magnitude",
      legend = :bottomright,
      label = "DC_BTheta_OPF_OPF",
      markersize = 11,
      color = RGB(79/255,55/255,45/255),  # Color for the dataset
      #alpha = 0.8,
      markerstrokewidth = 1,
      yticks = yticks_range,  
      xticks = (xticks_values_V,xticks_labels_V),  # Set xticks and labels
      xrotation = 0, # Rotate labels by 45 degrees
      markershape = :circle,
      size = (2000, 1000),  # Adjust the size for better spacing
      xtickfontsize = fz, ytickfontsize = fz,
      fontfamily = "Courier New" , # Better Unicode support
      titlefontsize = fz+1,
      xguidefontsize = fz+1,
      yguidefontsize = fz+1,
      legendfontsize = fz-2,
      framestyle = :box,
      margin = 12mm,
      grid = :true,
      minorgrid = :true,
)
    
    display(V)
    # # Save the plot
    savefig(V,joinpath(OUTPATH,"Voltage_magnitude_$case.pdf") )
end

########################################################################################################################################
########################################################################################################################################
########################################################################################################################################
########################################################################################################################################


function create_voltage_angles_plot_BTheta(
    result_df,
    OUTPATH="",
    case="";
    zoom_out=-0.25,
    yticks_range::Union{StepRangeLen,Vector,AbstractRange}=0:5:2,  # Proper yticks parameter
)


    VD_BTheta_df = result_df
    Y_D_BTheta = VD_BTheta_df[!, "va_degrees"]

    max_angle = maximum(Y_D_BTheta)
    min_angle = minimum(Y_D_BTheta)
    
    
    fz = 18 # fontsize 
    
    y_min = min_angle
    y_max = max_angle
    y_median = (y_min + y_max)/2
    y_range = y_max - y_min
    
    
    # # Data preparation
    buses = VD_BTheta_df.Bus
    bus_count = length(buses)

    # # Convert buses to a string to treat them as categorical
buses_str = string.(buses)
xticks_values_D = 0:5:bus_count
xticks_labels_D = buses_str[1:5:end]
    


    V_delta = scatter(
      buses_str,
      Y_D_BTheta,
      ylim = (y_median - (y_range+ zoom_out)/2, y_median + (y_range+ zoom_out)/2),
      xlim = (0,bus_count),
      xlabel = "Buses",
      ylabel = "Delta[°]",
      #title = "Voltage Magnitude",
      legend = :bottomleft,
      label = "BTheta_OPF",
      markersize = 11,
      color = RGB(79/255,55/255,45/255),  # Color for the dataset
      #alpha = 0.8,
      markerstrokewidth = 1,
      yticks = yticks_range,  
      xticks = (xticks_values_D,xticks_labels_D),  # Set xticks and labels
      xrotation = 0, 
      markershape = :circle,
      size = (2000, 1000),  # Adjust the size for better spacing
      xtickfontsize = fz, ytickfontsize = fz,
      fontfamily = "Courier New" , # Better Unicode support
      titlefontsize = fz+1,
      xguidefontsize = fz+1,
      yguidefontsize = fz+1,
      legendfontsize = fz-2,
      framestyle = :box,
      margin = 12mm,
      grid = :true,
      minorgrid = :true,
)
    
    #Για περισσότερα attributes https://docs.juliaplots.org/latest/attributes/
    display(V_delta)
    # # Save the plot
    savefig(V_delta,joinpath(OUTPATH,"Voltage_angles_$case.pdf") )
end



function create_nodal_prices_plot_BTheta(
    result_df,
    OUTPATH="",
    case="";
    zoom_out=-0.25,
    yticks_range::Union{StepRangeLen,Vector,AbstractRange}=0:0.5:2,  # Proper yticks parameter
)


    prices_BTheta_df = result_df
    Y_prices_BTheta = prices_BTheta_df[!, "nodal_price_euro/MWh"]

    max_price = maximum(Y_prices_BTheta)
    min_price = minimum(Y_prices_BTheta)
    
    
    fz = 18 # fontsize 
    
    y_min = min_price
    y_max = max_price
    y_median = (y_min + y_max)/2
    y_range = y_max - y_min
    
    
    # # Data preparation
    buses = prices_BTheta_df.Bus
    bus_count = length(buses)

    # # Convert buses to a string to treat them as categorical
buses_str = string.(buses)
xticks_values_prices = 0:5:bus_count
xticks_labels_prices = buses_str[1:5:end]
    


    prices = scatter(
      buses_str,
      Y_prices_BTheta,
      ylim = (y_median - (y_range+ zoom_out)/2, y_median + (y_range+ zoom_out)/2),
      xlim = (0,bus_count),
      xlabel = "Buses",
      ylabel = "Price [€/MWh]",
      legend = :bottomleft,
      label = "Thesis_BTheta_OPF",
      markersize = 11,
      color = RGB(79/255,55/255,45/255),  # Color for the dataset
      #alpha = 0.8,
      markerstrokewidth = 1,
      yticks = yticks_range,  
      xticks = (xticks_values_prices,xticks_labels_prices),  # Set xticks and labels
      xrotation = 0, 
      markershape = :circle,
      size = (2000, 1000),  # Adjust the size for better spacing
      xtickfontsize = fz, ytickfontsize = fz,
      fontfamily = "Courier New" , # Better Unicode support
      titlefontsize = fz+1,
      xguidefontsize = fz+1,
      yguidefontsize = fz+1,
      legendfontsize = fz-2,
      framestyle = :box,
      margin = 12mm,
      grid = :true,
      minorgrid = :true,
)
    
    #Για περισσότερα attributes https://docs.juliaplots.org/latest/attributes/
    display(prices)
    # # Save the plot
    savefig(prices,joinpath(OUTPATH,"Nodal_prices_$case.pdf") )
end



