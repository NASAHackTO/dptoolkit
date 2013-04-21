#! /usr/bin/env ppython

import sys
import re
from pylab import plot,errorbar,legend,xlabel,ylabel,title,gca,gcf,grid,show,savefig
from pylab import twinx, plot_date
from numpy import loadtxt
import optparse
import string
import datetime





unitDict = {
            'second': 1.,
            'minute': 60.,
            'hour': 3600.,
            'day': 24. * 3600.,
            'week': 7. * 24. * 3600.,
            'year': 31556926.,
            'date': 1,
           }
unitList = unitDict.keys()



#--- set up to handle command line arguments
description="Plots data from stdin.  Input data can contain one, two, or three "
description+="columns.  For single column of data, the points are plotted with "
description+="unit spacing on the x axis.  Two columns of data are plotted with "
description+="the first column used as x and the second used as y.  Three columns "
description+="of data are interpreted as follows.  The first column is treated as "
description+="a numeric trace identifier, the second column is x, the third y. "
description+="This allows multiple traces to be placed on the same plot.  All "
description+="x,y pairs with the same identifier are plotted as a single trace. "
description+="Additionally, there are some special cases for making specific plots. "
description+="Error bar plots can be created with the --errorBar option.  For errorbar "
description+="plots, the input should contain either three columns (x,y,e) or "
description+="four columns (traceID,x,y,e). Plots having two (left/right) y axes "
description+="can be created with the --twinX option.  For this type of plot, "
description+="the input must contain three columns interpreted as (x,y1,y2). "
description+="Various options exist for customizing and annotating the axes. "
description+="Note:  It is possible to print dates on the x axis with the -D option.  "
description+="In this case, it is assumed that the x data contains time elapsed "
description+="(in the specified units) since the specified epoch."



usage = "cat file.txt | %prog [optional args]"
p = optparse.OptionParser(usage,description=description)
p.add_option('-D','--dateForX',action='store',type='string',
      dest='dateForX', metavar="'day|2000 01 01 12 00 00 00'",
      help="Print the x axis as a date/time.  "+\
           "Format is:'inputUnit|epoch'='%s|YYYY MM DD [hh [mm [ss [us]]]]'"%\
                                                               (repr(unitList)))
p.add_option('-e','--errorBar',action='store_true', default=False,
      dest='errorBar', help='Make error bar plot')
p.add_option('-t','--twinX',action='store_true', default=False,
      dest='twinX', help='Make twin x axes for doing plotyy style plots')
p.add_option('-T','--twinXCat',action='store_true', default=False,
      dest='twinXCat', help='Make twin x axes for doing plotyy style plots. Data expected in p.cat format')
p.add_option('-m','--commentToken',action='store',type='string',
      dest='commentToken', metavar="#",default='#')
p.add_option('-x','--xLimits',action='store',type='string',
      dest='xlim', metavar="xmin:xmax")
p.add_option('-y','--yLimits',action='store',type='string',
      dest='ylim', metavar="ymin:ymax")
p.add_option('-Y','--yLimits2',action='store',type='string',
      dest='ylim2', metavar="ymin:ymax",help="yLimits for right axis of yy plot")
p.add_option('-p','--plotSpec',action='store',type='string',
      dest='plotSpec', metavar="'.-'",default='.-')
p.add_option('--p1',action='store',type='string',
      dest='plotSpec1', metavar="'b.-'",default='b.-',help='plotSpec for left yy plot')
p.add_option('--p2',action='store',type='string',
      dest='plotSpec2', metavar="'r.-'",default='r.-',help='plotSpec for right yy plot')
p.add_option('--xlabel',action='store',type='string',
      dest='xlabel', metavar="'x label text'",default='')
p.add_option('--ylabel',action='store',type='string',
      dest='ylabel', metavar="'y label text'",default='')
p.add_option('--ylabel2',action='store',type='string',
      dest='ylabel2', metavar="'y label text'",default='',help="yLabel for right axis of yy plot")
