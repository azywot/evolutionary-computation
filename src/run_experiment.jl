include("./parse_data.jl")
include("./methods/all_methods.jl")
include("./generate_solutions.jl")
include("./plots/solution_graph.jl")

# =================================================================
# GENERATE AND EVALUATE A SOLUTION:
# filename = "data/TSPA.csv"
# distance_matrix, cost_vector, coords = read_data(filename)
# N = 200
# solution_random = random_solution(N, 1, distance_matrix, cost_vector)
# evaluate_solution(solution_random, distance_matrix, cost_vector)

# solution_nn = nn_solution(N, 1, distance_matrix, cost_vector)
# evaluate_solution(solution_nn, distance_matrix, cost_vector)

# solution_greedy = greedy_cycle(N, 1, distance_matrix, cost_vector)
# evaluate_solution(solution_greedy, distance_matrix, cost_vector)

# =================================================================
# PERFORM EXPERIMENTS FOR ALL PROBLEMS: 
for letter in ["A", "B", "C", "D"]
    filename = "data/TSP$letter.csv"
    distance_matrix, cost_vector, coords = read_data(filename)
    for method in [greedy_2regret, greedy_2regret_heuristics]#[random_solution, nn_solution, greedy_cycle]
        evaluate_statistics(distance_matrix, cost_vector, coords, method, 200, filename)
        generate_solution_graph(
            "results/$method/TSP$letter" * "_best.csv",
            coords,
            cost_vector,
            "$method",
        )
    end
end



# TODO: create a small instance
distance_matrix, cost_vector, coords = read_data("data/TSPA.csv")
local_greedy_search(100, random_solution(200, 1, distance_matrix, cost_vector), distance_matrix, cost_vector, "node")