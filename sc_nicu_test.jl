# To run on PMACS


using DataFrames, StatFiles, DecisionTree, ScikitLearn, Query, JLD2


@load "/home/beanaus/models/model793.jld2" model793
@load "/home/beanaus/models/model791.jld2" model791



sc_dat = DataFrame(load("/home/beanaus/datacsv/SC_baby_hosp_rnm.dta"))


test_793 = @from i in sc_dat begin 
		# need to fix CMS DRG 
		@where (i.CMS_DRG == 793)
		@select {i.ADMN_NICU, i.ADMITTING_DIAGNOSIS, i.PRINC_DIAG_CODE, i.OTH_DIAG_CODE_1, i.OTH_DIAG_CODE_2, i.OTH_DIAG_CODE_3, i.OTH_DIAG_CODE_4, i.OTH_DIAG_CODE_5, i.OTH_DIAG_CODE_6, i.OTH_DIAG_CODE_7, i.OTH_DIAG_CODE_8, i.OTH_DIAG_CODE_9, i.OTH_DIAG_CODE_10, i.OTH_DIAG_CODE_11, i.OTH_DIAG_CODE_12, i.OTH_DIAG_CODE_13}
		@collect DataFrame
	end 




# TEST

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




println("Correct 793: ", correct_f793)

