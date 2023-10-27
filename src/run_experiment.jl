include("./parse_data.jl")
include("./methods/all_methods.jl")
include("./generate_solutions.jl")
include("./plots/solution_graph.jl")


# =================================================================
# PERFORM EXPERIMENTS FOR ALL PROBLEMS: 
# for letter in ["A", "B", "C", "D"]
#     filename = "data/TSP$letter.csv"
#     distance_matrix, cost_vector, coords = read_data(filename)
#     for method in [greedy_2regret, greedy_2regret_heuristics]#[random_solution, nn_solution, greedy_cycle]
#         evaluate_statistics(distance_matrix, cost_vector, coords, method, 200, filename)
#         generate_solution_graph(
#             "results/$method/TSP$letter" * "_best.csv",
#             coords,
#             cost_vector,
#             "$method",
#         )
#     end
# end


#  ======================= LOCAL SEARCH =======================
distance_matrix, cost_vector, coords = read_data("data/TSPX.csv", true)
instance_sol1 = [1, 2, 7, 4, 5, 6, 3, 8, 9] # node mode - działa
instance_sol2 = [1, 2, 6, 5, 4, 3, 7, 8, 9] # edge mode - działa
instance_sol3 = [1, 2, 3, 4, 5, 6, 7, 8, 9] # optimal solution with cost 36
instance_sol4 = [1, 3, 2, 4]

lg_solution, lg_cost =
    local_greedy_search(instance_sol4, distance_matrix, cost_vector, "edge")
lg_evaluated = evaluate_solution(lg_solution, distance_matrix, cost_vector)
println("Local steepest cost calculated: ", lg_cost)
println("Local steepest cost evaluated: ", lg_evaluated)

dir_path = "results/local_steepest_search"

best_solution_file_path = joinpath(dir_path, "TSPX_" * "best.csv")
CSV.write(
    best_solution_file_path,
    DataFrame(
        x = [coords[i][1] for i in lg_solution],
        y = [coords[i][2] for i in lg_solution],
        cost = [cost_vector[i] for i in lg_solution],
    ),
)

generate_solution_graph(
    "results/local_steepest_search/TSPX_best.csv",
    coords,
    cost_vector,
    "local_steepest_search",
)

#########################

for letter in ["A", "B", "C", "D"]
    filename = "data/TSP$letter.csv"
    distance_matrix, cost_vector, coords = read_data(filename)
    for start_method in [random_solution, greedy_2regret_heuristics]
        for mode in ["edge", "node"]
            for method in [local_steepest_search, local_greedy_search]
                println(
                    "Run parameters: TSP" *
                    "$letter" *
                    " " *
                    "$method" *
                    " " *
                    "$start_method" *
                    " " *
                    "$mode",
                )
                evaluate_local_search(
                    distance_matrix,
                    cost_vector,
                    coords,
                    method,
                    start_method,
                    mode,
                    200,
                    filename,
                )
                generate_solution_graph(
                    "results/$method/TSP$letter" *
                    "_" *
                    "$start_method" *
                    "_" *
                    "$mode" *
                    "_best.csv",
                    coords,
                    cost_vector,
                    "$method",
                )
            end
        end
    end
end
