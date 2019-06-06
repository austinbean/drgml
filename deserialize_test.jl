# load serialized object

# note - only available as of JL 1.1
using Serialization, DecisionTree, Dates, DataFrames, CSVFiles

function MainF(I::Int64)
	println("Deserialize  ", Dates.format(now(), "d/m/Y HH:MM"))
	# open("/Users/austinbean/Desktop/drgml/saved_thing.jls", "r") do file 
	# 	modeln = deserialize(file)
	# end 
	modeln = deserialize("/Users/austinbean/Desktop/drgml/saved_thing.jls")

	println("Loading holdout  ", Dates.format(now(), "d/m/Y HH:MM"))
	df_t = DataFrame(load("/Users/austinbean/Desktop/drgml/quick_val.csv"))

	println("Testing Model ", Dates.format(now(), "d/m/Y HH:MM"))
	test_set = df_t
		tf = test_set[names(test_set)[2:end-1]]
		tf = convert( Array{Union{Missing, Int64}, 2}, tf)
		tlabels = test_set[:ADMN_NICU]
	println("Classify ", Dates.format(now(), "d/m/Y HH:MM"))
		output = zeros(size(tlabels,1) , 2)
		for i = 1:size(tlabels,1)
			output[i, 1] = tlabels[i]
			output[i, 2] = convert(Float64, apply_forest(modeln, tf[i, :]))
		end 
		correct_f = 1- sum(abs.(output[:,1] .- output[:,2]))/size(output,1)
	println("Correct: ", correct_f)
end 

MainF(1)