########################################################################################
#This script was written for the biogeographic analyses of Dahur, M. J. (2019)
#Special thanks to Gabriel S. Ferreira for helping with the script
#All files can be found at GitHub repository: https://github.com/jacobmurilo/Didelphidaemonograph
#We conducted ancestral area reconstruction and biogeographic stochastic mapping (BSM) on DEC, DEC+w, DIVALIKE, DIVALIKE+W, BAYAREALIKE AND BAYAREALIKE+w
#Using the package BioGeoBEARS (Matzke, 2013)
#Correspondece to: murillojacob@outlook.com
########################################################################################

# Loading necessary packages	#Install them if needed
#Use always the cloud-0 repository
library(GenSA)
library(FD)
library(snow)
library(parallel)
library(BioGeoBEARS)
library(roxygen2)
library(optimx) 

library(devtools)
devtools::install_github(repo='nmatzke/BioGeoBEARS', force = TRUE)

library(rexpokit)
library(cladoRcpp)
library(BioGeoBEARS)

#check version of optmix; if >2014 then OK
source("http://phylo.wdfiles.com/local--files/biogeobears/BioGeoBEARS_add_fossils_randomly_v1.R")
source("http://phylo.wdfiles.com/local--files/biogeobears/BioGeoBEARS_basics_v1.R")
source("http://phylo.wdfiles.com/local--files/biogeobears/BioGeoBEARS_calc_transition_matrices_v1.R")
source("http://phylo.wdfiles.com/local--files/biogeobears/BioGeoBEARS_classes_v1.R")
source("http://phylo.wdfiles.com/local--files/biogeobears/BioGeoBEARS_detection_v1.R")
source("http://phylo.wdfiles.com/local--files/biogeobears/BioGeoBEARS_DNA_cladogenesis_sim_v1.R")
source("http://phylo.wdfiles.com/local--files/biogeobears/BioGeoBEARS_extract_Qmat_COOmat_v1.R")
source("http://phylo.wdfiles.com/local--files/biogeobears/BioGeoBEARS_generics_v1.R")
source("http://phylo.wdfiles.com/local--files/biogeobears/BioGeoBEARS_models_v1.R")
source("http://phylo.wdfiles.com/local--files/biogeobears/BioGeoBEARS_on_multiple_trees_v1.R")
source("http://phylo.wdfiles.com/local--files/biogeobears/BioGeoBEARS_plots_v1.R")
source("http://phylo.wdfiles.com/local--files/biogeobears/BioGeoBEARS_readwrite_v1.R")
source("http://phylo.wdfiles.com/local--files/biogeobears/BioGeoBEARS_simulate_v1.R")
source("http://phylo.wdfiles.com/local--files/biogeobears/BioGeoBEARS_SSEsim_makePlots_v1.R")
source("http://phylo.wdfiles.com/local--files/biogeobears/BioGeoBEARS_SSEsim_v1.R")
source("http://phylo.wdfiles.com/local--files/biogeobears/BioGeoBEARS_stochastic_mapping_v1.R")
source("http://phylo.wdfiles.com/local--files/biogeobears/BioGeoBEARS_stratified_v1.R")
source("http://phylo.wdfiles.com/local--files/biogeobears/BioGeoBEARS_univ_model_v1.R")
source("http://phylo.wdfiles.com/local--files/biogeobears/calc_uppass_probs_v1.R")
source("http://phylo.wdfiles.com/local--files/biogeobears/calc_loglike_sp_v01.R")
source("http://phylo.wdfiles.com/local--files/biogeobears/get_stratified_subbranch_top_downpass_likelihoods_v1.R")
source("http://phylo.wdfiles.com/local--files/biogeobears/runBSM_v1.R")
source("http://phylo.wdfiles.com/local--files/biogeobears/stochastic_map_given_inputs.R")
source("http://phylo.wdfiles.com/local--files/biogeobears/summarize_BSM_tables_v1.R")
source("http://phylo.wdfiles.com/local--files/biogeobears/cladoRcpp.R") 
calc_loglike_sp = compiler::cmpfun(calc_loglike_sp_prebyte)
calc_independent_likelihoods_on_each_branch = compiler::cmpfun(calc_independent_likelihoods_on_each_branch_prebyte)

#Set the working directory
setwd(wd)
getwd()

#load the saved tree into BioGeoBEARS
trfn = np("tree.newick")

#Look again at the timetree
tr = read.tree(trfn)
tr
plot(tr)
axisPhylo()

#Load the geographic distribution file
geog = np("areas.data")
moref(geog)
#Look at your geographic range data
tipranges <- getranges_from_LagrangePHYLIP(lgdata_fn=geog)
tipranges

#Set the maximum number of areas any species may occupy
#this cannot be larger than the total number of areas on the geography file
max_range_size = 5

###################################################################################
#Set the models parameters
#For this analysis we ran two nested models (standard, +w) based on DEC
###################################################################################

