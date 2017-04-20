RESULT=$(ps -A | grep actorflasks-assembly-1.0.jar | grep Peer | grep -v 'grep' | grep -v 'ttys' | awk '{print $1 ": " $6 " | " $13 " --- " $3}' | sort | uniq | xargs -L 1 echo 'peer@  ')

if [[ -z "${RESULT// }" ]]; # replaces all matches of the pattern (a single space) with nothing, to check for emptyness of results
then
echo "No current DataFlasks processes"
else
echo "Current functioning peer processes"
echo "$RESULT"
fi
