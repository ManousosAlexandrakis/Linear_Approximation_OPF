from pyomo.environ import *
import pandas as pd
import numpy as np
from pandas import DataFrame
from math import degrees as rad2deg 
import math
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

buses = bus_data["bus"].tolist()
edges_index = Edges.index.tolist()

# # Sbase of the system
Ssystem = 1

# Total number of buses and edges
n = len(buses)
Edges_leng =  len(Edges)

bus_id_to_index = {buses[i]: i for i in range(len(buses)-1)}
bus_id_to_index[slack_bus] = buses.index(slack_bus)

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


    
# # Create dictionaries to store PU, MinQ and MaxQ parameters for upward generators
PU = {Upward_data["Bus"].iloc[i] : Upward_data["PU"].iloc[i] for i in range(len(Upward_data))}
# Minimum and Maximum active power for generators
MinQ = {Upward_data["Bus"].iloc[i] : Upward_data["MinQ"].iloc[i]/Ssystem for i in range(len(Upward_data))}
MaxQ = {Upward_data["Bus"].iloc[i] : Upward_data["MaxQ"].iloc[i]/Ssystem for i in range(len(Upward_data))}
# Minimum and Maximum reactive power for generators
Qmin = {sgen_data["bus"].iloc[i] : sgen_data["QRmin"].iloc[i]/Ssystem for i in range(len(sgen_data))}
Qmax = {sgen_data["bus"].iloc[i] : sgen_data["QRmax"].iloc[i]/Ssystem for i in range(len(sgen_data))}

Upward_set = set(Upward_data["Bus"])

Flowmax_edge_dict = dict()
for i in range(len(Edges)):
    index = Edges["idx"].iloc[i] - 1
    Flowmax_edge_dict[i] = Edges["FlowMax"].iloc[index]



# # Create Y matrix
y = np.zeros((n,n), dtype=complex)


for i in range(len(Edges)):
    From_bus = bus_id_to_index[Edges["from_bus"].iloc[i]]
    To_bus = bus_id_to_index[Edges["to_bus"].iloc[i]]
    r = Edges["R_pu"].iloc[i]
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

#print("Y matrix:", Y)

G = Y.real
B = Y.imag


# Create dictionaries for active and reactive load (negative values)
total_pgen_pload = {bus_id_to_index[load_data["bus"].iloc[i]]:-load_data["p_mw"].iloc[i] for i in range(len(load_data))}
total_qgen_qload = {bus_id_to_index[load_data["bus"].iloc[i]]:-load_data["q_mvar"].iloc[i] for i in range(len(load_data))}


####################################################################                                 ####################################################################
#################################################################### Mathematical optimization model ####################################################################
####################################################################                                 ####################################################################

# # Model
model = ConcreteModel(name="AC-OPF")

# # Variables
model.u = Var(buses, within=Reals)
model.delta = Var(buses,within=Reals)
model.q = Var(Upward_set, within=Reals)
model.production = Var(Upward_set,within=Reals)

model.generation_cost = Var()

### Constraints for the optimization problem

def reactive_power_production_upper_limit(model,k):
    return model.q[k] <= Qmax[k]
model.reactive_power_production_upper_limit = Constraint(Upward_set,rule=reactive_power_production_upper_limit)
# for key in model.reactive_power_production_upper_limit:
#     print(f"Constraint {key}: {model.reactive_power_production_upper_limit[key].expr}")


def reactive_power_production_lower_limit(model,k):
    return model.q[k] >= Qmin[k]
model.reactive_power_production_lower_limit = Constraint(Upward_set,rule=reactive_power_production_lower_limit)
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
model.voltage_magnitude_upper_limit = Constraint(buses,rule=voltage_magnitude_upper_limit)

def voltage_magnitude_lower_limit(model,k):
    return model.u[k] >= 0.8
