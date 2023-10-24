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



# TODO: there's a bug in the local search
distance_matrix, cost_vector, coords = read_data("data/TSPX.csv", true)
instance_sol = [1, 2, 7, 4, 5, 6, 3, 8, 9]
instance_sol2 = [1, 2, 3, 4, 5, 6, 7, 8, 9] # optimal solution with cost 36

lg_solution, lg_cost = local_steepest_search(10, instance_sol2, distance_matrix, cost_vector, "node")
lg_evaluated = evaluate_solution(lg_solution, distance_matrix, cost_vector)
println("Local greedy cost calculated: ", lg_cost)
println("Local greedy cost evaluated: ", lg_evaluated)

# now's ugly
dir_path = "results/local_greedy_search"
if !isdir(dir_path)
    mkpath(dir_path)
end

best_solution_file_path = joinpath(dir_path, "TSPA_" * "best.csv")
CSV.write(
    best_solution_file_path,
    DataFrame(
        x = [coords[i][1] for i in lg_solution],
        y = [coords[i][2] for i in lg_solution],
        cost = [cost_vector[i] for i in lg_solution],
    ),
)


generate_solution_graph(
    "results/local_greedy_search/TSPA_best.csv",
    coords,
    cost_vector,
    "local_greedy_search",
)