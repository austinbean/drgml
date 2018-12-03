# Use the estimated TX model to predict the DRG.

using DataFrames, StatFiles, DecisionTree, ScikitLearn, Query, JLD2, DataValues


println("Loading Models")
#@load "/home/beanaus/models/modeldrg.jld2" modeldrg
@load "/home/beanaus/models/modelfull.jld2" model_full 
@load "/home/beanaus/models/model791.jld2" model791
@load "/home/beanaus/models/model793.jld2" model793 

println("Loading Data")
sc_dat = DataFrame(load("/home/beanaus/datacsv/sc_merged.dta"))


# The MSDRG is there!  Usual procedure will work.

#=
Running Option 0 - Predicting with MS DRG
Fraction 791 Correct: 0.6410211575450253
Fraction 793 Correct: 0.5617866004962779
=#  

# Option 0 - use MSDRG
# TODO - correct this for potentially missing ADMN_NICU
	println("Running Option 0 - Predicting with MS DRG")
	# 791
	x791 = @from i in sc_dat begin 
		@where (i.msdrg == 791)&&(!isna(i.ADMN_NICU))
		@select {i.ADMN_NICU, i.ADMITTING_DIAGNOSIS, i.PRINC_DIAG_CODE, i.OTH_DIAG_CODE_1, i.OTH_DIAG_CODE_2, i.OTH_DIAG_CODE_3, i.OTH_DIAG_CODE_4, i.OTH_DIAG_CODE_5, i.OTH_DIAG_CODE_6, i.OTH_DIAG_CODE_7, i.OTH_DIAG_CODE_8, i.OTH_DIAG_CODE_9, i.OTH_DIAG_CODE_10, i.OTH_DIAG_CODE_11, i.OTH_DIAG_CODE_12, i.OTH_DIAG_CODE_13 }
		@collect DataFrame
	end 

	# 793
	x793 = @from i in sc_dat begin 
		@where (i.msdrg == 793)&&(!isna(i.ADMN_NICU))
		@select {i.ADMN_NICU, i.ADMITTING_DIAGNOSIS, i.PRINC_DIAG_CODE, i.OTH_DIAG_CODE_1, i.OTH_DIAG_CODE_2, i.OTH_DIAG_CODE_3, i.OTH_DIAG_CODE_4, i.OTH_DIAG_CODE_5, i.OTH_DIAG_CODE_6, i.OTH_DIAG_CODE_7, i.OTH_DIAG_CODE_8, i.OTH_DIAG_CODE_9, i.OTH_DIAG_CODE_10, i.OTH_DIAG_CODE_11, i.OTH_DIAG_CODE_12, i.OTH_DIAG_CODE_13 }
		@collect DataFrame
	end

	# Now - use the models to predict admission and compare.  
	out_791 = zeros(size(x791,1),2)
	out_793 = zeros(size(x793,1),2)

	# Need to select out JUST the features of x791, x793 to use for prediction.  Also convert to string array.  
	# 791
	feat_791 = x791[names(x791)[2:end]]
	feat_791 = convert(Array{Union{Missing, String}, 2}, feat_791)
	feat_791 = string.(feat_791)
	# 793
	feat_793 = x793[names(x793)[2:end]]
	feat_793 = convert(Array{Union{Missing, String}, 2}, feat_793)
	feat_793 = string.(feat_793)

	for i = 1:size(x791,1)
		out_791[i,1] = x791[i,:ADMN_NICU]
		out_791[i,2] = parse(Float64, apply_forest(model791, feat_791[i,:]))
	end 
	correct_m791 = 1 - (sum(out_791[:,1].!=out_791[:,2])/size(x791,1))

	for i = 1:size(x793,1)
		out_793[i,1] = x793[i,:ADMN_NICU]
		out_793[i,2] = parse(Float64, apply_forest(model793, feat_793[i,:]))
	end 
	correct_m793 = 1 - (sum(abs.(out_793[:,1].!=out_793[:,2]))/size(x793,1))

println("Fraction 791 Correct (Partial Model): ", correct_m791)
println("Fraction 793 Correct (Partial Model): ", correct_m793)



#=
# OPTION 1 - predict the DRG, then predict NICU status.


