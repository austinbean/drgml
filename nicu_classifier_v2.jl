# New version of the NICU classifier

# use the nicu_collapsed matrix
# use each column as a predictor
# trees should be trained on something like 50 predictors
# and a few hundred trees.  

#=
julia nicu_classifier_v2.jl
opening data - can take forever.
data opened
Building Forests
forest trained
Loading holdout - can take forever.
Testing Model
Classify
Correct : 0.998689177852349
=#

# Transfer the result:
# scp  "/Users/austinbean/Desktop/drgml/model_nicu.jld2" beanaus@hsrdcsub2.pmacs.upenn.edu:/project/Lorch_project2018/bean/
 


using DataFrames, StatFiles, DecisionTree, ScikitLearn, Query, Dates, JLD2, CSVFiles, Serialization



function DoIt(x::Int64)
	println(VERSION)

	println("opening data ", Dates.format(now(), "d/m/Y HH:MM"))

	df_test = DataFrame(load("/Users/austinbean/Desktop/drgml/quick_test.csv"))

	println("data opened ", Dates.format(now(), "d/m/Y HH:MM"))
		train_dat = df_test;
		tf = train_dat[names(train_dat)[2:end-1]]
		tf = convert( Array{Union{Missing, Int64}, 2}, tf)
		tlabels = train_dat[:ADMN_NICU]



	println("Building Forests ", Dates.format(now(), "d/m/Y HH:MM"))
				#=
	model    =   build_forest(labels, features,
	                          n_subfeatures,
	                          n_trees,
	                          partial_sampling,
	                          max_depth,
	                          min_samples_leaf,
	                          min_samples_split,
	                          min_purity_increase)
				=#

	modeln = build_forest(tlabels, tf, -1, 1, 0.7, -1, 5, 2, 0.0)
	println("forest trained ", Dates.format(now(), "d/m/Y HH:MM"))

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
	@save "/Users/austinbean/Desktop/drgml/model_nicu.jld2" modeln

	println("Correct : ", correct_f, "   ", Dates.format(now(), "d/m/Y HH:MM"))
	# New Test to save using serializer.


	# can serialize the object if necessary, though this requires JL>1.1  
	open("/Users/austinbean/Desktop/drgml/saved_thing.jls", "w") do file 
		serialize(file, modeln)
		close(file)
	end 


end 

DoIt(0)


