#!/bin/bash
shopt -s lastpipe

EXTENSIONS_INPUT=$@
EXTENSIONS_GREP_FORMAT=${EXTENSIONS_INPUT// /\\|}

get_first_name() {
    message=$(echo $1 | tr ".=" "|")
    echo $message
}

spĺit_to_array() {
    echo ${$1// / }
}

GIT_USERNAME=$(git config user.name)
FIRST_NAME=$(get_first_name $GIT_USERNAME)
echo "Current user: " $GIT_USERNAME
echo "Searching for first name:" $FIRST_NAME


USERNAME_CANDIDATES=$(echo $(git log --format='%aN' | sort -u | grep $FIRST_NAME))  #get author names
# echo $USERNAME_CANDIDATES

TOTAL_FILES=$(git ls-files | grep $EXTENSIONS_GREP_FORMAT | wc -l)

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
    # printf "%s\t\t\t Added: %s\t Removed:%s\t Lines of code(LOC):%s\n" "$author" $added $removed $loc
    
done
echo -e "Lines added:" $added "\tLines removed:" $removed "\tLOC(added-removed):" $loc "\tCommits:" $TOTAL_FILES


git shortlog -sn --all | grep -i $FIRST_NAME | while read -r line;
do
    ((COMMITS_BY_USER+=$(echo $line | awk -F' ' '{print $1}')))
done
echo "TOTAL COMMITS: " $COMMITS_BY_USER

TOP_CONTRIBUTED_FILE_COUNT=0
CONTRIBUTED_FILE_COUNT=0
TOTAL_FILE_COUNT=0

files=$(git ls-files| grep $EXTENSIONS_GREP_FORMAT)
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
        # echo $TOTAL_BLAME $BLAME_FILE_COUNT $file 
    fi
    ((TOTAL_FILE_COUNT+=1))
    
done
CONTRIBUTED_AVERAGE=$(($TOTAL_BLAME / $CONTRIBUTED_FILE_COUNT))

echo "number of lines currently used" $TOTAL_BLAME 
echo "Number of files currently contributed" $CONTRIBUTED_FILE_COUNT 
echo "Total of files" $TOTAL_FILE_COUNT
echo "AVG lines by file" $CONTRIBUTED_AVERAGE

echo $TOTAL_BLAME
