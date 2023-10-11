using Random

"""
# Generate a random solution
- `N::Int`: number of nodes
- `start_node::Int`: node to start from

returns: a random solution (permutation of nodes)
"""
function random_solution(N, start_node, distance_matrix=nothing)

    k = round(Int, N / 2 -1)
    permutation = randperm(N)[1: k]

    if in(start_node, permutation)
        while length(permutation) != ceil(N/2)
            r = rand(1:N)
            if !(r in permutation)
                push!(permutation, r)
            end
        end
    else
        pushfirst!(permutation, start_node)
    end

    return permutation
end
