using Random
using StatsBase

include("./random.jl")
include("./local_greedy_search.jl")

# Generate an initial population X 
# repeat 
# Draw at random two different solutions (parents) using uniform distribution 
# Construct an offspring solution by recombining parents 
# y := Local search (y) 
# if y is better than the worst solution in the population and (sufficiently) different from all 
# solutions in the population 
# Add y to the population and remove the worst solution 
# until the stopping conditions are met 

# TODO:
# report the number of iteration

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
Operator 1. We locate in the offspring all common nodes and edges and fill the rest of the
solution at random
- `parent1::Vector{Int}`: vector of node ids
- `parent2::Vector{Int}`: vector of node ids
returns: child solution
"""
function recombine_operation1(parent1, parent2)
    n = length(parent1)
    child = zeros(Int, n)
    common_edges = find_longest_common_subarrays(parent1, parent2)
    common_edges = collect(Iterators.flatten(common_edges))
    nodes_to_add = collect(setdiff(Set(1:200), Set(common_edges)))
    for i = i:n
        if !(parent1[i] in common_edges)
            random_index = rand(1:length(nodes_to_add))
            random_node = splice!(nodes_to_add, random_index)
            child[i] = random_node
        else
            child[i] = parent1[i]
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
returns: child solution
"""
function recombine_operation2(parent1, parent2)
    # TODO
    n = length(parent1)
    child = zeros(Int, n)
    return child
end

function recombine_operation3(parent1, parent2)
    # TODO: our approach
    n = length(parent1)
    child = zeros(Int, n)
    return child
end


"""
Generate a hybrid evolutionary algorithm solution given a starting solution and a mode.
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of node
- `time_limit::Int`: time limit in seconds
- `recombine::Function`: recombination function
- `initial_population_size::Int`: size of the initial population
- `mode::String`: mode of the local search, either "node" or "edge"

returns: a hybrid evolutionary algorithm solution
"""
function hybrid_evolutionary_algorithm(
    distance_matrix,
    cost_vector,
    time_limit,
    recombine = recombine_operation1,
    initial_population_size = 20,
    mode = "edge",
)

    N, _ = size(distance_matrix)
    distance_matrix = deepcopy(distance_matrix)
    cost_vector = deepcopy(cost_vector)

    population = [] # List of tuples (cost, solution)
    start_time = time()
    for i = 1:initial_population_size
        solution =
            local_steepest_search(random_solution(N), distance_matrix, cost_vector, mode)
        solution_cost = evaluate_solution(solution, distance_matrix, cost_vector)
        push!(population, (solution_cost, solution))
    end

    worst_solution = maximum(population, lt = (x, y) -> x[1] < y[1])

    while time() - start_time < time_limit
        parents = sample(population, 2, replace = false)
        offspring = recombine(parents[1][2], parents[2][2])
        offspring_ls = local_steepest_search(offspring, distance_matrix, cost_vector, mode)
        offspring_cost = evaluate_solution(offspring_ls, distance_matrix, cost_vector)
        offspring_tuple = (offspring_cost, offspring_ls)

        # making sure there are no copies
        if !(offspring_tuple in population) && offspring_cost < worst_solution[1]
            push!(population, offspring_tuple)
            deleteat!(population, findfirst(==(worst_solution), population))
            worst_solution = maximum(population, lt = (x, y) -> x[1] < y[1])
        end
    end

    return best_solution
end
