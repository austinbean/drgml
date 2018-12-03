# Comparison of prediction with 24 vs. 13 DRGS

#=
Somewhat perplexing results here - there is no difference across the models:
Prediction Accuracy Using Model Trained on Full Feature Set:     0.9191534251994462
Prediction Accuracy Using Model Trained on Partial Features Set: 0.9223478604865827

# What about JUST the smaller DRGs?


=#


using DataFrames, StatFiles, DecisionTree, ScikitLearn, Query, JLD2


# LOAD DATA
	# Stata file to create this is ml_nicu_subset.dta 
	println("Loading")
	df1 = DataFrame(load("/Users/austinbean/Desktop/drgml/nicu_subset.dta"))

	# column names:
	names(df1)


# Full Set of Features
	println("Selecting Full")
	x_full = @from i in df1 begin 
		@select {i.ADMN_NICU, i.ADMITTING_DIAGNOSIS, i.PRINC_DIAG_CODE, i.OTH_DIAG_CODE_1, i.OTH_DIAG_CODE_2, i.OTH_DIAG_CODE_3, i.OTH_DIAG_CODE_4, i.OTH_DIAG_CODE_5, i.OTH_DIAG_CODE_6, i.OTH_DIAG_CODE_7, i.OTH_DIAG_CODE_8, i.OTH_DIAG_CODE_9, i.OTH_DIAG_CODE_10, i.OTH_DIAG_CODE_11, i.OTH_DIAG_CODE_12, i.OTH_DIAG_CODE_13, i.OTH_DIAG_CODE_14, i.OTH_DIAG_CODE_15, i.OTH_DIAG_CODE_16, i.OTH_DIAG_CODE_17, i.OTH_DIAG_CODE_18, i.OTH_DIAG_CODE_19, i.OTH_DIAG_CODE_20, i.OTH_DIAG_CODE_21, i.OTH_DIAG_CODE_22, i.OTH_DIAG_CODE_23, i.OTH_DIAG_CODE_24}
		@collect DataFrame
	end 

	features_full = x_full[names(x_full)[3:end]]
	f_full = convert( Array{Union{Missing, String}, 2}, features_full)
	f_full = string.(f_full)
	labels_full = x_full[:ADMN_NICU]

	labels_full = [string(i) for i in skipmissing(labels_full)]
	# Train model on full data 
	println("Train Full Model")
	model_full = build_forest(labels_full, f_full, 7, 20, 0.5, 6)


# Partial Set of Features
println("Selecting Subset")
	x_13 = @from i in df1 begin 
		@select {i.ADMN_NICU, i.ADMITTING_DIAGNOSIS, i.PRINC_DIAG_CODE, i.OTH_DIAG_CODE_1, i.OTH_DIAG_CODE_2, i.OTH_DIAG_CODE_3, i.OTH_DIAG_CODE_4, i.OTH_DIAG_CODE_5, i.OTH_DIAG_CODE_6, i.OTH_DIAG_CODE_7, i.OTH_DIAG_CODE_8, i.OTH_DIAG_CODE_9, i.OTH_DIAG_CODE_10, i.OTH_DIAG_CODE_11, i.OTH_DIAG_CODE_12, i.OTH_DIAG_CODE_13}
		@collect DataFrame
	end 

	features_13 = x_13[names(x_13)[3:end]]
	f_13 = convert( Array{Union{Missing, String}, 2}, features_13)
	f_13 = string.(f_13)
	labels_13 = x_13[:ADMN_NICU]

	labels_13 = [string(i) for i in skipmissing(labels_13)]
	# Train model on set of 13 features.
	println("Train Partial Model")
	model_13 = build_forest(labels_13, f_13, 7, 20, 0.5, 6)



println("Loading holdout")
	df_test = DataFrame(load("/Users/austinbean/Desktop/drgml/nicu_holdout.dta"))

println("Select Full Feature Set From Test.")
	test_full = @from i in df_test begin 
		@select {i.ADMN_NICU, i.ADMITTING_DIAGNOSIS, i.PRINC_DIAG_CODE, i.OTH_DIAG_CODE_1, i.OTH_DIAG_CODE_2, i.OTH_DIAG_CODE_3, i.OTH_DIAG_CODE_4, i.OTH_DIAG_CODE_5, i.OTH_DIAG_CODE_6, i.OTH_DIAG_CODE_7, i.OTH_DIAG_CODE_8, i.OTH_DIAG_CODE_9, i.OTH_DIAG_CODE_10, i.OTH_DIAG_CODE_11, i.OTH_DIAG_CODE_12, i.OTH_DIAG_CODE_13, i.OTH_DIAG_CODE_14, i.OTH_DIAG_CODE_15, i.OTH_DIAG_CODE_16, i.OTH_DIAG_CODE_17, i.OTH_DIAG_CODE_18, i.OTH_DIAG_CODE_19, i.OTH_DIAG_CODE_20, i.OTH_DIAG_CODE_21, i.OTH_DIAG_CODE_22, i.OTH_DIAG_CODE_23, i.OTH_DIAG_CODE_24}
		@collect DataFrame
	end 


	# NB - features must be arrays.  convert to Array{Union{missing, String}, 2}
	tffull = test_full[names(test_full)[3:end]]
	test_ffull = convert( Array{Union{Missing, String}, 2}, tffull)
	test_ffull = string.(test_ffull)
	tlabelsfull = test_full[:ADMN_NICU]

	output_full = zeros(size(tlabelsfull,1) , 2)
	for i = 1:size(tlabelsfull,1)
		output_full[i, 1] = tlabelsfull[i]
		output_full[i, 2] = parse(Float64, apply_forest(model_full, test_ffull[i, :]) )
	end 
	correct_ffull = 1- (sum(output_full[:,1] .!= output_full[:,2]))/size(output_full,1)


# Do the same with a subset of the features.
println("Subset of Features")
	test_13 = @from i in df_test begin 
		@select {i.ADMN_NICU, i.ADMITTING_DIAGNOSIS, i.PRINC_DIAG_CODE, i.OTH_DIAG_CODE_1, i.OTH_DIAG_CODE_2, i.OTH_DIAG_CODE_3, i.OTH_DIAG_CODE_4, i.OTH_DIAG_CODE_5, i.OTH_DIAG_CODE_6, i.OTH_DIAG_CODE_7, i.OTH_DIAG_CODE_8, i.OTH_DIAG_CODE_9, i.OTH_DIAG_CODE_10, i.OTH_DIAG_CODE_11, i.OTH_DIAG_CODE_12, i.OTH_DIAG_CODE_13}
		@collect DataFrame
	end 


	# NB - features must be arrays.  convert to Array{Union{missing, String}, 2}
	tf13 = test_13[names(test_13)[3:end]]
	test_f13 = convert( Array{Union{Missing, String}, 2}, tf13)
	test_f13 = string.(test_f13)
	tlabels13 = test_13[:ADMN_NICU]

	output_13 = zeros(size(tlabels13,1) , 2)
	for i = 1:size(tlabels13,1)
		output_13[i, 1] = tlabels13[i]
		output_13[i, 2] = parse(Float64, apply_forest(model_13, test_f13[i, :]) )
	end 
	correct_13 = 1- (sum(output_13[:,1] .!= output_13[:,2]))/size(output_13,1)


println("********** RESULTS ***************")
println("Prediction Accuracy Using Model Trained on Full Feature Set:     ", correct_ffull)
println("Prediction Accuracy Using Model Trained on Partial Features Set: ", correct_13)
