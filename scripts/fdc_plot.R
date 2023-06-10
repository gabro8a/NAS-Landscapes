#########################################################################
# Fitness landscape analysis for Neural Architecture Sarch (NAS) 
# Gabriela Ochoa and Nadarajen Veerapen
# June 2023 - Search Space Analysis Tutorial
# Fitness distance correlation plots (fdc) solutions and accuracy metrics
# Input:  Data file with solutions (genotypes) and accuracy (fitness function)
# Output: pdf files with fdc plots
#########################################################################

library(stringdist)  # for string distance calculation (Hamming distance)
library(ggplot2)     # grammar of graphic plotting 
library(ggpubr)      # publication ready plots (ggarrange function)
library(data.table)  # to facilitate data reading in table format

rm(list = ls(all.names = TRUE))  # Remove all objectes from previous work


# Location of input and output  
infolder ="data/accuracy/" 
plfolder  <- "plots/"

fsize <- 15   # font size to use in images

mycols <- c("sol", "valid-accuracy") # Select only the relevant columns 

# ---- Fitness distance correlation plot  for Accuracy  --------------

fdc_acc <- function(instance)  {
  fname <- paste0(infolder,instance)
  sp <- fread(fname, sep = ",", select = mycols)
  colnames(sp) <-  c("sol", "valid_accuracy")   # change field names, use under_score "_"
  best_acc <-max(sp$valid_accuracy)   #  best accuracy - Global optimum -- maximisation
  best_sol <- sp$sol[sp$valid_accuracy == best_acc][1] # best solution genotype (take first if there are more than one)
  bname <- substr(instance,1, nchar(instance)-4)  # Take instance name without extension
  plab <- strsplit(bname,"_")[[1]]
  ylab <- paste0("f_",plab[2])
  
  # Add Hamming Distance to global as a column
  if (length(best_sol) > 1) {
    # Since there are several global optima, compute distance to all the optimal solutions and take the min
    dmat <-  sapply(best_sol,stringdist, b=sp$sol, method = "hamming")
    sp$hd <- apply(dmat, 1,min) # take the distance to the closest global optimum
  } else {  # for a single global optimum there is a single distance
    sp$hd <- stringdist(best_sol, sp$sol, method ="hamming")  # Hamming distance to  best
  }
  
  mcol <- ifelse(ylab == "f_avg", "#E81313", "#1071E5")     # Different colors for the two fitness functions 
  a <- ggscatter(sp, x = "hd", y = "valid_accuracy", repel = T,
                 add = "reg.line", conf.int = TRUE, 
                 cor.coef.size = 4.5, 
                 cor.coef.coord = c(0,min(sp$valid_accuracy) + 4),  # placement of corrlation coefficient
                 cor.coef = TRUE, cor.method = "spearman",
                 xlab = "Hamming distance", ylab = ylab,
                 size = 1.2, shape = 21, title = plab[1], color = mcol) +
      theme(text = element_text(size = fsize)) 
  
  return (a)
}

# ---- read all files in the given input folder ----------------
dataf <- list.files(infolder)

# Compute the first plot in the list

instance <- dataf[1]
p <- fdc_acc(instance)

# Save plot as PDF

foname <- paste0(plfolder,substr(instance,1, nchar(instance)-4),"_fdc.pdf")
ggsave(p, filename = foname,  device = cairo_pdf, width = 9, height = 8)


# Compute all plots in the list
ps <- lapply(dataf, fdc_acc)

# Create a combined figure with all the sub-plots (best and worst) per instance 
# The figure has 3 column: one for each dataset, and 2 rows: best and worst

fdc <- ggarrange(ps[[2]], ps[[4]], ps[[6]],
                ps[[1]], ps[[3]], ps[[5]],
                ncol=3, nrow=2)

# Save plot as a png file as the pdf will bee too large
foname <- paste0(plfolder,"fdc.png")

ggsave(fdc, filename = foname,  device = png, width = 12, height = 8)




