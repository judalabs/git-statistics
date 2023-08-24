#!/bin/bash

shopt -s lastpipe
actual=$(pwd)
cd $1
EXTENSIONS_INPUT=${@:2:$#}
EXTENSIONS_GREP_FORMAT=${EXTENSIONS_INPUT// /\\|}

get_first_name() {
    message=$(echo $1 | tr ".=" "|")
    echo $message
}

GIT_USERNAME=$(git config user.name)
FIRST_NAME=$(get_first_name $GIT_USERNAME)
echo "Current user: " $GIT_USERNAME
echo "Searching for first name:" $FIRST_NAME


# USERNAME_CANDIDATES=$(echo $(git log --format='%aN' | sort -u | grep $FIRST_NAME))  #get all author names for debugging purposes
# echo $USERNAME_CANDIDATES

git shortlog -sn --all | grep -i $FIRST_NAME | while read -r line;
do
    ((COMMITS_BY_USER+=$(echo $line | awk -F' ' '{print $1}')))
done

git log --format='%aN' | sort -u | grep -i $FIRST_NAME | while read -r author ;
    do
    echo "found ["$author"]"
    tuples=($(git log --author="$author" --pretty=tformat: --numstat | grep $EXTENSIONS_GREP_FORMAT | gawk '{ add += $1; subs += $2; loc += $1 - $2 } END { printf "%s %s %s\n", add, subs, loc }' -))
    if [ ${#tuples} -gt 0 ];
    then
        ((added+=${tuples[0]}))
        ((removed+=${tuples[1]}))
        ((loc+=${tuples[2]}))
    fi
done
echo -e "Lines added:" $added "\tLines removed:" $removed "\tLOC(added-removed):" $loc "\tCommits:" $COMMITS_BY_USER

TOTAL_FILES=$(git ls-files | grep $EXTENSIONS_GREP_FORMAT | wc -l)

TOP_CONTRIBUTED_SAME_FILE=0
CONTRIBUTED_FILE_COUNT=0
TOTAL_FILE_COUNT=0
files=$(git ls-files | grep $EXTENSIONS_GREP_FORMAT)
for file in $files; 
do
    CONTRIBUTED_LINES_ON_FILE=$(git blame $file | grep -i $FIRST_NAME | wc -l)
    ((MY_LEGACY_LINES+=$CONTRIBUTED_LINES_ON_FILE));
    if [ $CONTRIBUTED_LINES_ON_FILE -gt $TOP_CONTRIBUTED_SAME_FILE ];
    then
        TOP_CONTRIBUTED_SAME_FILE=$CONTRIBUTED_LINES_ON_FILE
        echo New TOP contributed on git blame: $TOP_CONTRIBUTED_SAME_FILE "lines on" $file
    fi
    if [ $CONTRIBUTED_LINES_ON_FILE -gt 0 ];
    then
        ((CONTRIBUTED_FILE_COUNT+=1))
    fi
    ((TOTAL_FILE_COUNT+=1))
    
done
CONTRIBUTED_AVERAGE=$(($MY_LEGACY_LINES / $CONTRIBUTED_FILE_COUNT))

TOTAL_LINES_COUNT=$(git ls-tree --full-tree -r HEAD --name-only | grep $EXTENSIONS_GREP_FORMAT | xargs -I '$' git show master:$ | wc -l)
echo "Number of lines currently used" $MY_LEGACY_LINES/$TOTAL_LINES_COUNT
echo "Number of files currently contributed" $CONTRIBUTED_FILE_COUNT/$TOTAL_FILE_COUNT
echo "Average lines by file" $CONTRIBUTED_AVERAGE


DATE_LAST_COMMIT_BY_AUTHOR=$(git log --pretty=format:"%ad%x09%an" --date=short --grep=$FIRST_NAME -i | head -n 1 | awk -F' ' '{print $1}')
DATE_FIRST_COMMIT_BY_AUTHOR=$(git log --pretty=format:"%ad%x09%an" --date=short --grep=$FIRST_NAME -i --reverse | head -n 1 | awk -F' ' '{print $1}')
echo "My commits between:" $DATE_FIRST_COMMIT_BY_AUTHOR":"$DATE_LAST_COMMIT_BY_AUTHOR 

echo "{
    \"totalAddedLines\": $added,
    \"totalRemovedLines\": $removed,
    \"linesOfCode\": $loc,
    \"myLegacyLines\": $MY_LEGACY_LINES,
    \"topContributedOnSameFile\": $TOP_CONTRIBUTED_SAME_FILE,
    \"myFileContributions\": $CONTRIBUTED_FILE_COUNT,
    \"totalFiles\": $TOTAL_FILE_COUNT,
    \"totalLinesCount\": $TOTAL_LINES_COUNT,
    \"myAverageContributionByFile\": $CONTRIBUTED_AVERAGE,
    \"firstCommit\": \"$DATE_FIRST_COMMIT_BY_AUTHOR\",
    \"lastCommit\": \"$DATE_LAST_COMMIT_BY_AUTHOR\"
}" > result.txt