p.add_option('--title',action='store',type='string',
      dest='title', metavar="'title text'",default='')
p.add_option('-g','--grid',action='store_true', default=False,
      dest='grid', help='show grid lines')
p.add_option('-G','--grid2',action='store_true', default=False,
      dest='grid2', help='show grid lines for right axis of yy plot')
p.add_option('-l','--legendList',action='store', default="",
      dest='legend', help="a list of pipe separated legends (e.g. -l 'leg a|leg b|leg c')")
p.add_option('--xlog',action='store_true', default=False,
      dest='xlog', help='make x a log scale')
p.add_option('--ylog',action='store_true', default=False,
      dest='ylog', help='make y a log scale')
p.add_option('--ylog2',action='store_true', default=False,
      dest='ylog2', help='make y a log scale for right axis of yy plot')
p.add_option('-s','--save',action='store',type='string',
                                            dest='fileName', metavar="fileName")
p.add_option('-q','--quiet',action='store_true', default=False,
      dest='quiet', help='Quiet. (For saing without drawing plot)')
p.add_option('--page',action='store',
              dest='page',choices=['portrait','landscape','slideFull','slideHalf','slideBumper',
                                   "slideHalfBumper"],
     help = "turn on figure formatting. presets are: portrait|landscape|slideFull|slideHalf|slideBumper"+
            "|slideHalfBumper")
p.add_option('--figSize',action='store',type='string',
       dest='figSize', metavar="'8.5:11'",
               help="Customize --page specification with explicit width:height")
p.add_option('--marginTop',action='store', dest='marginTop',type=float,
                  default=.08,  metavar="0.08",help = "top margin (fig fraction)")
p.add_option('--marginBottom',action='store', dest='marginBottom',type=float,
                 default=.1,metavar="0.1",help = "bottom margin (fig fraction)")
p.add_option('--marginLeft',action='store', dest='marginLeft',type=float,
                 default=.12,metavar="0.12",help = "left margin (fig fraction)")
p.add_option('--marginRight',action='store', dest='marginRight',type=float,
                default=.08, metavar=".08",help = "right margin (fig fraction)")
p.add_option('--sizeTitle',action='store', dest='sizeTitle',type=float,default=18,
                                          metavar="18",help = "title font size")
p.add_option('--sizeLabel',action='store', dest='sizeLabel',type=float,default=16,
                                          metavar="16",help = "label font size")
p.add_option('--sizeNumber',action='store', dest='sizeNumbers',type=float,default=14,
                                          metavar="14",help = "label font size")
p.add_option('--lineWidth',action='store', dest='lineWidth',type=float,default=2,
                                          metavar="2",help = "label font size")
p.add_option('--markerSize',action='store', dest='markerSize',type=float,default=7,
                                          metavar="7",help = "label font size")
p.add_option('--dpi',action='store', dest='dpi',type='int',default=300,
                                             metavar="300",help = "savefig dpi")


#--- parse the input arguments
options,arguments=p.parse_args()

doFormatting = False
if not options.page == None:
   doFormatting = True

#--- set any formatting instructions
if doFormatting:
   from matplotlib import rcParams
   
   #for p in sorted(rcParams.keys()):
   #   print p
   #sys.exit()
   #
   rcParams['font.weight'] = 300 # (val = 100 to 900)
   rcParams['font.size'] = 14 # (val = 100 to 900)
   
   
   rcParams['axes.titlesize'] = options.sizeTitle
   rcParams['axes.labelsize'] = options.sizeLabel
   rcParams['axes.linewidth'] = options.lineWidth
   
   rcParams['xtick.labelsize'] = options.sizeNumbers
   rcParams['ytick.labelsize'] = options.sizeNumbers
   rcParams["xtick.major.size"] = 7
   rcParams["ytick.major.size"] = 7
   rcParams['xtick.major.pad'] = 6
   rcParams['ytick.major.pad'] = 6
   
   
   rcParams['lines.linewidth'] = options.lineWidth #plot lineWidths
   rcParams['lines.markersize'] = options.markerSize #plot marker sizes
   
   if options.page == "portrait":
      rcParams["figure.figsize"] = [8.5,11] #portrait
   elif options.page == "slideFull":
      rcParams["figure.figsize"] = [8.8,5.9] #single power point graph