model.voltage_magnitude_lower_limit = Constraint(buses,rule=voltage_magnitude_lower_limit)











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

    
# from_bus = Edges["from_bus"].tolist()
# to_bus = Edges["to_bus"].tolist()
# Sn = Edges["FlowMax"].tolist()


# Global dictionaries
g_from_dict = {}
b_from_dict = {}
Sn_dict = {}

# Fill dictionaries from Edges
for _, n in Edges.iterrows():
    from_bus = n['from_bus']
    to_bus = n['to_bus']
    
    i = bus_id_to_index[from_bus]
    j = bus_id_to_index[to_bus]
    
    y_ij = y[i, j]  # complex admittance

    # Store real and imaginary parts (conductance and susceptance)
    g_from_dict[(from_bus, to_bus)] = y_ij.real
    b_from_dict[(from_bus, to_bus)] = y_ij.imag
    Sn_dict[(from_bus, to_bus)] = n['FlowMax']

# Define the constraint rule
def flows_constraint_1(model, i, j):
    i_idx = i
    j_idx = j
    
    g = g_from_dict[(i, j)]
    b = b_from_dict[(i, j)]
    Sn = Sn_dict[(i, j)]

    term1 = (model.u[i_idx]**2 - model.u[i_idx] * model.u[j_idx] * cos(model.delta[i_idx] - model.delta[j_idx]))**2
    term2 = (model.u[i_idx] * model.u[j_idx] * sin(model.delta[i_idx] - model.delta[j_idx]))**2

    return term1 + term2 <= Sn**2 / (g**2 + b**2)

# Create the list of (from_bus, to_bus) pairs
flow_edges = list(g_from_dict.keys())

# Add the constraint to the model
model.flows_constraint_1 = Constraint(
    flow_edges, 
    rule=flows_constraint_1
)
# Print the constraints
# for key in model.flows_constraint_1:
#     print(f"Constraint {key}: {model.flows_constraint_1[key].expr}")
    

# # Power Flow equation
# def power_flow_equation(model,k,m):
#     return total_pgen_pload[bus_id_to_index[k]] + sum(model.production[i] for i in Upward_set if i == k) == model.u[k]**2 * G[bus_id_to_index[k],bus_id_to_index[k]] - model.u[k]*sum(model.u[m] * (-G[bus_id_to_index[k],bus_id_to_index[k]] * cos(model.delta[k] - model.delta[m])
#     - B[bus_id_to_index[k], bus_id_to_index[m]] * sin(model.delta[k] - model.delta[m])))

# connected_bus_pairs = [(k, m) for k in buses for m in connected_buses_dict[k]]
# model.power_flow_equation = Constraint(connected_bus_pairs,rule=power_flow_equation)


# Power flow equation (active power balance) using bus IDs directly
def power_flow_equation(model, k):
    # Left-hand side: total generation - load
    lhs = total_pgen_pload[bus_id_to_index[k]] + sum(
        model.production[i] for i in Upward_set if i == k
    )

    # Diagonal admittance contribution
    diag_term = model.u[k] ** 2 * G[bus_id_to_index[k], bus_id_to_index[k]]

    # Sum over neighboring buses
    interaction = sum(
        model.u[k] * model.u[m] * (
            -G[bus_id_to_index[k], bus_id_to_index[m]] * cos(model.delta[k] - model.delta[m])
            - B[bus_id_to_index[k], bus_id_to_index[m]] * sin(model.delta[k] - model.delta[m])
        )
        for m in connected_buses_dict[k]
    )

    return lhs == diag_term - interaction

# Register the constraint for all buses
model.power_flow_equation = Constraint(buses, rule=power_flow_equation)
for k in model.power_flow_equation:
    print(f"Constraint at bus {k}:")
    print(model.power_flow_equation[k].expr)
    print()
    
    
    
