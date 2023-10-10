using CSV, DataFrames, Distances


function read_data(filename)
    df = CSV.read(filename, DataFrame, header=false)
    rename!(df, [:x, :y, :cost])
    coords = reshape(Array(df[!, Not("cost")]), (2, N))

    distance_matrix = round.(Int, pairwise(Euclidean(), coords))
    cost_vector = df[!, "cost"]
    return distance_matrix, cost_vector, coords
end
