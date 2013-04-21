#! /usr/bin/env ppython

import re
import sys
import optparse
import string
import os

#--- set up to handle command line arguments
description="Python regular expression processor"
usage = "%prog [optional args]"
p = optparse.OptionParser(usage,description=description)
p.add_option('-r','--regExp',action='store',type='string',
      dest='rex', metavar="'.*'",default=".*",help="regular expression")
p.add_option('-o','--output',action='store',type='string',
      dest='outExp', metavar="'m.group(0)'",default="m.group(0)",
      help="output specs (m = matchObj for normal, m = findall result for multiline)")
p.add_option('-m','--mulitLine',action='store_true', default=False,
      dest='multiLine', help='match across lines')






#--- parse the input arguments
options,arguments=p.parse_args()

#--- create a regular expression object from the command line input
if options.multiLine:
   cmd =  'rex = re.compile(r"""%s""",re.DOTALL|re.MULTILINE)' % options.rex
else:
   cmd =  'rex = re.compile(r"""%s""")' % options.rex

exec cmd

#--- create a default command object that prints desired results
outExp = options.outExp
if options.multiLine and (outExp=="m.group(0)"):
   outExp = "m"
printCommand = """print %s""" % outExp

if options.multiLine:
   s = sys.stdin.read()
   m = rex.findall(s)
   emptyList = []
   if(type(m) == type(emptyList)):
      M = m
      for m in M:
         exec printCommand
   else:
      exec printCommand

   
else:
   #--- process each input line with the regular expression
   try:
      for line in sys.stdin:
         m = rex.match(line)
         #--- if line matched
         if m:
            exec printCommand
   except IOError:
      sys.exit()


         





