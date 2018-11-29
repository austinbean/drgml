


#=  

- some packages.

Pkg.add("StatFiles")
Pkg.add("Query")
Pkg.add("JLD2")
=#


using DataFrames, StatFiles, DecisionTree, ScikitLearn, Query, JLD2


# LOAD DATA
	# Stata file to create this is ml_nicu_subset.dta 
	println("Loading")
	df1 = DataFrame(load("/Users/austinbean/Desktop/drgml/nicu_subset.dta"))

	# column names:
	names(df1)

#=
########################## This works with the whole subset of features.  
# select out DRGs 
println("Selecting Subsets")
# DRG 791
	x791 = @from i in df1 begin 
		@where (i.CMS_DRG == 791)
		@select {i.ADMN_NICU, i.ADMITTING_DIAGNOSIS, i.PRINC_DIAG_CODE, i.OTH_DIAG_CODE_1, i.OTH_DIAG_CODE_2, i.OTH_DIAG_CODE_3, i.OTH_DIAG_CODE_4, i.OTH_DIAG_CODE_5, i.OTH_DIAG_CODE_6, i.OTH_DIAG_CODE_7, i.OTH_DIAG_CODE_8, i.OTH_DIAG_CODE_9, i.OTH_DIAG_CODE_10, i.OTH_DIAG_CODE_11, i.OTH_DIAG_CODE_12, i.OTH_DIAG_CODE_13, i.OTH_DIAG_CODE_14, i.OTH_DIAG_CODE_15, i.OTH_DIAG_CODE_16, i.OTH_DIAG_CODE_17, i.OTH_DIAG_CODE_18, i.OTH_DIAG_CODE_19, i.OTH_DIAG_CODE_20, i.OTH_DIAG_CODE_21, i.OTH_DIAG_CODE_22, i.OTH_DIAG_CODE_23, i.OTH_DIAG_CODE_24}
		@collect DataFrame
	end 

	features791 = x791[names(x791)[3:end]]
	f791 = convert( Array{Union{Missing, String}, 2}, features791)
	f791 = string.(f791)
	labels791 = x791[:ADMN_NICU]

	labels791 = [string(i) for i in skipmissing(labels791)]



# DRG 793
	x793 = @from i in df1 begin 
		@where (i.CMS_DRG == 793)
		@select {i.ADMN_NICU, i.ADMITTING_DIAGNOSIS, i.PRINC_DIAG_CODE, i.OTH_DIAG_CODE_1, i.OTH_DIAG_CODE_2, i.OTH_DIAG_CODE_3, i.OTH_DIAG_CODE_4, i.OTH_DIAG_CODE_5, i.OTH_DIAG_CODE_6, i.OTH_DIAG_CODE_7, i.OTH_DIAG_CODE_8, i.OTH_DIAG_CODE_9, i.OTH_DIAG_CODE_10, i.OTH_DIAG_CODE_11, i.OTH_DIAG_CODE_12, i.OTH_DIAG_CODE_13, i.OTH_DIAG_CODE_14, i.OTH_DIAG_CODE_15, i.OTH_DIAG_CODE_16, i.OTH_DIAG_CODE_17, i.OTH_DIAG_CODE_18, i.OTH_DIAG_CODE_19, i.OTH_DIAG_CODE_20, i.OTH_DIAG_CODE_21, i.OTH_DIAG_CODE_22, i.OTH_DIAG_CODE_23, i.OTH_DIAG_CODE_24}
		@collect DataFrame
	end 


	# NB - features must be arrays.  convert to Array{Union{missing, String}, 2}
	features793 = x793[names(x793)[3:end]]
	f793 = convert( Array{Union{Missing, String}, 2}, features793)
	f793 = string.(f793)
	labels793 = x793[:ADMN_NICU]

	# There must be a better way to convert this? 
	labels793 = [string(i) for i in skipmissing(labels793)]

# ALL # DRG _full
	x_full = @from i in df1 begin 
		@select {i.ADMN_NICU, i.ADMITTING_DIAGNOSIS, i.PRINC_DIAG_CODE, i.OTH_DIAG_CODE_1, i.OTH_DIAG_CODE_2, i.OTH_DIAG_CODE_3, i.OTH_DIAG_CODE_4, i.OTH_DIAG_CODE_5, i.OTH_DIAG_CODE_6, i.OTH_DIAG_CODE_7, i.OTH_DIAG_CODE_8, i.OTH_DIAG_CODE_9, i.OTH_DIAG_CODE_10, i.OTH_DIAG_CODE_11, i.OTH_DIAG_CODE_12, i.OTH_DIAG_CODE_13}
		@collect DataFrame
	end 

	features_full = x_full[names(x_full)[3:end]]
	f_full = convert( Array{Union{Missing, String}, 2}, features_full)
	f_full = string.(f_full)
	labels_full = x_full[:ADMN_NICU]

	labels_full = [string(i) for i in skipmissing(labels_full)]
