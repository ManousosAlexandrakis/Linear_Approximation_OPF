function create_opf_model()
    # Create Gurobi environment and model
    if solver == "gurobi"
        GUROBI_ENV = Gurobi.Env()
        model = Model(() -> Gurobi.Optimizer(GUROBI_ENV))
    else
        model = Model(GLPK.Optimizer)
    end

    set_silent(model) ### Variables (will be stored globally)


    @variable(model, V[Nodes])                                  # Variable representing voltage magnitudes of each node
    @variable(model, delta[Nodes])                              # Variable representing voltage angles of each node
    @variable(model, Q[slack_K_buses])                          # Variable representing Reactive Power production by generator buses
    @variable(model, production[Upward_set])                    # Variable representing Active Power production by generator buses
    @variable(model, active_power_k[Nodes])                     # Variable representing Active Power injection for each node
    @variable(model, reactive_power_k[Nodes])                   # Variable representing Reactive Power injection for each node
    @variable(model, f[edges_index])                            # Variable representing Active Power flow on each edge
    @variable(model, f_q[edges_index])                          # Variable representing Reactive Power flow on each edge

### Constraints for the optimization problem

# # Limits for the Reactive Power produced by the slack and the K buses
@constraint(model, [k in slack_K_buses], Qmin[k] <= Q[k] <= Qmax[k]) 

# # Define the voltage magnitude and angle of the slack bus
@constraint(model, V[slack_bus] == slack_v)                           
@constraint(model, delta[slack_bus] == slack_degree) 

# # Limits for the Active Power produced by the slack and the K buses
@constraint(model, UpperBound1[i in Upward_set], production[i] <= maxQ[i])
@constraint(model, UpperBound2[i in Upward_set], production[i] >= minQ[i])

# # Voltage magnitude limits for all buses except the slack bus
@constraint(model,LowerBoundV[k in K_L_buses] ,0.8 <= V[k] ) 
@constraint(model,UpperBoundV[k in K_L_buses] , V[k] <= 1.2) 


# # Power Balance for each node
@constraint(model,injectionsandflows[i in Nodes], sum(f[j] for j in edges_index if Edges.from_bus[j] == i) - sum(f[j] for j in edges_index if Edges.to_bus[j] == i) == active_power_k[i])
@constraint(model,[i in Nodes], sum(f_q[j] for j in edges_index if Edges.from_bus[j] == i) - sum(f_q[j] for j in edges_index if Edges.to_bus[j] == i) == reactive_power_k[i])

# # Active Power Flows on each edge (Taylor Series Approximation)
@constraint(model, TaylorActiveFlow[i in edges_index],f[i] - (Rij[i] * (V[Edges.from_bus[i]] - V[Edges.to_bus[i]]) + Xij[i] * (delta[Edges.from_bus[i]] - delta[Edges.to_bus[i]])) 
/ (Rij[i]^2 + Xij[i]^2)  == 0 )

# # Reactive Power Flows on each edge (Taylor Series Approximation)
@constraint(model, TaylorReActiveFlow[i in edges_index], f_q[i] - (Xij[i] * (V[Edges.from_bus[i]] - V[Edges.to_bus[i]]) - Rij[i] * (delta[Edges.from_bus[i]] - delta[Edges.to_bus[i]])) 
/ (Rij[i]^2 + Xij[i]^2)    == 0)

# # Active Power Flow Limits
@constraint(model, FlowmaxUpper[i in edges_index],f[i] <=Flowmax_edge_dict[i])
@constraint(model, FlowmaxDown[i in edges_index],-f[i] <=Flowmax_edge_dict[i])

# # Reactive Power Flow Limits
@constraint(model, [i in edges_index],f_q[i] <=Flowmax_edge_dict[i])
@constraint(model, [i in edges_index],-f_q[i] <=Flowmax_edge_dict[i])

# # Voltage magnitude equation for all buses except the slack bus
@constraint(model, Voltage[k in K_L_buses], V[k] == slack_v + (sum(R_matrix[complete_mapping[k], complete_mapping[i]] * (active_power_k[i]) for i in K_buses)
+ sum(X_matrix[complete_mapping[k], complete_mapping[i]] * (reactive_power_k[i]) for i in K_buses)
+ sum(R_matrix[complete_mapping[k], complete_mapping[i]] * (active_power_k[i]) for i in L_buses)
+ sum(X_matrix[complete_mapping[k], complete_mapping[i]] * (reactive_power_k[i]) for i in L_buses)) / slack_v)

