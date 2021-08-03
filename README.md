GitHub Repository Update Tool:
The tool walks through all the directories in the current path,
pulls changes from remote and installs dependencies (runs 'npm install').
The script will update the directory only when the following conditions are met:
- you are on master branch
- you have nothing to commit, working tree is clean
- your branch is behind 'origin/master
Otherwise the directory will be skipped.