###################################################################################
#Run DEC M0 (w=1)
###################################################################################
BioGeoBEARS_run_object = define_BioGeoBEARS_run()
BioGeoBEARS_run_object$force_sparse=FALSE    # sparse=FALSE causes pathology & isn't much faster at this scale
BioGeoBEARS_run_object$speedup=TRUE          # shorcuts to speed ML search; use FALSE if worried (e.g. >3 params)
BioGeoBEARS_run_object$use_optimx = 'GenSA'     # set as GenSA previously
BioGeoBEARS_run_object$calc_ancprobs=TRUE    # get ancestral states from optim run

# Set up a time-stratified analysis 
BioGeoBEARS_run_object$timesfn = "Timeperiods.txt"
BioGeoBEARS_run_object$dispersal_multipliers_fn = "Multiplier.txt"
BioGeoBEARS_run_object$areas_allowed_fn = "Areas_allowed.txt"

# Input the maximum range size
BioGeoBEARS_run_object$max_range_size = max_range_size

# Multicore processing if desired
BioGeoBEARS_run_object$num_cores_to_use=8

#Turn sparse matrix exponentiation off
BioGeoBEARS_run_object$force_sparse = FALSE

#Give BioGeoBEARS the location of the geography file
BioGeoBEARS_run_object$geogfn = geog

#Give BioGeoBEARS the location of the topology file
BioGeoBEARS_run_object$trfn = trfn

# Load the input files into the model object 
# (It also runs some checks on these inputs for certain errors.)
BioGeoBEARS_run_object = readfiles_BioGeoBEARS_run(BioGeoBEARS_run_object)

#Divide the tree up by timeperiods
BioGeoBEARS_run_object = section_the_tree(inputs=BioGeoBEARS_run_object, make_master_table=TRUE, plot_pieces=FALSE, cut_fossils = FALSE)
# Check the stratified tree description in this table:
BioGeoBEARS_run_object$master_table

# Default settings to get ancestral states
BioGeoBEARS_run_object$return_condlikes_table = TRUE
BioGeoBEARS_run_object$calc_TTL_loglike_from_condlikes_table = TRUE
BioGeoBEARS_run_object$calc_ancprobs = TRUE

# Set up DEC model
# Look at the BioGeoBEARS_run_object; it's just a list of settings etc.
BioGeoBEARS_run_object

# This contains the model object
BioGeoBEARS_run_object$BioGeoBEARS_model_object

# This table contains the parameters of the model 
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["d","min"]= 0.00000001 #tried to set as 0.01 due to NaN errors; they decreased but didn't ceased
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["e","min"]= 0.00000001 
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["d","max"]= 3 
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["e","max"]= 3

# Run this to check inputs. Read the error messages if you get them!
check_BioGeoBEARS_run(BioGeoBEARS_run_object)

#DEC M0: w=1
runslow = TRUE
resfn = "DEC_M0.Rdata"
if (runslow)
{
  res = bears_optim_run(BioGeoBEARS_run_object)
  res    
  
  save(res, file=resfn)
  resDEC = res
} else {
  # Loads to "res"
  load(resfn)
  resDEC = res
}

#######################################################
# Run M1 - DEC+w (w as free parameter)
#######################################################
BioGeoBEARS_run_object = define_BioGeoBEARS_run()
BioGeoBEARS_run_object$force_sparse=FALSE    # sparse=FALSE causes pathology & isn't much faster at this scale
BioGeoBEARS_run_object$speedup=TRUE          # shorcuts to speed ML search; use FALSE if worried (e.g. >3 params)
BioGeoBEARS_run_object$use_optimx = 'GenSA'     # set as GenSA previously
BioGeoBEARS_run_object$calc_ancprobs=TRUE    # get ancestral states from optim run

# Set up a time-stratified analysis 
BioGeoBEARS_run_object$timesfn = "Timeperiods.txt"
BioGeoBEARS_run_object$dispersal_multipliers_fn = "Multiplier.txt"
BioGeoBEARS_run_object$areas_allowed_fn = "Areas_allowed.txt"

# Input the maximum range size
BioGeoBEARS_run_object$max_range_size = max_range_size

# Multicore processing if desired
BioGeoBEARS_run_object$num_cores_to_use=8

#Turn sparse matrix exponentiation off
BioGeoBEARS_run_object$force_sparse = FALSE

#Give BioGeoBEARS the location of the geography file
BioGeoBEARS_run_object$geogfn = geog

#Give BioGeoBEARS the location of the topology file
BioGeoBEARS_run_object$trfn = trfn

# Load the input files into the model object 
# (It also runs some checks on these inputs for certain errors.)
BioGeoBEARS_run_object = readfiles_BioGeoBEARS_run(BioGeoBEARS_run_object)

#Divide the tree up by timeperiods
BioGeoBEARS_run_object = section_the_tree(inputs=BioGeoBEARS_run_object, make_master_table=TRUE, plot_pieces=FALSE, cut_fossils = FALSE)
# Check the stratified tree description in this table:
BioGeoBEARS_run_object$master_table

