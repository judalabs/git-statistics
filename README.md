### git-statistics
Project statistics and contribution by numbers

### How to run?
./git-stats.sh path-to-desired-project list-of-extensions-separated-by-space

Example:
./git-status.sh /home/user/projectx .java .sql


It generates a result json file containing the following properties

- myFirstCommit
- myLastCommit
- myTotalAddedLines
- myTotalRemovedLines
- myLinesOfCode
- myCommitCount
- myLegacyLines
- myTopContributedOnSameFile
- myFileContributions
- totalFiles
- totalLinesCount
- myAverageContributionByFile