#      if options.marginLeft == .12:
#         options.marginLeft = .1
#      if options.marginRight == .08:
#         options.marginRight = .03
#      if options.marginTop == .08:
#         options.marginTop = .07
   elif options.page == "slideHalf":
      rcParams["figure.figsize"] = [4.8,5.7] #one of two side-by-side power point graphs
#      if options.marginLeft == .12:
#         options.marginLeft = .14
#      if options.marginRight == .08:
#         options.marginRight = .04
#      if options.marginTop == .08:
#         options.marginTop = .06
   elif options.page == "slideBumper":
      rcParams["figure.figsize"] = [8.8,4.9] #single power point graph
#      if options.marginLeft == .12:
#         options.marginLeft = .1
#      if options.marginRight == .08:
#         options.marginRight = .03
#      if options.marginTop == .08:
#         options.marginTop = .08
#      if options.marginBottom == .1:
#         options.marginBottom = .12
   elif options.page == "slideHalfBumper":
      rcParams["figure.figsize"] = [4.8,4.9] #one of two side-by-side power point graphs
#      if options.marginLeft == .12:
#         options.marginLeft = .2
#      if options.marginRight == .08:
#         options.marginRight = .04
#      if options.marginTop == .08:
#         options.marginTop = .15
   else:
      rcParams["figure.figsize"] = [11,8.5] #default to landscape
   
   if not options.figSize == None:
      m = re.match('^(\S+):(\S+)$',options.figSize)
      if m:
         width,height = float(m.group(1)),float(m.group(2))
         rcParams["figure.figsize"] = [width,height]
      
   
   if not options.marginTop == None:
      rcParams["figure.subplot.top"] = 1 - options.marginTop
   if not options.marginBottom == None:
      rcParams["figure.subplot.bottom"] = options.marginBottom
   if not options.marginLeft == None:
      rcParams["figure.subplot.left"] = options.marginLeft
   if not options.marginRight == None:
      rcParams["figure.subplot.right"] = 1 - options.marginRight
      
   
   
   #rcParams["figure.dpi"] = 80
   #rcParams["savefig.dpi"] = 80


#--- pre-process datetime x axis stuff
xIsDateTime = False
epochObj = None
if not options.dateForX == None:
   xIsDateTime = True
   #--- parse dateForX string
   inUnitString,epochString = tuple(string.split(options.dateForX,'|'))
   inUnitString = inUnitString.strip()
   if not inUnitString in unitList:
      raise StandardError, "\n\ninputUnit '%s' not recognized.\n"%inUnitString+\
                              "Valid units: %s" % (repr(unitList))
   inUnit = unitDict[inUnitString]
   year,month,day,hour,minute,second,microsecond = None,None,None,0,0,0,0
   epochList = string.split(epochString)
   if len(epochList) > 2:
      year,month,day = int(epochList[0]),int(epochList[1]),int(epochList[2])
   else:
      raise StandardError,"\n\nYou must specify at least YY MM DD of epoch\n\n"
   if len(epochList) > 3:
      hour = int(epochList[3])
   if len(epochList) > 4:
      minute = int(epochList[4])
   if len(epochList) > 5:
      second = int(epochList[5])
   if len(epochList) > 6:
      microsecond = int(epochList[6])
   epochObj = datetime.datetime(year,month,day,hour,minute,second,microsecond)
      

#--- read in the data
data = loadtxt(sys.stdin,comments=options.commentToken)