# Good default settings to get ancestral states
BioGeoBEARS_run_object$return_condlikes_table = TRUE
BioGeoBEARS_run_object$calc_TTL_loglike_from_condlikes_table = TRUE
BioGeoBEARS_run_object$calc_ancprobs = TRUE

# Set up DEC+w model
# Get the ML parameter values from the 2-parameter nested model
# (this will ensure that the 3-parameter model always does at least as good)
dstart = resDEC$outputs@params_table["d","est"]
estart = resDEC$outputs@params_table["e","est"]

# Input starting values for d, e  and define max and min
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["d","min"]= 0.00000001 
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["e","min"]= 0.00000001
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["d","max"]= 3 
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["e","max"]= 3
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["d","init"] = dstart
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["d","est"] = dstart
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["e","init"] = estart
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["e","est"] = estart

# Add w as a free parameter  and define max and min
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["w","type"]= "free"
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["w","min"]= 0.00000001
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["w","max"]= 3

check_BioGeoBEARS_run(BioGeoBEARS_run_object)

#DEC M1:  w=free
resfn = "DEC_M1.Rdata"
runslow = TRUE
if (runslow)
{
  #sourceall("C:\\R\\Sourceall")
  
  res = bears_optim_run(BioGeoBEARS_run_object)
  res    
  
  save(res, file=resfn)
  
  resDECw = res
} else {
  # Loads to "res"
  load(resfn)
  resDECw = res
}


#######################################################
# PDF plots
#######################################################
pdffn = "DEC.pdf"
pdf(pdffn, width=12.01, height=16.01)

#######################################################
# Plot ancestral states - M0 DEC
#######################################################
analysis_titletxt ="DEC M0 (w=1) Didelphidae"

# Setup
results_object = resDEC
scriptdir = np(system.file("extdata/a_scripts", package="BioGeoBEARS"))

# States
res2 = plot_BioGeoBEARS_results(results_object, analysis_titletxt, addl_params=list("w"), plotwhat="text", label.offset=0.45, tipcex=0.7, statecex=0.7, splitcex=0, titlecex=0.8, plotsplits=FALSE, cornercoords_loc=scriptdir, include_null_range=TRUE, tr=tr, tipranges=tipranges)

# Pie chart
plot_BioGeoBEARS_results(results_object, analysis_titletxt, addl_params=list("w"), plotwhat="pie", label.offset=0.45, tipcex=0, statecex=0.4, splitcex=0, titlecex=0.8, plotsplits=FALSE, cornercoords_loc=scriptdir, include_null_range=TRUE, tr=tr, tipranges=tipranges)

#######################################################
# Plot ancestral states - M1 DEC+w
#######################################################
analysis_titletxt ="DEC M1 (w=free) Didelphidae"

# Setup
results_object = resDECw
scriptdir = np(system.file("extdata/a_scripts", package="BioGeoBEARS"))

# States
res3 = plot_BioGeoBEARS_results(results_object, analysis_titletxt, addl_params=list("w"), plotwhat="text", label.offset=0.45, tipcex=0.7, statecex=0.7, splitcex=0, titlecex=0.8, plotsplits=FALSE, cornercoords_loc=scriptdir, include_null_range=TRUE, tr=tr, tipranges=tipranges)

# Pie chart
plot_BioGeoBEARS_results(results_object, analysis_titletxt, addl_params=list("w"), plotwhat="pie", label.offset=0.45, tipcex=0, statecex=0.4, splitcex=0, titlecex=0.8, plotsplits=FALSE, cornercoords_loc=scriptdir, include_null_range=TRUE, tr=tr, tipranges=tipranges)


dev.off()  # Turn off PDF
cmdstr = paste("open ", pdffn, sep="")
system(cmdstr) # Plot it

########################################################################
#DIVALIKE M0 and M1 models
########################################################################

#######################################################
# Run DIVALIKE M0
#######################################################
BioGeoBEARS_run_object = define_BioGeoBEARS_run()
BioGeoBEARS_run_object$force_sparse=FALSE    # sparse=FALSE causes pathology & isn't much faster at this scale
BioGeoBEARS_run_object$speedup=TRUE          # shorcuts to speed ML search; use FALSE if worried (e.g. >3 params)
BioGeoBEARS_run_object$use_optimx = 'GenSA'     # set as GenSA previously
BioGeoBEARS_run_object$calc_ancprobs=TRUE    # get ancestral states from optim run

# Set up a time-stratified analysis 
BioGeoBEARS_run_object$timesfn = "Timeperiods.txt"
BioGeoBEARS_run_object$dispersal_multipliers_fn = "Multiplier.txt"
BioGeoBEARS_run_object$areas_allowed_fn = "Areas_allowed.txt"

# Input the maximum range size
BioGeoBEARS_run_object$max_range_size = max_range_size

# Multicore processing if desired
BioGeoBEARS_run_object$num_cores_to_use=8

#Turn sparse matrix exponentiation off
BioGeoBEARS_run_object$force_sparse = FALSE

#Give BioGeoBEARS the location of the geography file
BioGeoBEARS_run_object$geogfn = geog

#Give BioGeoBEARS the location of the topology file
BioGeoBEARS_run_object$trfn = trfn

