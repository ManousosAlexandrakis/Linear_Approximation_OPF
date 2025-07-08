using Pkg
using DataFrames,JuMP, Ipopt
using LinearAlgebra
using XLSX

# Load Excel file
filepath = "/Users/malexandrakis/Library/CloudStorage/OneDrive-Personal/Diploma_Thesis/Linear_Approximation_OPF/Case_Files"
filename = joinpath(filepath,"case_ieee123_modified.xlsx")


load_data = DataFrame(XLSX.readtable(filename, "load"))
gen_data = DataFrame(XLSX.readtable(filename, "gen"))
bus_data = DataFrame(XLSX.readtable(filename, "bus"))
slack_data = DataFrame(XLSX.readtable(filename, "ext_grid"))
Downward_data = DataFrame(XLSX.readtable(filename, "Downward"))
Upward_data = DataFrame(XLSX.readtable(filename, "Upward"))
#FlowMax_data = DataFrame(XLSX.readtable(filename, "FlowMax"))
Edges = DataFrame(XLSX.readtable(filename, "edges"))

#data = Line in transportation model
data = DataFrame(
    from_bus = Edges.from_bus,
    to_bus = Edges.to_bus,
    Flowmax = Edges.FlowMax
) 

slack_v = slack_data[1, :vm_pu]
slack_bus = slack_data[1, :bus]
slack_degree = slack_data[1, :va_degree]

slack_index = findfirst(bus_data[:, :bus] .== slack_bus)
bus_id_to_index = Dict(bus_data[setdiff(1:end, slack_index), :bus] .=> 1:size(bus_data, 1)-1)
bus_id_to_index[slack_bus] = size(bus_data, 1)

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

n = size(bus_data,1)

Edges_leng = 1:length(data.from_bus)

Nodes = Int[]
for row in eachrow(bus_data)
    bus = row.bus
    push!(Nodes, bus)
end

Ssystem = 1

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
minQ = Dict{Int,Float64}()
maxQ = Dict{Int,Float64}()
for row in eachrow(Upward_data)
    name = row.name
    u_price = row.PU
    u_minquantity = row.MinQ
    u_maxquantity = row.MaxQ
    #println(u_quantity)
    PU[name] = u_price
    minQ[name] = u_minquantity
    maxQ[name] = u_maxquantity
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
global yk = zeros(Complex, n, n)
global yshunt = zeros(Complex,n)

for row in eachrow(Edges)
    From_Bus = bus_id_to_index[row.from_bus]
    To_Bus = bus_id_to_index[row.to_bus]
    x = row.X_pu
    r = row.R_pu
    local z = r + x .* im
    y[From_Bus,To_Bus] = 1 ./ z[1]
    y[To_Bus,From_Bus] = 1 ./ z[1]
end

# for row in eachrow(shunt_data)
#     bus = row.bus
#     Pshunt = row.p_mw
#     Qshunt = row.q_mvar
#     yshunt[bus_id_to_index[bus]] = Pshunt - Qshunt*im
# end

Y = zeros(Complex, n, n)


for k in Nodes
    Y[bus_id_to_index[k], bus_id_to_index[k]] = yshunt[bus_id_to_index[k]] + sum((y[bus_id_to_index[k], bus_id_to_index[m]] + 0.5*yk[bus_id_to_index[k], bus_id_to_index[m]]) for m in connected_buses_dict[k])
end


for k in Nodes
    for m in connected_buses_dict[k]
        Y[bus_id_to_index[k],bus_id_to_index[m]] = -y[bus_id_to_index[k], bus_id_to_index[m]]
    end
end

#println("Admittance Matrix (Ykk):")
#println(Y)

G = real.(Y)
B = imag.(Y)

PV_buses = Int[]
for row in eachrow(gen_data)
    if !(row.bus in PV_buses)
        push!(PV_buses, row.bus)
    end
end

model = Model(optimizer_with_attributes(Ipopt.Optimizer))

@variable(model, V[Nodes])
@variable(model, delta[Nodes])
@variable(model, Q[PV_buses])
@variable(model, production[Upward_set])