# # Voltage angle equation for all buses except the slack bus
@constraint(model, DeltaConstraint[k in K_L_buses], delta[k] == slack_degree + (sum(-R_matrix[complete_mapping[k], complete_mapping[i]] * (reactive_power_k[i]) for i in K_buses)
+ sum(X_matrix[complete_mapping[k], complete_mapping[i]] * (active_power_k[i]) for i in K_buses)
+ sum(-R_matrix[complete_mapping[k], complete_mapping[i]] * (reactive_power_k[i]) for i in L_buses)
+ sum(X_matrix[complete_mapping[k], complete_mapping[i]] * (active_power_k[i]) for i in L_buses)) / (slack_v^2))

# # Fixing Voltage Magnitude for generator-buses
@constraint(model, fixed[i in Upward_set], V[i]==1)


# # Reactive and Active Power injection equations for all buses
@constraint(model,  reactive_power[k in Nodes],reactive_power_k[k] == sum(Q[i] for i in slack_K_buses if i == k) + get(total_qgen_qload,k,0))
@constraint(model,  active_power[k in Nodes],  active_power_k[k] == get(total_pgen_pload,k,0) + sum(production[i] for i in Upward_set if i == k) ) #dual-variable is the nodal price

    @objective(model, Max,  -  sum(PU[i]*production[i] for i in Upward_set))

    println("Starting optimization...")
    start_time = time()
    optimize!(model)
    solve_time = time() - start_time
    println("Optimization completed in $(round(solve_time, digits=3)) seconds")

    # Calculate prices using the constraint reference
     global price = Dict{Int, Float64}()
     for j in Nodes
         price[j] = -dual(active_power[j])  # Use the constraint reference
     end
     model[:prices] = Dict(j => -dual(active_power[j]) for j in Nodes)
    
    return model
end




function create_results_dataframes(model, case = "case_ieee123_modified")
        ## Ανάλυση αποτελεσμάτων 
        println("")
        println("#################################################")
        println("#### $case: Ανάλυση Αποτελεσμάτων ")
        println("#################################################")
        println("")

        global V = model[:V]
        global delta = model[:delta]
        global production = model[:production]
        global Q = model[:Q]
        global reactive_power_k = model[:reactive_power_k]
        global active_power_k = model[:active_power_k]
        global f = model[:f]
        global f_q = model[:f_q]


        println("")
        println(" Voltage magnitudes [p.u.] and Voltage angles [°]:")
        println("")
    # Voltage Magnitude and Angle Results
   global results_df = DataFrame(
        Bus = Nodes,
        vm_pu = [value(V[i]) for i in Nodes],
        va_degree = [rad2deg(value(delta[i])) for i in Nodes]
    )
    println(results_df)


    println("")
    println(" Active power production [p.u.]:")
    println("")
   # Active Power Production Results
   global prod_df = DataFrame(
    bus = Upward_set,
    production = [value(production[i]) for i in Upward_set],
    pmax = [maxQ[i] for i in Upward_set],
    pmin = [minQ[i] for i in Upward_set],
    PU = [PU[i] for i in Upward_set]
)
    println(prod_df)

    
    println("")
    println(" Reactive power production [p.u.]:")
    println("")
        # Reactive Power Production Results
        global Qreact_df = DataFrame(
            Bus = slack_K_buses,
            q_pu = [value(Q[i]) for i in slack_K_buses],
            qmin = [Qmin[i] for i in slack_K_buses],
            qmax = [Qmax[i] for i in slack_K_buses]
        )
        println(Qreact_df)


        println("")
        println(" Active and Reactive injections [p.u.]:")
        println("")
        global PowerInjection_df = DataFrame(
            Bus = Nodes,
            q_injection = [value(reactive_power_k[i]) for i in Nodes],
            p_injection = [value(active_power_k[i]) for i in Nodes]
        )
        println(PowerInjection_df)



    println("")
    println(" Nodal prices [€/MWh]:")
    println("") 
    # Nodal Price Results
    global  price_df = DataFrame(
        Bus = Nodes,
        price = [price[j] for j in Nodes]  # Using all nodes
    )
    println(price_df)





    println("")
    println(" Active and Reactive power flows for lines [p.u.]:")
    println("")
    # Power Flow Results
    global flows_df = DataFrame(
        Edge = edges_index,
        from_bus = Edges.from_bus,
        to_bus = Edges.to_bus,
        Flow_Active = [value(f[i]) for i in edges_index],
        Flow_Reactive = [value(f_q[i]) for i in edges_index],
        Flowmax = [Flowmax_edge_dict[i] for i in edges_index]
    )
    println(flows_df)

    # Check if file exists before writing