# Load the input files into the model object 
# (It also runs some checks on these inputs for certain errors.)
BioGeoBEARS_run_object = readfiles_BioGeoBEARS_run(BioGeoBEARS_run_object)

#Divide the tree up by timeperiods
BioGeoBEARS_run_object = section_the_tree(inputs=BioGeoBEARS_run_object, make_master_table=TRUE, plot_pieces=FALSE, cut_fossils = FALSE)
# Check the stratified tree description in this table:
BioGeoBEARS_run_object$master_table

# Good default settings to get ancestral states
BioGeoBEARS_run_object$return_condlikes_table = TRUE
BioGeoBEARS_run_object$calc_TTL_loglike_from_condlikes_table = TRUE
BioGeoBEARS_run_object$calc_ancprobs = TRUE

# Set up DIVALIKE (w=1) model
# Remove subset-sympatry
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["s","type"] = "fixed"
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["s","init"] = 0.0
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["s","est"] = 0.0

BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["ysv","type"] = "2-j"
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["ys","type"] = "ysv*1/2"
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["y","type"] = "ysv*1/2"
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["v","type"] = "ysv*1/2"

# Allow classic, widespread vicariance; all events equiprobable
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["mx01v","type"] = "fixed"
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["mx01v","init"] = 0.5
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["mx01v","est"] = 0.5

#Disactivate w
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["w","type"] = "fixed"
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["w","init"] = 1
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["w","est"] = 1

check_BioGeoBEARS_run(BioGeoBEARS_run_object)

#Run DIVALIKE M0: w=1
runslow = TRUE
resfn = "DIVALIKE_M0.Rdata"
if (runslow)
{
  res = bears_optim_run(BioGeoBEARS_run_object)
  res    
  
  save(res, file=resfn)
  resDIVALIKE = res
} else {
  # Loads to "res"
  load(resfn)
  resDIVALIKE = res
}

#######################################################
# Run DIVALIKE+w M1
#######################################################
BioGeoBEARS_run_object = define_BioGeoBEARS_run()
BioGeoBEARS_run_object$force_sparse=FALSE    # sparse=FALSE causes pathology & isn't much faster at this scale
BioGeoBEARS_run_object$speedup=TRUE          # shorcuts to speed ML search; use FALSE if worried (e.g. >3 params)
BioGeoBEARS_run_object$use_optimx = 'GenSA'     # set as GenSA previously
BioGeoBEARS_run_object$calc_ancprobs=TRUE    # get ancestral states from optim run

# Set up a time-stratified analysis 
BioGeoBEARS_run_object$timesfn = "Timeperiods.txt"
BioGeoBEARS_run_object$dispersal_multipliers_fn = "Multiplier.txt"
BioGeoBEARS_run_object$areas_allowed_fn = "Areas_allowed.txt"

# Input the maximum range size
BioGeoBEARS_run_object$max_range_size = max_range_size

# Multicore processing if desired
BioGeoBEARS_run_object$num_cores_to_use=8

#Turn sparse matrix exponentiation off
BioGeoBEARS_run_object$force_sparse = FALSE

#Give BioGeoBEARS the location of the geography file
BioGeoBEARS_run_object$geogfn = geog

#Give BioGeoBEARS the location of the topology file
BioGeoBEARS_run_object$trfn = trfn

# Load the input files into the model object 
# (It also runs some checks on these inputs for certain errors.)
BioGeoBEARS_run_object = readfiles_BioGeoBEARS_run(BioGeoBEARS_run_object)

#Divide the tree up by timeperiods
BioGeoBEARS_run_object = section_the_tree(inputs=BioGeoBEARS_run_object, make_master_table=TRUE, plot_pieces=FALSE, cut_fossils = FALSE)
# Check the stratified tree description in this table:
BioGeoBEARS_run_object$master_table

# Good default settings to get ancestral states
BioGeoBEARS_run_object$return_condlikes_table = TRUE
BioGeoBEARS_run_object$calc_TTL_loglike_from_condlikes_table = TRUE
BioGeoBEARS_run_object$calc_ancprobs = TRUE

# Set up DIVALIKE (w=1) model
# Remove subset-sympatry
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["s","type"] = "fixed"
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["s","init"] = 0.0
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["s","est"] = 0.0

BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["ysv","type"] = "2-j"
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["ys","type"] = "ysv*1/2"
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["y","type"] = "ysv*1/2"
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["v","type"] = "ysv*1/2"

# Allow classic, widespread vicariance; all events equiprobable
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["mx01v","type"] = "fixed"
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["mx01v","init"] = 0.5
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["mx01v","est"] = 0.5

# Add w as a free parameter  and define max and min
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["w","type"]= "free"
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["w","min"]= 0.00000001
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["w","max"]= 3

check_BioGeoBEARS_run(BioGeoBEARS_run_object)

#DIVALIKE M1: w=free 
runslow = TRUE
resfn = "DIVALIKE_M1.Rdata"
if (runslow)
{
  res = bears_optim_run(BioGeoBEARS_run_object)
  res    
  
  save(res, file=resfn)
  resDIVALIKEw = res
} else {
  # Loads to "res"
  load(resfn)
  resDIVALIKEw = res
}

