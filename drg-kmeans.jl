

#=
using Pkg
Pkg.add("Clustering")
=#

#=
There is a trick here in that we need to check if an ICD9 appears in diagnoses 1-24 of each patient.
What is diagnosis 1 in one patient might be diagnosis 3 in another patient.
That's a pain.  But in principle doable.

First of all: define a distance -  this should be like the sum of discrete metrics:
So for each of the N DRG variables of record k, we define the distance with respect to that DRG between records
k and k'
1.  D_{DRG}(k, k', i) = 1 if DRG(k, i) ≂̸ DRG (k', j) for j = 1, ..., N
                    = 0 else.
    So we compare whatever is in DRG column i of record k with the DRGs in columns 1, ..., N of k'
    Is this a metric?
        - Reflexive: D_{DRG}(k, k') - careful... maybe isn't?  
        - Symmetric
        - Transitive.



2.  D_{\alpha} = ∑ ()
=#
