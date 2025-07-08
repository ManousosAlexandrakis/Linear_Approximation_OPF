from pyomo.environ import *
import pandas as pd
import numpy as np
from pandas import DataFrame
from math import degrees as rad2deg 

###### Data Handling ######
def load_excel(filepath,sheet_name, fill_empty_values = True):
    output_dataframe = pd.read_excel(filepath, sheet_name=sheet_name)
    if fill_empty_values:
        output_dataframe = output_dataframe.fillna(0)
        
    return output_dataframe

excel_directory = "//Users//malexandrakis//Library//CloudStorage//OneDrive-Personal//Diploma_Thesis/Linear_Approximation_OPF//Case_Files//"

filename = "case_ieee123_modified.xlsx"

sgen_data = load_excel(excel_directory + filename,"gen")
Edges = load_excel(excel_directory + filename,"edges")
bus_data = load_excel(excel_directory + filename,"bus")
load_data = load_excel(excel_directory + filename,"load")
slack_data = load_excel(excel_directory + filename,"ext_grid")
Upward_data = load_excel(excel_directory + filename,"Upward")


# Data for slack bus
slack_v = slack_data["vm_pu"].iloc[0]      #1
slack_degree = slack_data["va_degree"].iloc[0] #0
slack_bus = slack_data["bus"].iloc[0] #1000

#
buses = bus_data["bus"].tolist()
edges_index = Edges.index.tolist()
# edges_index = Edges["idx"].tolist()

# Create a dictionary to store the index of each bus
# slack_index = buses.index(slack_bus)

bus_id_to_index = {buses[i]: i for i in range(len(buses)-1)}
bus_id_to_index[slack_bus] = buses.index(slack_bus)



# # Create a dictionary mapping edges to FlowMax
Flowmax_dict = dict()
for i in range(len(Edges)): 
    to_bus = Edges["to_bus"].iloc[i]
    from_bus = Edges["from_bus"].iloc[i]
    Flowmax_dict[(from_bus, to_bus)] = Edges["FlowMax"].iloc[i]
    Flowmax_dict[(to_bus, from_bus)] = Edges["FlowMax"].iloc[i]
    
Flowmax_edge_dict = dict()
for i in range(len(Edges)):
    index = Edges["idx"].iloc[i] - 1
    Flowmax_edge_dict[i] = Edges["FlowMax"].iloc[index]
    
# # Sbase of the system
Ssystem = 1
# # Create a dictionary to store connected buses
connected_buses_dict = dict()

for i in range(len(Edges)):
    from_bus = int(Edges["from_bus"].iloc[i])
    to_bus = int(Edges["to_bus"].iloc[i])

    # Add to_bus to from_bus's connection list
    if from_bus not in connected_buses_dict:
        connected_buses_dict[from_bus] = set()
    connected_buses_dict[from_bus].add(to_bus)

    # Add from_bus to to_bus's connection list
    if to_bus not in connected_buses_dict:
        connected_buses_dict[to_bus] = set()
    connected_buses_dict[to_bus].add(from_bus)

# Optional: convert sets to sorted lists
for bus in connected_buses_dict:
    connected_buses_dict[bus] = sorted(connected_buses_dict[bus])
    #print(connected_buses_dict)

# Example: print nicely
for bus, neighbors in connected_buses_dict.items():
    print(f"Bus {bus} is connected to: {neighbors}")
    
    
# Total number of buses and edges
n = len(buses)
Edges_leng =  len(Edges)

# # Create dictionaries to store PU, MinQ and MaxQ parameters for upward generators
PU = {Upward_data["Bus"].iloc[i] : Upward_data["PU"].iloc[i] for i in range(len(Upward_data))}
MinQ = {Upward_data["Bus"].iloc[i] : Upward_data["MinQ"].iloc[i] for i in range(len(Upward_data))}
MaxQ = {Upward_data["Bus"].iloc[i] : Upward_data["MaxQ"].iloc[i] for i in range(len(Upward_data))}

