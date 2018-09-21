# reading stata files for classification


#=  

- some packages.

Pkg.add("StatFiles")
Plg.add("Query")
=#

using DataFrames, StatFiles, Query, DecisionTree, ScikitLearn


# Load data 
df1 = DataFrame(load("/Users/austinbean/Google Drive/Texas Inpatient Discharge/Full Versions/2010 4 Quarter PUDF.dta"))

# column names:
names(df1)

# query just childbirth related into a new dataframe. 
x1 = @from i in df1 begin
	@where (i.apr_mdc == 14 || i.apr_mdc == 15)&(i.pat_age <= 1)&(i.apr_drg >=789 & i.apr_drg <=795 )
	@select {i.admitting_diagnosis, i.princ_diag_code, i.oth_diag_code_1, i.oth_diag_code_2, i.oth_diag_code_3, i.oth_diag_code_4, i.oth_diag_code_5, i.oth_diag_code_6, i.oth_diag_code_7, i.oth_diag_code_9, i.oth_diag_code_10, i.oth_diag_code_11, i.oth_diag_code_12, i.oth_diag_code_13, i.oth_diag_code_14, i.oth_diag_code_15, i.oth_diag_code_16, i.oth_diag_code_17, i.oth_diag_code_18, i.oth_diag_code_19, i.oth_diag_code_20, i.oth_diag_code_21, i.oth_diag_code_22, i.oth_diag_code_23, i.oth_diag_code_24, i.apr_drg }
	@collect DataFrame 
end



# slice the features out, convert to strings.  
features = convert(Array{Union{Missing, String}, 2}, x1[1:25])
features = string.(features)

# labels:
labels = convert(Array{Union{Missing, Int16}, 1}, x1[:apr_drg])


# model: 
mod1=DecisionTreeClassifier(max_depth = 3)

# fit: 

fit!(mod1, features, labels)


# probabilities?

println(get_classes(mod1))


# cross validation: 
using ScikitLearn.CrossValidation: cross_val_score
acc = cross_val_score(mod1, features, labels, cv=3)


"""
`Tab`
Like Stata's tab function.  
Returns unique values plus frequencies.
"""
function Tab(df::DataFrame, name::Symbol; noprint = false )
	if !isa(name, Symbol)
		println("Column names must be symbols")
		return 0
	end  
	try df[name]
	catch err1
		if err1 == KeyError 
			println("Column name not found.")
			return 0  
		else 
			# exists... good?  
		end 
	end 
	# want the type of the column element.  
	# start with Int64 because I know that works
	outp = Dict{Int64, Int64}()
	for el in df[name]
		if haskey(outp, el)
			outp[el] += 1
		else 
			outp[el] = 1
		end 
	end 
	if !noprint 
		println(" ***** Results ***** *****")
		println(" Item             Count")
		for k1 in keys(outp)
			println("| ", k1, "       ", outp[k1], "      |")
		end 
		println(" ***** ****** ****** ***** *****")
	end 
	return outp
end 


# model...