#--- Error Bar Plotting ----------------------------------------------------
if options.errorBar:
   #--- if two columns of data and one errorbar columns
   if data.shape[1] == 3:
      #print len(data[:,0]),len(data[:,1]),len(data[:,2]),option)
      
      errorbar(data[:,0],data[:,1], yerr=data[:,2], fmt=options.plotSpec)
      

   #--- if three columns of data assume cols are dataSetID,x,y
   if data.shape[1] == 4:
      setNumbers = data[:,0]
      xAll = data[:,1]
      yAll = data[:,2]
      eAll = data[:,3]
      dataSetList = list(set(setNumbers))
      #--- get any specified legends
      legendList = options.legend.split('|')
      
      for dataSetNum in dataSetList:
         useIndex = setNumbers == dataSetNum
         x = xAll[useIndex]
         y = yAll[useIndex]
         e = eAll[useIndex]
         label = str(int(dataSetNum))
         if legendList:
            if dataSetNum <= len(legendList):
               newLabel = legendList[int(dataSetNum)-1]
               if newLabel:
                  label = newLabel
         errorbar(x,y,yerr=e,label=label)
      legend(loc='best')


#--- Double Y axis plots -------------------------------------------------------
elif (options.twinX or options.twinXCat):
   #--- if two columns of data 
   if not data.shape[1] == 3:
      raise StandardError,"\n\ntwinX option requires 3 data columns\n\n"
   
   #--- get the axis color for the left
   mTrace = re.match('.*?([a-z]).*',options.plotSpec1)
   if mTrace:
      axisColor = mTrace.group(1)
      
   #--- take care of case with x, y1,y2   
   if options.twinX:      
      xLeft = data[:,0]
      yLeft = data[:,1]
      xRight = xLeft
      yRight = data[:,2]
   
   #--- take care of case id,x,y
   elif options.twinXCat:      
      #--- get all the data
      setNumbers = data[:,0]
      xAll = data[:,1]
      yAll = data[:,2]
      #--- make a list of set numbers
      dataSetList = sorted(list(set(setNumbers)))
      
      #--- loop over all data sets
      for dataSetCount,dataSetNum in enumerate(dataSetList):
         #--- find all the data for this set         
         useIndex = setNumbers == dataSetNum
         #--- put the first set in xLeft
         if dataSetCount == 0:
            xLeft = xAll[useIndex]
            yLeft = yAll[useIndex]
         #--- put the second set in xRight
         elif dataSetCount == 1:
            xRight = xAll[useIndex]
            yRight = yAll[useIndex]
      
   #--- plot the left axis -----------------------------------------------------
   if xIsDateTime:
      dateObjList = [epochObj +datetime.timedelta(seconds = d * inUnit) for d in xLeft]
      plot_date(dateObjList,yLeft,options.plotSpec1)
      gcf().autofmt_xdate()
   else:
      plot(xLeft,yLeft, options.plotSpec1)
   
   for t in gca().get_yticklabels():
      t.set_color(axisColor)
   
   #--- anotate common elements on the left axis
   xlabel(options.xlabel)
   ylabel(options.ylabel,color=axisColor)
   title(options.title)

   #--- set any requested log scaling for left axis
   if options.xlog:
      gca().set_xscale('log')
   if options.ylog:
      gca().set_yscale('log')
      
   #--- show grid lines if requested
   if options.grid:
      gca().grid(True)

   #--- set x/y axis limits for left axis
   for limString in ['xlim','ylim']:
      exec 'lim = options.%s' % limString
      if not lim == None:
         exec "m = re.match('^(\S+):(\S+)$',options.%s)" % limString
         if m:
            limRange = float(m.group(1)),float(m.group(2))
            if xIsDateTime and (limString == 'xlim'):
               limRange = [epochObj +datetime.timedelta(seconds = d * inUnit) for d in limRange]
            exec 'gca().set_%s(limRange)' % (limString)

   #--- plot the right axis ----------------------------------------------------
   twinx()
   
   if xIsDateTime:
      dateObjList = [epochObj +datetime.timedelta(seconds = d * inUnit) for d in xRight]
      plot_date(dateObjList,yRight,options.plotSpec2)
      gcf().autofmt_xdate()
   else:
      plot(xRight,yRight, options.plotSpec2)
   
   #--- get the axis color for the left
   mTrace = re.match('.*?([a-z]).*',options.plotSpec2)
   if mTrace:
      axisColor = mTrace.group(1)
   
   for t in gca().get_yticklabels():
      t.set_color(axisColor)

   #--- annotate right y axis
   ylabel(options.ylabel2,color=axisColor)

   #--- show grid lines if requested
   if options.grid2:
      gca().grid(True)

   #--- set any requested log scaling for right axis
   if options.xlog:
      gca().set_xscale('log')
   if options.ylog2:
      gca().set_yscale('log')

   #--- set x/y axis limits for right axis
   for limString,optString in zip(['xlim','ylim'],['xlim','ylim2']):
      exec 'lim = options.%s' % optString
      if not lim == None:
         exec "m = re.match('^(\S+):(\S+)$',options.%s)" % optString
         if m:
            limRange = float(m.group(1)),float(m.group(2))
            if xIsDateTime and (limString == 'xlim'):
               limRange = [epochObj +datetime.timedelta(seconds = d * inUnit) for d in limRange]
            exec 'gca().set_%s(limRange)' % (limString)

