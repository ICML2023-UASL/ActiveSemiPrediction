library(splines);library(ggplot2);library(xtable);
source('ActiveLearningFinal.R')
set.seed(20230120)
beta = c(-5.4, rep(0.7,7));re=300; t.n = 10000; m1 = 10;deg = 2; batch = 100; pilot <- 150
t.beta <- pilot.est <- matrix(0,re, length(beta))
mod.Ent.CW <- mod.SES.CW  <- mod.Ent.IMP <- mod.SES.IMP <- array(0, dim=c(m1,length(beta),re))
for(i in 1:re)
{
   dat = Datageneration(t.n, beta = beta, Dist = 'mzNormal', corr = 2*0.4, link = 'mod3')   
   X = dat$X; Y = dat$Y; mean(Y)
   t.beta[i,]  = glm(Y~X-1, family = 'binomial')$coefficient
   ind.pilot = sample(1:t.n, size = pilot)
   pilot.X=  X[ind.pilot,]; pilot.Y = Y[ind.pilot]
   pilot.beta = glm(pilot.Y ~ pilot.X-1, family = "binomial")$coefficient
   sub.p.u = 1/(t.n:(t.n-pilot+1))
   pool.X = X[-ind.pilot,]; pool.Y = Y[-ind.pilot]
   imp.moe = m.t(pilot.Y, pilot.X, pool.X, sub.p.u, deg, method = 'IMP')$i.model
   #inital
   set.ent.CW <-entropy(pool.X, pool.Y, pilot.X, pilot.Y, sub.p.u, batch, pilot.beta, setup = TRUE) 
   set.ses.CW <-SES(pool.X, pool.Y, pilot.X, pilot.Y, sub.p.u, batch, pilot.beta, i.model = imp.moe, setup = TRUE) 
   
   set.ent.IMP <-entropy(pool.X, pool.Y, pilot.X, pilot.Y, sub.p.u, batch, pilot.beta, setup = TRUE) 
   set.ses.IMP <-SES(pool.X, pool.Y, pilot.X, pilot.Y, sub.p.u, batch, pilot.beta, i.model = imp.moe, setup = TRUE) 
   for(j in 1:m1)
   { 
      ##Sampling
      set.ent.CW = entropy(set.ent.CW$pool.x, set.ent.CW$pool.y, set.ent.CW$sub.x, set.ent.CW$sub.y, set.ent.CW$sub.p, batch, set.ent.CW$c.est) 
      set.ses.CW = SES(set.ses.CW$pool.x, set.ses.CW$pool.y, set.ses.CW$sub.x, set.ses.CW$sub.y, set.ses.CW$sub.p, batch, set.ses.CW$c.est, set.ses.CW$i.model)
      
      set.ent.IMP = entropy(set.ent.IMP$pool.x, set.ent.IMP$pool.y, set.ent.IMP$sub.x, set.ent.IMP$sub.y, set.ent.IMP$sub.p, batch, set.ent.IMP$c.est) 
      set.ses.IMP = SES(set.ses.IMP$pool.x, set.ses.IMP$pool.y, set.ses.IMP$sub.x, set.ses.IMP$sub.y, set.ses.IMP$sub.p, batch, set.ses.IMP$c.est, set.ses.IMP$i.model) 
      
      ##Model training
      #Entropy 
      mod.Ent.CW[j,,i] <- m.t(set.ent.CW$sub.y, set.ent.CW$sub.x, set.ent.CW$pool.x, set.ent.CW$pi, deg, method = 'IPW')$cur.est
      #SES Mean
      mod.SES.CW[j,,i] <- set.ses.CW$c.est <- m.t(set.ses.CW$sub.y, set.ses.CW$sub.x, set.ses.CW$pool.x, set.ses.CW$pi, deg, method = 'IPW')$cur.est
      set.ses.CW$i.model <- m.t(set.ses.CW$sub.y, set.ses.CW$sub.x, set.ses.CW$pool.x, set.ses.CW$pi, deg, method = 'IMP')$i.model
      
      #Entropy 
      mod.Ent.IMP[j,,i] <- set.ent.IMP$c.est <- m.t(set.ent.IMP$sub.y, set.ent.IMP$sub.x, set.ent.IMP$pool.x, set.ent.IMP$pi, deg, method = 'IMP')$cur.est
      #SES mean
      fit.AI.IMP = m.t(set.ses.IMP$sub.y, set.ses.IMP$sub.x, set.ses.IMP$pool.x, set.ses.IMP$pi, deg, method = 'IMP')
      mod.SES.IMP[j,,i] <- set.ses.IMP$c.est <- fit.AI.IMP$cur.est
      set.ses.IMP$i.model <- fit.AI.IMP$i.model
      print(rbind(  t.beta[i,],set.ent.IMP$c.est, set.ses.IMP$c.est))
      print(j)
   }
   print(i)
}

save.image("Case3.RData")

m.t.beta = colMeans(t.beta[1:re,])
s= 10
m.t.beta
rowMeans(mod.Ent.CW[s,,1:re])
round(rowMeans(mod.SES.CW[s,,1:re]),4)
rowMeans(mod.Ent.IMP[s,,1:re])
round(rowMeans(mod.SES.IMP[s,,1:re]),4)
tab1 <- tab2 <- tab3 <-tab4 <- c()
for(s in 1:m1)
{  
   tab1 = cbind(tab1, round(sqrt(mean(colSums((mod.Ent.CW[s,,1:re] -m.t.beta)^2))),4))
   tab2 = cbind(tab2, round(sqrt(mean(colSums((mod.SES.CW[s,,1:re] -m.t.beta)^2))),4))
   tab3 = cbind(tab3, round(sqrt(mean(colSums((mod.Ent.IMP[s,,1:re] -m.t.beta)^2))),4))
   tab4 = cbind(tab4, round(sqrt(mean(colSums((mod.SES.IMP[s,,1:re] -m.t.beta)^2))),4))
}
xtable(rbind(tab1,tab2,tab3,tab4), digits=3)

tab1 = c(tab1);tab2=c(tab2);tab3=c(tab3);tab4 = c(tab4);
pdf(file = "~/Desktop/RPlot03.pdf", width = 8, height = 5)
par(mar = c(5.1, 5.1, 4.1, 1.1))
plot(tab1, ylim = c(min(tab4),max(tab2)) ,xaxt = "n",  cex.lab=2, lty=2,
     col = 'green3',cex.axis=1.5,lwd= 2,#,main = expression(F[1])
     cex.main=2, xlab='Batch',ylab = '', type = 'b', pch = 4,  cex = 1.5)
title(ylab=expression(sqrt('MSE')),cex.lab=2)
points( tab2, col = 'red', type = 'b', lty=2,  pch = 8, lwd=2, cex = 1.5)
points( tab3, col = 'orange1', type = 'b', pch = 4, lwd= 2, cex = 1.5)
points( tab4, col = 'purple', type = 'b', pch = 8, lwd= 2, cex = 1.5)
axis(1, at=1:10, labels=c(1:10), cex.axis=1.8)
legend("topright", legend=c('Ent-CW', 'SBS-CW','Ent-AI', 'SBS-AI'),
       col=c('green3','red','orange1','purple'),cex = 1.5,
       pch = c(4,8), lty = c(2,2,1,1), lwd = 2, y.intersp = 1.2)
dev.off()
