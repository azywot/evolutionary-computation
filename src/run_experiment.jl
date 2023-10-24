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


#  ======================= LOCAL SEARCH =======================
# MOCK EXAMPLE FROM THE SLIDES
# TODO: ensure it's good (especially the indices part)
distance_matrix, cost_vector, coords = read_data("data/TSPX.csv", true)
instance_sol1 = [1, 2, 7, 4, 5, 6, 3, 8, 9] # node mode - działa
instance_sol2 = [1, 2, 6, 5, 4, 3, 7, 8, 9] # edge mode - działa
instance_sol3 = [1, 2, 3, 4, 5, 6, 7, 8, 9] # optimal solution with cost 36


lg_solution, lg_cost = local_steepest_search(100, instance_sol2, distance_matrix, cost_vector, "edge")
lg_evaluated = evaluate_solution(lg_solution, distance_matrix, cost_vector)
println("Local steepest cost calculated: ", lg_cost)
println("Local steepest cost evaluated: ", lg_evaluated)

# NOTE: ik this part's ugly
dir_path = "results/local_steepest_search"
if !isdir(dir_path)
    mkpath(dir_path)
end

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



# REAL EXAMPLE - TSPA
# NOTE: sth's wrong with delta calculation 
# - I am wondering whether its's because of selecting half of the solution and possibly 
# some mess in the inter route move, especially indices, modulo 
# - I left the comments I found useful along the way - maybe they would come handy too,
# otherwise feel free to delete them 🫡👍
# - I suggest commenting out parts in local_steepest to investigate the routes separately, with different modes etc.
# - Will look at this one back in a few days 🙏
# - you can delete this comment too, I just wanted to leave some notes haha

distance_matrix, cost_vector, coords = read_data("data/TSPA.csv", true)
# random_sol = random_solution(200, 1, distance_matrix, cost_vector)

lg_solution, lg_cost = local_steepest_search(100, random_sol, distance_matrix, cost_vector, "edge")
lg_evaluated = evaluate_solution(lg_solution, distance_matrix, cost_vector)
println("Local steepest cost calculated: ", lg_cost)
println("Local greedy cost evaluated: ", lg_evaluated)

# NOTE: ik this part's ugly
dir_path = "results/local_steepest_search"
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
    "results/local_steepest_search/TSPA_best.csv",
    coords,
    cost_vector,
    "local_steepest_search",
)