###################################
=#



######################### WORKS WITH SUBSET OF FEATURES ONLY ########################
println("Selecting Subsets")
# DRG 791
	x791 = @from i in df1 begin 
		@where (i.CMS_DRG == 791)
		@select {i.ADMN_NICU, i.ADMITTING_DIAGNOSIS, i.PRINC_DIAG_CODE, i.OTH_DIAG_CODE_1, i.OTH_DIAG_CODE_2, i.OTH_DIAG_CODE_3, i.OTH_DIAG_CODE_4, i.OTH_DIAG_CODE_5, i.OTH_DIAG_CODE_6, i.OTH_DIAG_CODE_7, i.OTH_DIAG_CODE_8, i.OTH_DIAG_CODE_9, i.OTH_DIAG_CODE_10, i.OTH_DIAG_CODE_11, i.OTH_DIAG_CODE_12, i.OTH_DIAG_CODE_13 }
		@collect DataFrame
	end 

	features791 = x791[names(x791)[3:end]]
	f791 = convert( Array{Union{Missing, String}, 2}, features791)
	f791 = string.(f791)
	labels791 = x791[:ADMN_NICU]

	labels791 = [string(i) for i in skipmissing(labels791)]



# DRG 793
	x793 = @from i in df1 begin 
		@where (i.CMS_DRG == 793)
		@select {i.ADMN_NICU, i.ADMITTING_DIAGNOSIS, i.PRINC_DIAG_CODE, i.OTH_DIAG_CODE_1, i.OTH_DIAG_CODE_2, i.OTH_DIAG_CODE_3, i.OTH_DIAG_CODE_4, i.OTH_DIAG_CODE_5, i.OTH_DIAG_CODE_6, i.OTH_DIAG_CODE_7, i.OTH_DIAG_CODE_8, i.OTH_DIAG_CODE_9, i.OTH_DIAG_CODE_10, i.OTH_DIAG_CODE_11, i.OTH_DIAG_CODE_12, i.OTH_DIAG_CODE_13 }
		@collect DataFrame
	end 


	# NB - features must be arrays.  convert to Array{Union{missing, String}, 2}
	features793 = x793[names(x793)[3:end]]
	f793 = convert( Array{Union{Missing, String}, 2}, features793)
	f793 = string.(f793)
	labels793 = x793[:ADMN_NICU]

	# There must be a better way to convert this? 
	labels793 = [string(i) for i in skipmissing(labels793)]

# ALL # DRG _full
	x_full = @from i in df1 begin 
		@select {i.ADMN_NICU, i.ADMITTING_DIAGNOSIS, i.PRINC_DIAG_CODE, i.OTH_DIAG_CODE_1, i.OTH_DIAG_CODE_2, i.OTH_DIAG_CODE_3, i.OTH_DIAG_CODE_4, i.OTH_DIAG_CODE_5, i.OTH_DIAG_CODE_6, i.OTH_DIAG_CODE_7, i.OTH_DIAG_CODE_8, i.OTH_DIAG_CODE_9, i.OTH_DIAG_CODE_10, i.OTH_DIAG_CODE_11, i.OTH_DIAG_CODE_12, i.OTH_DIAG_CODE_13}
		@collect DataFrame
	end 

	features_full = x_full[names(x_full)[3:end]]
	f_full = convert( Array{Union{Missing, String}, 2}, features_full)
	f_full = string.(f_full)
	labels_full = x_full[:ADMN_NICU]

	labels_full = [string(i) for i in skipmissing(labels_full)]





println("Building Forests")
# RANDOM FOREST

	model793 = build_forest(labels793, f793, 7, 20, 0.5, 6)
		# What does nfoldCV actually do...?  
	#acc = nfoldCV_forest(labels793, f793, 3, 2)

# RANDOM FOREST 

	model791 = build_forest(labels791, f791, 7, 20, 0.5, 6)
		# why does none of this depend on any model parameters?  No dependence on the forest so what does it do?  
	#acc = nfoldCV_forest(labels791, f791, 3, 2)

# RANDOM FOREST 
	model_full = build_forest(labels_full, f_full, 7, 20, 0.5, 6)




# Test on holdout...
println("Loading holdout")
	df_test = DataFrame(load("/Users/austinbean/Desktop/drgml/nicu_holdout.dta"))

