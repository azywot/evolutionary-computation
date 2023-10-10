using CSV, DataFrames, Distances

df = CSV.read("evolutionary-computation/data/TSPA.csv", DataFrame, header=false)
rename!(df,[:x,:y,:cost])

coords = reshape(Array(df[!, Not("cost")]), (2, 200))

# we need only these two variables
distance_matrix = round.(Int, pairwise(Euclidean(), coords))
cost_vector = df[!, "cost"]
