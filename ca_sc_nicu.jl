# CA, SC
#=
this uses the estimated random forest to predict admissions.
RF is in the file model_nicu.jld2
That file is generated in server_nicu_classifier.jl
scp  "/Users/austinbean/Desktop/drgml/ca_sc_nicu.jl" beanaus@hsrdcsub2.pmacs.upenn.edu:/project/Lorch_project2018/bean/
TODO - rerun this now that the SC data does not drop the admitting diagnosis.   Maybe it will give
better results.  

NOTE - requires use of Julia 1.1.0.  Load this by hand
=#


using DecisionTree
using DataFrames, StatFiles, ScikitLearn, Query, Dates, JLD2, CSVFiles, Serialization

println(VERSION)

function Predict(x::Int64)
	# now do this with deserialize 
		# Load NICU predictive model. 
	println("Deserialize  ", Dates.format(now(), "d/m/Y HH:MM"))
	modeln = deserialize("/project/Lorch_project2018/bean/saved_model.jls")

		# FYI need to rename a bunch of columns here?  No, don't think so.
	#df_ca = DataFrame(load("/project/Lorch_project2018/bean/ca_nicu_coll.csv"))

	df_sc = DataFrame(load("/project/Lorch_project2018/bean/sc_nicu_coll.csv"))
	# needs to be converted from a dataframe.  
	sc_a = convert( Array{Union{Missing, Int64}, 2}, df_sc)
	#ca_a = convert( Array{Union{Missing, Int64}, 2}, df_ca)

	# What's the correct column w/ nicu admission?  That needs to be below.  

	output_sc = zeros(size(df_sc,1) , 2)
	for i = 1:size(output_sc,1)
		output_sc[i, 1] += df_sc[i,1] # use baby id for now. XXXXXX FIXME XXXXXX [i]
		output_sc[i, 2] += apply_forest(modeln, sc_a[i, :]) 
	end 
	println("number classified as admitted: ", sum(output_sc[:,2]))
	correct_sc = 1- sum(abs.(output_sc[:,1] .- output_sc[:,2]))/size(output_sc,1)
	# It still seems like I'm getting only 154 categorized as admits???
	# this made it worse actually?  121 classified now?  

	# save SC output
	save("/project/Lorch_project2018/bean/sc_nicu_predicted.csv", output_sc)

	output_ca = zeros(size(df_ca, 1), 2) # record PID/status 

	for i = 1:size(output_ca, 1)
		output_ca[i,1] += df_ca[1,i]   
		output_ca[i,2] += apply_forest(modeln, ca_a[i,:]))
	end 

	# Write to CSV. 
	save("/project/Lorch_project2018/bean/ca_nicu_predicted.csv", output_ca)


end

Predict(0) 