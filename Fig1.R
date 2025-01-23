
library(survival)
library(survminer)

#load('cryoadf.rda')

# combine 3 plots

fit.transfer <- survfit(Surv(days.transferred/365.25,Transfer) ~ 1, data = cryoadf)
fit.deceased <- survfit(Surv(days.deceased/365.25,Deceased) ~ 1, data = cryoadf)
fit.discarded <- survfit(Surv(days.discarded/365.25,Discarded) ~ 1, data = cryoadf)

quantile(fit.transfer, probs = c(0.25, 0.5, 0.75, 0.9))$quantile -> transfer # 1.0 2.4312115 6.0 10.5
quantile(fit.deceased, probs = c(0.25, 0.5, 0.75, 0.9))$quantile -> deceased # 0.9 1.6591376 3.3 6.0
quantile(fit.discarded, probs = c(0.25, 0.5, 0.75, 0.9))$quantile -> discarded # 4.8 7.690623 11.1 15.3
time <- rbind(transfer,deceased,discarded)
colnames(time) <- c("25% to outcome","50% to outcome","75% to outcome","90% to outcome")
rownames(time) <- NULL

ggsurv3com.cum <- function(fit,data,title) {
  ggsurvplot_combine(fit, data, fun = "event",
                     break.time.by = 3, 
                     cumevents = TRUE,
                     fontsize = 8, # number size for risk table and cumevent table, or cumevents.fontsize = 10
                     xlab = "Time (years)",
                     xlim = c(0,30),
                     title = title,
                     legend = c(0.35,0.75),
                     legend.title = "Time to outcomes",
                     legend.labs = c("Transfer", "Death", "Discarded"),
                     font.main = c(25, "bold", "black"), # title font
                     font.tickslab = c(18, "plain", "black"), # x- y-lab, table number font size
                     conf.int = TRUE, 
                     tables.col = "strata",
                     tables.height = 0.15,
                     tables.theme = theme_cleantable() + 
                       theme(text = element_text(size = 20, face = "bold"), # table title font size
                             axis.text.y = element_text(size = 20, face = "bold", # table strata name font size
                                                        margin = margin(t=0,r=0,b=0,l=-65))),
                     ggtheme = theme_light() +
                       theme(legend.title = element_text(size = 20, color = "black", face = "bold"),
                             legend.text = element_text(size = 19, color = "black", face = "plain"),
                             axis.text.x = element_text(size = 20, color = "black", face = "bold"),
                             axis.text.y = element_text(size = 20, color = "black", face = "bold"),
                             axis.title.x = element_text(size = 20, color = "black", face = "bold"),
                             axis.title.y = element_text(size = 20, color = "black", face = "bold",
                                                         margin = margin(t = 0, r = 15, b = 0, l = 30))),
                     size = 1,
                     conf.int.style = "step"
  ) 
} # cumulative incidence

fit <- list(Transfer=fit.transfer, Deceased=fit.deceased, Discarded=fit.discarded)
ggsurv3com.cum(fit,cryoadf,"Time to Transfer, Death and Discarded") -> ggsurv
ggsurv$plot <- ggsurv$plot + 
  theme(legend.position = c(.4,.475),
        legend.key.size = unit(2.5, 'lines'),
        legend.spacing.y = unit(0.2,"cm")
  ) +
  geom_segment(aes(x = 0, y = 0.5, xend = 7.690623, yend = 0.5), linetype="dashed") +
  geom_segment(aes(x = 7.690623, y = 0, xend = 7.690623, yend = 0.5), linetype="dashed") +
  geom_segment(aes(x = 1.6591376, y = 0, xend = 1.6591376, yend = 0.5), linetype="dashed") +
  geom_segment(aes(x = 2.4312115, y = 0, xend = 2.4312115, yend = 0.5), linetype="dashed")

# add time table 

library(grid)
library(gridExtra)

vp <- viewport(x = 0.7, y = 0.5, width = 0.3, height = 0.3) 
grid.rect(vp = vp) # grib table position on the white background
timetbl <- tableGrob(round(time, 1), vp = vp)
timetbl$widths <- rep(unit(1/ncol(timetbl),"null"), ncol(timetbl))
timetbl$heights <- rep(unit(1/nrow(timetbl), "null"), nrow(timetbl))
ele <- c(1:4, 9:20)
for (i in ele) {
  timetbl$grobs[[i]][["gp"]] <- gpar(fontsize=20, fontface="bold")
}
grid.newpage()
grid.draw(timetbl)

ggsurv$plot <- ggsurv$plot +
  annotation_custom(timetbl,xmin=13.97, xmax=31, ymin=0.35, ymax=0.6)

ggsurv

# save plot

png("Fig1.jpeg", res=600, width=12000, height=7000)
print(ggsurv)
dev.off()
