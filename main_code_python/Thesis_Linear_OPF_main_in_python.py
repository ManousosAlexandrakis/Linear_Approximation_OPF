from pyomo.environ import *
import pandas as pd
import numpy as np
from pandas import DataFrame
from math import degrees as rad2deg 
from pyomo.opt import TerminationCondition

###### Data Handling ######
def load_excel(filepath,sheet_name, fill_empty_values = True):
    output_dataframe = pd.read_excel(filepath, sheet_name=sheet_name)
    if fill_empty_values:
        output_dataframe = output_dataframe.fillna(0)
        
    return output_dataframe

excel_directory = ".//"

filename = "case_ieee123_modified.xlsx"

sgen_data = load_excel(excel_directory + filename,"gen")
Edges = load_excel(excel_directory + filename,"edges")
bus_data = load_excel(excel_directory + filename,"bus")
load_data = load_excel(excel_directory + filename,"load")
slack_data = load_excel(excel_directory + filename,"ext_grid")
Upward_data = load_excel(excel_directory + filename,"Upward")


# Data for slack bus
slack_v = slack_data["vm_pu"].iloc[0]      #1
slack_delta = slack_data["va_degree"].iloc[0] #0
slack_bus = slack_data["bus"].iloc[0] #1000

#
buses = bus_data["bus"].tolist()
edges_index = Edges.index.tolist()
# edges_index = Edges["idx"].tolist()

# Create a dictionary to store the index of each bus
# slack_index = buses.index(slack_bus)

bus_id_to_index = {buses[i]: i for i in range(len(buses)-1)}
bus_id_to_index[slack_bus] = buses.index(slack_bus)

K_buses = sorted(set(
    row['bus'] for _, row in sgen_data.iterrows() if row['bus'] != slack_bus
))
n_K_buses = len(K_buses)


L_buses = sorted([
    bus for bus in buses if bus != slack_bus and bus not in K_buses
])
n_L_buses = len(L_buses)

slack_K_buses = [slack_bus] + list(K_buses)
K_L_buses = K_buses + L_buses
n_K_L_buses = len(K_L_buses)

# # Create a map for all the buses(bus names to indexes)
# Slack gets the last index
# K buses get the first indexes 
# L buses get the indexes after the K buses

# slack bus has the biggest index
slack_map = {slack_bus: len(buses)-1 }

# # Create a map for all the K buses
# K buses get the first indexes
K_bus_mapping = {K_buses[i]: i for i in range(len(K_buses))}

L_bus_mapping = {L_buses[i]:i for i in range(len(L_buses))}

complete_mapping = {}

# Start with K_bus_mapping
complete_mapping.update(K_bus_mapping)

# Offset for L_buses
offset = len(K_bus_mapping)

# Add L_buses with continued indexing
for i, bus_id in enumerate(L_buses):
    complete_mapping[bus_id] = offset + (i)

# Add slack_bus at the end
complete_mapping[slack_bus] = len(buses)-1



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

    
# Total number of buses and edges
n = len(buses)
Edges_leng =  len(Edges)

# # Create dictionaries to store PU, MinQ and MaxQ parameters for upward generators
PU = {Upward_data["Bus"].iloc[i] : Upward_data["PU"].iloc[i] for i in range(len(Upward_data))}
# Minimum and Maximum active power for generators
MinQ = {Upward_data["Bus"].iloc[i] : Upward_data["MinQ"].iloc[i]/Ssystem for i in range(len(Upward_data))}
MaxQ = {Upward_data["Bus"].iloc[i] : Upward_data["MaxQ"].iloc[i]/Ssystem for i in range(len(Upward_data))}
# Minimum and Maximum reactive power for generators
Qmin = {sgen_data["bus"].iloc[i] : sgen_data["QRmin"].iloc[i]/Ssystem for i in range(len(sgen_data))}
Qmax = {sgen_data["bus"].iloc[i] : sgen_data["QRmax"].iloc[i]/Ssystem for i in range(len(sgen_data))}

Upward_set = set(Upward_data["Bus"])
buses_except_upward = set(buses) - set(Upward_set)


# ! να το τσεκάρω και με το μεγαλύτερο σύστημα
Rij = {edges_index[i]: Edges["R_pu"].iloc[i] for i in range(len(Edges))}
Xij = {edges_index[i]: Edges["X_pu"].iloc[i] for i in range(len(Edges))}


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