# APR DRG V 20 Codes:
# https://www.hcup-us.ahrq.gov/db/nation/nis/APR-DRGsV20MethodologyOverviewandBibliography.pdf
	c_580 = "Neonate Transferred < 5 Days Not Born Here"
	c_581 = "Neonate Transferred < 5 5 Days Born Here"
	c_583 = "Neonate w/ ECMO"
	c_588 = "Neonate BWT < 1500 G W Major Procedure"
	c_589 = "Neonate BWT < 500 G"
	c_591 = "NEONATE BIRTHWT 500-749G W/O MAJOR PROCEDURE"
	c_593 = "NEONATE BIRTHWT 750-999G W/O MAJOR PROCEDURE"
	c_602 = "NEONATE BWT 1000-1249G W RESP DIST SYND/OTH MAJ RESP OR MAJ ANOM"
	c_603 = "NEONATE BIRTHWT 1000-1249G W OR W/O OTHER SIGNIFICANT CONDITION"
	c_607 = "NEONATE BWT 1250-1499G W RESP DIST SYND/OTH MAJ RESP OR MAJ ANOM"
	c_608 = "NEONATE BWT 1250-1499G W OR W/O OTHER SIGNIFICANT CONDITION"
	c_609 = "NEONATE BWT 1500-2499G W MAJOR PROCEDURE"
	c_611 = "NEONATE BIRTHWT 1500-1999G W MAJOR ANOMALY"
	c_612 = "NEONATE BWT 1500-1999G W RESP DIST SYND/OTH MAJ RESP COND"
	c_613 = "NEONATE BIRTHWT 1500-1999G W CONGENITAL/PERINATAL INFECTION"
	c_614 = "NEONATE BWT 1500-1999G W OR W/O OTHER SIGNIFICANT CONDITION"
	c_621 = "NEONATE BWT 2000-2499G W MAJOR ANOMALY"
	c_622 = "NEONATE BWT 2000-2499G W RESP DIST SYND/OTH MAJ RESP COND"
	c_623 = "NEONATE BWT 2000-2499G W CONGENITAL/PERINATAL INFECTION"
	c_625 = "NEONATE BWT 2000-2499G W OTHER SIGNIFICANT CONDITION"
	c_626 = "NEONATE BWT 2000-2499G, NORMAL NEWBORN OR NEONATE W OTHER PROBLEM"
	c_630 = "NEONATE BIRTHWT >2499G W MAJOR CARDIOVASCULAR PROCEDURE"
	c_631 = "NEONATE BIRTHWT >2499G W OTHER MAJOR PROCEDURE"
	c_633 = "NEONATE BIRTHWT >2499G W MAJOR ANOMALY"
	c_634 = "NEONATE, BIRTHWT >2499G W RESP DIST SYND/OTH MAJ RESP COND"
	c_636 = "NEONATE BIRTHWT >2499G W CONGENITAL/PERINATAL INFECTION"
	c_639 = "NEONATE BIRTHWT >2499G W OTHER SIGNIFICANT CONDITION"
	c_640 = "NEONATE BIRTHWT >2499G, NORMAL NEWBORN OR NEONATE W OTHER PROBLEM"


	df_n = DataFrame(BABY_ID = sc_dat[:BABY_ID], blank = zeros(Int64, size(sc_dat,1)))
	merg_d = join(df_n, sc_dat, on = :BABY_ID)

	for i = 1:size(sc_dat,1)
		merg_d[i,:blank] += parse(Int64, apply_forest(modeldrg, sc_dat[i, :]))
	end 
	# now there is a predicted DRG.  
	rename!(merg_d, :blank => :CMS_DRG)
	# NOW select on DRG.  Apply models.  
	# rename blank CMS_DRG
# DRG 791
	x791 = @from i in df_n begin 
		@where (i.CMS_DRG == 791)
		@select {i.ADMN_NICU, i.ADMITTING_DIAGNOSIS, i.PRINC_DIAG_CODE, i.OTH_DIAG_CODE_1, i.OTH_DIAG_CODE_2, i.OTH_DIAG_CODE_3, i.OTH_DIAG_CODE_4, i.OTH_DIAG_CODE_5, i.OTH_DIAG_CODE_6, i.OTH_DIAG_CODE_7, i.OTH_DIAG_CODE_8, i.OTH_DIAG_CODE_9, i.OTH_DIAG_CODE_10, i.OTH_DIAG_CODE_11, i.OTH_DIAG_CODE_12, i.OTH_DIAG_CODE_13, i.OTH_DIAG_CODE_14, i.OTH_DIAG_CODE_15, i.OTH_DIAG_CODE_16, i.OTH_DIAG_CODE_17, i.OTH_DIAG_CODE_18, i.OTH_DIAG_CODE_19, i.OTH_DIAG_CODE_20, i.OTH_DIAG_CODE_21, i.OTH_DIAG_CODE_22, i.OTH_DIAG_CODE_23, i.OTH_DIAG_CODE_24}
		@collect DataFrame
	end 

	features791 = x791[names(x791)[3:end]]
	f791 = convert( Array{Union{Missing, String}, 2}, features791)
	f791 = string.(f791)
	labels791 = x791[:ADMN_NICU]
	labels791 = [string(i) for i in skipmissing(labels791)]


	# Now with those selected...
	out_791 = zeros(size(x791, 1), 2)
	for i = 1:size(x791,1)
		out_791[i,1] = parse(Float64, apply_forest(model791, x791[i, :]) )
		out_791[i,2] = x791[i,:ADMN_NICU]
	end 
	correct_f791 = 1- sum(abs.(output_791[:,1] .- output_791[:,2]))/size(output_791,1)
	println("Fraction Correct in DRG 791: ", correct_f791)