#PQ
global total_p= 0.0
global total_q = 0.0

total_pgen_pload = Dict{Int, Float64}()
total_qgen_qload = Dict{Int, Float64}()
for row in eachrow(bus_data)
    bus = row.bus
    total_pgen_pload[bus_id_to_index[bus]] = 0.0
    total_qgen_qload[bus_id_to_index[bus]] = 0.0
end

for row in eachrow(load_data)
    bus = bus_id_to_index[row.bus]
    Pload = row.p_mw/Ssystem
    Qload = row.q_mvar/Ssystem
    total_pgen_pload[bus] = get(total_pgen_pload, bus, 0.0) - Pload 
    total_qgen_qload[bus] = get(total_qgen_qload, bus, 0.0) - Qload 
    global total_p += total_pgen_pload[bus]
    global total_q += total_qgen_qload[bus]
    
end
println(total_p)
println(total_q)
total_pgen_pload[bus_id_to_index[1]]
bus_id_to_index

#PV
Qmin = Dict{Int, Float64}()
Qmax = Dict{Int, Float64}()
for row in eachrow(gen_data)
    bus = bus_id_to_index[row.bus]
    #println(row.bus)
    Pgen = row.p_mw
    # vm = row.vm_pu
    Qmin[row.bus] = row.QRmin
    Qmax[row.bus] = row.QRmax
    #total_pgen_pload[bus] += Pgen ./ Ssystem
    #@constraint(model, V[row.bus] == vm)
end

for k in PV_buses 
     @constraint(model, Qmin[k] <= Q[k] <= Qmax[k])
     #@constraint(model, 0 <= Q_downward[k] <= Qmax[k])
end

PQ_buses = filter(bus -> !(bus in PV_buses), Nodes)

@constraint(model, V[slack_bus] == slack_v)
@constraint(model, delta[slack_bus] == slack_degree)

# PQ_buses
# for k in Nodes
#     if k != slack_bus
#         # @constraint(model, Q[k] - total_qgen_qload[bus_id_to_index[k]] <= 10^-3)
#         # @constraint(model, Q[k] - total_qgen_qload[bus_id_to_index[k]] >= -10^-3)
#         @constraint(model, Q[k] - total_qgen_qload[bus_id_to_index[k]] == 0)
#     end
# end

for k in Nodes
    if k != slack_bus
        @constraint(model,  0.8 <= V[k] <= 1.2) 
    end
end

for n in eachrow(data)

    from_bus = n.from_bus
    to_bus = n.to_bus
    Sn = n.Flowmax
    g_from = real(y[bus_id_to_index[from_bus],bus_id_to_index[to_bus]])
    b_from = imag(y[bus_id_to_index[from_bus],bus_id_to_index[to_bus]])
    g_to = real(y[bus_id_to_index[to_bus],bus_id_to_index[from_bus]])
    b_to = imag(y[bus_id_to_index[to_bus],bus_id_to_index[from_bus]])

    @NLconstraint(model, (V[from_bus]^2 - V[from_bus]*V[to_bus]*cosd(delta[from_bus] - delta[to_bus]))^2 
    +(V[from_bus]*V[to_bus]*sind(delta[from_bus]-delta[to_bus]))^2 <= Sn^2*(1/(g_from^2 + b_from^2))
    )

    @NLconstraint(model, (V[to_bus]^2 - V[to_bus]*V[from_bus]*cosd(delta[to_bus] - delta[from_bus]))^2 
    +(V[to_bus]*V[from_bus]*sind(delta[to_bus]-delta[from_bus]))^2 <= Sn^2*(1/(g_to^2 + b_to^2))
    )

end

#powerflow equation
@NLconstraint(model,  price[k in Nodes],  total_pgen_pload[bus_id_to_index[k]] + sum(production[i] for i in Upward_set if i == k) == 
V[k]^2*G[bus_id_to_index[k],bus_id_to_index[k]] - V[k]*sum(V[m] * (-G[bus_id_to_index[k], bus_id_to_index[m]] * cosd(delta[k] - delta[m]) - B[bus_id_to_index[k], bus_id_to_index[m]] * sind(delta[k] - delta[m])) for m in connected_buses_dict[k]) 
)

