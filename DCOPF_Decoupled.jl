using DataFrames,JuMP, GLPK
using XLSX,Gurobi





#filename = joinpath("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\DCOPF","Trondheim_no_dublicates-B-theta-newUpward.xlsx")

#filename = joinpath("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Simple Datasets","3nodes-test_newV20.xlsx")
#filename = joinpath("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Simple Datasets","3nodes-test_newV21.xlsx")

#filename = joinpath("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας","promised_ehv4_Ruan_for_my_code.xlsx")
#filename = joinpath("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας","Paper_nodes_PV.xlsx")
filename = joinpath("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας","promised_ehv1_Ruan_for_my_code.xlsx")




#Loading Excel sheets into DataFrames
gen_data = DataFrame(XLSX.readtable(filename, "gen"))
Edges = DataFrame(XLSX.readtable(filename, "edges"))
bus_data = DataFrame(XLSX.readtable(filename, "bus"))
load_data = DataFrame(XLSX.readtable(filename, "load"))
slack_data = DataFrame(XLSX.readtable(filename, "ext_grid"))
Upward_data = DataFrame(XLSX.readtable(filename, "Upward"))
Downward_data = DataFrame(XLSX.readtable(filename, "Downward"))

slack_v = slack_data[1, :vm_pu]  #παίρνει απο το dataframe slack_data την πρωτη γραμμή της στήλης vm_pu
slack_degree = slack_data[1,:va_degree]
slack_bus = slack_data[1,:bus]



buses = bus_data[:, :bus]

slack_index = findfirst(bus_data[:, :bus] .== slack_bus)
bus_id_to_index = Dict(bus_data[setdiff(1:end, slack_index), :bus] .=> 1:size(bus_data, 1)-1)
bus_id_to_index[slack_bus] = size(bus_data, 1)


data = DataFrame(
    from_bus = Edges.from_bus,
    to_bus = Edges.to_bus,
    Flowmax = Edges.FlowMax
) 

flowmax_dict = Dict{Int, Float64}()
for row in eachrow(Edges)
    flowmax_dict[row.idx] = row.FlowMax
end
Flowmax = flowmax_dict




Ssystem = 1
edges_index = Edges[:,:idx]
# Create a dictionary to store connected buses
connected_buses_dict = Dict{Int, Vector{Int}}()

for row in eachrow(data)
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



connected_buses_dict


n = size(bus_data,1)

Edges_leng = 1:length(data.from_bus)

Nodes = Int[]
for row in eachrow(bus_data)
    bus = row.bus
    push!(Nodes, bus)
end

# Ssystem = 100

PD = Dict{Int,Float64}()
QD = Dict{Int,Float64}()
for row in eachrow(Downward_data)
    bus = row.Bus
    d_price = row.PD
    d_quantity = row.QD
    #print(d_quantity)
    PD[bus] = d_price
    QD[bus] = d_quantity
end

PU = Dict{Int,Float64}()
for row in eachrow(Upward_data)
    bus = row.Bus
    u_price = row.PU
    PU[bus] = u_price
end


# Create a dictionary mapping bus to MinQ (minimum quantity produced)      
MinQ_dict = Dict{Int, Float64}()
for row in eachrow(Upward_data)
    MinQ_dict[row.Bus] = row.MinQ
end
MinQ = MinQ_dict

# Create a dictionary mapping bus to MaxQ (maximum quantity produced)      
MaxQ_dict = Dict{Int, Float64}()

for row in eachrow(Upward_data)
    MaxQ_dict[row.Bus] = row.MaxQ
    MinQ_dict[row.Bus] = row.MinQ
end


maxQ = MaxQ_dict
minQ = MinQ_dict


Qmin = Dict{Int, Float64}()
Qmax = Dict{Int, Float64}()
for row in eachrow(gen_data)
    bus = row.bus
    Pgen = row.p_mw
    #vm = row.vm_pu
    Qmin[row.bus] = row.QRmin/Ssystem
    Qmax[row.bus] = row.QRmax/Ssystem
    # total_pgen_pload[bus] = get(total_pgen_pload, bus, 0.0) + Pgen / Ssystem
end


Downward_set = Int[]
for row in eachrow(Downward_data)
    bus = row.Bus
    if QD[bus] !=0 
        push!(Downward_set, bus)
    end
end

Upward_set = Int[]
for row in eachrow(Upward_data)
    bus = row.Bus
    if maxQ[bus] !=0 
        push!(Upward_set, bus)
    end
end

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
Y
#println("Admittance Matrix (Ykk):")
#println(Y)


B = imag.(Y)

# Create Downward_set
Downward_set = Downward_data[:, :Bus]
buses_except_downward = setdiff(buses, Downward_set)
# Create Upward_set
Upward_set = Upward_data[:, :Bus]
buses_except_upward = setdiff(buses, Upward_set)


global total_p= 0.0


total_pgen_pload = Dict{Int, Float64}()

for row in eachrow(bus_data)
    bus = row.bus
    total_pgen_pload[bus_id_to_index[bus]] = 0.0
    
end

for row in eachrow(load_data)
    bus = bus_id_to_index[row.bus]
    # Pload = row.p_pu
    
    Pload = row.p_mw/ Ssystem
    
    total_pgen_pload[bus] = get(total_pgen_pload, bus, 0.0) - Pload 
    
    global total_p += total_pgen_pload[bus]
    
end

println(total_p)


Flowmax_dict = Dict{Tuple{Int, Int}, Float64}()
for row in eachrow(Edges)
    Flowmax_dict[(row.from_bus, row.to_bus)] = row.FlowMax
    Flowmax_dict[(row.to_bus, row.from_bus)] = row.FlowMax
