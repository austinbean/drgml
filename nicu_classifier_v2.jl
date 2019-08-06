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

#=
TODO - there is a way to do two things:
- parallelize the training process.  That isn't working right now.
- use multithreading on the classification.  That sound be easy.



=#

# Transfer the result:
# scp  "/Users/austinbean/Desktop/drgml/model_nicu.jld2" beanaus@hsrdcsub2.pmacs.upenn.edu:/project/Lorch_project2018/bean/


using DataFrames, StatFiles, DecisionTree, ScikitLearn, Query, Dates, JLD2, TableReader, Serialization, Distributed

#@everywhere using DataFrames, StatFiles, DecisionTree, ScikitLearn, Query, Dates, JLD2, TableReader, Serialization, Distributed

# maybe tablereader is better than csvfiles ????
# TODO - switch to tablereader.  Also cut down the purity of the tree, or min node size.  It's generating too many leaves now.


function DoIt(x::Int64)
	println(VERSION)
	#addprocs()

	path = "tuk39938"
	#path = "austinbean"

	println("opening data ", Dates.format(now(), "d/m/Y HH:MM"))

	df_test = TableReader.readcsv("/Users/$path/Desktop/programs/drgml/tx_d1.csv")

	println("data opened ", Dates.format(now(), "d/m/Y HH:MM"))
		train_dat = df_test;
			# TODO - change next line for new indexing scheme
		tf = train_dat[names(train_dat)[2:end-1]]
		tf = convert( Array{Union{Missing, Int64}, 2}, tf)
			# there is a dep warn about the indexing scheme
		tlabels = train_dat[:admn_nicu]



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
					# TODO - lower sample, probably.  Lower the last four so this is faster.
					# Makes sense to subsample fewer points, since taking an ensemble at the end anyway.
					# cutting "partial_sampling" down to 0.1 speeds up by a factor of 3
	modeln = build_forest(tlabels, tf, -1, 250, 0.2, -1, 5, 2, 0.0)
	println("forest trained ", Dates.format(now(), "d/m/Y HH:MM"))

	println("Loading holdout  ", Dates.format(now(), "d/m/Y HH:MM"))
		# this is going to run on the TX 2000 data.
	df_t = TableReader.readcsv("/Users/$path/Desktop/programs/drgml/tx00.csv")

	println("Testing Model ", Dates.format(now(), "d/m/Y HH:MM"))
	test_set = df_t
		tf = test_set[names(test_set)[3:end-1]]
		tf = convert( Array{Union{Missing, Int64}, 2}, tf)
		#tlabels = test_set[:admn_nicu]
	println("Classify ", Dates.format(now(), "d/m/Y HH:MM"))
		output = zeros(size(tf,1) , 2)
		for i = 1:size(tf,1)
			#output[i, 1] = tlabels[i]
			output[i, 2] = convert(Float64, apply_forest(modeln, tf[i, :]))
		end
		#correct_f = 1- sum(abs.(output[:,1] .- output[:,2]))/size(output,1)
	correct_f = sum(output, dims=1)[2]
	#@save "/Users/$path/Desktop/programs/drgml/model_nicu.jld2" modeln

	println("Adm predict : ", correct_f, "   ", Dates.format(now(), "d/m/Y HH:MM"))
	# New Test to save using serializer.


	# can serialize the object if necessary, though this requires JL>1.1
	open("/Users/$path/Desktop/programs/drgml/saved_thing.jls", "w") do file
		serialize(file, modeln)
		close(file)
	end


end

DoIt(0)
