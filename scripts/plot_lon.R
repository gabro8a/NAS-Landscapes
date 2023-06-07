#########################################################################
# Local Optima Network Analysis (LONs) for Neural Architecture Sarch (NAS) 
# Gabriela Ochoa and Nadarajen Veerapen
# June 2023 - Search Space Analysis Tutorial
# LONs For ILS sampled NAS Search Space
# Decorate and plot lon models
# Input:  R file with LONs  
# Output: pdf files with plots
#########################################################################
rm(list = ls(all = TRUE))
library(igraph) # Network analysis and visualisation
library(rgl)    # High level functions for 3D interactive graphics, 

inpath <- "lons/"        # input data
outpath <- "lon-plots/"  # lon plots

# Colors for nodes and edges
# LON  model has 3 types of perturbation edges: 3 Types: (i)mprovement, (e)qual, (w)orsening
pi_ecol <-  "gray40" # Opaque dark gray improvement edges
# alpha is for transparency: (as an opacity, 0 means fully transparent,  max (255) opaque)
pe_ecol <- rgb(0,0,250, max = 255, alpha = 150)  # transparent blue 
pw_ecol <- rgb(255,165,0, max = 255, alpha = 150)  # transparent orange
# node colors for global and local optima
g_ncol <- "red"  # Red
l_ncol <- rgb(128,128,128, max = 255, alpha = 180)  # transparent gray, local optima nodes
s_ncol <- "blue"  # color for sinks


# Legendes for plots
legend.txt <- c("Local", "Global", "Improving", "Equal", "Worsening") 
legend.bg <- c(l_ncol, g_ncol, pi_ecol, pe_ecol, pw_ecol)
legend.shape <- c(21,21,NA,NA,NA)  # Circles, NA for Lines
legend.lty <-  c(NA,NA,1,1,1)      # Line style
 

#----------------------------------------------------------------------------------------------------------------------------
# Plot Network in 2D. Either in the screen or as pdf file (if bpdf is True) 
# N:      Graph object
# nsizef:  node size factor, to increase or decrease node size
# ewidthf: edge  width factor, to increase or decrease width
# asize:  arrow size for plots
# ecurv:  curvature of the edges (0 = non curvature (ie. straight), 1 = max curvature)
# mylay:  graph layout as a parameter
# bleg:   Boolean TRUE for include a legend

plotLON <-function(N, nsizef, ewidthf, asize, ecurv, bleg) {
  nsize <- nsizef * V(N)$size
  ewidth <- ewidthf * E(N)$width
  lonlay <- layout.graphopt(N)  # you can select a different different layot.
  plot(N, layout = lonlay, vertex.label = NA,
       vertex.size = nsize, edge.width = ewidth, edge.arrow.size = asize, edge.curved = ecurv)
  if (bleg) {
   legend("topright", legend.txt, pch = legend.shape, pt.bg = legend.bg, col = legend.bg, 
         lty = legend.lty,  cex = 1, pt.cex = 1.3,  bty = "n")
  }     
}

#----------------------------------------------------------------------------------------------------------------------------
# Decorate LON object

decorateLON <-function(instance) {
  fname <- paste0(inpath,instance)
  load(fname, verbose = F)
  # Remove all the outgoing edges from the global optimum
  best_id <- which(V(LON)$Fitness==best)
  edge_ids <- incident(LON, best_id, mode = c( "out"))
  LON <- LON - edge_ids   # remove the otgoing edges from global optimum
  isolated  <-  which(degree(LON)==0)
  LON  <-  delete.vertices(LON, isolated)
  
  E(LON)$width <- sqrt(E(LON)$weight) + 0.2
  V(LON)$size <- sqrt(strength(LON, mode="in")) + 2
  #  Coloring Edges
  E(LON)$color[E(LON)$Type=="improving"] = pi_ecol  #Color of edges
  E(LON)$color[E(LON)$Type=="equal"] = pe_ecol
  E(LON)$color[E(LON)$Type=="worsening"] = pw_ecol
  
  # Coloring Nodes
  V(LON)$color <- ifelse(V(LON)$Fitness==best, g_ncol, l_ncol)
  V(LON)$vertex.frame.color <- ifelse(V(LON)$Fitness==best, "black",l_ncol) 
  return(LON)
}

#-------------------------------------------------------------------------------
# Plot Network in 3D
# N: Graph object
# ewidthf: factor for vector with 
# nsizef: factor to multiply for node sizes
# asize: arrow size for plots
# bSave: save 3d visualisation as html

plotLON_3D <-function(N, nsizef =1, ewidthf=1, asize=1, bSave = F) 
{
  ns <-  nsizef * V(N)$size
  ew <- ewidthf * E(N)$width
  
  zcoord <- V(N)$Fitness 
  lonlay <- layout.graphopt(N)  # you can select a different different layot.
  lay = cbind(lonlay, zcoord)
  open3d()
  bg3d("white")
  
  rglplot(N, layout = lay, vertex.label = NA, 
          vertex.size = ns, edge.width = ew,
          edge.arrow.size = asize)
  if (bSave) {
    # Save it to a file. and then open in browser
    filename <- tempfile(fileext = ".html")
    htmlwidgets::saveWidget(rglwidget(elementId = "plot3drgl"), filename)
    browseURL(filename)
  }
}
# ---- read files from folder, but process one at a time  ----------------

dataf <- list.files(inpath)  # in the given inpath folder
inst <- dataf[2]    # Select a file from the list

lon <- decorateLON(inst)

#### VISUALISATION ####
# Plot LON in Screen
plotLON(N = lon, nsizef = 1.8, ewidthf = 1.2, asize = 0.4, ecurv = 0.3, bleg = T)

# Plot LON in pdf file
iname <- substr(inst,1, nchar(inst)-5)
ofname <- paste0(outpath,iname,"pdf")
cairo_pdf(filename  = ofname,onefile = T)
plotLON(N = lon, nsizef = 1.8, ewidthf = 1.2,  asize = 0.4, ecurv = 0.3,  bleg = T)
dev.off()

# 3D visualisation

plotLON_3D(lon,1.5,1,1)