#######################################################
# PDF plots
#######################################################
pdffn = "DIVA.pdf"
pdf(pdffn, width=12.01, height=16.01)

#######################################################
# Plot ancestral states - M0 DEC
#######################################################
analysis_titletxt ="DIVALIKE M0 (w=1) Didelphidae"

# Setup
results_object = resDIVALIKE
scriptdir = np(system.file("extdata/a_scripts", package="BioGeoBEARS"))

# States
res2 = plot_BioGeoBEARS_results(results_object, analysis_titletxt, addl_params=list("w"), plotwhat="text", label.offset=0.45, tipcex=0.7, statecex=0.7, splitcex=0, titlecex=0.8, plotsplits=FALSE, cornercoords_loc=scriptdir, include_null_range=TRUE, tr=tr, tipranges=tipranges)

# Pie chart
plot_BioGeoBEARS_results(results_object, analysis_titletxt, addl_params=list("w"), plotwhat="pie", label.offset=0.45, tipcex=0, statecex=0.4, splitcex=0, titlecex=0.8, plotsplits=FALSE, cornercoords_loc=scriptdir, include_null_range=TRUE, tr=tr, tipranges=tipranges)

#######################################################
# Plot ancestral states - M1 DIVALIKE+w
#######################################################
analysis_titletxt ="DIVALIKE M1 (w=free) Didelphidae"

# Setup
results_object = resDIVALIKEw
scriptdir = np(system.file("extdata/a_scripts", package="BioGeoBEARS"))

# States
res3 = plot_BioGeoBEARS_results(results_object, analysis_titletxt, addl_params=list("w"), plotwhat="text", label.offset=0.45, tipcex=0.7, statecex=0.7, splitcex=0, titlecex=0.8, plotsplits=FALSE, cornercoords_loc=scriptdir, include_null_range=TRUE, tr=tr, tipranges=tipranges)

# Pie chart
plot_BioGeoBEARS_results(results_object, analysis_titletxt, addl_params=list("w"), plotwhat="pie", label.offset=0.45, tipcex=0, statecex=0.4, splitcex=0, titlecex=0.8, plotsplits=FALSE, cornercoords_loc=scriptdir, include_null_range=TRUE, tr=tr, tipranges=tipranges)


dev.off()  # Turn off PDF
cmdstr = paste("open ", pdffn, sep="")
system(cmdstr) # Plot it


#######################################################
# BAYAREALIKE, BAYAREALIKE+X AND BAYAREALIKE+X+J ANALYSIS
#######################################################

# NOTE: As with DIVA, the BioGeoBEARS BayArea-like model is 
# not identical with the full Bayesian model implemented 
# in the "BayArea" program of Landis et al. (2013). 
#
# Instead, this is a simplified likelihood interpretation
# of the model.  Basically, in BayArea and BioGeoBEARS-BAYAREALIKE, 
# "d" and "e" work like they do in the DEC model of Lagrange 
# (and BioGeoBEARS), and then BayArea's cladogenesis assumption
# (which is that nothing in particular happens at cladogenesis) is 
# replicated by BioGeoBEARS.
#
# This leaves out 3 important things that are in BayArea:
# 1. Distance dependence (you can add this with a distances 
#    matrix + the "x" parameter in BioGeoBEARS, however)
# 2. A correction for disallowing "e" events that drive
#    a species extinct (a null geographic range)
# 3. The neat Bayesian sampling of histories, which allows
#    analyses on large numbers of areas.
#
# The main purpose of having a "BAYAREALIKE" model is 
# to test the importance of the cladogenesis model on 
# particular datasets. Does it help or hurt the data 
# likelihood if there is no special cladogenesis process?
# 
# I thus now call the model "BAYAREALIKE", and you should also. ;-)
# 

#######################################################
# Run BAYAREALIKE
#######################################################
BioGeoBEARS_run_object = define_BioGeoBEARS_run()
BioGeoBEARS_run_object$force_sparse=FALSE    # sparse=FALSE causes pathology & isn't much faster at this scale
BioGeoBEARS_run_object$speedup=TRUE          # shorcuts to speed ML search; use FALSE if worried (e.g. >3 params)
BioGeoBEARS_run_object$use_optimx = 'GenSA'     # set as GenSA previously
BioGeoBEARS_run_object$calc_ancprobs=TRUE    # get ancestral states from optim run

# Set up a time-stratified analysis 
BioGeoBEARS_run_object$timesfn = "Timeperiods.txt"
BioGeoBEARS_run_object$dispersal_multipliers_fn = "Multiplier.txt"
BioGeoBEARS_run_object$areas_allowed_fn = "Areas_allowed.txt"

# Input the maximum range size
BioGeoBEARS_run_object$max_range_size = max_range_size

# Multicore processing if desired
BioGeoBEARS_run_object$num_cores_to_use=8

