#! /usr/bin/env ppython

import sys
import optparse



helpString = \
"""
There are two modes of operation: 'numeric' and 'text'.  They are each
described below.

-------------------------------------------------------------------------
Numeric mode:

--- INPUTS ---
All input columns must be interpretable as numbers.  All input
data is simultaneously loaded into RAM where it can be manipulated before being
printed to the screen.

--- INTERNAL DATA REPRESENTATION
Data is loaded into memory and placed into numpy arrays named
c0, c1,... cN corresponding the the N columns of data found on the input.

These are used to generate two sets of additional arrays as follows:
d0, d1,... dN are arrays holding the incremental difference between rows.
Note that the first element of each of these arrays will be NaN as there is
no prevous point from which to compute a difference.

An index over the rows is provided in an array named n.  This allowes for useful
constructs such as computing the second difference for the entire first column:
diff2 = (d0[n] - d0[n-1])/.001

Elements of these arrays can be accessed and set with the usual python syntax.
For example, first0=c0[0] and last0=c0[-1]

--- PRE-PROCESSING COMMANDS
After being read into memory, any specified math pre-processing command are
executed.   These commands are supplied with the -m option.  These math
pre-processing commands allow the user to perform a series of vectorized
calculations to manipulate the data in preparation for output.

-- OUTPUT COMMANDS
The output commands are a series of command line arguments each containing
a valid python expression that evaluates to a numpy array.  These arrays
are packaged into output columns that are printed to stdout in the order
in which they are specified.


--- EXAMPLE
Here is an example of taking a data file with columns of [time, z], running a
math preprocessing command to compute the second difference and the square of
the time step.  The final two arguments are expressions for numpy arrays to be
packaged and printed to stdout.

cat file.txt | p.cl -m 'd2z=c1[n-1] - 2*c1[n] + c1[n+1]; dt2=c0**2' t 'd2z/dt2'


-------------------------------------------------------------------------
Text mode:

This mode is for text manipulation and I'll describe it later.
-------------------------------------------------------------------------
"""


description = "cat file.txt | %prog [-t] [-m 'mathExpr1;...mathExprN'] [outExpr1,... outExprN]"

usage = "cat file.txt | %prog [-t] [-m 'mathExpr1;...mathExprN'] [outExpr1,... outExprN]"
usage = helpString
p = optparse.OptionParser(description=description, usage = usage)

p.add_option('-t','--textMode',action='store_false',
                                      dest='textMode',help="Run in text mode")

p.add_option('-m','--math',action='store',type='string',
                                 dest='mathCommands',metavar='commandList',
                                 help="Semicolon delimited list of python/numpy "+
                         "commands to run before producing numeric-mode output")
p.add_option('-f','--outFormat',action='store',type='string',
                                 dest='fmt',metavar='%0.15g',default = "%0.15g",
                                                help="Numeric output specifier")


options,arguments = p.parse_args()



#--- if text mode specifed, run text algorithms and exit
if options.textMode:
   print "you selected text mode, but lazy-ass Rob hasn't written it yet"
   
#--- run numeric mode stuff
else:
   #--- only import numpy if in numeric mode
   from numpy import *
   
   #--- load the input data
   data = loadtxt(sys.stdin)
   
   #--- figure out how many input columns were provided
   if len(data.shape) == 1:
      #--- create the numpy array
      c0 = data
      #--- create the index array
      n = arange(len(c0))
      #--- create the difference array
      d0 = c0 - c0[n-1]
      d0[0] = NaN
   else:
      #--- create the numpy arrays for the columns
      for nc in range(data.shape[1]):
         exec 'c%d = data[:,%d]' % (nc,nc)
      #--- create the index array
      n = arange(len(c0))
      #--- create the difference arrays
      for nc in range(data.shape[1]):
         exec 'd%d = c%d[n] - c%d[n-1]' % (nc,nc,nc)
         exec 'd%d[0] = NaN' % (nc)
   
   
   #--- loop over all the math statements and execute them
   if options.mathCommands:
      for statement in options.mathCommands.split(';'):
         try:
            exec statement.strip()
         except:
            sys.stderr.write("\n\nError in p.cl.\n\n\tCan't evaluate statement: '%s'\n\n" % statement.strip())
            sys.exit(1)
   
   #--- loop over all output statements create print an output table
   outList = []
   for statement in arguments:
      try:
         exec 'outList.append(%s)' % statement
      except:
         sys.stderr.write("\n\nError in p.cl.\n\n\tCan't evaluate output: '%s'\n\n" % statement.strip())
         sys.exit(1)



   try:      
      savetxt(sys.stdout,column_stack(tuple(outList)),fmt=options.fmt)      
   except IOError:
      pass
   #print outList
   #x = n
   #y = d1
   #outData = column_stack((x,y))
   #savetxt(sys.stdout,outData,fmt="%0.15g")
      
   
   

   
