end
Flowmax_dict


# Create Load_set
Load_set = Int[]
for row in eachrow(load_data)
    load_buses = row.bus
    push!(Load_set,load_buses)
end
Load_set

Buses_without_load =  setdiff(buses, Load_set)
###################
#Create Load_Dict
# Add buses and their load values from load_data
# Initialize Load_dict as a dictionary
Load_dict = Dict{Int, Float64}()

for row in eachrow(load_data)
    Load_dict[row.bus] = row.p_mw  # Add the bus and its corresponding load value
end

# Now, add the additional buses with load 0.0 if they are not already in Load_dict
for bus in Buses_without_load
    Load_dict[bus] = 0.0
end

Load = Load_dict

buses_except_upward = setdiff(buses, Upward_set)



Load_dict_q = Dict{Int, Float64}()

for row in eachrow(load_data)
    Load_dict_q[row.bus] = row.q_mvar  # Add the bus and its corresponding load value
end

# Now, add the additional buses with load 0.0 if they are not already in Load_dict
for bus in Buses_without_load
    Load_dict_q[bus] = 0.0
end

Load_q = Load_dict_q


model = Model(Gurobi.Optimizer)

Nodes

#variables
@variable(model, f[1:n,1:n])
@variable(model, j[1:n,1:n])
@variable(model, p[Nodes]>=0)
@variable(model, delta[Nodes])
@variable(model, V[Nodes])
@variable(model, Q[Nodes])  

#Active Power Flow calculation for each edge
@constraint(model,[m in Nodes,n in connected_buses_dict[m]],B[bus_id_to_index[m], bus_id_to_index[n]] *(delta[m] - delta[n])==f[bus_id_to_index[m], bus_id_to_index[n]]) 
@constraint(model,[m in Nodes,n in connected_buses_dict[m]],B[bus_id_to_index[m], bus_id_to_index[n]] *(V[m] - V[n])==j[bus_id_to_index[m], bus_id_to_index[n]])  ###########

#Voltage for all buses is considered 1
@constraint(model, V[slack_bus] == 1)

for k in Nodes 
    if k != slack_bus
        @constraint(model, 0.8 <= V[k] <= 1.2)         ###########
    end
end

#Voltage angle for slack bus is considered 0
@constraint(model, delta[slack_bus] == 0)
#Active Power Limits for Generators
@constraint(model,PowerProductionLimits[i=Upward_set] , minQ[i] <= p[i]  <= maxQ[i])
#Reactive Power Limits for Generators
@constraint(model,ReactivePowerProductionLimits[i=Upward_set] , Qmin[i] <= Q[i]  <= Qmax[i]) ##############




Flowmax_dict = Dict{Tuple{Int, Int}, Float64}()
for row in eachrow(Edges)
    Flowmax_dict[(row.from_bus, row.to_bus)] = row.FlowMax
    Flowmax_dict[(row.to_bus, row.from_bus)] = row.FlowMax
end

# Active Power Limit for Edges' Flows
@constraint(model,[m in Nodes,n in connected_buses_dict[m]] ,  f[bus_id_to_index[m], bus_id_to_index[n]] <= Flowmax_dict[m,n])  
@constraint(model,[m in Nodes,n in connected_buses_dict[m]] ,  j[bus_id_to_index[m], bus_id_to_index[n]] <= Flowmax_dict[m,n])  



#Active Power Production of non Gen
@constraint(model, [n in buses_except_upward], p[n]==0)
#Reactive Power Production of non Gen
@constraint(model, [n in buses_except_upward], Q[n]==0) #############

#Active Power injection of node n = Sum of ejected power flows from node n
@constraint(model, price[n in Nodes], sum(f[bus_id_to_index[n], bus_id_to_index[m]] for m in connected_buses_dict[n]) ==p[n] - Load[n] )
#Reactive Power injection of node n = Sum of ejected power flows from node n
@constraint(model, [n in Nodes], sum(j[bus_id_to_index[n], bus_id_to_index[m]] for m in connected_buses_dict[n]) ==Q[n] - Load_q[n] ) ###############

Load_q
Load
Upward_set
PU

@objective(model, Min,  sum(PU[i]*p[i] for i in Upward_set))

optimize!(model)
status = termination_status(model)
println(status)   




@show objective_value(model)

#Results for production and injection
results_df = DataFrame(
    Bus = buses,
    V_pu = [value(V[i]) for i in buses],
    Delta = [rad2deg(value(delta[i])) for i in buses],

)


production_df = DataFrame(
    Bus = Upward_set,
    production = [value(p[i]) for i in Upward_set],
    q = [value(Q[i]) for i in Upward_set],
)

flows_df = DataFrame(
    Edge = edges_index,
    from_bus = [Edges.from_bus[i] for i in Edges_leng],
    flows_to = [Edges.to_bus[i] for i in Edges_leng],
    Flow_p = [value(f[bus_id_to_index[Edges.from_bus[i]], bus_id_to_index[Edges.to_bus[i]]]) for i in Edges_leng],
    Flow_q = [value(j[bus_id_to_index[Edges.from_bus[i]], bus_id_to_index[Edges.to_bus[i]]]) for i in Edges_leng],

)

price_df = DataFrame(
    Bus = Nodes,
    node_price = [dual(price[j]) for j in Nodes]
)


#XLSX.writetable("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Thesis_Writing\\Results\\Decoupled_Paper_nodes_PV.xlsx", "flows"=> flows_df, "results" => results_df, "production" => production_df, "price" => price_df)