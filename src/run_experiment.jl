include("./parse_data.jl")
include("./methods/all_methods.jl")
include("./generate_solutions.jl")

const N = 200 # number of nodes; NOTE: I'd change it to local since it's passed/read from the shape anyway
filename = "data/TSPA.csv"
distance_matrix, cost_vector, coords = read_data(filename)

solution_random = random_solution(N, 1, distance_matrix)
evaluate_solution(solution_random, distance_matrix, cost_vector)

solution_nn = nn_solution(N, 1, distance_matrix)
evaluate_solution(solution_nn, distance_matrix, cost_vector)

# total_value, cycle = greedy_cycle(1, distance_matrix, cost_vector)
# add cost and x,y later from original df (for plotting)

# =================================================================
# PERFORM EXPERIMENTS:
FILE = "data/TSPA.csv"
evaluate_statistics(FILE, random_solution, 200)
evaluate_statistics(FILE, nn_solution, 200)
# evaluate_statistics(filename, greedy_cycle, 200) TODO