#Turn sparse matrix exponentiation off
BioGeoBEARS_run_object$force_sparse = FALSE

#Give BioGeoBEARS the location of the geography file
BioGeoBEARS_run_object$geogfn = geog

#Give BioGeoBEARS the location of the topology file
BioGeoBEARS_run_object$trfn = trfn

# Load the input files into the model object 
# (It also runs some checks on these inputs for certain errors.)
BioGeoBEARS_run_object = readfiles_BioGeoBEARS_run(BioGeoBEARS_run_object)

#Divide the tree up by timeperiods
BioGeoBEARS_run_object = section_the_tree(inputs=BioGeoBEARS_run_object, make_master_table=TRUE, plot_pieces=FALSE, cut_fossils = FALSE)
# Check the stratified tree description in this table:
BioGeoBEARS_run_object$master_table

# Good default settings to get ancestral states
BioGeoBEARS_run_object$return_condlikes_table = TRUE
BioGeoBEARS_run_object$calc_TTL_loglike_from_condlikes_table = TRUE
BioGeoBEARS_run_object$calc_ancprobs = TRUE


# Set up BAYAREALIKE model
# No subset sympatry
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["s","type"] = "fixed"
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["s","init"] = 0.0
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["s","est"] = 0.0

# No vicariance
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["v","type"] = "fixed"
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["v","init"] = 0.0
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["v","est"] = 0.0

# Adjust linkage between parameters
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["ysv","type"] = "1-j"
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["ys","type"] = "ysv*1/1"
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["y","type"] = "1-j"

# Only sympatric/range-copying (y) events allowed, and with 
# exact copying (both descendants always the same size as the ancestor)
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["mx01y","type"] = "fixed"
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["mx01y","init"] = 0.9999
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["mx01y","est"] = 0.9999

# Distance factor x = 1
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["w","init"] = 1
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["w","est"] = 1


# Check the inputs
check_BioGeoBEARS_run(BioGeoBEARS_run_object)

#BAYAREALIKE M0 w=1
runslow = TRUE
resfn = "BAYAREALIKE_M0.Rdata"
if (runslow)
{
  res = bears_optim_run(BioGeoBEARS_run_object)
  res    
  
  save(res, file=resfn)
  resBAYAREALIKE = res
} else {
  # Loads to "res"
  load(resfn)
  resBAYAREALIKE = res
}



#######################################################
# Run BAYAREALIKE +w free
#######################################################
BioGeoBEARS_run_object = define_BioGeoBEARS_run()
BioGeoBEARS_run_object$force_sparse=FALSE    # sparse=FALSE causes pathology & isn't much faster at this scale
BioGeoBEARS_run_object$speedup=TRUE          # shorcuts to speed ML search; use FALSE if worried (e.g. >3 params)
BioGeoBEARS_run_object$use_optimx = 'GenSA'     # set as GenSA previously
BioGeoBEARS_run_object$calc_ancprobs=TRUE    # get ancestral states from optim run

# Set up a time-stratified analysis 
BioGeoBEARS_run_object$timesfn = "Timeperiods.txt"
BioGeoBEARS_run_object$dispersal_multipliers_fn = "Multiplier.txt"
BioGeoBEARS_run_object$areas_allowed_fn = "Areas_allowed.txt"

# Input the maximum range size
BioGeoBEARS_run_object$max_range_size = max_range_size

# Multicore processing if desired
BioGeoBEARS_run_object$num_cores_to_use=8

#Turn sparse matrix exponentiation off
BioGeoBEARS_run_object$force_sparse = FALSE

#Give BioGeoBEARS the location of the geography file
BioGeoBEARS_run_object$geogfn = geog

#Give BioGeoBEARS the location of the topology file
BioGeoBEARS_run_object$trfn = trfn

# Load the input files into the model object 
# (It also runs some checks on these inputs for certain errors.)
BioGeoBEARS_run_object = readfiles_BioGeoBEARS_run(BioGeoBEARS_run_object)

#Divide the tree up by timeperiods
BioGeoBEARS_run_object = section_the_tree(inputs=BioGeoBEARS_run_object, make_master_table=TRUE, plot_pieces=FALSE, cut_fossils = FALSE)
# Check the stratified tree description in this table:
BioGeoBEARS_run_object$master_table

# Good default settings to get ancestral states
BioGeoBEARS_run_object$return_condlikes_table = TRUE
BioGeoBEARS_run_object$calc_TTL_loglike_from_condlikes_table = TRUE
BioGeoBEARS_run_object$calc_ancprobs = TRUE

# Set up BAYAREALIKE model
# No subset sympatry
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["s","type"] = "fixed"
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["s","init"] = 0.0
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["s","est"] = 0.0

# No vicariance
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["v","type"] = "fixed"
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["v","init"] = 0.0
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["v","est"] = 0.0

# Adjust linkage between parameters
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["ysv","type"] = "1-j"
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["ys","type"] = "ysv*1/1"
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["y","type"] = "1-j"