#--- Regular plotting ----------------------------------------------------------
else:
   gca().set_color_cycle(['b','r','g','m','c','k','y'])

   #--- plot single column of data
   if len(data.shape) == 1:
      if xIsDateTime:
         raise StandardError, "\n\nDateTime x axes require at least 2 input columns\n\n"
      plot(data,options.plotSpec)
   
   #--- plot multiple columns
   else:
      #--- if two columns of data
      if data.shape[1] == 2:

         if xIsDateTime:
            dateObjList = [epochObj +datetime.timedelta(seconds = d * inUnit) for d in data[:,0]]
            plot_date(dateObjList,data[:,1],options.plotSpec)
            gcf().autofmt_xdate()
         else:
            plot(data[:,0],data[:,1], options.plotSpec)
   
      #--- if three columns of data assume cols are dataSetID,x,y
      if data.shape[1] == 3:
         setNumbers = data[:,0]
         xAll = data[:,1]
         yAll = data[:,2]
         dataSetList = sorted(list(set(setNumbers)))
         #--- get any specified legends
         legendList = options.legend.split('|')
         
         for dataSetNum in dataSetList:
            useIndex = setNumbers == dataSetNum
            x = xAll[useIndex]
            y = yAll[useIndex]
            label = str(int(dataSetNum))
            if legendList:
               if dataSetNum <= len(legendList):
                  newLabel = legendList[int(dataSetNum)-1]
                  if newLabel:
                     label = newLabel
                     
            if xIsDateTime:
               dateObjList = [epochObj +datetime.timedelta(seconds = d * inUnit) for d in x]
               plot_date(dateObjList,y,options.plotSpec,label=label)
               gcf().autofmt_xdate()
            else:
               plot(x,y,options.plotSpec,label=label)
         legend(loc='best')
         
            
#--- this stuff should be done for everything except twinx which handles its own
if not (options.twinX or options.twinXCat):
   #--- add labels and titles
   xlabel(options.xlabel)
   ylabel(options.ylabel)
   title(options.title)
   
   #--- set any requested log scaling
   if options.xlog:
      gca().set_xscale('log')
   if options.ylog:
      gca().set_yscale('log')
   
   #--- set any requested axis limits
   for limString in ['xlim','ylim']:
      exec 'lim = options.%s' % limString
      if not lim == None:
         exec "m = re.match('^(\S+):(\S+)$',options.%s)" % limString
         if m:
            limRange = float(m.group(1)),float(m.group(2))
            if xIsDateTime and (limString == 'xlim'):
               limRange = [epochObj +datetime.timedelta(seconds = d * inUnit) for d in limRange]
            exec 'gca().set_%s(limRange)' % (limString)
   
   #--- show grid lines if requested
   if options.grid:
      grid(True)
      
#--- save the file if requested
if not options.fileName == None:
   savefig(options.fileName,dpi=options.dpi)
   
#--- plot if requested
if not options.quiet:
   show()