# Convert sets to sorted lists
for bus in connected_buses_dict:
    connected_buses_dict[bus] = sorted(connected_buses_dict[bus])
    
    
# # Create Y matrix
y = np.zeros((n,n), dtype=complex)

for i in range(len(Edges)):
    From_bus = complete_mapping[Edges["from_bus"].iloc[i]]
    To_bus = complete_mapping[Edges["to_bus"].iloc[i]]
    r = Edges["R_pu"].iloc[i]
    x = Edges["X_pu"].iloc[i]
    z = complex(r,x)
    y[From_bus, To_bus] = 1/z
    y[To_bus, From_bus] = 1/z # symmetric
    
Y = np.zeros((n,n), dtype=complex)

for k in buses:
    Y[complete_mapping[k], complete_mapping[k]] = sum(y[complete_mapping[k],complete_mapping[m]] for m in connected_buses_dict[k])

for k in buses:
    for m in connected_buses_dict[k]:
        Y[complete_mapping[k], complete_mapping[m]] = -y[complete_mapping[k], complete_mapping[m]]
        
# np.set_printoptions(precision=4, suppress=True, linewidth=200, threshold=np.inf)

#print(Y)

# for row in Y:
#     print("  ".join(f"{z.real:+.2f}{z.imag:+.2f}j" for z in row))

# print(slack_map)
# Remove slack bus row
Y_without_slack = np.delete(Y, slack_map[slack_bus], axis=0)

# Remove slack bus column
Y_without_slack = np.delete(Y_without_slack, slack_map[slack_bus], axis=1)

Z = np.linalg.inv(Y_without_slack)
print(Z)
#print(Y)

# Define R and X matrix
R_matrix = np.real(Z)
X_matrix = np.imag(Z)


R_KK = np.zeros((n_K_buses,n_K_buses), dtype=float)
X_KK = np.zeros((n_K_buses,n_K_buses), dtype=float)

R_KL = np.zeros((n_K_buses,n_L_buses), dtype=float)
X_KL = np.zeros((n_K_buses,n_L_buses), dtype=float)

R_LK = np.zeros((n_L_buses,n_K_buses), dtype = float)
X_LK = np.zeros((n_L_buses,n_K_buses), dtype = float)

R_LL = np.zeros((n_L_buses, n_L_buses), dtype=float)
X_LL = np.zeros((n_L_buses, n_L_buses), dtype=float)

X_KK_inv = np.zeros( (n_K_buses, n_K_buses),dtype=float)

# # R_KK and X_KK
for k in K_buses:
    for m in K_buses:
        R_KK[K_bus_mapping[k], K_bus_mapping[m]] = R_matrix[complete_mapping[k], complete_mapping[m]]
        X_KK[K_bus_mapping[k], K_bus_mapping[m]] = X_matrix[complete_mapping[k], complete_mapping[m]]

# # R_KL and X_KL
for k in K_buses:
    for m in L_buses:
        R_KL[K_bus_mapping[k], L_bus_mapping[m]] = R_matrix[complete_mapping[k], complete_mapping[m]]
        X_KL[K_bus_mapping[k], L_bus_mapping[m]] = X_matrix[complete_mapping[k], complete_mapping[m]]
        
print(f"complete_mapping[{k}] = {complete_mapping[k]}")
print(f"complete_mapping[{m}] = {complete_mapping[m]}")
print(f"R_matrix shape = {R_matrix.shape}")
        
# # R_LK and X_LK
for k in L_buses:
    for m in K_buses:
        R_LK[L_bus_mapping[k], K_bus_mapping[m]] = R_matrix[complete_mapping[k], complete_mapping[m]]
        X_LK[L_bus_mapping[k], K_bus_mapping[m]] = X_matrix[complete_mapping[k], complete_mapping[m]]

# # R_LL and X_LL
for k in L_buses:
    for m in L_buses:
        R_LL[L_bus_mapping[k], L_bus_mapping[m]] = R_matrix[complete_mapping[k], complete_mapping[m]]
        X_LL[L_bus_mapping[k], L_bus_mapping[m]] = X_matrix[complete_mapping[k], complete_mapping[m]]

# # X_KK_inverted
X_KK_inv = np.linalg.inv(X_KK)


