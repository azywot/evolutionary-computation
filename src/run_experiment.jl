include("./parse_data.jl")
include("./methods/all_methods.jl")

const N = 200 # number of nodes
distance_matrix, cost_vector, coords = read_data("data/TSPA.csv")
# total_value, cycle = greedy_cycle(1, distance_matrix, cost_vector)


solution = random_solution(N, 1)
evaluate_solution(solution, distance_matrix, cost_vector)
# add cost and x,y later from original df (for plotting)
