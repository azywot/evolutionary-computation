include("./parse_data.jl")
include("./methods/all_methods.jl")

const N = 200 # number of nodes
distance_matrix, cost_vector, coords = read_data("data/TSPA.csv")

solution_random = random_solution(N, 1)
evaluate_solution(solution_random, distance_matrix, cost_vector)

solution_nn = nn_solution(N, 1, distance_matrix, cost_vector)
evaluate_solution(solution_nn, distance_matrix, cost_vector)

# total_value, cycle = greedy_cycle(1, distance_matrix, cost_vector)
# add cost and x,y later from original df (for plotting)