for k in Nodes
    @NLconstraint(model, V[k]^2*B[bus_id_to_index[k],bus_id_to_index[k]] + V[k]*sum(V[m] * (-G[bus_id_to_index[k], bus_id_to_index[m]] * sind(delta[k] - delta[m]) + B[bus_id_to_index[k], bus_id_to_index[m]] * cosd(delta[k] - delta[m])) for m in connected_buses_dict[k])   + sum(Q[i] for i in PV_buses if i == k) + total_qgen_qload[bus_id_to_index[k]] <= 10^-3)

    @NLconstraint(model, V[k]^2*B[bus_id_to_index[k],bus_id_to_index[k]] + V[k]*sum(V[m] * (-G[bus_id_to_index[k], bus_id_to_index[m]] * sind(delta[k] - delta[m]) + B[bus_id_to_index[k], bus_id_to_index[m]] * cosd(delta[k] - delta[m])) for m in connected_buses_dict[k])   + sum(Q[i] for i in PV_buses if i == k) + total_qgen_qload[bus_id_to_index[k]] >= -10^-3)
end


@constraint(model, UpperBound1[i in Upward_set], production[i] <= maxQ[i])
@constraint(model, UpperBound2[i in Upward_set], production[i] >= minQ[i])


#@objective(model, Min, 0)
@objective(model, Max,  -  sum(PU[i]*production[i] for i in Upward_set))

optimize!(model)

# Create a new DataFrame to store the results
println(value(production[slack_bus]))
results_df = DataFrame(
    Bus = Nodes,
    vm_pu = [value(V[i]) for i in Nodes],
    va_degree = [value(delta[i]) for i in Nodes]
    
)
# println(results_df)
Q = DataFrame(
    Bus = PV_buses,
    q_pu = [value(Q[i]) for i in PV_buses],

)

# reactive= DataFrame(
#     Bus = Nodes,
#     reactive = [value(Q[i]) for i in Nodes]
# )
prod_df = DataFrame(   
    bus = Upward_set,
    p = [value(production[i]) for i in Upward_set],
    pmax = [maxQ[i] for i in Upward_set],
    pmin =[minQ[i] for i in Upward_set],
    PU = [PU[i] for i in Upward_set]
)


#println(results_df)
# println(prod_df)
# println(cons_df)
# println(Q)
obj_value = objective_value(model)
println("Objective Function Value: $obj_value")

# flow = []
# flow_reactive = []
# global Vfrom = Complex{Float64}[]
# global Vto = Complex{Float64}[]
# for row in eachrow(data)
    
#     from_bus = row.from_bus
#     to_bus = row.to_bus
#     global Vfrom = value(V[from_bus])*(cosd(value(delta[from_bus]))+ sind(value(delta[from_bus]))*im) 
#     global Vto = value(V[to_bus])*(cosd(value(delta[to_bus]))+ sind(value(delta[to_bus]))*im) 
#     I = (Vfrom-Vto)*y[bus_id_to_index[from_bus],bus_id_to_index[to_bus]]
#     flow_valuefrom = (Vfrom)*conj(I)
#     flow_valueto = (Vto)*conj(I)
#     #println(from_bus,"  ",real(flow_valuefrom) , "  ", to_bus, " ", real(flow_valueto))
#     if real(flow_valuefrom) > real(flow_valueto)
#         push!(flow, real(flow_valuefrom))
#     else    
#         push!(flow,real(-flow_valueto))
#     end
#     if imag(flow_valuefrom) > imag(flow_valueto)
#         push!(flow_reactive, imag(flow_valuefrom))
#     else    
#         push!(flow_reactive,imag(-flow_valueto))
#     end
# end
flow_from = []
flow_to = []
flow_reactive_from = []
flow_reactive_to = []
global Vfrom = Complex{Float64}[]
global Vto = Complex{Float64}[]
for row in eachrow(data)
    
    from_bus = row.from_bus
    to_bus = row.to_bus
    global Vfrom = value(V[from_bus])*(cosd(value(delta[from_bus]))+ sind(value(delta[from_bus]))*im) 
    global Vto = value(V[to_bus])*(cosd(value(delta[to_bus]))+ sind(value(delta[to_bus]))*im) 
    I = (Vfrom-Vto)*y[bus_id_to_index[from_bus],bus_id_to_index[to_bus]]
    flow_valuefrom = (Vfrom)*conj(I)
    flow_valueto = (Vto)*conj(-I)
    #println(from_bus,"  ",real(flow_valuefrom) , "  ", to_bus, " ", real(flow_valueto))
    push!(flow_from, real(flow_valuefrom)) 
    push!(flow_to,real(flow_valueto))

    push!(flow_reactive_from, imag(flow_valuefrom))  
    push!(flow_reactive_to,imag(flow_valueto))