println("Testing 791")
	test_791 = @from i in df_test begin 
		@where (i.CMS_DRG == 791)
		@select {i.ADMN_NICU, i.ADMITTING_DIAGNOSIS, i.PRINC_DIAG_CODE, i.OTH_DIAG_CODE_1, i.OTH_DIAG_CODE_2, i.OTH_DIAG_CODE_3, i.OTH_DIAG_CODE_4, i.OTH_DIAG_CODE_5, i.OTH_DIAG_CODE_6, i.OTH_DIAG_CODE_7, i.OTH_DIAG_CODE_8, i.OTH_DIAG_CODE_9, i.OTH_DIAG_CODE_10, i.OTH_DIAG_CODE_11, i.OTH_DIAG_CODE_12, i.OTH_DIAG_CODE_13, i.OTH_DIAG_CODE_14, i.OTH_DIAG_CODE_15, i.OTH_DIAG_CODE_16, i.OTH_DIAG_CODE_17, i.OTH_DIAG_CODE_18, i.OTH_DIAG_CODE_19, i.OTH_DIAG_CODE_20, i.OTH_DIAG_CODE_21, i.OTH_DIAG_CODE_22, i.OTH_DIAG_CODE_23, i.OTH_DIAG_CODE_24}
		@collect DataFrame
	end 

	tf791 = test_791[names(test_791)[3:end]]
	test_f791 = convert( Array{Union{Missing, String}, 2}, tf791)
	test_f791 = string.(test_f791)
	tlabels791 = test_791[:ADMN_NICU]
	output_791 = zeros(size(tlabels791,1) , 2)
	for i = 1:size(tlabels791,1)
		output_791[i, 1] = tlabels791[i]
		output_791[i, 2] = parse(Float64, apply_forest(model791, test_f791[i, :]))
	end 
	correct_f791 = 1- sum(abs.(output_791[:,1] .- output_791[:,2]))/size(output_791,1)


println("testing 793")
# DRG 793
	test_793 = @from i in df_test begin 
		@where (i.CMS_DRG == 793)
		@select {i.ADMN_NICU, i.ADMITTING_DIAGNOSIS, i.PRINC_DIAG_CODE, i.OTH_DIAG_CODE_1, i.OTH_DIAG_CODE_2, i.OTH_DIAG_CODE_3, i.OTH_DIAG_CODE_4, i.OTH_DIAG_CODE_5, i.OTH_DIAG_CODE_6, i.OTH_DIAG_CODE_7, i.OTH_DIAG_CODE_8, i.OTH_DIAG_CODE_9, i.OTH_DIAG_CODE_10, i.OTH_DIAG_CODE_11, i.OTH_DIAG_CODE_12, i.OTH_DIAG_CODE_13, i.OTH_DIAG_CODE_14, i.OTH_DIAG_CODE_15, i.OTH_DIAG_CODE_16, i.OTH_DIAG_CODE_17, i.OTH_DIAG_CODE_18, i.OTH_DIAG_CODE_19, i.OTH_DIAG_CODE_20, i.OTH_DIAG_CODE_21, i.OTH_DIAG_CODE_22, i.OTH_DIAG_CODE_23, i.OTH_DIAG_CODE_24}
		@collect DataFrame
	end 


	# NB - features must be arrays.  convert to Array{Union{missing, String}, 2}
	tf793 = test_793[names(test_793)[3:end]]
	test_f793 = convert( Array{Union{Missing, String}, 2}, tf793)
	test_f793 = string.(test_f793)
	tlabels793 = test_793[:ADMN_NICU]

	output_793 = zeros(size(tlabels793,1) , 2)
	for i = 1:size(tlabels793,1)
		output_793[i, 1] = tlabels793[i]
		output_793[i, 2] = parse(Float64, apply_forest(model793, test_f793[i, :]) )
	end 
	correct_f793 = 1- sum(abs.(output_793[:,1] .- output_793[:,2]))/size(output_793,1)


# DRG full
println("Testing full ")
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
	correct_ffull = 1- sum(abs.(output_full[:,1] .- output_full[:,2]))/size(output_full,1)



println("Correct 791: ", correct_f791)
println("Correct 793: ", correct_f793)
println("Correct Full: ", correct_ffull)



# save the models:

println("Saving")
@save "/Users/austinbean/Desktop/drgml/model793.jld2" model793
@save "/Users/austinbean/Desktop/drgml/model791.jld2" model791
@save "/Users/austinbean/Desktop/drgml/modelfull.jld2" model_full


#=
Correct 791: 0.9246301131418625
Correct 793: 0.7746300546015669
=#


#=
# Test the model loading process. 





=#