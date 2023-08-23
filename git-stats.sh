#!/bin/bash
shopt -s lastpipe

EXTENSIONS_INPUT=$@
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
# # echo $USERNAME_CANDIDATES

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

TOP_CONTRIBUTED_FILE_COUNT=0
CONTRIBUTED_FILE_COUNT=0
TOTAL_FILE_COUNT=0

files=$(git ls-files | grep $EXTENSIONS_GREP_FORMAT)
for file in $files; 
do
    BLAME_FILE_COUNT=$(git blame $file | grep -i $FIRST_NAME | wc -l)
    ((TOTAL_BLAME+=$BLAME_FILE_COUNT));
    if [ $BLAME_FILE_COUNT -gt $TOP_CONTRIBUTED_FILE_COUNT ];
    then
        TOP_CONTRIBUTED_FILE_COUNT=$BLAME_FILE_COUNT
        echo New TOP contributed on git blame: $TOP_CONTRIBUTED_FILE_COUNT "lines on" $file
    fi
    if [ $BLAME_FILE_COUNT -gt 0 ];
    then
        ((CONTRIBUTED_FILE_COUNT+=1))
    fi
    ((TOTAL_FILE_COUNT+=1))
    
done
CONTRIBUTED_AVERAGE=$(($TOTAL_BLAME / $CONTRIBUTED_FILE_COUNT))

echo "Number of lines currently used" $TOTAL_BLAME 
echo "Number of files currently contributed" $CONTRIBUTED_FILE_COUNT/$TOTAL_FILE_COUNT
echo "Average lines by file" $CONTRIBUTED_AVERAGE

DATE_LAST_COMMIT_BY_AUTHOR=$(git log --pretty=format:"%ad%x09%an" --date=short --grep=$FIRST_NAME -i | head -n 1 | awk -F' ' '{print $1}')
DATE_FIRST_COMMIT_BY_AUTHOR=$(git log --reverse --pretty=format:"%ad%x09%an" --date=short --grep=$FIRST_NAME -i | head -n 1 | awk -F' ' '{print $1}')
echo "My commits between:" $DATE_FIRST_COMMIT_BY_AUTHOR":"$DATE_LAST_COMMIT_BY_AUTHOR 

