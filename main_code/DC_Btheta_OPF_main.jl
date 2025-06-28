# # Packages
using DataFrames, JuMP
using XLSX, Gurobi
####################################################################                                 ####################################################################
####################################################################          Data Handling          ####################################################################
####################################################################                                 ####################################################################

# # Choose xlsx file you want to read
#filename = "Paper_nodes_PV.xlsx"
#filename = "Name of file.xlsx" , xlsx file should be in the same directory as the code

# # Alternative way to choose the file
filename = joinpath("filepath","The name of the file.xlsx")

# Example
#filepath = "/Users/malexandrakis/Library/CloudStorage/OneDrive-Personal/Diploma_Thesis/Linear_Approximation_OPF/Case_Files"
#filename = joinpath(filepath,"case_ieee123_modified.xlsx")

# # Loading Excel sheets into DataFrames
sgen_data = DataFrame(XLSX.readtable(filename, "gen"))
Edges = DataFrame(XLSX.readtable(filename, "edges"))
bus_data = DataFrame(XLSX.readtable(filename, "bus"))
load_data = DataFrame(XLSX.readtable(filename, "load"))
slack_data = DataFrame(XLSX.readtable(filename, "ext_grid"))
Upward_data = DataFrame(XLSX.readtable(filename, "Upward"))
Downward_data = DataFrame(XLSX.readtable(filename, "Downward"))

# # Data for slack bus(voltage magnitude,voltage degree,bus number)
slack_v = slack_data[1, :vm_pu]  
slack_degree = slack_data[1,:va_degree]
slack_bus = slack_data[1,:bus]

buses = bus_data[:, :bus]
edges_index = Edges[:,:idx]
# # Create a dictionary to store the index of each bus
slack_index = findfirst(bus_data[:, :bus] .== slack_bus)
bus_id_to_index = Dict(bus_data[setdiff(1:end, slack_index), :bus] .=> 1:size(bus_data, 1)-1)
bus_id_to_index[slack_bus] = size(bus_data, 1)

# # Create a dictionary mapping edges' idx to FlowMax
Flowmax_dict = Dict{Tuple{Int, Int}, Float64}()
for row in eachrow(Edges)
    Flowmax_dict[(row.from_bus, row.to_bus)] = row.FlowMax
    Flowmax_dict[(row.to_bus, row.from_bus)] = row.FlowMax
end


# # Sbase of the system
Ssystem = 1

# # Create a dictionary to store connected buses
connected_buses_dict = Dict{Int, Vector{Int}}()
for row in eachrow(Edges)
    From = row.from_bus
    To = row.to_bus
    
    if !haskey(connected_buses_dict, From)
        connected_buses_dict[From] = Int[]
    end
    push!(connected_buses_dict[From], To)
    
    if !haskey(connected_buses_dict, To)
        connected_buses_dict[To] = Int[]
    end
    push!(connected_buses_dict[To], From)
end


# # Total number of buses and edges
n = size(bus_data,1)
Edges_leng = 1:length(Edges.from_bus)

# # Create an array to store all the Nodes
Nodes = Int[]
for row in eachrow(bus_data)
    bus = row.bus
    push!(Nodes, bus)
end

# # Create dictionaries to store generator buses' Marginal Cost, Minimum and Maximum Active Power production limits
PU = Dict{Int,Float64}()
MinQ = Dict{Int, Float64}()
MaxQ = Dict{Int, Float64}()
for row in eachrow(Upward_data)
    name = row.name
    u_price = row.PU
    u_minquantity = row.MinQ
    u_maxquantity = row.MaxQ
    #println(u_quantity)
    PU[name] = u_price
    MinQ[name] = u_minquantity
    MaxQ[name] = u_maxquantity
end

# # Create an array to store all the buses that can offer upward flexibility
Upward_set = Int[]
for row in eachrow(Upward_data)
    bus = row.Bus
    if MaxQ[bus] !=0 
        push!(Upward_set, bus)
    end
end
buses_except_upward = setdiff(buses, Upward_set)

# # Create Y matrix
global y = zeros(Complex, n, n)

for row in eachrow(Edges)
    From_Bus = bus_id_to_index[row.from_bus]
    To_Bus = bus_id_to_index[row.to_bus]
    x = row.X_pu
    row.R_pu = 0
    r = row.R_pu
    local z = r + x .* im
    y[From_Bus,To_Bus] = 1 ./ z[1]
    y[To_Bus,From_Bus] = 1 ./ z[1]
end

Y = zeros(Complex, n, n)

for k in Nodes
    Y[bus_id_to_index[k], bus_id_to_index[k]] =  sum((y[bus_id_to_index[k], bus_id_to_index[m]] ) for m in connected_buses_dict[k])