Upward_set = set(Upward_data["Bus"])
buses_except_upward = set(buses) - set(Upward_set)

# # Create Y matrix
y = np.zeros((n,n), dtype=complex)


for i in range(len(Edges)):
    From_bus = bus_id_to_index[Edges["from_bus"].iloc[i]]
    To_bus = bus_id_to_index[Edges["to_bus"].iloc[i]]
    r = 0
    x = Edges["X_pu"].iloc[i]
    z = complex(r,x)
    y[From_bus, To_bus] = 1/z
    y[To_bus, From_bus] = 1/z # symmetric
    
Y = np.zeros((n,n), dtype=complex)

for k in buses:
    Y[bus_id_to_index[k], bus_id_to_index[k]] = sum(y[bus_id_to_index[k],bus_id_to_index[m]] for m in connected_buses_dict[k])

for k in buses:
    for m in connected_buses_dict[k]:
        Y[bus_id_to_index[k], bus_id_to_index[m]] = -y[bus_id_to_index[k], bus_id_to_index[m]]

# print("Y matrix:", Y)

B = Y.imag
# print("B matrix:", B)

Load_set = set(load_data["bus"])
buses_without_load = set(buses) - set(Load_set)

Load_dict = {load_data["bus"].iloc[i] : load_data["p_mw"].iloc[i] for i in range(len(load_data))}

##### Math Optimization model ######

# # Model
model = ConcreteModel(name="BTheta")

# # Variables
model.p = Var(buses, within=NonNegativeReals)
model.f = Var(range(n), range(n), within=Reals)
model.delta = Var(buses, within=Reals)
model.u = Var(buses, within=Reals)

model.generation_cost = Var()

# # CONSTRAINTS

#  # Real Power Flow calculation for each edge
def real_power_flow(model,m,n):
    return model.f[bus_id_to_index[m],bus_id_to_index[n]] == B[bus_id_to_index[m], bus_id_to_index[n]] *(model.delta[m] - model.delta[n])
connected_bus_pairs = [(m, n) for m in buses for n in connected_buses_dict[m]]
model.real_power_flow = Constraint(connected_bus_pairs, rule=real_power_flow)

# print("Real Power Flow Constraints:")
# for key in model.real_power_flow:
#     print(f"Constraint {key}: {model.real_power_flow[key].expr}")

# # Voltage magnitude for all buses is considered 1 p.u.
def voltage_magnitude(model, m):
    return model.u[m] == 1
model.voltage_magnitude = Constraint(buses, rule=voltage_magnitude)

# print("Voltage Magnitude Constraints:")
# for key in model.voltage_magnitude:
#     print(f"Constraint {key}: {model.voltage_magnitude[key].expr}")

def slack_bus_delta(model):
    return model.delta[slack_bus] == 0
model.slack_bus_delta = Constraint(rule=slack_bus_delta)

# print("Slack Bus Delta Constraint:")
# print(f"Constraint: {model.slack_bus_delta.expr}]")

def power_generation_upper_limit(model, m):
    if m in Upward_set:
        return model.p[m] <= MaxQ[m]
    else:
        return model.p[m] == 0
model.power_generation_upper_limit = Constraint(buses, rule=power_generation_upper_limit)

# print("Power Generation Upper Limit Constraints:")
# for key in model.power_generation_upper_limit:
#     print(f"Constraint {key}: {model.power_generation_upper_limit[key].expr}")

def power_generation_lower_limit(model, m):
    if m in Upward_set:
        return model.p[m] >= MinQ[m]
    else:
        return model.p[m] == 0
model.power_generation_lower_limit = Constraint(buses, rule=power_generation_lower_limit)

# print("Power Generation Lower Limit Constraints:")
# for key in model.power_generation_lower_limit:
#     print(f"Constraint {key}: {model.power_generation_lower_limit[key].expr}")
    
def flows_limit(model,m,n):
    return model.f[bus_id_to_index[m], bus_id_to_index[n]] <= Flowmax_dict[(m,n)]
