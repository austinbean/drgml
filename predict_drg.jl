# use the TX data to predict a DRG.


using DataFrames, StatFiles, DecisionTree, ScikitLearn, Query, JLD2


# LOAD DATA
	# Stata file to create this is ml_nicu_subset.dta 
	df1 = DataFrame(load("/Users/austinbean/Desktop/drgml/nicu_subset.dta"))

	# column names:
	names(df1)

	# select subset of columns from all patients.
	xdrg = @from i in df1 begin 
		@select {i.CMS_DRG, i.ADMITTING_DIAGNOSIS, i.PRINC_DIAG_CODE, i.OTH_DIAG_CODE_1, i.OTH_DIAG_CODE_2, i.OTH_DIAG_CODE_3, i.OTH_DIAG_CODE_4, i.OTH_DIAG_CODE_5, i.OTH_DIAG_CODE_6, i.OTH_DIAG_CODE_7, i.OTH_DIAG_CODE_8, i.OTH_DIAG_CODE_9, i.OTH_DIAG_CODE_10, i.OTH_DIAG_CODE_11, i.OTH_DIAG_CODE_12, i.OTH_DIAG_CODE_13}
		@collect DataFrame
	end

	featuresdrg = xdrg[names(xdrg)[3:end]]
	fdrg = convert( Array{Union{Missing, String}, 2}, featuresdrg)
	fdrg = string.(fdrg)
	labelsdrg = xdrg[:CMS_DRG]

	labelsdrg = [string(i) for i in skipmissing(labelsdrg)]


	modeldrg = build_forest(labelsdrg, fdrg, 7, 20, 0.5, 6)


	df_test = DataFrame(load("/Users/austinbean/Desktop/drgml/nicu_holdout.dta"))



	test_drg = @from i in df_test begin 
		@select {i.CMS_DRG, i.ADMITTING_DIAGNOSIS, i.PRINC_DIAG_CODE, i.OTH_DIAG_CODE_1, i.OTH_DIAG_CODE_2, i.OTH_DIAG_CODE_3, i.OTH_DIAG_CODE_4, i.OTH_DIAG_CODE_5, i.OTH_DIAG_CODE_6, i.OTH_DIAG_CODE_7, i.OTH_DIAG_CODE_8, i.OTH_DIAG_CODE_9, i.OTH_DIAG_CODE_10, i.OTH_DIAG_CODE_11, i.OTH_DIAG_CODE_12, i.OTH_DIAG_CODE_13}
		@collect DataFrame
	end


	tfdrg = test_drg[names(test_drg)[3:end]]
	test_fdrg = convert( Array{Union{Missing, String}, 2}, tfdrg)
	test_fdrg = string.(test_fdrg)
	tlabelsdrg = test_drg[:CMS_DRG]
	output_drg = zeros(size(tlabelsdrg,1) , 2)
	for i = 1:size(tlabelsdrg,1)
		output_drg[i, 1] = tlabelsdrg[i]
		output_drg[i, 2] = parse(Float64, apply_forest(modeldrg, test_fdrg[i, :]))
	end 
	# measures difference between predicted DRG and actual as 0/1
	correct_fdrg = 1 - ((size(output_drg,1) - sum(output_drg[:,1] .== output_drg[:,2]))/size(output_drg,1))

println("Correct DRG: ", correct_fdrg)

println("Saving DRG Model")
@save "/Users/austinbean/Desktop/drgml/modeldrg.jld2" modeldrg



# Now let's see how to predict and save a new column.
# use record ID to join.  
	# works... 
	df_n = DataFrame(RECORD_ID = df_test[:RECORD_ID], rnn = [rand() for i = 1:size(df_test,1)])
	df_m = DataFrame(RECORD_ID = df_test[:RECORD_ID], blank = zeros(Int64, size(df_test,1)) )
	mer_df = join(df_n, df_m, on = :RECORD_ID)

	mt_df = join(df_test, df_m, on = :RECORD_ID)

for i = 1:size(mt_df, 1)
	mt_df[i, :blank] = parse(Int64, apply_forest(modeldrg, test_fdrg[i, :]))
end 



