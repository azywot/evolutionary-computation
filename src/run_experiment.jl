include("./parse_data.jl")
include("./methods/all_methods.jl")
include("./generate_solutions.jl")
include("./plots/solution_graph.jl")

# =================================================================
# GENERATE AND EVALUATE A SOLUTION:
filename = "data/TSPA.csv"
distance_matrix, cost_vector, coords = read_data(filename)
N = 200
solution_random = random_solution(N, 1, distance_matrix, cost_vector)
evaluate_solution(solution_random, distance_matrix, cost_vector)

solution_nn = nn_solution(N, 1, distance_matrix, cost_vector)
evaluate_solution(solution_nn, distance_matrix, cost_vector)

solution_greedy = greedy_cycle(N, 1, distance_matrix, cost_vector)
evaluate_solution(solution_greedy, distance_matrix, cost_vector)

# =================================================================
# PERFORM EXPERIMENTS:
FILE = "data/TSPA.csv"
evaluate_statistics(FILE, random_solution, 200)
evaluate_statistics(FILE, nn_solution, 200)
evaluate_statistics(FILE, greedy_cycle, 200)

# =================================================================
# PLOT SOLUTIONS:
generate_solution_graph("results/TSPA_random_solution_best.csv")
generate_solution_graph("results/TSPA_nn_solution_best.csv")
generate_solution_graph("results/TSPA_greedy_cycle_solution_best.csv")

# =================================================================
# PERFORM EXPERIMENTS FOR ALL PROBLEMS: 
#  -> delete all of the above stuffas it performs everything that's necessary
for letter in ["A", "B", "C", "D"]
    filename = "data/TSP$letter.csv"
    distance_matrix, cost_vector, coords = read_data(filename)
    for method in [random_solution, nn_solution, greedy_cycle]
        evaluate_statistics(filename, method, 200)
        generate_solution_graph("results/TSP$letter" * "_" * "$method" * "_best.csv")
    end
end