# DRG 793
	x793 = @from i in df_n begin 
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


	# Now predict...
	output_793 = zeros(size(x793,1) , 2)
	for i = 1:size(x793,1)
		output_793[i, 1] = x793[i,:ADMN_NICU]
		output_793[i, 2] = parse(Float64, apply_forest(model793, x793[i, :]) )
	end 
	correct_f793 = 1- sum(abs.(output_793[:,1] .- output_793[:,2]))/size(output_793,1)
	println("Fraction Correct in DRG 793: ", correct_f793)




##############################################


# OPTION 2 - just predict NICU status for a subset of DRGs.

	xXYZ = @from i in df1 begin 
	#APDRG20
		@where (i.APDRG20 == 614)
		@select {i.ADMN_NICU, i.ADMITTING_DIAGNOSIS, i.PRINC_DIAG_CODE, i.OTH_DIAG_CODE_1, i.OTH_DIAG_CODE_2, i.OTH_DIAG_CODE_3, i.OTH_DIAG_CODE_4, i.OTH_DIAG_CODE_5, i.OTH_DIAG_CODE_6, i.OTH_DIAG_CODE_7, i.OTH_DIAG_CODE_8, i.OTH_DIAG_CODE_9, i.OTH_DIAG_CODE_10, i.OTH_DIAG_CODE_11, i.OTH_DIAG_CODE_12, i.OTH_DIAG_CODE_13, i.OTH_DIAG_CODE_14, i.OTH_DIAG_CODE_15, i.OTH_DIAG_CODE_16, i.OTH_DIAG_CODE_17, i.OTH_DIAG_CODE_18, i.OTH_DIAG_CODE_19, i.OTH_DIAG_CODE_20, i.OTH_DIAG_CODE_21, i.OTH_DIAG_CODE_22, i.OTH_DIAG_CODE_23, i.OTH_DIAG_CODE_24}
		@collect DataFrame
	end 

	featuresXYZ = xXYZ[names(xXYZ)[3:end]]
	fXYZ = convert( Array{Union{Missing, String}, 2}, featuresXYZ)
	fXYZ = string.(fXYZ)
	labelsXYZ = xXYZ[:ADMN_NICU]

	labelsXYZ = [string(i) for i in skipmissing(labelsXYZ)]

	output_xyz = zeros(size(xXYZ, 1),2)
	for i = 1:size(output_xyz, 1)
		output_xyz = xXYZ[i, :ADMN_NICU]
		output_xyz = parse(Float64, apply_forest(model793, xXYZ[i,:]))
	end 
	correct_f614 = 1- ( sum(abs.(output_xyz[:,1] .- output[:,2]))/size(output_xyz,1))

	println("Fraction Correct in DRG 614: ", correct_f614)

#############################################
=#


# OPTION 3 - predict NICU status using ALL data.  
	println("OPTION 3: predicting with full model, including comparison to partial.")

	xfull = @from i in sc_dat begin 
		@where !isna(i.ADMN_NICU) # ignores missing values.  Requires DataValues package.
		@select {i.ADMN_NICU, i.ADMITTING_DIAGNOSIS, i.PRINC_DIAG_CODE, i.OTH_DIAG_CODE_1, i.OTH_DIAG_CODE_2, i.OTH_DIAG_CODE_3, i.OTH_DIAG_CODE_4, i.OTH_DIAG_CODE_5, i.OTH_DIAG_CODE_6, i.OTH_DIAG_CODE_7, i.OTH_DIAG_CODE_8, i.OTH_DIAG_CODE_9, i.OTH_DIAG_CODE_10, i.OTH_DIAG_CODE_11, i.OTH_DIAG_CODE_12, i.OTH_DIAG_CODE_13 }
		@collect DataFrame
	end 

	out_full = zeros(size(xfull,1),2)

	feat_full = xfull[names(xfull)[2:end]]
	feat_full = convert(Array{Union{Missing, String}, 2}, feat_full)
	feat_full = string.(feat_full)


	for i = 1:size(xfull,1)
		out_full[i,1] = xfull[i,:ADMN_NICU]
		out_full[i,2] = parse(Float64, apply_forest(model_full, feat_full[i,:]))
	end 
	correct_ffull = 1 - (sum(abs.(out_full[:,1].-out_full[:,2]))/size(xfull,1))