model.flows_limit = Constraint(connected_bus_pairs, rule=flows_limit)

# print("Flows Limit Constraints:")
# for key in model.flows_limit:
#     print(f"Constraint {key}: {model.flows_limit[key].expr}")

def nodal_power_balance(model,m):
    return -sum(model.f[bus_id_to_index[m], bus_id_to_index[n]] for n in connected_buses_dict[m]) + model.p[m] - Load_dict.get(m,0) == 0
model.nodal_power_balance = Constraint(buses, rule=nodal_power_balance)

# print('Nodal Power Balance Constraints:')
# for key in model.nodal_power_balance:
#     print(f"Constraint {key}: {model.nodal_power_balance[key].expr}")
    
    
# # Objective Function
def obj_rule(model):
    return model.generation_cost
model.obj_rule = Objective(rule=obj_rule,sense=minimize)

def objective_function(model):
    return model.generation_cost == sum(model.p[m] * PU[m] for m in Upward_set)
model.objective_function = Constraint(rule=objective_function)

# Set up dual variables
model.dual = Suffix(direction=Suffix.IMPORT)

# Set solver
solver = SolverFactory("gurobi")

# Solve model
solver.solve(model, tee=True)


# Set up dual variables
# model.dual = Suffix(direction=Suffix.IMPORT)

print("###############################################")
print(">> ")
print(">> Optimization problem executed successfully!!")
print(">>")
print("###############################################")

# Print results
print(">> Results:")
print(">> Generation Costs:", model.generation_cost())



# print(">> Power Generation at each bus:")
# Print active power production for each bus
# for m in buses:
#     print(f">> {m}: {model.p[m]():.4f} MW")  # 4 decimal precision

# Create a DataFrame for upward production
prod_df = DataFrame({
    "Bus": list(Upward_set),
    "p_pu": [value(model.p[i]) for i in list(Upward_set)],
    "pmax_pu": [MaxQ[i] for i in list(Upward_set)],
    "pmin_pu": [MinQ[i] for i in list(Upward_set)],
    "PU_euro/MWh": [PU[i] for i in Upward_set]
})


# print(">> Voltages at each bus:")

# Print voltage results for each bus
# for m in buses:
#     print(f">> {m}: |V| = {value(model.u[m]):.1f} pu, angle = {rad2deg(value(model.delta[m])):.6f}°")

# Create DataFrame for results
results_df = pd.DataFrame({
    "Bus": buses,
    "vm_pu": [value(model.u[i]) for i in buses],
    "va_degrees": [rad2deg(value(model.delta[i])) for i in buses]
})

price_df = pd.DataFrame({
    "Bus": buses,
    "nodal_price_euro/MWh": [model.dual[model.nodal_power_balance[i]] for i in buses]
})

flows_df = pd.DataFrame({
    "Edge": [i + 1 for i in edges_index],
    "from_bus": [Edges["from_bus"].iloc[i] for i in range(Edges_leng)],
    "flows_to": [Edges["to_bus"].iloc[i] for i in range(Edges_leng)],
    "Flow_p_pu": [value(model.f[bus_id_to_index[Edges["from_bus"].iloc[i]], bus_id_to_index[Edges["to_bus"].iloc[i]]]) for i in range(Edges_leng)],
    "Flowmax_pu": [Flowmax_edge_dict[i] for i in range(len(Edges))]
})


filepath1 = "//Users//malexandrakis//Documents//Results//Paper_nodes_PV//"
writer = pd.ExcelWriter(filepath1 + "BTheta_results_case_ieee123_python.xlsx", engine='xlsxwriter')

results_df.to_excel(writer, sheet_name="Results", index=False)
prod_df.to_excel(writer, sheet_name="Production", index=False)
price_df.to_excel(writer, sheet_name="LMP", index=False)
flows_df.to_excel(writer, sheet_name="Flows", index=False)


writer.close()