# Create dictionaries for active and reactive load (negative values)
total_pgen_pload = {load_data["bus"].iloc[i]:-load_data["p_mw"].iloc[i] for i in range(len(load_data))}
total_qgen_qload = {load_data["bus"].iloc[i]:-load_data["q_mvar"].iloc[i] for i in range(len(load_data))}



####################################################################                                 ####################################################################
#################################################################### Mathematical optimization model ####################################################################
####################################################################                                 ####################################################################

# # Model
model = ConcreteModel(name="Bolognani")

# # Variables
model.u = Var(buses, within=Reals)
model.delta = Var(buses,within=Reals)
model.q = Var(slack_K_buses, within=Reals)
model.production = Var(Upward_set,within=Reals)
model.active_power_k = Var(buses,within=Reals)
model.reactive_power_k = Var(buses,within=Reals)
model.f = Var(edges_index,within=Reals)
model.fq = Var(edges_index,within=Reals)

model.generation_cost = Var()

### Constraints for the optimization problem
def active_power_production_upper_limit(model,k):
    return model.production[k] <= MaxQ[k]
model.active_power_production_upper_limit = Constraint(Upward_set,rule=active_power_production_upper_limit)
# for key in model.active_power_production_upper_limit:
#     print(f"Constraint {key}: {model.active_power_production_upper_limit[key].expr}")


def active_power_production_lower_limit(model,k):
    return model.production[k] >= MinQ[k]
model.active_power_production_lower_limit = Constraint(Upward_set,rule=active_power_production_lower_limit)
# for key in model.active_power_production_lower_limit:
#     print(f"Constraint {key}: {model.active_power_production_lower_limit[key].expr}")

def reactive_power_production_upper_limit(model,k):
    return model.q[k] <= Qmax[k]
model.reactive_power_production_upper_limit = Constraint(slack_K_buses,rule=reactive_power_production_upper_limit)
# for key in model.reactive_power_production_upper_limit:
#     print(f"Constraint {key}: {model.reactive_power_production_upper_limit[key].expr}")


def reactive_power_production_lower_limit(model,k):
    return model.q[k] >= Qmin[k]
model.reactive_power_production_lower_limit = Constraint(slack_K_buses,rule=reactive_power_production_lower_limit)
# for key in model.reactive_power_production_lower_limit:
#     print(f"Constraint {key}: {model.reactive_power_production_lower_limit[key].expr}")



def slack_bus_voltage_magnitude(model):
    return model.u[slack_bus] == slack_v
model.slack_bus_voltage_magnitude = Constraint(rule=slack_bus_voltage_magnitude)
# for key in model.slack_bus_voltage_magnitude:
#     print(f"Constraint {key}: {model.slack_bus_voltage_magnitude[key].expr}")

def slack_bus_voltage_angle(model):
    return model.delta[slack_bus] == slack_delta
model.slack_bus_voltage_angle = Constraint(rule=slack_bus_voltage_angle)
# for key in model.slack_bus_voltage_magnitude:
#     print(f"Constraint {key}: {model.slack_bus_voltage_angle[key].expr}")


def voltage_magnitude_upper_limit(model,k):
    return model.u[k] <= 1.2
model.voltage_magnitude_upper_limit = Constraint(K_L_buses,rule=voltage_magnitude_upper_limit)

def voltage_magnitude_lower_limit(model,k):
    return model.u[k] >= 0.8
model.voltage_magnitude_lower_limit = Constraint(K_L_buses,rule=voltage_magnitude_lower_limit)


def voltage_magnitude_for_generators(model,k):
    return model.u[k] == 1
model.voltage_magnitude_for_generators = Constraint(Upward_set,rule=voltage_magnitude_for_generators)


def nodal_power_balance(model,i):
    return (sum(model.f[j] for j in edges_index if Edges["from_bus"].iloc[j] == i) - sum(model.f[j] for j in edges_index if Edges["to_bus"].iloc[j]==i)== model.active_power_k[i])
model.nodal_power_balance = Constraint(buses,rule=nodal_power_balance)
# for key in model.nodal_power_balance:
#      print(f"Constraint {key}: {model.nodal_power_balance[key].expr}")

def reactive_nodal_power_balance(model,i):
    return (sum(model.fq[j] for j in edges_index if Edges["from_bus"].iloc[j] == i) - sum(model.fq[j] for j in edges_index if Edges["to_bus"].iloc[j]==i)== model.reactive_power_k[i])
