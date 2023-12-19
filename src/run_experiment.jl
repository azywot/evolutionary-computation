include("./parse_data.jl")
include("./methods/all_methods.jl")
include("./generate_solutions.jl")
include("./plots/solution_graph.jl")
include("./utils/similarity_tests.jl")


# =================================================================
# PERFORM EXPERIMENTS FOR ALL PROBLEMS: 
for letter in ["A", "B", "C", "D"]
    filename = "data/TSP$letter.csv"
    distance_matrix, cost_vector, coords = read_data(filename)
    for method in [greedy_cycle]
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
distance_matrix, cost_vector, coords = read_data("data/TSPX.csv", true)
instance_sol1 = [1, 2, 7, 4, 5, 6, 3, 8, 9]
instance_sol2 = [1, 2, 6, 5, 4, 3, 7, 8, 9]
instance_sol3 = [1, 2, 3, 4, 5, 6, 7, 8, 9]
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
include("./methods/all_methods.jl")
for letter in ["A"]#, "B", "C", "D"]
    filename = "data/TSP$letter.csv"
    distance_matrix, cost_vector, coords = read_data(filename)
    for start_method in [random_solution]#, "greedy_cycle"]
        for mode in ["edge"]#, "node"]
            for method in [local_search_previous_deltas]#, local_steepest_search, local_greedy_search]
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
                    1,#200,
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


#  ========== Multiple start local search (MSLS) and iterated local search (ILS) =========
include("./methods/all_methods.jl")
include("./generate_solutions.jl")
MSLS_ITERATIONS = 200
METHODS_ITERATIONS = 20

for letter in ["A", "B", "C", "D"]
    filename = "data/TSP$letter.csv"
    distance_matrix, cost_vector, coords = read_data(filename)
    println("Problem instance: TSP" * "$letter")
    evaluate_msls_ils(distance_matrix, 
                        cost_vector, 
                        coords, 
                        MSLS_ITERATIONS, 
                        METHODS_ITERATIONS, 
                        filename, 
                        true) # verbose

    for method in ["msls", "ils"]
        generate_solution_graph(
            "results/$method/TSP$letter" * "_best.csv",
            coords,
            cost_vector,
            "$method",
            "TSP$letter" * " " * "$method best",
        )
    end
end



#  ======================= LARGE SCALE NBHD SEARCH =======================
include("./methods/all_methods.jl")
include("./generate_solutions.jl")
# time_limits = Dict(
#     "A" => 183.3111,
#     "B" => 174.6152,
#     "C" => 172.8097,
#     "D" => 170.8673,
# )
# ITERATIONS = 20

time_limits = Dict(
    "A" => 2,
    "B" => 2,
    "C" => 2,
    "D" => 2,
)
ITERATIONS = 2

config = Dict(
    # "time_limit" => nothing, # to be set
    # "method_name" => nothing, # to be set
    # "use_local_search" => nothing, # to be set
    "destroy_rate" => 0.25,
    "mode" => "edge",
    "tournament_size" => 5,
    "columns" => ["mean", "min", "max", "iter_mean", "iter_min", "iter_max"]
)

for letter in ["A", "B", "C", "D"]

    filename = "data/TSP$letter.csv"
    distance_matrix, cost_vector, coords = read_data(filename)
    config["time_limit"] = time_limits[letter]

    for (method_name, use_local_search) in zip(["large_scale_nbhd_search", "large_scale_nbhd_search_ls"], [false, true])        
        
        d_rate = replace(string(config["destroy_rate"]), "." => "_")
        config["method_name"] = method_name * "_$d_rate"
        config["use_local_search"] = use_local_search
        
        println(
                "Run parameters: TSP" *
                "$letter" *
                " " *
                config["method_name"] *
                ", time limit: " * 
                string(config["time_limit"]))
        evaluate_statistics(
                    distance_matrix, 
                    cost_vector, 
                    coords, 
                    large_scale_neighbourhood_search, 
                    ITERATIONS, 
                    filename,
                    config
                )
        generate_solution_graph(
            "results/"*config["method_name"]*"/TSP$letter" * "_best.csv",
            coords,
            cost_vector,
            config["method_name"]*" (k = "*string(config["tournament_size"])*")", # k = tournament size
        )
    end
