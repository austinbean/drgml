# Test model load and predict process

using DataFrames, StatFiles, DecisionTree, ScikitLearn, Query, JLD2


@load "/Users/austinbean/Desktop/drgml/model793.jld2" model793

println("loaded")

println("load data")
df_test = DataFrame(load("/Users/austinbean/Desktop/drgml/nicu_holdout.dta"))

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


#println("Correct 791: ", correct_f791)
println("Correct 793: ", correct_f793)
