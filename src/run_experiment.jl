include("./prepare_data.jl")
include("./greedy_cycle.jl")


const N = 200 # number of nodes
distance_matrix, cost_vector, coords = read_data("data/TSPA.csv")
total_value, cycle = greedy_cycle(1, distance_matrix, cost_vector)
# add cost and x,y later from original df (for plotting)