# Define the nonlinear constraints
def reactive_power_upper_rule(model, k):
    idx_k = bus_id_to_index[k]
    term1 = model.u[k]**2 * B[idx_k, idx_k]
    term2 = model.u[k] * sum(
        model.u[m] * (-G[idx_k, bus_id_to_index[m]] * sin(model.delta[k] - model.delta[m])
                     + B[idx_k, bus_id_to_index[m]] * cos(model.delta[k] - model.delta[m]))
        for m in connected_buses_dict[k]
    )
    term3 = sum(model.q[i] for i in Upward_set if i == k)
    term4 = total_qgen_qload[idx_k]
    return term1 + term2 + term3 + term4 <= 1e-3

def reactive_power_lower_rule(model, k):
    idx_k = bus_id_to_index[k]
    term1 = model.u[k]**2 * B[idx_k, idx_k]
    term2 = model.u[k] * sum(
        model.u[m] * (-G[idx_k, bus_id_to_index[m]] * sin(model.delta[k] - model.delta[m])
                     + B[idx_k, bus_id_to_index[m]] * cos(model.delta[k] - model.delta[m]))
        for m in connected_buses_dict[k]
    )
    term3 = sum(model.q[i] for i in Upward_set if i == k)
    term4 = total_qgen_qload[idx_k]
    return term1 + term2 + term3 + term4 >= -1e-3

# Add constraints to model
model.reactive_power_upper = Constraint(buses, rule=reactive_power_upper_rule)
model.reactive_power_lower = Constraint(buses, rule=reactive_power_lower_rule)

for k in buses:
    print(f"Reactive power upper constraint at node {k}:")
    print(model.reactive_power_upper[k].expr)
    print()

    print(f"Reactive power lower constraint at node {k}:")
    print(model.reactive_power_lower[k].expr)
    print()


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
solver = SolverFactory("ipopt")

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


# # Results for Prices
price_df = DataFrame({
    "Bus":  buses,
    "nodal_price_euro/MWh": [model.dual[model.power_flow_equation[i]] for i in buses]
})

# # Results for Flows     
import cmath

flow_from = []
flow_to = []
flow_reactive_from = []
flow_reactive_to = []

Vfrom_list = []
Vto_list = []

for _, row in Edges.iterrows():
    from_bus = row['from_bus']
    to_bus = row['to_bus']

    i = bus_id_to_index[from_bus]
    j = bus_id_to_index[to_bus]

    # Extract voltage magnitude and angle from solution
    u_i = value(model.u[from_bus])
    u_j = value(model.u[to_bus])
    delta_i = value(model.delta[from_bus])
    delta_j = value(model.delta[to_bus])

    # Construct complex voltages using Euler's formula
    Vfrom = u_i * cmath.rect(1, delta_i)  # rect(r, phi) = r * (cos(phi) + j sin(phi))
    Vto = u_j * cmath.rect(1, delta_j)

    # Get line admittance
    Y_ij = y[i, j]

    # Compute current and power flows
    I = (Vfrom - Vto) * Y_ij
    S_from = Vfrom * I.conjugate()
    S_to = Vto * (-I).conjugate()

    # Store flows
    flow_from.append(S_from.real)
    flow_to.append(S_to.real)
    flow_reactive_from.append(S_from.imag)
    flow_reactive_to.append(S_to.imag)

    Vfrom_list.append(Vfrom)
    Vto_list.append(Vto)
    
from_bus = Edges["from_bus"].tolist()
to_bus = Edges["to_bus"].tolist()

flows_df = DataFrame({
    "Edge": [i + 1 for i in edges_index],
    "from_bus": [from_bus[i] for i in range(len(Edges))],
    "flows_to": [to_bus[i] for i in range(len(Edges))],
    "Flows_p_pu_from": [flow_from[i] for i in range(len(Edges))],
    "Flows_p_pu_to": [flow_to[i] for i in range(len(Edges))],
    "Flows_q_pu_from": [flow_reactive_from[i] for i in range(len(Edges))],
    "Flows_q_pu_to": [flow_reactive_to[i] for i in range(len(Edges))],
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


print("Termination Status:", results.solver.termination_condition)
