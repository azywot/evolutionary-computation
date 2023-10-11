include("./parse_data.jl")

using Statistics

"""
# Evaluate Statistics for a problem instance given a particaular method.
- 'filename::String': path to CSV file
- `method::Function`: method to be used to solve the problem
- `iter::Int`: number of times to run the method default 200
 #nodes >= iter as it itetates over the nodes while choosing the starting point
"""
function evaluate_statistics(filename, method, iter)

    distance_matrix, cost_vector, coords = read_data(filename)
    N = length(cost_vector)
    values = []

    best_solution = nothing
    best_cost = 1000000

    for i in 1:iter
        permutation = method(N, i, distance_matrix)
        cost = evaluate_solution(permutation, distance_matrix, cost_vector)
        push!(values, cost)

        if cost < best_cost
            best_solution = permutation
            best_cost = cost
        end

    end

    # TODO: output file for visualisation + coords of the best solution
    println("Best solution: ", best_solution)
    println("\nLowest cost: ", best_cost)
    println("\nStatistics:")
    println("Mean: ", mean(values))
    println("Min: ", minimum(values))
    println("Max: ", maximum(values))

end
