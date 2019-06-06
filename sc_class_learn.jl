#=
The Texas RF is weirdly inaccurate on SC data.
Is the reverse true?  If so, why?  (This question may be answerable in R.)
Can also compare ICD-9's of those wtih NICU admits.  
 
- understand importance of different diagnoses in generating admissions in SC vs. TX (RF variable importance?)

scp  "/Users/austinbean/Desktop/drgml/sc_class_learn.jl" beanaus@hsrdcsub2.pmacs.upenn.edu:/project/Lorch_project2018/bean/

=#

using DataFrames, StatFiles, DecisionTree, ScikitLearn, Query, Dates, JLD2, CSVFiles, Serialization


function SCEst(x)

		# do the same thing done for training in TX data.  
	println(VERSION)
	println("opening data ", Dates.format(now(), "d/m/Y HH:MM"))

	# load 
	df_test = DataFrame(load("/project/Lorch_project2018/bean/sc_nicu_train.csv"))
	println("data opened ", Dates.format(now(), "d/m/Y HH:MM"))

	# select training set: 
		# double check these rows...
	train_dat = df_test[:,3:end];
	train_dat = convert(Array{Union{Missing, Int64}, 2}, train_dat)
	tlabels = df_test[:,1];

	println("Building Forests: ", Dates.format(now(), "d/m/Y HH:MM"))
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
	modeln = build_forest(tlabels, train_dat, -1, 200, 0.7, -1, 5, 2, 0.0)
	println("Finished Training at: ", Dates.format(now(), "d/m/Y HH:MM"))

	# Testing 
	println("Loading Test Data at: ", Dates.format(now(), "d/m/Y HH:MM"))
	df_t = DataFrame(load("/project/Lorch_project2018/bean/sc_nicu_test.csv"))
	println("Test Data Loaded at:", Dates.format(now(), "d/m/Y HH:MM"))

	test_set = df_t
	tf = test_set[:,3:end]
	tf = convert( Array{Union{Missing, Int64}, 2}, tf)
	tlabels = test_set[:,1]

	println("Starting Classification Test at: ", Dates.format(now(), "d/m/Y HH:MM"))
	output = zeros(size(tlabels,1) , 2)
		for i = 1:size(tlabels,1)
			output[i, 1] = tlabels[i]
			output[i, 2] = convert(Float64, apply_forest(modeln, tf[i, :]))
		end 
	correct_f = 1- sum(abs.(output[:,1] .- output[:,2]))/size(output,1)

	println("Correct : ", correct_f)

	println("Starting to save model at: ", Dates.format(now(), "d/m/Y HH:MM"))
	@save "/project/Lorch_project2018/bean/sc_model_nicu.jld2" modeln

	println("Saving backup at: ", Dates.format(now(), "d/m/Y HH:MM"))
	@save "/project/Lorch_project2018/bean/sc_model_nicu_b.jld2" modeln 

	# save using serializer instead. 
	println("Serializing: ", Dates.format(now(), "d/m/Y HH:MM"))
	open("/project/Lorch_project2018/bean/sc_saved_model.jls", "w") do file 
		serialize(file, modeln)
		close(file)
	end 


	println("Finished at: ", Dates.format(now(), "d/m/Y HH:MM"))

end 

SCEst(1)