# Only sympatric/range-copying (y) events allowed, and with 
# exact copying (both descendants always the same size as the ancestor)
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["mx01y","type"] = "fixed"
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["mx01y","init"] = 0.9999
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["mx01y","est"] = 0.9999

# Distance factor w free
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["w","type"] = "free"
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["w","init"] = 0.0001
BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["w","est"] = 0.0001


# Check the inputs
check_BioGeoBEARS_run(BioGeoBEARS_run_object)

#BAYAREALIKE M1 x=free; j=0
runslow = TRUE
resfn = "BAYAREALIKE-M1.Rdata"
if (runslow)
{
  res = bears_optim_run(BioGeoBEARS_run_object)
  res    
  
  save(res, file=resfn)
  resBAYAREALIKEw = res
} else {
  # Loads to "res"
  load(resfn)
  resBAYAREALIKEw = res
}

#######################################################
# PDF plots
#######################################################
pdffn = "BAYAREA.pdf"
pdf(pdffn, width=12.01, height=16.01)

#######################################################
# Plot ancestral states - M0 BAYAREA
#######################################################
analysis_titletxt ="BAYAREALIKE M0 (w=1) Didelphidae"

# Setup
results_object = resBAYAREALIKE
scriptdir = np(system.file("extdata/a_scripts", package="BioGeoBEARS"))

# States
res2 = plot_BioGeoBEARS_results(results_object, analysis_titletxt, addl_params=list("w"), plotwhat="text", label.offset=0.45, tipcex=0.7, statecex=0.7, splitcex=0, titlecex=0.8, plotsplits=FALSE, cornercoords_loc=scriptdir, include_null_range=TRUE, tr=tr, tipranges=tipranges)

# Pie chart
plot_BioGeoBEARS_results(results_object, analysis_titletxt, addl_params=list("w"), plotwhat="pie", label.offset=0.45, tipcex=0, statecex=0.4, splitcex=0, titlecex=0.8, plotsplits=FALSE, cornercoords_loc=scriptdir, include_null_range=TRUE, tr=tr, tipranges=tipranges)

#######################################################
# Plot ancestral states - M1 BAYAREALIKE+w
#######################################################
analysis_titletxt ="BAYAREALIKE M1 (w=free) Didelphidae"

# Setup
results_object = resBAYAREALIKEw
scriptdir = np(system.file("extdata/a_scripts", package="BioGeoBEARS"))

# States
res3 = plot_BioGeoBEARS_results(results_object, analysis_titletxt, addl_params=list("w"), plotwhat="text", label.offset=0.45, tipcex=0.7, statecex=0.7, splitcex=0, titlecex=0.8, plotsplits=FALSE, cornercoords_loc=scriptdir, include_null_range=TRUE, tr=tr, tipranges=tipranges)

# Pie chart
plot_BioGeoBEARS_results(results_object, analysis_titletxt, addl_params=list("w"), plotwhat="pie", label.offset=0.45, tipcex=0, statecex=0.4, splitcex=0, titlecex=0.8, plotsplits=FALSE, cornercoords_loc=scriptdir, include_null_range=TRUE, tr=tr, tipranges=tipranges)


dev.off()  # Turn off PDF
cmdstr = paste("open ", pdffn, sep="")
system(cmdstr) # Plot it

#########################################################################
#########################################################################
# 
# CALCULATE SUMMARY STATISTICS TO COMPARE
# DEC, DEC+w, DIVALIKE, DIVALIKE+w, BAYAREALIKE, BAYAREALIKE+w
# 
#########################################################################
#########################################################################

# Set up empty tables to hold the statistical results
restable = NULL
teststable = NULL

#######################################################
# Statistics -- DEC vs. DEC+w
#######################################################
# Extract the log-likelihood
LnL_2 = get_LnL_from_BioGeoBEARS_results_object(resDEC)
LnL_1 = get_LnL_from_BioGeoBEARS_results_object(resDECw)

numparams1 = 3
numparams2 = 2
stats = AICstats_2models(LnL_1, LnL_2, numparams1, numparams2)
stats

# DEC, null model for Likelihood Ratio Test (LRT)
res2 = extract_params_from_BioGeoBEARS_results_object(results_object=resDEC, returnwhat="table", addl_params=c("w"), paramsstr_digits=4)
# DEC+w, alternative model for Likelihood Ratio Test (LRT)
res1 = extract_params_from_BioGeoBEARS_results_object(results_object=resDECw, returnwhat="table", addl_params=c("w"), paramsstr_digits=4)

# The null hypothesis for a Likelihood Ratio Test (LRT) is that two models
# confer the same likelihood on the data. See: Brian O'Meara's webpage:
# http://www.brianomeara.info/tutorials/aic
# ...for an intro to LRT, AIC, and AICc

rbind(res2, res1)
tmp_tests = conditional_format_table(stats)

restable = rbind(restable, res2, res1)
teststable = rbind(teststable, tmp_tests)

#######################################################
# Statistics -- DIVALIKE vs. DIVALIKE+w
#######################################################
# Extract the log-likelihood
# Extract the log-likelihood
LnL_2 = get_LnL_from_BioGeoBEARS_results_object(resDIVALIKE)
LnL_1 = get_LnL_from_BioGeoBEARS_results_object(resDIVALIKEw)