if !isfile(results_path)
    XLSX.writetable(
        results_path,
        "Results" => results_df,
        "Production" => prod_df,
        "Reactive_Production" => Qreact_df,
        "Price" => price_df,
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




function create_active_plot_Thesis_Linear(
    result_df,
    OUTPATH="",
    case="";
    zoom_out=0.25,
    yticks_range::Union{StepRangeLen,Vector,AbstractRange}=0:5:50,  # Proper yticks parameter
    # OUTPATH=joinpath(pwd(), "Results"))
)
    # Τα plots χρειάζονται ως δεδομένα εισόδου arrays ή matrices. 
    # Εδώ δημιουργώ από το result_df ένα Matrix με όλες τοσ στήλες εκτός από την πρώτη Time. 
    production_LINEAR_df = result_df   # Δημιουργώ μια λίστα με τα ονόματα των γεννητριών 
    Y_LINEAR = production_LINEAR_df[!, "production"]
    X= production_LINEAR_df.bus
    # που αντιστοιχούν στα ονόματα στις στήλες μου στο result_df.
    bus_count = length(X)
    max_production = maximum(Y_LINEAR)
    min_production = minimum(Y_LINEAR)
    
    # # Data preparation
    buses = production_LINEAR_df.bus
    
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
        Y_LINEAR,  # Values for the first dataset
        ylim = (max(y_median - (y_range + zoom_out)/2, 0), y_median + (y_range + zoom_out)/2),
        xlim = (0.5,bus_count+2.2),
        xlabel = "Buses",
        ylabel = "Active Power Production [p.u.]",
        #title = "Active Power Production",
        label = "Thesis_Linear_OPF",  # Label for the legend
        color = RGB(204/255,42/255,54/255),  # Color for the dataset
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


function create_reactive_plot_Thesis_Linear(
    result_df,
    OUTPATH="",
    case="";
    zoom_out=-0.25,
    yticks_range::Union{StepRangeLen,Vector,AbstractRange}=0:5:2,  # Proper yticks parameter
)

    reactive_LINEAR_df = result_df
    Y_reactive_LINEAR = reactive_LINEAR_df[!, "q_pu"]
    X= reactive_LINEAR_df.Bus
    # που αντιστοιχούν στα ονόματα στις στήλες μου στο result_df.
    bus_count = length(X)
    max_reactive_production = maximum(Y_reactive_LINEAR)
    min_reactive_production = minimum(Y_reactive_LINEAR)
    
    # # Data preparation
    buses = X
    
    # # y_range 
    y_min = max_reactive_production
    y_max = min_reactive_production
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
    reactive = bar(
        x_indices .- 0*offset,  # Center the first group of bars
        Y_reactive_LINEAR,  # Values for the first dataset
        ylim = (y_median - abs((y_range + zoom_out)/2), 
        y_median + abs((y_range + zoom_out)/2)),
        xlim = (0.5,bus_count+1.6),
        xlabel = "Buses",
        ylabel = "Reactive Power Production [p.u.]",
        label = "Thesis_Linear_OPF",  # Label for the legend
        color = RGB(204/255,42/255,54/255),  # Color for the dataset
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
    display(reactive)
    # # Save the plot
    savefig(reactive,joinpath(OUTPATH,"Reactive_power_$case.pdf") )
end




function create_voltage_magnitude_plot_Thesis_Linear(
    result_df,
    OUTPATH="",
    case="";
    zoom_out=-0.25,
    yticks_range::Union{StepRangeLen,Vector,AbstractRange}=0:5:2,  # Proper yticks parameter
)


    VD_LINEAR_df = result_df
    Y_V_LINEAR = VD_LINEAR_df[!, "vm_pu"]

    max_voltage = maximum(Y_V_LINEAR)
    min_voltage = minimum(Y_V_LINEAR)
    
    
    fz = 18 # fontsize 
    
    y_min = min_voltage
    y_max = max_voltage
    y_median = (y_min + y_max)/2
    y_range = y_max - y_min
    
    
    # # Data preparation
    buses = VD_LINEAR_df.Bus
    bus_count = length(buses)

    # # Convert buses to a string to treat them as categorical
    buses_str = string.(buses)
    xticks_values_V = 0:1:bus_count+20
    xticks_values_V = 0:5:bus_count
    xticks_labels_V = buses_str[1:5:end]
    


    V = scatter(
      buses_str,
      Y_V_LINEAR,
      ylim = (y_median - (y_range+ zoom_out)/2, y_median + (y_range+ zoom_out)/2),
      xlim = (0,bus_count),
      xlabel = "Buses",
      ylabel = "Voltage Magnitude [p.u.]",
      #title = "Voltage Magnitude",
      legend = :bottomright,
      label = "Thesis_Linear_OPF",
      markersize = 11,
      color = RGB(204/255,42/255,54/255),  # Color for the dataset
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



function create_voltage_angles_plot_Thesis_Linear(
    result_df,
    OUTPATH="",
    case="";
    zoom_out=-0.25,
    yticks_range::Union{StepRangeLen,Vector,AbstractRange}=0:5:2,  # Proper yticks parameter
)


    VD_LINEAR_df = result_df
    Y_D_LINEAR = VD_LINEAR_df[!, "va_degree"]

    max_angle = maximum(Y_D_LINEAR)
    min_angle = minimum(Y_D_LINEAR)
    
    
    fz = 18 # fontsize 
    
    y_min = min_angle
    y_max = max_angle
    y_median = (y_min + y_max)/2
    y_range = y_max - y_min
    
    
    # # Data preparation
    buses = VD_LINEAR_df.Bus
    bus_count = length(buses)

    # # Convert buses to a string to treat them as categorical
buses_str = string.(buses)
xticks_values_D = 0:5:bus_count
xticks_labels_D = buses_str[1:5:end]
    


    V_delta = scatter(
      buses_str,
      Y_D_LINEAR,
      ylim = (y_median - (y_range+ zoom_out)/2, y_median + (y_range+ zoom_out)/2),
      xlim = (0,bus_count),
      xlabel = "Buses",
      ylabel = "Delta[°]",
      #title = "Voltage Magnitude",
      legend = :bottomleft,
      label = "Thesis_Linear_OPF",
      markersize = 11,
      color = RGB(204/255,42/255,54/255),  # Color for the dataset
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



function create_nodal_prices_plot_Thesis_Linear(
    result_df,
    OUTPATH="",
    case="";
    zoom_out=-0.25,
    yticks_range::Union{StepRangeLen,Vector,AbstractRange}=0:0.5:2,  # Proper yticks parameter
)


    prices_LINEAR_df = result_df
    Y_prices_LINEAR = prices_LINEAR_df[!, "price"]

    max_price = maximum(Y_prices_LINEAR)
    min_price = minimum(Y_prices_LINEAR)
    
    
    fz = 18 # fontsize 
    
    y_min = min_price
    y_max = max_price
    y_median = (y_min + y_max)/2
    y_range = y_max - y_min
    
    
    # # Data preparation
    buses = prices_LINEAR_df.Bus
    bus_count = length(buses)

    # # Convert buses to a string to treat them as categorical
buses_str = string.(buses)
xticks_values_prices = 0:5:bus_count
xticks_labels_prices = buses_str[1:5:end]
    


    prices = scatter(
      buses_str,
      Y_prices_LINEAR,
      ylim = (y_median - (y_range+ zoom_out)/2, y_median + (y_range+ zoom_out)/2),
      xlim = (0,bus_count),
      xlabel = "Buses",
      ylabel = "Price [€/MWh]",
      legend = :bottomleft,
      label = "Thesis_Linear_OPF",
      markersize = 11,
      color = RGB(204/255,42/255,54/255),  # Color for the dataset
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