#########################################################################
# Local Optima Network Analysis (LONs) for Neural Architecture Sarch (NAS) 
# Gabriela Ochoa and Nadarajen Veerapen
# June 2023 - Search Space Analysis Tutorial
# Heatmaps showing the solutions (genotypes) as colored vectors
# Input:  Text file with the best or worst performance architectures
# Output: pdf files with plots
#########################################################################


library(ggplot2)    # grammar of graphic plotting 
library(reshape2)   # restructure and aggregate data  (melt function)
library(ggpubr)     # publication ready plots (ggarrange function)

# Location of input and output  
infolder ="data/genotype/" 
plfolder  <- "plots/"


# Colors for genotype that match figures in the paper
mycol <- c("#1071E5", "#6DB1FF", "#008A0E","#FC9432", "#E81313" )

fsize <- 15   # font size to use in images


# ----- function to produce the genotype map

gen_map <- function(instance) {
  dfile <- paste0(infolder,instance) 
  s <- read.csv(dfile,header=T, colClasses=c("character","numeric", "numeric"))
  s <- s[order(s$f_avg),]  # order by avg fitness
  sols <- as.vector(s$sol) 
  v <- sapply(sols, function(x) as.integer(strsplit(x,"")[[1]]))
  colnames(v) <- paste0("sol", 1:ncol(v))
  rownames(v) <- paste0("", 1:nrow(v))
  # convert wide to long format
  plotDat <- melt(v)
  colnames(plotDat) <- c("Sol","Op","value")
  bname <- substr(instance,1, nchar(instance)-4)
  aux <- strsplit(bname,"_")[[1]]
  tit <- aux[1]
  yl <- paste(aux[2], "1% cells")
  p <- ggplot(plotDat, aes(Sol, Op, fill= factor(value) )) + 
        geom_tile() +
        theme(axis.text.y=element_blank(), 
              axis.ticks.y=element_blank(),
              panel.grid.major = element_blank(), 
              panel.grid.minor = element_blank(),
              panel.background = element_blank()) +
        scale_fill_manual(values=mycol, labels = c("A", "B", "C", "D", "E")) +
        labs(fill="operations", x="", y=yl, title = tit) +
      theme(text = element_text(size = 15)) 
    return (p)
}

# ---- read all files in the given input folder ----------------
dataf <- list.files(infolder)

# Compute the first plot in the list

instance <- dataf[1]
p <- gen_map(instance)


# Save plot as PDF

foname <- paste0(plfolder,substr(instance,1, nchar(instance)-4),"_genmap.pdf")
ggsave(p, filename = foname,  device = cairo_pdf, width = 9, height = 8)

# Compute all plots in the list
ps <- lapply(dataf, gen_map)


# Create a combined figure with all the sub-plots (best and worst) per instance 
# The figure has 3 column: one for each dataset, and 2 rows: best and worst

maps <- ggarrange(ps[[1]], ps[[3]], ps[[5]],
                  ps[[2]], ps[[4]], ps[[6]],
                  common.legend = T,
                  ncol=3, nrow=2)

# Save plot as PDF
foname <- paste0(plfolder,"genotype_maps.pdf")

ggsave(maps, filename = foname,  device = cairo_pdf, width = 12, height = 8)



