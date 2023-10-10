using CSV, DataFrames

df = CSV.read("evolutionary-computation/data/TSPA.csv", DataFrame, header=false)
rename!(df,[:x,:y,:cost])