model.reactive_nodal_power_balance = Constraint(buses,rule=reactive_nodal_power_balance)
# for key in model.reactive_nodal_power_balance:
#      print(f"Constraint {key}: {model.reactive_nodal_power_balance[key].expr}")


# # Active Power Flows on each edge (Taylor Series Approximation)
def active_power_flow_Taylor_series(model,i):
    return model.f[i] - ( Rij[i] * (model.u[Edges["from_bus"].iloc[i]]-model.u[Edges["to_bus"].iloc[i]]) + Xij[i] * (model.delta[Edges["from_bus"].iloc[i]]-model.delta[Edges["to_bus"].iloc[i]]) ) / (Rij[i]**2 + Xij[i]**2)  == 0
model.active_power_flow_Taylor_series = Constraint(edges_index,rule=active_power_flow_Taylor_series)

def reactive_power_flow_Taylor_series(model,i):
    return model.fq[i] - ( Xij[i] * (model.u[Edges["from_bus"].iloc[i]]-model.u[Edges["to_bus"].iloc[i]]) - Rij[i] * (model.delta[Edges["from_bus"].iloc[i]]-model.delta[Edges["to_bus"].iloc[i]]) ) / (Rij[i]**2 + Xij[i]**2)  == 0
model.reactive_power_flow_Taylor_series = Constraint(edges_index,rule=reactive_power_flow_Taylor_series)


# # Active Power Flow Limits
def active_power_flow_upper_limits(model,i):
    return model.f[i] <= Flowmax_edge_dict[i]
model.active_power_flow_upper_limits = Constraint(edges_index,rule=active_power_flow_upper_limits)

def active_power_flow_lower_limits(model,i):
    return -model.f[i] <= Flowmax_edge_dict[i]
model.active_power_flow_lower_limits = Constraint(edges_index,rule=active_power_flow_lower_limits)


# # Reactive Power Flow Limits
def reactive_power_flow_upper_limits(model,i):
    return model.fq[i] <= Flowmax_edge_dict[i]
model.reactive_power_flow_upper_limits = Constraint(edges_index,rule=reactive_power_flow_upper_limits)

def reactive_power_flow_lower_limits(model,i):
    return -model.fq[i] <= Flowmax_edge_dict[i]
model.reactive_power_flow_lower_limits = Constraint(edges_index,rule=reactive_power_flow_lower_limits)

def voltage_magnitude(model,k):
    return model.u[k] == slack_v + (sum(R_matrix[complete_mapping[k], complete_mapping[i]] * (model.active_power_k[i]) for i in K_buses)
                                 + sum(X_matrix[complete_mapping[k], complete_mapping[i]] * (model.reactive_power_k[i]) for i in K_buses)
                                 + sum(R_matrix[complete_mapping[k], complete_mapping[i]] * (model.active_power_k[i]) for i in L_buses)
                                 + sum(X_matrix[complete_mapping[k], complete_mapping[i]] * (model.reactive_power_k[i]) for i in L_buses)) / slack_v
model.voltage_magnitude = Constraint(K_L_buses,rule=voltage_magnitude)

def voltage_angles(model,k):
    return model.delta[k] == slack_delta + (sum(-R_matrix[complete_mapping[k], complete_mapping[i]] * (model.reactive_power_k[i]) for i in K_buses)
                                         + sum(X_matrix[complete_mapping[k], complete_mapping[i]] * (model.active_power_k[i]) for i in K_buses)
                                         + sum(-R_matrix[complete_mapping[k], complete_mapping[i]] * (model.reactive_power_k[i]) for i in L_buses)
                                         + sum(X_matrix[complete_mapping[k], complete_mapping[i]] * (model.active_power_k[i]) for i in L_buses)) / (slack_v**2)
model.voltage_angles = Constraint(K_L_buses,rule=voltage_angles)

# # Reactive and Active Power injection equations for all buses
def reactive_power_injection(model,k):
    return model.reactive_power_k[k] == sum(model.q[i] for i in slack_K_buses if i == k) + total_qgen_qload.get(k, 0)
model.reactive_power_injection = Constraint(buses,rule=reactive_power_injection)

# print("=== Reactive Power Injection Constraints ===")
# for key in model.reactive_power_injection:
#     print(f"{key}: {model.reactive_power_injection[key].expr}")
    

def active_power_injection(model,k):
    return -model.active_power_k[k] == -sum(model.production[i] for i in slack_K_buses if i == k) - total_pgen_pload.get(k, 0)