numparams1 = 3
numparams2 = 2
stats = AICstats_2models(LnL_1, LnL_2, numparams1, numparams2)
stats

# DIVALIKE, null model for Likelihood Ratio Test (LRT)
res2 = extract_params_from_BioGeoBEARS_results_object(results_object=resDIVALIKE, returnwhat="table", addl_params=c("w"), paramsstr_digits=4)
# DIVALIKE+w, alternative model for Likelihood Ratio Test (LRT)
res1 = extract_params_from_BioGeoBEARS_results_object(results_object=resDIVALIKEw, returnwhat="table", addl_params=c("w"), paramsstr_digits=4)

# The null hypothesis for a Likelihood Ratio Test (LRT) is that two models
# confer the same likelihood on the data. See: Brian O'Meara's webpage:
# http://www.brianomeara.info/tutorials/aic
# ...for an intro to LRT, AIC, and AICc

rbind(res2, res1)
tmp_tests = conditional_format_table(stats)

restable = rbind(restable, res2, res1)
teststable = rbind(teststable, tmp_tests)

#######################################################
# Statistics -- BAYAREALIKE vs. BAYAREALIKE+w
#######################################################
# Extract the log-likelihood
LnL_2 = get_LnL_from_BioGeoBEARS_results_object(resBAYAREALIKE)
LnL_1 = get_LnL_from_BioGeoBEARS_results_object(resBAYAREALIKEw)

numparams1 = 3
numparams2 = 2
stats = AICstats_2models(LnL_1, LnL_2, numparams1, numparams2)
stats

# DEC, null model for Likelihood Ratio Test (LRT)
res2 = extract_params_from_BioGeoBEARS_results_object(results_object=resBAYAREALIKE, returnwhat="table", addl_params=c("w"), paramsstr_digits=4)
# DEC+w, alternative model for Likelihood Ratio Test (LRT)
res1 = extract_params_from_BioGeoBEARS_results_object(results_object=resBAYAREALIKEw, returnwhat="table", addl_params=c("w"), paramsstr_digits=4)

# The null hypothesis for a Likelihood Ratio Test (LRT) is that two models
# confer the same likelihood on the data. See: Brian O'Meara's webpage:
# http://www.brianomeara.info/tutorials/aic
# ...for an intro to LRT, AIC, and AICc

rbind(res2, res1)
tmp_tests = conditional_format_table(stats)

restable = rbind(restable, res2, res1)
teststable = rbind(teststable, tmp_tests)


#########################################################################
# RESULTS: DEC, DEC+w, DIVALIKE, DIVALIKE+w, BAYAREALIKE, BAYAREALIKE+W
#########################################################################
teststable$alt = c("DEC+w", "DIVALIKE+w", "BAYAREALIKE+w")
teststable$null = c("DEC", "DIVALIKE", "BAYAREALIKE")
row.names(restable) = c("DEC", "DEC+w", "DIVALIKE", "DIVALIKE+w", "BAYAREALIKE", "BAYAREALIKE+w")

# Look at the results
restable
teststable

#######################################################
# Save the results tables
#######################################################

# Loads to "restable"
save(restable, file="restable_x1.Rdata")
load(file="restable_x1.Rdata")

# Loads to "teststable"
save(teststable, file="teststable_x1.Rdata")
load(file="teststable_x1.Rdata")

# Also save to text files
write.table(restable, file="restablex1.txt", quote=FALSE, sep="\t")
write.table(unlist_df(teststable), file="teststablex1.txt", quote=FALSE, sep="\t")

#######################################################
# Model weights of all three models
#######################################################
restable2 = restable

# With AICs:
AIC = calc_AIC_column(LnL_vals=restable$LnL, nparam_vals=restable$numparams)
restable = cbind(restable, AIC)
restable = AkaikeWeights_on_summary_table(restable=restable, colname_to_use="AIC")
restable

rellike_AIC = restable$AIC_wt / sum(restable$AIC_wt)
restable_AIC_rellike = cbind(restable, rellike_AIC)

# With AICcs -- factors in sample size
samplesize = length(tr$tip.label)
AIC = calc_AICc_column(LnL_vals=restable$LnL, nparam_vals=restable$numparams, samplesize=samplesize)
restable2 = cbind(restable2, AIC)
restable2 = AkaikeWeights_on_summary_table(restable=restable2, colname_to_use="AIC")
restable2
names(restable2) = c("LnL", "numparams", "d", "e", "w", "AICc", "AICc_wt_vBest")
rellike_AICc = restable2$AICc_wt_vBest / sum(restable2$AICc_wt_vBest)
restable_AICc_rellike = cbind(restable2, rellike_AICc)

# Also save to text files
write.table(restable_AIC_rellike, file="restable_AIC_rellikex1.txt", quote=FALSE, sep="\t")
write.table(restable_AICc_rellike, file="restable_AICc_rellikex1.txt", quote=FALSE, sep="\t")


#END
