# check that the working directory is set to the OSF folder that has been downloaded. 
# It should already be the case if you opened RStudio via the file OSF.Rproj located 
# in the OSF folder. 

remove(list = ls()) # clear environment

getwd() # to check the working directory

# load libraries
library(readr)
library(PRISMA2020)
library(metafor)
library(tidyr)
library(kableExtra)
library(MAd)
library(dplyr)

# Prisma flow diagram ----
selection <- read.csv("prisma.csv");
selection <- PRISMA_data(selection);
flowd <- PRISMA_flowdiagram(selection,fontsize = 12, interactive = FALSE, previous = FALSE, other = TRUE);
flowd

df <- read_csv("df.csv")

# Effect size ----
df <- escalc(measure="SMD",
             m1i=C_Mean, 
             m2i=ASD_Mean, 
             sd1i=C_Sd, 
             sd2i=ASD_Sd, 
             n1i=c_n, 
             n2i=asd_n,
             data=df, 
             drop00=TRUE, 
             vtype="AV", #computes the sampling variances with the usual large-sample approximation but plugging the sample-size weighted average of the Hedges' g values into the equation
             var.names=c("yi","vi","SMD"), add.measure=TRUE,
             append=TRUE, replace=TRUE)

df_agg<-MAd::agg(data=df, id=id, es=yi, var=vi, method = 'BHHR', cor = .50)  # change .50 to .70 or .90 to run analyses with different hypothesized correlation among outcomes 

# Descriptives ----
df_info<-read.csv("df_info.csv")
info<- Reduce(function(x,y) merge(x,y,by="id",all=TRUE) ,list(df_agg,df_info))
info<-info[,c("id","authors","country",
              "c_n","c_m_f_ratio","c_age_range","c_age_m","c_age_sd",
              "asd_n","asd_m_f_ratio","asd_age_range","asd_age_m","asd_age_sd",
              "synch_type","es", "var")]
df_agg<-info[,c(1,2,14,15,16)]

names(info)[names(info) == "id"] <-  "ID"
names(info)[names(info) == "authors"] <-  "Authors" 
names(info)[names(info) == "country"] <-  "Country"
names(info)[names(info) == "synch_type"] <-  "Type of Synchrony"
names(info)[names(info) == "c_n"] <-  "N"
names(info)[names(info) == "c_m_f_ratio"] <-  "M/F ratio" #td
names(info)[names(info) == "c_age_range"] <-  "range" #td
names(info)[names(info) == "c_age_m"] <-  "mean" #td
names(info)[names(info) == "c_age_sd"] <-  "sd" #td
names(info)[names(info) == "asd_n"] <-  "N" #asd
names(info)[names(info) == "asd_m_f_ratio"] <-  "M/F ratio" #asd
names(info)[names(info) == "asd_age_range"] <-  "range" #asd
names(info)[names(info) == "asd_age_m"] <-  "mean" #asd
names(info)[names(info) == "asd_age_sd"] <-  "sd" #asd

kbl(info, digits = 2) %>%
  kable_classic() %>%
  add_header_above(c(" "= 3, " " = 2, "Age" = 3, " " = 2, "Age" = 3, " " = 3))%>%
  add_header_above(c(" " = 3, "Control Group" = 5, "ASD Group" = 5, " " = 3))


# Random-effects meta-analysis ----

m.random <- rma(yi=es, vi=var, data=df_agg, method="REML")
RE.results <- summary(m.random)
print(RE.results)

#fit moderation model (type of synchrony)
moderation.random <- rma(yi=es, vi=var, mods = ~ synch_type, data=df_agg, method="REML")
summary(moderation.random)

# Forest plot

forest(m.random, # combined effect size
       annotate=TRUE,
       df_agg$var, # variance of the composite hp .5
       showweights=T,
       header=T,
       slab=df_agg$authors,
       ilab=df_agg$synch_type,
       ilab.xpos = -5,
       ilab.pos = 4, 
       cex=.75,
       xlim=c(-10,11),
       xlab="Hedge's g", 
       addpred = TRUE)
text(-3.8, 15, "SynchType", cex=.75, font=2)

### add text with Q-value, dfs, p-value, and I^2 statistic
text(-10, -1.8, pos=4, cex=0.70, bquote(paste("(Q = ",
                                              .(formatC(m.random$QE, digits=2, format="f")), ", df = ", .(m.random$k - m.random$p),
                                              ", p < .0001", "; ", I^2, " = ",
                                              .(formatC(m.random$I2, digits=1, format="f")), "%)")))

# Prediction interval

predict(m.random)

# Funnel plot

### carry out trim-and-fill analysis
taf<-trimfill(m.random, main="", 
              ma.fixed = FALSE, 
              fixed = FALSE, 
              random = TRUE, 
              label=TRUE)

### draw funnel plot with missing studies filled in
funnel(taf, legend=TRUE, xlab="Hedge's g")

summary(trimfill(m.random))



# Sensitivity analysis
# Leave-One-Out

sens.random<-as.data.frame(leave1out(m.random))

sens.random<-data.frame(df_agg$authors, format(round(sens.random[,],2),nsmal=2))
sens.random$CI<-paste0("[",sens.random$ci.lb,";",sens.random$ci.ub,"]")
sens.random$tau<-sqrt(as.numeric(sens.random$tau2))
sens.random$tau2<-NULL
sens.random<-sens.random[,c(1:2,10,13,12)]
sens.random[,1]<-as.character(sens.random[,1])
names(sens.random)[names(sens.random) == "df_agg.authors"] <- "Authors"
names(sens.random)[names(sens.random) == "estimate"] <- "Estimate"

# Compute prediction intervals using leave-one-out method

PI.random <- data.frame(Authors = character(), 
                        #CI = character(),  
                        PI = character())

for (j in 1:nrow(df_agg)) {
  df_agg_l1o <- df_agg[-j, ]  # Remove one study from the dataset
  m.leave1out.random <- rma(yi = es, vi = var, data = df_agg_l1o, method = "REML")  # Run model
  predicted <- predict(m.leave1out.random, interval = "prediction")  # Compute prediction interval
  # conf_lb<-round(predicted$ci.lb, digits = 2)
  # conf_ub<-round(predicted$ci.ub, digits = 2)
  pred_lb<-round(predicted$pi.lb, digits = 2)
  pred_ub<-round(predicted$pi.ub, digits = 2)
  
  # Create a new row with results
  new_row <- data.frame(Authors = df_agg$authors[j], 
                        #CI = paste0("[",conf_lb,";",conf_ub,"]"), 
                        PI = paste0("[",pred_lb,";",pred_ub,"]"))
  
  # Bind the new row to results_table
  PI.random <- rbind(PI.random, new_row)
}

sens.random<-merge(sens.random, PI.random, by="Authors", all=TRUE)

kbl(sens.random, digits = 2, caption = "Leave-one-out sensitivity analysis") %>%
  kable_paper() #latex_options = "scale_down"


# Cook's distance
dinf<-influence(m.random)
highest<-max(dinf$inf$cook.d)
plot(dinf$inf$cook.d, ylab = "Cook's distance", xlab = "ID", col=ifelse(dinf$inf$cook.d==highest, "red", "black"), pch=ifelse(dinf$inf$cook.d==highest, 19, 1), type = "b")
axis(1, at=dinf$inf$slab, labels=dinf$inf$slab)

