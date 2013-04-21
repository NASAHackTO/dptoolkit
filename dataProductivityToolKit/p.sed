#! /usr/bin/env ppython

import re
import sys
import optparse
import string
import os

#--- set up to handle command line arguments
description="sed-like utility using python regular expressions"
usage = "%prog [optional args]"
p = optparse.OptionParser(usage,description=description)
p.add_option('-f','--find',action='store',type='string',
      dest='rex',default="",metavar="''",help="regular expression to find")
p.add_option('-r','--replace',action='store',type='string',metavar="''",
      dest='outExp',default=r"",
         help=r"replace all occurences with this expression. (Groups define by \1,\2,etc.)")



#--- parse the input arguments
options,arguments=p.parse_args()




#--- process each input line with the regular expression
for line in sys.stdin:
   try:
      sys.stdout.write(re.sub(options.rex,options.outExp,line))
   except IOError:
      sys.exit()
      
