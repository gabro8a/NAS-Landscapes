#########################################################################
# Local Optima Network Analysis (LONs) for Neural Architecture Sarch (NAS) 
# Gabriela Ochoa and Nadarajen Veerapen
# June 2023 - Search Space Analysis Tutorial
# LONs For ILS sampled NAS Search Space
# LON construction. 
# Input:  Zip file containing Nodes and Edges (traces from runs)
# Output: Save RData file containing LON model
#########################################################################
rm(list = ls(all = TRUE))
library(igraph) # Network analysis and visualisation
library(plyr)   # Splitting, Applying and Combining Data


# Location of input and output  
infolder ="data/lon/" 
lfolder  <- "lons/"     # folder to save lon models 


minimization = FALSE  # Since we are maximising accuracy, this is a maximisation problem

# Macros to use  according to minimisation or maximisation problem
if (minimization) {
  strictly.improving <- function(x, y) {x < y}
  strictly.worsening <- function(x, y) {x > y}
  non.deteriorating <- function(x, y) {x <= y}
  best.value <- function(z) {min(z)}
} else {
  strictly.improving <- function(x, y) {x > y}
  strictly.worsening <- function(x, y) {x < y}
  non.deteriorating <- function(x, y) {x >= y}
  best.value <- function(z) {max(z)}
}

# Creates LON Object  ----------------------------------------------------
# LON:    Complete set of Nodes and Edges
# number of runs to read from the input zip file, we are using all available
runs <- 100

# dara structures to keep raw data
lnodes <- vector("list", runs)
ledges <- vector("list", runs)


create_lon <- function(instance)  {
  zipname = paste0(infolder,instance) # file name with input data
  print(instance)
  for (i in (1:runs)) {
    tracef <- paste("run",i,".dat",sep="") 
    trace  <- read.table(unz(zipname,tracef), 
                         header=F, 
                         colClasses=c("double", "character", "double", "character"), 
                         stringsAsFactors = F)
    colnames(trace) <- c("fit1", "node1", "fit2", "node2")
    lnodes[[i]] <- rbind(setNames(trace[,c("node1","fit1")], c("Node", "Fitness")), 
                         setNames(trace[,c("node2","fit2")], c("Node", "Fitness")))
    ledges[[i]] <- trace[,c("node1", "node2")]
  }
  # combine the list of nodes into one dataframe and 
  # group by (Node,Fitness) to identify unique nodes and count them
  nodes <- ddply((do.call("rbind", lnodes)), .(Node,Fitness), nrow)
  colnames(nodes) <- c("Node", "Fitness", "Count")
  # combine the list of edges into one dataframe and
  # group by (node1,node2) to identify unique edges and count them
  edges <- ddply(do.call("rbind", ledges), .(node1,node2), nrow)
  colnames(edges) <- c("Start","End","Count")
  
  ## Create the LON
  LON <- graph_from_data_frame(d = edges, directed = T, vertices = nodes) # Create graph
  LON <- igraph::simplify(LON, remove.multiple = F)   # Remove self-loops
  
  ## Creation Identify improving and worsening edges
  ## get the list of edges and fitness values in order to filter
  el<-as_edgelist(LON)
  fits<-V(LON)$Fitness
  names<-V(LON)$name
  ## get the fitness values at each endpoint of an edge
  f1<-fits[match(el[,1],names)]
  f2<-fits[match(el[,2],names)]
  E(LON)[which(strictly.improving(f2,f1))]$Type = "improving"   # improving edges
  E(LON)[which(strictly.worsening(f2,f1))]$Type = "worsening"   # worsening edges
  E(LON)[which(f2==f1)]$Type = "equal"  # equal fitness edges
  
  E(LON)$weight <- E(LON)$Count   # Weights is the Count - How many times it was visited
  best <- best.value(fits)  # Global optimum value. 
  
  print(paste('LON: V:',vcount(LON), 'E:',ecount(LON)))
  
  # Calculate Number of global optima
  global_opt <- V(LON)[Fitness == best]   # ID of the Global Optimum
  nglobals <- length(global_opt)
  cat("nglobals: ", nglobals,"\n")
  
  # File name to save graph object and other useful variables
  dfile = paste0(lfolder,substr(instance, 1, nchar(instance)-3),"RData")
  # Save the LON object other useful variables
  save(LON, best, nglobals, minimization, file=dfile)
}

# ---- read all files in the given input folder ----------------
dataf <- list.files(infolder)

# Create lons for all data files int eh folder
lapply(dataf, create_lon)
