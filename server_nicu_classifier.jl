# New version of the NICU classifier

# use the nicu_collapsed matrix
# use each column as a predictor
# trees should be trained on something like 50 predictors
# and a few hundred trees.  
# scp  "/Users/austinbean/Desktop/drgml/server_nicu_classifier.jl" beanaus@hsrdcsub2.pmacs.upenn.edu:/project/Lorch_project2018/bean/

using DataFrames, StatFiles, DecisionTree, ScikitLearn, Query, Dates, JLD2, CSVFiles, Serialization
	# this requires 1.1

println(VERSION)

function DoIt(x::Int64)
	println("starting")
	println(Dates.format(now(), "d/m/Y HH:MM"))
	println("loaded packages")

	println("opening data - csv.")
	df_test = DataFrame(load("/project/Lorch_project2018/bean/nicu_train_csv.csv"))

	print("data opened at ")
	println(Dates.format(now(), "d/m/Y HH:MM"))
	# use 30 features.

	println("Selecting Features at: ", Dates.format(now(), "d/m/Y HH:MM"))
		train_dat = df_test;
		tf = train_dat[names(train_dat)[2:end-1]]
		tf = convert( Array{Union{Missing, Int64}, 2}, tf)
		tlabels = train_dat[:ADMN_NICU]



	println("Building Forest at: ", Dates.format(now(), "d/m/Y HH:MM"))
	# RANDOM FOREST
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

	modeln = build_forest(tlabels, tf, -1, 200, 0.7, -1, 5, 2, 0.0)
	println("Finished Training at: ", Dates.format(now(), "d/m/Y HH:MM"))

	println("Loading Test Data at: ", Dates.format(now(), "d/m/Y HH:MM"))
		df_t = DataFrame(load("/project/Lorch_project2018/bean/nicu_test_csv.csv"))

	println("Test Data Loaded at:", Dates.format(now(), "d/m/Y HH:MM"))

	test_set = df_t
		tf = test_set[names(test_set)[2:end-1]]
		tf = convert( Array{Union{Missing, Int64}, 2}, tf)
		tlabels = test_set[:ADMN_NICU]

	println("Starting Classification Test at: ", Dates.format(now(), "d/m/Y HH:MM"))
		output = zeros(size(tlabels,1) , 2)
		for i = 1:size(tlabels,1)
			output[i, 1] = tlabels[i]
			output[i, 2] = convert(Float64, apply_forest(modeln, tf[i, :]))
		end 
		correct_f = 1- sum(abs.(output[:,1] .- output[:,2]))/size(output,1)

	println("Correct : ", correct_f)

	println("Starting to save model at: ", Dates.format(now(), "d/m/Y HH:MM"))
	@save "/project/Lorch_project2018/bean/model_nicu.jld2" modeln

	println("Saving backup at: ", Dates.format(now(), "d/m/Y HH:MM"))
	@save "/project/Lorch_project2018/bean/model_nicu_b.jld2" modeln 

	# save using serializer instead. 
	println("Serializing: ", Dates.format(now(), "d/m/Y HH:MM"))
	open("/project/Lorch_project2018/bean/saved_model.jls", "w") do file 
		serialize(file, modeln)
		close(file)
	end 


	println("Finished at: ", Dates.format(now(), "d/m/Y HH:MM"))
end 

DoIt(0)


