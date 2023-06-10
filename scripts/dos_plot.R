#########################################################################
# Local Optima Network Analysis (LONs) for Neural Architecture Sarch (NAS) 
# Gabriela Ochoa and Nadarajen Veerapen
# June 2023 - Search Space Analysis Tutorial
# Density of States (DOS) plots
# Input:  Data file with accuracy (fitness function)
# Output: pdf files with plots
#########################################################################

# Check if required packages are installed or not. Install if required
packages <- c("ggplot2", "ggpubr", "data.table" )
if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(packages, rownames(installed.packages())))  
}

library(ggplot2)    # grammar of graphic plotting 
library(ggpubr)     # publication ready plots (ggarrange function)
library(data.table) # to facilitate data reading in table format (fread)

rm(list = ls(all.names = TRUE))  # Remove all objectes from previous work

# Location of input and output  
infolder ="data/accuracy/" 
plfolder  <- "plots/"

mycols <- c("sol","valid-accuracy")

# ---- Density of States plot  -------------------------------------

dos_plot <- function(instance) {
  fname <- paste0(infolder,instance)
  bname <- substr(instance,1, nchar(instance)-4)
  aux <- strsplit(bname,"_")[[1]]
  tit <- aux[1]
  xl <- paste0("f_", aux[2])
  mcol <- ifelse(xl == "f_avg", "#E81313", "#1071E5")
  sp <- fread(fname, sep = ",", select = mycols)
  colnames(sp) <-  c("sol","valid_acc")  # change names to "_"
  gp <-  ggplot(sp, aes(valid_acc)) +
    geom_freqpoly(binwidth=0.5, color = mcol) +
    labs(x=xl, title =tit)+
    theme(text = element_text(size = 15)) 
  return (gp)
}

# ---- read all files in the given input folder ----------------
dataf <- list.files(infolder)

# Compute the first plot in the list

instance <- dataf[1]
p <- dos_plot(instance)

# Save plot as PDF

foname <- paste0(plfolder,substr(instance,1, nchar(instance)-4),"_dos.pdf")
ggsave(p, filename = foname,  device = cairo_pdf, width = 9, height = 8)

# Compute all plots in the list
ps <- lapply(dataf, dos_plot)

# Create a combined figure with all the sub-plots (best and worst) per instance 
# The figure has 3 column: one for each dataset, and 2 rows: best and worst

dos <- ggarrange(ps[[2]], ps[[4]], ps[[6]],
                 ps[[1]], ps[[3]], ps[[5]],
                 ncol=3, nrow=2)

# Save plot as a pdf
foname <- paste0(plfolder,"dos.pdf")

ggsave(dos, filename = foname,  device = cairo_pdf, width = 12, height = 8)
