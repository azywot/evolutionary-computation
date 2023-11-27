include("./random.jl")
include("./local_greedy_search.jl")

using Random
using StatsBase

"""
# Perofrm a multiple start local search algorithm.
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of node
- `iterations::Int`: number of iterations to run the algorithm
- `mode::String`: mode of the local search, either "node" or "edge"

returns: a multiple start local search solution
"""
function multiple_start_local_search(distance_matrix, cost_vector, iterations = 200, mode = "edge", )

    N = length(cost_vector)
    best_solution = []
    best_cost = 1000000

    for i in 1:iterations
        initial_solution = random_solution(N)
        solution = local_steepest_search(initial_solution, distance_matrix, cost_vector, mode)
        cost = evaluate_solution(solution, distance_matrix, cost_vector)
        if cost < best_cost
            best_solution = solution
            best_cost = cost
        end
    end 
    
    return best_solution
end


""" 
# Perofrm a perturbation on a solution.
- `solution::Vector{Int}`: solution
- `N::Int`: number of nodes
- `perturbation_rate::Float64`: perturbation rate

returns: a perturbed solution
"""
function perturb_solution(solution, N, perturbation_rate)
    solution = deepcopy(solution)
    n = length(solution)
    perturbation_number = round(Int, perturbation_rate * n)

    unvisited = collect(setdiff(Set(1:N), Set(solution)))
    unvisited_sample = sample(unvisited, perturbation_number, replace = false)
    visited_sample = sample(solution, perturbation_number, replace = false)
    for i in 1:perturbation_number
        visited_pos = findfirst(==(visited_sample[i]), solution)
        solution[visited_pos] = unvisited_sample[i]
    end

    return solution
end

"""
# Perform an iterated local search algorithm.
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of node
- `time_limit::Int`: time limit in seconds
- `mode::String`: mode of the local search, either "node" or "edge"
- `perturbation_rate::Float64`: perturbation rate

returns: an iterated local search solution, local steepest counter
"""
function iterated_local_search(distance_matrix, cost_vector, time_limit, mode = "edge", perturbation_rate = 0.3)

    N = length(cost_vector)
    best_solution = local_steepest_search(random_solution(N), distance_matrix, cost_vector, mode)
    best_cost = evaluate_solution(best_solution, distance_matrix, cost_vector)
    local_steepest_counter = 1
    start_time = time()

    while time() - start_time < time_limit
        perturbed_solution = perturb_solution(best_solution, N, perturbation_rate)
        solution = local_steepest_search(perturbed_solution, distance_matrix, cost_vector, mode)
        local_steepest_counter += 1
        cost = evaluate_solution(solution, distance_matrix, cost_vector)
        if cost < best_cost
            best_solution = solution
            best_cost = cost
        end
    end 
    
    return best_solution, local_steepest_counter
end