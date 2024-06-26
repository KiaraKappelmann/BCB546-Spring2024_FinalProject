
`is.outlier` <- function (x,mcut=6.2) {
  y <- na.omit(x)
  lims <- median(y) + c(-1, 1) * mcut * mad(y, constant = 1)
  for(j in 1:length(x)){
    if(is.na(x[j]) | x[j] < lims[1] | x[j] > lims[2]){
      x[j] <- NA
    }
  }
  return(x)	
}

#########################################

`outlierRemoveDataset` <- function (x,mcut=6.2,by=NA,cols){
  for(i in cols){
    if(is.na(by)){
      x[,i] <- is.outlier(x[,i],mcut)
    }else{
      for(j in unique(x[,by])){
        if(is.na(j)){
          x[is.na(x[,by]), i] <- is.outlier(x[is.na(x[,by]), i],mcut)
        }else{
          x[x[,by] == j & !(is.na(x[,by])), i] <- is.outlier(x[x[,by] == j & !(is.na(x[,by])), i],mcut)
        }
      }
    }
  }
  return(x)
}

#This will calculate the rsd breaks of ICP-MS runs for data points

`scatterPlot` <- function(scatter,rsd=NA,shape=NA,main,xlab="Sample No.",ylab="Concentration",runBreaks=NA){
  suppressPackageStartupMessages(require(ggplot2))
  suppressPackageStartupMessages(require(grid))
  data <- data.frame(scatter = scatter,rsd = rsd, shape = shape)  
  smooth <- stats::lowess(na.omit(data[,1]),f=0.1)$y
  if(any(is.na(data$scatter))){
    for(na.val in which(is.na(data$scatter))){
      smooth <- append(smooth,NA,after=na.val-1)
    }
  }
  data$smooth <- smooth
  if(!sum(is.na(data$rsd))==length(data$rsd)){
    data$colorCol <- cut(as.numeric(data$rsd),breaks=c(2*(0:5),Inf),labels=c("<2","2-4","4-6","6-8","8-10",">10"),include.lowest=TRUE)
  }
  data$x <- 1:nrow(data)
  p1 <- ggplot(data=data,aes(x=x,y=scatter))  
  if(!sum(is.na(data$rsd))==length(data$rsd) & !sum(is.na(data$shape))==length(data$shape)){ #both shape and rsd
    p1 <- p1 + geom_point(aes(colour=colorCol,shape=shape))
    p1 <- p1 + scale_colour_manual(values=colorRampPalette(c("#00007F", "blue", "#007FFF", "cyan","#7FFF7F", "yellow", "#FF7F00", "red", "#7F0000"))(7),name="RSD")
    p1 <- p1 + scale_shape_manual(name = "Type", values = c(17,16))      
  }else if(!sum(is.na(data$rsd))==length(data$rsd)){ #only rsd
    p1 <- p1 + geom_point(aes(colour=colorCol))
    p1 <- p1 + scale_colour_manual(values=colorRampPalette(c("#00007F", "blue", "#007FFF", "cyan","#7FFF7F", "yellow", "#FF7F00", "red", "#7F0000"))(7),name="RSD")      
  }else if(!sum(is.na(data$shape))==length(data$shape)){ #only shape
    p1 <- p1 + geom_point(aes(shape=shape))
    p1 <- p1 + scale_shape_manual(name = "Type", values = c(17,16))
  }else{ #neither
    p1 <- p1 + geom_point()
  }
  if(nrow(data) > 50){
    p1 <- p1 + geom_line(aes(y=smooth),size=1.3,colour="blue")
  }
  p1 <- p1 + labs(x = xlab,y = ylab,title = main)
  p1 <- p1 + theme(legend.background=element_rect(),legend.position="bottom",legend.box="horizontal",legend.direction="horizontal")
  p1 <- p1 + scale_x_continuous(limits=c(0,nrow(data)),expand=c(0,0))
  if(!is.na(runBreaks)){
    p1 <- p1 + geom_vline(xintercept = runBreaks)
  }
  p1 <- p1 + geom_hline(yintercept = mean(data[,1],na.rm=TRUE),colour="red",size=1)
  #print(p1)
  return(p1)
  #grid.text(0.2, unit(0.035,"npc"), label=paste("mean=",signif(mean(data[,1],na.rm=TRUE),2),sep=""),gp=gpar(col="red",fontsize=12))
}

# Multiple plot function
#
# I did not write this function, it is from:
# http://wiki.stdout.org/rcookbook/Graphs/Multiple%20graphs%20on%20one%20page%20%28ggplot2%29/
#
# ggplot objects can be passed in ..., or to plotlist (as a list of ggplot objects)
# - cols:   Number of columns in layout
# - layout: A matrix specifying the layout. If present, 'cols' is ignored.
#
# If the layout is something like matrix(c(1,2,3,3), nrow=2, byrow=TRUE),
# then plot 1 will go in the upper left, 2 will go in the upper right, and
# 3 will go all the way across the bottom.
# usage: multiplot(p1, p2, p3, p4, cols=2)
multiplot <- function(..., plotlist=NULL, file, cols=1, layout=NULL) {
  require(grid)
  
  # Make a list from the ... arguments and plotlist
  plots <- c(list(...), plotlist)
  
  numPlots = length(plots)
  
  # If layout is NULL, then use 'cols' to determine layout
  if (is.null(layout)) {
    # Make the panel
    # ncol: Number of columns of plots
    # nrow: Number of rows needed, calculated from # of cols
    layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                     ncol = cols, nrow = ceiling(numPlots/cols))
  }
  
  if (numPlots==1) {
    print(plots[[1]])
    
  } else {
    # Set up the page
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))
    
    # Make each plot, in the correct location
    for (i in 1:numPlots) {
      # Get the i,j matrix positions of the regions that contain this subplot
      matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))
      
      print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                      layout.pos.col = matchidx$col))
    }
  }
}

