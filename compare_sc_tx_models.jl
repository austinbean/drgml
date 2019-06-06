#=

use the models estimated on TX and SC data on data from the other state, 
to see how much misclassification there is

scp  "/Users/austinbean/Desktop/drgml/compare_sc_tx_models.jl" beanaus@hsrdcsub2.pmacs.upenn.edu:/project/Lorch_project2018/bean/


=#

using DataFrames, StatFiles, DecisionTree, ScikitLearn, Query, Dates, JLD2, CSVFiles, Serialization


function Test_Models(x)
		# verify that version is 1.1.0 >>
	println(VERSION)
	
	# opening data
	println("opening data ", Dates.format(now(), "d/m/Y HH:MM"))
	sc_data = DataFrame(load("/project/Lorch_project2018/bean/sc_nicu_coll.csv"))
	tx_data = DataFrame(load("/project/Lorch_project2018/bean/nicu_train_csv.csv"))

	# select out label, reset dataframe to required form.
	# Texas 
		println("Selecting Texas Features at: ", Dates.format(now(), "d/m/Y HH:MM"))
		train_dat = tx_data;
			# double-check where the nicu label is here - yes, column order is [pid icd9s ... record_id admn_nicu]
		tf = train_dat[names(train_dat)[2:end-2]]
		tx_tf = convert( Array{Union{Missing, Int64}, 2}, tf)
		tx_tlabels = train_dat[:ADMN_NICU]
	# South Carolina 
		println("Selecting Texas Features at: ", Dates.format(now(), "d/m/Y HH:MM"))
		sc_dat = sc_data;
			# double-check where the nicu label is here - yes, column order is [admn_nicu pid icd9s... ]
		sc_tf = sc_dat[names(sc_dat)[3:end]]
		sc_tf = convert( Array{Union{Missing, Int64}, 2}, sc_tf)
		sc_tlabels = sc_dat[:ADMN_NICU]


	# loading models 
	println("re-loading models ", Dates.format(now(), "d/m/Y HH:MM"))
	model_tx = deserialize("/project/Lorch_project2018/bean/saved_model.jls")
	model_sc = deserialize("/project/Lorch_project2018/bean/sc_saved_model.jls")

	# running test 
	# Texas 
		output_tx = zeros(size(tx_tf, 1) , 2)
		for i = 1:size(output_tx,1)
			output_tx[i, 1] += tx_tlabels[i,1] # "adds" label value, which is 0/1
			output_tx[i, 2] += apply_forest(model_tx, tx_tf[i, :]) 
		end 
		println("TX number classified as admitted: ", sum(output_tx[:,2]))
		correct_tx = 1- sum(abs.(output_tx[:,1] .- output_tx[:,2]))/size(output_tx,1)
		println("TX correctly classified: ", correct_tx)
	# South Carolina 
		output_sc = zeros(size(sc_tf, 1) , 2)
		for i = 1:size(output_sc,1)
			output_sc[i, 1] += sc_tlabels[i,1] # "adds" label value, which is 0/1
			output_sc[i, 2] += apply_forest(model_tx, sc_tf[i, :]) 
		end 
		println("SC number classified as admitted: ", sum(output_sc[:,2]))
		correct_sc = 1- sum(abs.(output_sc[:,1] .- output_sc[:,2]))/size(output_sc,1)
		println("SC correctly classified: ", correct_sc)

end

Test_Models(1) 