end

for k in Nodes
    for m in connected_buses_dict[k]
        Y[bus_id_to_index[k],bus_id_to_index[m]] = -y[bus_id_to_index[k], bus_id_to_index[m]]
    end
end

# println("Admittance Matrix (Ykk):")
# println(Y)

# # Create B matrix
B = imag.(Y)


# # Active Load for each bus
global total_p= 0.0
total_pgen_pload = Dict{Int, Float64}()
for row in eachrow(load_data)
    bus = bus_id_to_index[row.bus]
    Pload = row.p_mw/ Ssystem
    total_pgen_pload[bus] = get(total_pgen_pload, bus, 0.0) - Pload 
    global total_p += total_pgen_pload[bus]
end


# # Create Load_set
Load_set = Int[]
for row in eachrow(load_data)
    load_buses = row.bus
    push!(Load_set,load_buses)
end
Buses_without_load =  setdiff(buses, Load_set)


# # Load_Dict
# Add buses and their load values from load_data
Load_dict = Dict{Int, Float64}()
for row in eachrow(load_data)
    Load_dict[row.bus] = row.p_mw  
end
# Add the additional buses with load 0.0 if they are not already in Load_dict
for bus in Buses_without_load
    Load_dict[bus] = 0.0
end
Load = Load_dict


####################################################################                                 ####################################################################
#################################################################### Mathematical optimization model ####################################################################
####################################################################                                 ####################################################################

# # Create a mathematical optimization model using the Gurobi Optimizer as the solver
GUROBI_ENV = Gurobi.Env()
model = Model(() -> Gurobi.Optimizer(GUROBI_ENV))
set_optimizer_attribute(model, "MIPGap", 0.0) 
set_silent(model)





### Variables
@variable(model, f[1:n,1:n])   # Variable representing Active Power flow on each edge(both directions)
@variable(model, p[Nodes]>=0)  # Variable representing Active Power production by generator buses
@variable(model, delta[Nodes]) # Variable representing voltage angles of each node
@variable(model, V[Nodes])     # Variable representing voltage magnitudes of each node

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
@constraint(model, price[n in Nodes], sum(f[bus_id_to_index[n], bus_id_to_index[m]] for m in connected_buses_dict[n]) ==p[n] - Load[n] )



### Objective Function
@objective(model, Min,  sum(PU[i]*p[i] for i in Upward_set))

# # Solve the optimization problem
start = time()
optimize!(model)
elapsed = (time() - start) * 1000  # convert seconds to milliseconds
println("Solve time: $(round(elapsed; digits=3)) ms")
 

# # Dual variables for pricing
for k in Nodes
    println(dual(price[k]))
end
####################################################################                                      ####################################################################
#################################################################### Results for the optimization problem ####################################################################
####################################################################                                      ####################################################################

# # Results for Prices
price_df = DataFrame(
    Bus = Nodes,
    node_price = [-dual(price[j]) for j in Nodes]
)

println("Objective value:c ")
@show objective_value(model)

# # Results for the Voltage Magnitude and Voltage Angle
results_df = DataFrame(
    Bus = buses,
    V_pu = [value(V[i]) for i in buses],
    Delta = [rad2deg(value(delta[i])) for i in buses],

)

# # Results for the Active Power production
production_df = DataFrame(
    Bus = Upward_set,
    production = [value(p[i]) for i in Upward_set],
)

# # Results for Flows  
flows_df = DataFrame(
    Edge = edges_index,
    from_bus = [Edges.from_bus[i] for i in Edges_leng],
    flows_to = [Edges.to_bus[i] for i in Edges_leng],
    Flow = [value(f[bus_id_to_index[Edges.from_bus[i]], bus_id_to_index[Edges.to_bus[i]]]) for i in Edges_leng],
)

# # Print the results
println("")
println("Voltage magnitudes [p.u.] and Voltage angles [°]:")
println(results_df)
println("")
println("Active power production [p.u.]:")
println(production_df)
println("")
println("Nodal prices [€/MWh]:")
println(price_df)
println("")
println("Active power flows for lines [p.u.]:")
println(flows_df)

println("Termination Status:", termination_status(model))

# # Results Stored in an Excel File
#XLSX.writetable("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Thesis_Writing\\Results\\BTheta_ehv1.xlsx", "flows"=> flows_df, "results" => results_df, "production" => production_df, "price" => price_df)
#XLSX.writetable("filepath.xlsx",  "Results" => results_df , "Production" => prod_df ,  "Reactive_Production" => Qreact_df, "Price" => price_df,"Flows"=> flows_df)   