end

#  ======================= SIMILARITY TESTS =======================
include("./utils/similarity_tests.jl")
include("./plots/solution_graph.jl")
# ex1 = [1, 2, 3, 4]
# ex2 = [1, 4, 3, 5]
# edges, nodes = calculate_solution_similarity(ex1, ex2)

dir_path = "results/similarity_tests"
if !isdir(dir_path)
    mkpath(dir_path)
end

ITERATIONS = 1000
best_solution_path = "results/ils_0_1/"

for letter in ["A", "B", "C", "D"]
    filename = "data/TSP$letter.csv"
    distance_matrix, cost_vector, coords = read_data(filename)

    # read best solution from file (add 1 to each node index to match Julia's 1-indexing)
    best_solution_content = read(best_solution_path * "TSP$letter" * "_best_nodes.txt", String)
    best_solution = parse.(Int, split(best_solution_content))
    best_solution .+= 1
    # r_sol = random_solution(length(cost_vector))
    # best_solution = local_greedy_search(r_sol, distance_matrix, cost_vector)

    solution_df = perform_similarity_tests(ITERATIONS, distance_matrix, cost_vector, best_solution)
    CSV.write(
        joinpath(dir_path, "TSP$letter" * "_similarity_tests.csv"),
        solution_df
    )
    generate_similarity_test_charts(dir_path * "/TSP$letter" * "_similarity_tests.csv", "TSP$letter")
end


#  ======================= HYBRID EA =======================
include("./methods/all_methods.jl")
include("./generate_solutions.jl")
# time_limits = Dict(
#     "A" => 183.3111,
#     "B" => 174.6152,
#     "C" => 172.8097,
#     "D" => 170.8673,
# )
# ITERATIONS = 20

time_limits = Dict(
    "A" => 2,
    "B" => 2,
    "C" => 2,
    "D" => 2,
)
ITERATIONS = 1

config = Dict(
    # "time_limit" => nothing, # to be set
    # "method_name" => nothing, # to be set
    # "recombine" => nothing, # to be set
    # "use_local_search" => nothing, # to be set
    "population_size" => 20,
    "max_patience" => 10,
    "perturbation_rate" => 0.1,
    "mode" => "edge",
    "columns" => ["mean", "min", "max", "iter_mean", "iter_min", "iter_max"]
)

for letter in ["A"]#, "B", "C", "D"]

    filename = "data/TSP$letter.csv"
    distance_matrix, cost_vector, coords = read_data(filename)
    config["time_limit"] = time_limits[letter]

    for (recombine, use_local_search) in 
        zip([recombine_operation1, recombine_operation2, recombine_operation2, recombine_operation3, recombine_operation3],
            [true, false, true, false, true])   
        
        if use_local_search
            config["method_name"] = "hea" * "_$recombine" * "_ls"
        else
            config["method_name"] = "hea" * "_$recombine"
        end
        config["recombine"] = recombine
        config["use_local_search"] = use_local_search
        
        println(
                "Run parameters: TSP" *
                "$letter" *
                " " *
                config["method_name"] *
                ", time limit: " * 
                string(config["time_limit"]))
        evaluate_statistics(
                    distance_matrix, 
                    cost_vector, 
                    coords, 
                    hybrid_evolutionary_algorithm, 
                    ITERATIONS, 
                    filename,
                    config
                )
        generate_solution_graph(
            "results/"*config["method_name"]*"/TSP$letter" * "_best.csv",
            coords,
            cost_vector,
            config["method_name"],
        )
    end
end

