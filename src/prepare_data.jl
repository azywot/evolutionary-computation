using CSV, DataFrames, Distances


function read_data(filename)
    df = CSV.read(filename, DataFrame, header=false)
    rename!(df, [:x, :y, :cost])
    coords = [collect(row) for row in eachrow(hcat(df.x, df.y))]
    distance_matrix = round.(Int, pairwise(Euclidean(), coords))

    return distance_matrix, df.cost, coords
end