model.active_power_injection = Constraint(buses,rule=active_power_injection) #dual-variable is the nodal price

# print("\n=== Active Power Injection Constraints ===")
# for key in model.active_power_injection:
#     print(f"{key}: {model.active_power_injection[key].expr}")

# # Objective Function
def obj_rule(model):
    return model.generation_cost
model.obj_rule = Objective(rule=obj_rule,sense=minimize)

def objective_function(model):
    return model.generation_cost == sum(model.production[m] * PU[m] for m in Upward_set)
model.objective_function = Constraint(rule=objective_function)

# Set up dual variables
model.dual = Suffix(direction=Suffix.IMPORT)

# Set solver
solver = SolverFactory("gurobi")

# Solve model
results = solver.solve(model, tee=True)

print("###############################################")
print(">> ")
print(">> Optimization problem executed successfully!!")
print(">>")
print("###############################################")

# Print results
print(">> Results:")
print(">> Generation Costs:", model.generation_cost())

results_df = DataFrame({
    "Bus": buses,
    "vm_pu": [value(model.u[i]) for i in buses],
    "va_degrees": [rad2deg(value(model.delta[i])) for i in buses]
})

prod_df = DataFrame({
    "Bus": list(Upward_set),
    "p_pu": [value(model.production[i]) for i in list(Upward_set)],
    "pmax_pu": [MaxQ[i] for i in list(Upward_set)],
    "pmin_pu":[MinQ[i] for i in list(Upward_set)],
    "PU_euro/MWh" : [PU[i] for i in Upward_set]
})

Qreact_df = DataFrame({
    "Bus": list(Upward_set),
    "q_pu": [value(model.q[i]) for i in list(Upward_set)],
    "qmax_pu": [Qmax[i] for i in list(Upward_set)],
    "qmin_pu":[Qmin[i] for i in list(Upward_set)]
})

# # Results for Power Injections
PowerInjection_df = DataFrame({
    "Bus":  buses,
    "q_injection_pu" : [value(model.reactive_power_k[i]) for i in buses],
    "p_injection_pu" : [value(model.active_power_k[i]) for i in buses]
    
})

# # Results for Prices
price_df = DataFrame({
    "Bus":  buses,
    "nodal_price_euro/MWh": [model.dual[model.active_power_injection[i]] for i in buses]
})

# # Results for Flows     
from_bus = Edges["from_bus"].tolist()
to_bus = Edges["to_bus"].tolist()

flows_df = DataFrame({
    "Edge": [i + 1 for i in edges_index],
    "from_bus": [from_bus[i] for i in range(len(Edges))],
    "flows_to": [to_bus[i] for i in range(len(Edges))],
    "Flow_p_pu": [value(model.f[i]) for i in range(len(Edges))],
    "Flow_q_pu": [value(model.fq[i]) for i in range(len(Edges))],
    "Flowmax_pu": [Flowmax_edge_dict[i] for i in range(len(Edges))]
})


# # # Print the results
print("")
print("Voltage magnitudes [p.u.] and Voltage angles [°]:")
print(results_df)
print("")
print("Active power production [p.u.]:")
print(prod_df)
print("")
print("Reactive power production [p.u.]:")
print(Qreact_df)
print("")
print("Nodal prices [€/MWh]:")
print(price_df)
print("")
print("Active and Reactive power flows for lines [p.u.]:")
print(flows_df)
print("")
print("Active and reactive power injections [p.u.]:")
print(PowerInjection_df)
print("")

print("Termination Status:", results.solver.termination_condition)

writer = pd.ExcelWriter(excel_directory + "Bolognani_results_case_ieee123.xlsx", engine='xlsxwriter')

# results_df.to_excel(writer, sheet_name="results", index=False)
# prod_df.to_excel(writer, sheet_name="production", index=False)
# Qreact_df.to_excel(writer,sheet_name="reactive")
# price_df.to_excel(writer, sheet_name="price", index=False)
# flows_df.to_excel(writer, sheet_name="flows", index=False)

results_df.to_excel(writer, sheet_name="results", index=False)
prod_df.to_excel(writer, sheet_name="production", index=False)
Qreact_df.to_excel(writer,sheet_name="reactive")
price_df.to_excel(writer, sheet_name="price", index=False)
flows_df.to_excel(writer, sheet_name="flows", index=False)

writer.close()
