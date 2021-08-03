#!/bin/bash

WORKDIR=$(pwd)

declare -a manual_handle_array

# package.json search depth from the bash root
depth_root=3
# package.json search depth from the app dir
depth_app=2

Off='\033[0m'             # Text Reset
Yellow='\033[0;33m'       # Yellow
BYellow='\033[1;33m'      # Yellow
Black='\033[0;30m'        # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
Cyan='\033[0;36m'         # Cyan
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White
BIWhite='\033[1;97m'      # White


function readme {
  printf "\n${BCyan}GitHub Repository Update Tool:${Cyan}\nThe tool walks through all the directories in the current path,\
\npulls changes from remote and installs dependencies (runs 'npm install').\n\
The script will update the directory only when the following conditions are met:\
\n- you are on master branch\
\n- you have nothing to commit, working tree is clean\
\n- your branch is behind 'origin/master\
\nOtherwise the directory will be skipped.${Off}\n\n"
}


function walkDir {
  printf "${BIWhite}\nDirectory: $1${Off}\n"
  cd $1
  checkGitStatus $1
  cd $WORKDIR
}


function quit {
  printf "${BYellow}\nTasks are completed, quitting...${Off}\n\n"
}


function printDirArray {
arr=("$@")
printf "${Yellow}"
for each in "${arr[@]}"
  do
    printf '%s%s\n' " * " "$each"
  done
printf "${Off}"
}


function checkGitStatus {
  printf "[$1] Fetching origin... \n"
  git fetch origin 2> /dev/null
  
  master=$(git status 2> /dev/null | grep -E -i "On branch master")
  clean=$(git status 2> /dev/null | grep -E -i "Nothing to commit, working tree clean")
  uptodate=$(git status 2> /dev/null | grep -E -i "Your branch is up to date with 'origin/master'")
  behind=$(git status 2> /dev/null | grep -E -i "Your branch is behind 'origin/master'")
  
  if [[ -n "$master" ]] && [[ -n "$clean" ]]; then
      if [[ -n "$behind" ]]; then
          printf "[$1] Pulling... "
          git pull
          runNpmInstall $(pwd) $depth_app $1
      elif [[ -n "$uptodate" ]]; then
          printf "[$1] ${BGreen}Your branch is up to date with origin/master${Off}\n"
          return 0      
      fi  
  else
  printf "[$1] ${BRed}Directory can not be handled by script. Skipping...${Off}\n"
  manual_handle_array+=($(pwd))
  fi
}


function runNpmInstall {
  printf "${BYellow}\nStarting dependencies' update...${Off}\n"
  package_jsons=()
  while IFS=  read -r -d $'\0'; do
    package_jsons+=("$REPLY")
  done < <(find $1 -maxdepth $2 -type f ! -path "*/node_modules/*" -name package.json -print0)
  if [ "${#package_jsons[@]}" -ne 0 ]; then
      printf "\n[$3] package.json files are found in the following directories:\n"
      printDirArray "${package_jsons[@]}"
      printf "\n[$3] Running npm install...\n"
      find $1 -maxdepth $2 -type f ! -path "*/node_modules/*" -name package.json -execdir npm install \;
  else
      printf "\n[$3] No package.json files are found. Skipping npm install run...\n"
  fi
}


function update {
  printf "${BYellow}\nStarting update...${Off}\n"
  for f in *; do
      if [ -d "$f" ]; then
          walkDir $f
      fi
  done
  
if [ "${#manual_handle_array[@]}" -ne 0 ]; then
  printf "${BRed}\nCould not update ${#manual_handle_array[@]} directories. You should process the following directories manually:${Off}\n"
  printDirArray "${manual_handle_array[@]}"
else
  printf "\n${BGreen}All the directories are up to date${Off}\n"
fi
}


# ===== main =====
readme
PS3='Please select the process: '
options=("Sync with origin/master + Run npm install" "Run npm install" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Sync with origin/master + Run npm install")
            printf "Choice: Sync with origin/master + Run npm install\n"
            update
            quit
            break
            ;;
        "Run npm install")
            printf "Choice: Run npm install\n"
            runNpmInstall . $depth_root $(pwd)
            quit
            break
            ;;
        "Quit")
            printf "Choice: Quit\n"
            quit
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done