end

# println(flow)

# Sn_flow=[]
# for n in eachrow(data)
#     from_bus = n.from_bus
#     to_bus = n.to_bus
#     Sn = n.Flowmax
#     g_from = real(y[bus_id_to_index[from_bus], bus_id_to_index[to_bus]])
#     b_from = imag(y[bus_id_to_index[from_bus], bus_id_to_index[to_bus]])
#     g_to = real(y[bus_id_to_index[to_bus], bus_id_to_index[from_bus]])
#     b_to = imag(y[bus_id_to_index[to_bus], bus_id_to_index[from_bus]])

#     # Retrieve the values after solving
#     V_from_bus_val = value(V[from_bus])
#     V_to_bus_val = value(V[to_bus])
#     delta_from_bus_val = value(delta[from_bus])
#     delta_to_bus_val = value(delta[to_bus])

#     # Calculate the LHS values for both constraints
#     flow_from = sqrt((
#         (V_from_bus_val^2 - V_from_bus_val * V_to_bus_val * cosd(delta_from_bus_val - delta_to_bus_val))^2 +
#         (V_from_bus_val * V_to_bus_val * sind(delta_from_bus_val - delta_to_bus_val))^2
#     ) * (g_from^2 + b_from^2))

#     flow_to = sqrt((
#         (V_to_bus_val^2 - V_to_bus_val * V_from_bus_val * cosd(delta_to_bus_val - delta_from_bus_val))^2 +
#         (V_to_bus_val * V_from_bus_val * sind(delta_to_bus_val - delta_from_bus_val))^2
#     ) * (g_to^2 + b_to^2))
#     if flow_from > flow_to
#         push!(Sn_flow, flow_from)
#     else
#         push!(Sn_flow, flow_to) 
#     end
# end


flows_df = DataFrame(
    Edge = Edges_leng,
    flows_from = [flow_from[i] for i in Edges_leng],
    flows_to = [flow_to[i] for i in Edges_leng],
    flows_reactive_from = [flow_reactive_from[i] for i in Edges_leng],
    flows_reactive_to = [flow_reactive_to[i] for i in Edges_leng],
    #Sn_flows = [Flowmax[i] for i in Edges_leng]
    Sn = [data.Flowmax[i] for i in Edges_leng]
)



# println(flows_df)
# XLSX.writetable("paper_PV__opf_flows3.xlsx","flows" => flows_df)

# for j in Downward_set
#     println("dual[$j] = ", JuMP.dual(price[j]))
# end
price_df = DataFrame(
    Bus = Nodes,
    node_price = [dual(price[j]) for j in Nodes]
)
# ptotal = DataFrame(
#     bus = 1:n,
#     p_mw = [total_pgen_pload[i] for i in 1:n]
# )
# #for j in Downward_set
# #    println("dual[$j] = ", JuMP.shadow_price(LowerBound1[j]))
# #end

# XLSX.writetable("HV-UG_acopf.xlsx", "flows"=> flows_df, "prod" => prod_df, "bus" => results_df, "reactive" => Q, "LMP" => price_df)
