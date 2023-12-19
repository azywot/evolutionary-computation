using Random
using StatsBase

include("./random.jl")
include("./local_greedy_search.jl")
include("./msls_ils.jl")

# Generate an initial population X 
# repeat 
# Draw at random two different solutions (parents) using uniform distribution 
# Construct an offspring solution by recombining parents 
# y := Local search (y) 
# if y is better than the worst solution in the population and (sufficiently) different from all 
# solutions in the population 
# Add y to the population and remove the worst solution 
# until the stopping conditions are met 


"""
Find longest common subarrays (common parts of graphs)
- `arr1::Vector{Int}`: vector of node ids
- `arr2::Vector{Int}`: vector of node ids
returns: list of common subarrays
"""
function find_longest_common_subarrays(arr1, arr2)
    common_subarrays = []
    used_elements = []
    # Generate all subarrays of length >= 2 for arr1
    subarrays_arr1 = [arr1[i:j] for i = 1:length(arr1) for j = length(arr1):-1:i+1]
    subarrays_arr1 = sort(subarrays_arr1, lt = (x, y) -> length(x) > length(y))

    for subarray in subarrays_arr1
        if length(intersect(subarray, arr2)) == length(subarray) &&
           isempty(intersect(subarray, used_elements))
            longest_common_subarray = subarray
            push!(common_subarrays, longest_common_subarray)
            used_elements = vcat(used_elements, longest_common_subarray)
        end
    end
    return common_subarrays
end


"""
Pop random node from given list (return and remove)
- `node_list::Vector{Int}`: vector of node ids
returns: popped node
"""
function pop_random_node(node_list)
    random_index = rand(1:length(node_list))
    random_node = splice!(node_list, random_index)
    return random_node
end


"""
Operator 1. We locate in the offspring all common nodes and edges and fill the rest of the
solution at random
- `parent1::Vector{Int}`: vector of node ids
- `parent2::Vector{Int}`: vector of node ids
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of node
- `N::Int`: number of all nodes
returns: child solution
"""
function recombine_operation1(parent1, parent2, distance_matrix, cost_vector, N)
    n = length(parent1)
    child = zeros(Int, n)
    common_edges = find_longest_common_subarrays(parent1, parent2)
    common_edges = collect(Iterators.flatten(common_edges))
    nodes_to_add = collect(setdiff(Set(1:N), Set(common_edges)))
    for i = 1:n
        if parent1[i] in common_edges
            child[i] = parent1[i]
        else
            child[i] = pop_random_node(nodes_to_add)
        end
    end
    return child
end


"""
Operator 2. We choose one of the parents as the starting solution. We remove from this
solution all edges and nodes that are not present in the other parent. The solution is
repaired using the heuristic method in the same way as in the LNS method. We also test the
version of the algorithm without local search after recombination (we still use local search
for the initial population).
- `parent1::Vector{Int}`: vector of node ids
- `parent2::Vector{Int}`: vector of node ids
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of node
- `N::Int`: number of all nodes
returns: child solution
"""
function recombine_operation2(parent1, parent2, distance_matrix, cost_vector, N)
    common_edges = find_longest_common_subarrays(parent1, parent2)
    common_edges = collect(Iterators.flatten(common_edges))
    nodes_to_delete = collect(setdiff(Set(1:N), Set(common_edges)))
    child_destroyed = collect(filter(x -> !(x in nodes_to_delete), parent1)) # preserve the order of nodes
    child_repaired = greedy_cycle(N, nothing, distance_matrix, cost_vector, child_destroyed)
    return child_repaired
end


"""
Take all intersecting nodes + repair
- `parent1::Vector{Int}`: vector of node ids
- `parent2::Vector{Int}`: vector of node ids
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of node
- `N::Int`: number of all nodes
returns: child solution
"""
function recombine_operation3(parent1, parent2, distance_matrix, cost_vector, N)
    child_destroyed = collect(intersect(parent1, parent2))
    child_repaired = greedy_cycle(N, nothing, distance_matrix, cost_vector, child_destroyed)
    return child_repaired
end


"""
Generate a hybrid evolutionary algorithm solution given a starting solution and a mode.
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of node
- `config::Dict`: configuration dictionary with keys:
    - `time_limit::Int`: time limit in seconds
    - `recombine::Function`: recombination function
    - `population_size::Int`: size of the initial population
    - `use_local_search::Bool`: whether to use local search
    - `max_patience::Int`: maximum number of iterations without improvement
    - `perturbation_rate::Float64`: perturbation rate
    - `mode::String`: mode of the local search, either "node" or "edge"

returns: a hybrid evolutionary algorithm solution and number of iterations
"""
function hybrid_evolutionary_algorithm(
    solution, # to be compatible with the test setup
    distance_matrix,
    cost_vector,
    config,
)
    N, _ = size(distance_matrix)
    distance_matrix = deepcopy(distance_matrix)
    cost_vector = deepcopy(cost_vector)

    population = [] # List of tuples (cost, solution)
    start_time = time()

    for i = 1:config["population_size"]
        solution = local_steepest_search(
            random_solution(N),
            distance_matrix,
            cost_vector,
            config["mode"],
        )
        solution_cost = evaluate_solution(solution, distance_matrix, cost_vector)
        push!(population, (solution_cost, solution))
    end

    worst_solution = maximum(population)
    iteration_counter = 0
    patience = 0

    while time() - start_time < config["time_limit"]
        parents = sample(population, 2, replace = false)
        offspring = config["recombine"](
            parents[1][2],
            parents[2][2],
            distance_matrix,
            cost_vector,
            N,
        )

        if config["recombine"] == recombine_operation1 || config["use_local_search"]
            offspring = local_steepest_search(
                offspring,
                distance_matrix,
                cost_vector,
                config["mode"],
            )
        end

        offspring_cost = evaluate_solution(offspring, distance_matrix, cost_vector)
        offspring_tuple = (offspring_cost, offspring)

        # making sure there are no copies
        if !(offspring_tuple in population) && offspring_cost < worst_solution[1]
            push!(population, offspring_tuple)
            deleteat!(population, findfirst(==(worst_solution), population))
            worst_solution = maximum(population)
            patience = 0
        else
            patience += 1
            if patience == config["max_patience"]
                patience -= 1
                perturbed_solution =
                    perturb_solution(minimum(population), N, config["perturbation_rate"])
                perturbed_solution_ls = local_steepest_search(
                    perturbed_solution,
                    distance_matrix,
                    cost_vector,
                    config["mode"],
                )
                perturbed_solution_cost =
                    evaluate_solution(perturbed_solution_ls, distance_matrix, cost_vector)
                perturbed_solution_tuple = (perturbed_solution_cost, perturbed_solution_ls)
                if !(perturbed_solution_tuple in population) &&
                   perturbed_solution_cost < worst_solution[1]
                    push!(population, perturbed_solution_tuple)
                    deleteat!(population, findfirst(==(worst_solution), population))
                    worst_solution = maximum(population)
                    patience = 0
                end
            end
        end
        iteration_counter += 1
    end
    best_solution = minimum(population)
    return best_solution[2], iteration_counter
end
