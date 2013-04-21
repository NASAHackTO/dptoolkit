#! /usr/bin/env ppython

import os
import sys
import string
import optparse
import re
from numpy import array,nonzero,loadtxt,linspace,histogram,diff,arange
from numpy import median,std,mean
from pylab import bar, gca, plot,xlabel,ylabel,title,grid,show,legend
from scipy.stats import norm

#--- set up for tex ability
#from matplotlib import rc
#rc('text',usetex=True)



#===============================================================================
def plotCDF(x,limits=None,plotSpec='b.-',createPlot=True, probPaperFlag=False,showCount=False):
   
   #--- if limits specified, apply them
   if not limits == None:
      goodPoints = nonzero(x>min(limits))[0]
      x = x[goodPoints]
      goodPoints = nonzero(x<max(limits))[0]
      x = x[goodPoints]
      
   #--- sort the data
   x.sort()
   
   #--- create a cumulative array
   cumArray = arange(1.0,1.0*(len(x)+1))/(1.0*(len(x)+1))

   #--- express the cumulative prob in sigma
   if probPaperFlag:
      cumArray = norm.ppf(cumArray)
   elif showCount:
      cumArray = cumArray * (1.0*(len(x)+1))

   if createPlot:
      plot(x,100*cumArray,plotSpec)
      if not limits == None:
         gca().set_xlim(*limits)
      #legend(loc="best")


   #if createPlot:
   #   bar(edges[:-1],counts,binWidth,color=color,linewidth=linewidth)
   #   yLimits = gca().get_ylim()
   #   plot([meanVal, meanVal],[yLimits[0],yLimits[1]],'r-',label='$\mu$ = %g'%meanVal)
   #   plot([meanVal-sigma, meanVal-sigma],[yLimits[0],yLimits[1]],'g-')
   #   plot([meanVal+sigma, meanVal+sigma],[yLimits[0],yLimits[1]],'g-', label=r'$\sigma$ = %g'%(sigma))
   #   if not limits == None:
   #      gca().set_xlim(*limits)
   #   legend(loc="best")
   
   return (x,cumArray)

#===============================================================================
if __name__ == "__main__":
   
   
   
   #--- set up to handle command line arguments
   description="Plot the Histogram"
   usage = "cat singleColFile | %prog [OPTIONS]"

   p = optparse.OptionParser(usage,description=description)

   p.add_option('-l','--limits',action='store',type='string',
         dest='limits', metavar="min:max",default="")
   p.add_option('--xlog',action='store_true', default=False,
         dest='xlog', help='make x a log scale')
   p.add_option('--ylog',action='store_true', default=False,
         dest='ylog', help='make y a log scale')
   p.add_option('--xlabel',action='store',type='string',
         dest='xlabel', metavar="'x label text'",default='Value')
   p.add_option('--ylabel',action='store',type='string',
         dest='ylabel', metavar="'y label text'",default='_default_')
   p.add_option('--title',action='store',type='string',
         dest='title', metavar="'title text'",default='')
   p.add_option('-p','--plotSpec',action='store',type='string',dest='plotSpec',
                 default='b.-', help='The line style to use (default: b.-)')
   p.add_option('-c','--countOutput',action='store_true', default=False,
         dest='countOutput', help='Show cumulative count instead of probability')
   p.add_option('-b','--probPaper',action='store_true', default=False,
         dest='probPaper', help='Show CDF drawn on probability-paper axes.')
   p.add_option('-g','--grid',action='store_true', default=False,
         dest='grid', help='show grid lines')
   p.add_option('-o','--output',action='store_true', default=False,
         dest='output', help='print results to console instead of making plot')



   options,arguments=p.parse_args()

   #--- get the data from stdin
   x = loadtxt(sys.stdin)
   
   #--- get the remaining arguments
   minVal,maxVal = min(x)-1e-12,max(x)+1e-12
   m = re.match('^(\S+):(\S+)$',options.limits)
   if m:
      minVal, maxVal = float(m.group(1)), float(m.group(2))
      
   plotSpec = options.plotSpec
   probPaperFlag = options.probPaper
   showCount = options.countOutput
   limits = (minVal,maxVal)
   createPlot = not options.output

   if (probPaperFlag and showCount):
      msg = 'Cant set probPaper and countOutput at the same time'
      raise StandardError, msg

   outTup = plotCDF(x,limits=limits,plotSpec=plotSpec,createPlot=createPlot, probPaperFlag=probPaperFlag,showCount=showCount)
   
   
   if options.output:
      vals = outTup[0]
      cumProbs = outTup[1]

      for val,cumProb in zip(vals,cumProbs):
         print "%-20f %-20f" % (val,cumProb)
      sys.exit()
      
   #--- set default ylabel if it exists
   yLabel = options.ylabel
   if options.ylabel == '_default_':
      if probPaperFlag:
         yLabel = 'Sigma from mean'
      elif showCount:
         yLabel = 'Cumulative count'
      else:
         yLabel = 'Cumulative Probability'
   #--- add labels and titles
   xlabel(options.xlabel)
   ylabel(yLabel)
   title(options.title)
   
   #--- set any requested log scaling
   if options.xlog:
      gca().set_xscale('log')
   if options.ylog:
      gca().set_yscale('log')
   
   #--- show grid lines if requested
   if options.grid:
      grid(True)


   show()
   
      
   
