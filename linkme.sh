#!/bin/sh
#==================================================
# linkme.sh
#
# A script to create symlinks based on a config file
# named 'linkme'
#
# USEAGE:
#       linkme.sh
#
# REQUIRES: sh,readlink,pwd,grep,ln,mv
#
# CREATED: Mon Mar 24 09:53:34 CDT 2014
#==================================================

#========================================
# FUNCTIONS
#========================================

#========================================
# MAIN ()
#========================================
#..Record inital current working dir.....
IWD=${PWD}

#..Set timestamp for this session........
TIMESTAMP=$(date '+%Y%m%d')

#..Test that there is a config file in current dir..
if [ ! -s  "${IWD}/linkme" ]; then
  echo "ERROR: No file named 'linkme' in '${IWD}'."
  exit 1
fi

RULE=1
LINE=0
#..Read config file, ./linkme.....
while read line; do
  LINE=$(expr ${LINE} + 1)

  #..Skip.comments..............
  TEMP=`echo $line | grep '^#'`
  if [ $? -eq 0 ]; then
    continue
  fi

  #..Skip.blank.lines...........
  TEMP=`echo $line | grep '^[[:space:]]*$'`
  if [ $? -eq 0 ]; then
    continue
  fi

  #..We're not skipping so create some separation
  echo '' #VERBOSE

  #..Parse.line.................
  L_DIR=''; L_DIR=`echo ${line} |cut -d':' -f1`
  L_SRC=''; L_SRC=`echo ${line} |cut -d':' -f2`
  L_DST=''; L_DST=`echo ${line} |cut -d':' -f3`

  #..Make.sure.values.are.not.null.....
  if [ "${L_DIR}x" = 'x' ]; then
    echo "Line ${LINE}: field 1 can't be blank. Skipping"
    continue
  fi
  if [ "${L_SRC}x" = 'x' ]; then
    echo "Line ${LINE}: field 2 can't be blank. Skipping"
    continue
  fi
  if [ "${L_DST}x" = 'x' ]; then
    echo "Line ${LINE}: field 3 can't be blank. Skipping"
    continue
  fi

  #..Do.substitutions.for.special.values.......
  # (%HOME% valid only for directory config item)
  eval L_DIR=\`echo \$\{L_DIR\} \|sed \'s\|%HOME%\|${HOME}\|\'\`

  # (%HERE% valid only for source file/dir config item)
  # Make %HERE% relative to $L_DIR
  eval REL_HERE=\`echo \"\$\{IWD\}\" \|sed \'s\|\^${HOME}/\|\|\'\`
  eval L_SRC=\`echo \$\{L_SRC\} \|sed \'s\|%HERE%\|${REL_HERE}\|\'\`

  echo "Executing Rule ${RULE} [Ln: ${LINE}]: (${L_DST})" #VERBOSE
  echo " * GOAL:  In '${L_DIR}' create '${L_DST}' -> '${L_SRC}'" #VERBOSE

  ##FIXME - add code computing relative path inside SymLinked dirs
  if [ -h ${L_DIR} ]; then
    echo " ! ERROR: '${L_DIR}' is a SymLink. Skip this rule."
    echo " ! NOTE:  Not smart enough to compute link path properly ...yet."
    continue
  fi

  #..Create directory if it doesn't exist................
  if [ ! -d ${L_DIR} ]; then
    echo " * STATE: Directory '${L_DIR}' doesn't exist."
    echo " ! MAKE:  Create directory '${L_DIR}'"
    eval mkdir -p ${L_DIR}
  fi

  #..Change to directory that will contain the symlink...
  eval cd ${L_DIR}

  #..Test that the file you are linking to exists...........
  if [ ! -s ${L_SRC} ]; then
    echo " ! ERROR: '${L_SRC}' doesn't exist. Skip this rule."
    continue
  fi

  eval OUTPUT=\`readlink ${L_DST}\`
  #echo "${L_SRC} is symlink pointing to ${OUTPUT}"
  if [ $? -eq 0 ]; then
    echo " * STATE: In '${PWD}' exists '${L_DST}' -> '${OUTPUT}'"
    if [ "x${L_SRC}" = "x${OUTPUT}" ]; then
      echo " * STATE: Current SymLink matches GOAL - Done!"
    else
      echo " * STATE: Current SymLink does not match GOAL."
      echo " ! REMOVE: '${L_DST}'"
      rm -f ${L_DST}
      echo " ! MAKE:  In '${PWD}' create '${L_DST}' -> '${L_SRC}'"
      ln -s ${L_SRC} ${L_DST}
    fi
  else
    if [ -e ${L_DST} ]; then
      echo " * STATE: '${L_DST}' already exists and isn't a SymLink."
      echo " ! MOVE:  Rename to '${L_DST}.${TIMESTAMP}_MOVED_BY_LINKME'"
      mv ${L_DST} ${L_DST}.${TIMESTAMP}
    else
      echo " * STATE: In '${PWD}', file '${L_DST}' doesn't exist."
    fi
    echo " ! MAKE:  In '${PWD}' create '${L_DST}' -> '${L_SRC}'"
    ln -s ${L_SRC} ${L_DST}
  fi

  RULE=$(expr ${RULE} + 1)
done < "${IWD}/linkme"