# Where do the model predictions differ on the subsets...


	out_f791 = zeros(size(x791,1),3)
	for i = 1:size(x791,1)
		# First column: data
		out_f791[i,1] = x791[i,:ADMN_NICU]
		# Second column: prediction from full model
		out_f791[i,2] = parse(Float64, apply_forest(model_full, feat_791[i,:]))
		# Third column: prediction from drg 791 model
		out_f791[i,3] = parse(Float64, apply_forest(model791, feat_791[i,:]))
	end 
	correct_full791 = 1 - (sum(out_f791[:,1].!=out_f791[:,2])/size(out_f791,1))
	correct_p791 = 1 - (sum(out_f791[:,1].!=out_f791[:,3])/size(out_f791,1))

	out_f793 = zeros(size(x793,1),3)
	for i = 1:size(x793,1)
		# first column: data
		out_f793[i,1] = x793[i,:ADMN_NICU]
		# second column: prediction from full model
		out_f793[i,2] = parse(Float64, apply_forest(model_full, feat_793[i,:]))
		# third column: prediction from drg 793 model
		out_f793[i,3] = parse(Float64, apply_forest(model793, feat_793[i,:]))
	end 
	correct_full793 = 1 - (sum(out_f793[:,1].!=out_f793[:,2])/size(out_f793,1))
	correct_p793 = 1 - (sum(out_f793[:,1].!=out_f793[:,3])/size(out_f793,1))





	println(" ********* 791 **********")
	println("fraction correct using partial model for 791: ", correct_p791)
	println("fraction correct using full model for 791:    ", correct_full791)

	println(" ********* 793 **********")
	println("fraction correct using partial model for 793: ", correct_p793)
	println("fraction correct using full model for 793:    ", correct_full793)


#=
RESULTS:

OPTION 3: predicting with full model, including comparison to partial.
 ********* 791 **********
fraction correct using partial model for 791: 0.6410211575450253
fraction correct using full model for 791:    0.6759923063472635
 ********* 793 **********
fraction correct using partial model for 793: 0.5617866004962779
fraction correct using full model for 793:    0.6690818858560794

=#




#=
	function ctt(a::Array{Float64,2})
		dis = 0
		bet = 0
		for i = 1:size(a,1)
			if (a[i,1] == a[i,3])&(a[i,2] != a[i,1])
				bet += 1
			elseif (a[i,2] != a[i,3])
				dis += 1
			end 
		end 
		return dis, bet, bet/size(a,1)
	end 

	d791, b791, fb791 = ctt(out_f791)
	d793, b793, fb793 = ctt(out_f793)
=#




#=



	function misscount(x::Array{Union{Missing, T},1}) where T
		mc = 0
		for i = 1:size(x,1)
			if ismissing(x[i])
				mc += 1
			end 
		end 
		return mc 
	end 


	function predcor(m::Ensemble{String,String}, f::Array{String,2} , v::Array{Union{Missing, T},1}) where T 
		mc = 0
		tc = 0
		for i = 1:size(v,1)
			if !ismissing(v[i])
				tc += 1
				if (parse(Float64, apply_forest(m, f[i, :]) )) == (v[i])
					mc += 1
				end 
			end 
		end 
		return mc/tc  
	end 

	println("Fraction Correct Using Whole Model: ", predcor(model_full, feat_full, sc_dat[:ADMN_NICU]) )



	function DRGCT(f::Array{String,2})
		outp::Dict{Int64,Int64}()
		return 0
	end 


=#


#=
	for i = 1:size(sc_dat,1)
		if !ismissing(sc_dat[i,:ADMN_NICU])
			output_full[i, 1] = sc_dat[i, :ADMN_NICU]
			output_full[i, 2] = parse(Float64, apply_forest(model_full, feat_full[i, :]) )
		end
	end 
	println("missing count ", misscount(sc_dat[:ADMN_NICU]))
	correct_ffull = 1- (sum(abs.(output_full[:,1] .- output_full[:,2])))/(size(output_full,1) )

	println("Fraction Correct Using Whole Model: ", correct_ffull)
=#








#=

=#