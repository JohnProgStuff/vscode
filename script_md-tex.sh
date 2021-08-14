#!/bin/bash

reportName="output.txt"

echo "starting script" > $reportName

while IFS= read -r line
do
  # echo $line >> $reportName
  :
done < out/test.md

headers=""
capturingHeader=false
declare lineNumber=0
declare tableNum=0
declare FigureNum=0

echo "# List Of Tables" > ListOfTables.md
echo "# List Of Figures" > ListOfFigures.md

while IFS= read -r line || [ "$line" ] # a b time x; 
  do
    lineNumber=$((lineNumber+1))
    #echo "a: $a, b: $b $time x"
    #[[ $b == - ]] && echo $time;
    # echo $line
    tag1=""
    idIntag1=""

    ####### HEADER tag1 #######
    # get header [^>] says any char except > so when it hits the first > char it stops
    [[ $line =~ (<[hH][^>]+>) ]] && tag1=${BASH_REMATCH[1]} #&& echo "hdr:${BASH_REMATCH[1]}"

    ####### HEADER tag1 TO LOWER #######
    # replace all uppercase letters with lowercase in a header tag
    header=`echo "$tag1" | tr '[:upper:]' '[:lower:]'`
    

    ####### ID ########### 
    # find id tag in $tag1, 
    #   look for ws(whitespace) the word 'id' any ws and = then a quote and any character 
    #   until a " which probably backtracks to find the quote
    [[ $header =~ ([[:blank:]+]id[[:blank:]=]+[\"].+[\"]) ]] &&
        idIntag1=`echo "${BASH_REMATCH[1]}" | cut -d'"' -f2` #&& echo "'${BASH_REMATCH[1]}'"
    
    # tried to use lookback method to not match id=" but couldn't get it working
    #[[ $line =~ (?<=[[:blank:]+]id])(.+) ]] && echo "'${BASH_REMATCH[1]}'"
    #[[ $line =~ ([:blank:]+id[:blank:]{0,10}=[:blank:]{0,10}\"[)(\'\*[:lower:][:digit:]\.\-]+\") ]] && tag1="${BASH_REMATCH[1]}"

    #print lineNumber tag1 and id if id exists
    [[ $idIntag1 != "" ]] && echo -e "$lineNumber: tag1: $tag1 \t id: $idIntag1"

    #Todo: run a check on idIntag1 to flag invalid characters or linking.

    id2Intag1=""
    ###### the below works but I don't like that it requires a regex a cut, and then another regex ######
    [[ $line =~ ([:blank:]*id[[:blank:]=\"{1})(\*\'[:lower:][:digit:]\.\-]+\") ]] && id2Intag1="${BASH_REMATCH[1]}" && 
         id2Intag1=`echo "$tag1" | cut -d'=' -f2` && [[ $id2Intag1 =~ ([)(\'\*[:lower:][:digit:]\.\-]+) ]] && id2Intag1="${BASH_REMATCH[1]}" || id2Intag1=""
    [[ $id2Intag1 ]] && echo "$lineNumber: 2nd try idTag: $id2Intag1"
    
    ####### TABLE NUMBERING #######
    # find anchor html tag <a id="" >
    #echo "$line"
    anchorTag=""
    idInAtag=""
    if [ "$lineNumber" -gt "14" ]
    then
        # if anchor tag found search, save anchorTag and id field in tag 
        [[ $line =~ (<a[^>]+>) ]] && [[ ${BASH_REMATCH[1]} != "" ]] && #echo "$lineNumber: anchor: ${BASH_REMATCH[1]}" &&
            anchorTag=${BASH_REMATCH[1]} &&
            [[ ${BASH_REMATCH[1]} =~ ([[:blank:]+]id[[:blank:]=]+[\"].+[\"]) ]] &&
            idInAtag=`echo "${BASH_REMATCH[1]}" | cut -d'"' -f2`

        contents=""
        # get contents
        [[ $line =~ (>[^<]+) ]] && contents=${BASH_REMATCH[1]} && contents=` echo $contents | cut -d'>' -f2` #&& echo $contents
        # echo contents if they exists
        [[ "$contents" != "" ]] && echo "contents: '$contents'"
        
        tag2=""
        # tag2
        [[ $line =~ (</a>) ]] && tag2=${BASH_REMATCH[1]} # && echo "tag2: $tag2"

        #print lineNumber tag1 and id if anchor id exists
        [[ $idInAtag != "" ]] && echo -e "$lineNumber: anchor: $anchorTag \t id: $idInAtag contents: $contents"
        
        anchorFix=""
        # if id starts with 'Table' then add 'Table $tableNum to start of content text
        [[ $idInAtag != "" ]] && echo "idinAtag: $idInAtag"
        if [[ $idInAtag =~ (^Table) ]] 
        then
            echo "Tableid: ${BASH_REMATCH[1]}" #| sed s/Table/Table $tableNum/)`
            #remove Table off of contents if it exists
            contents=`echo $contents | sed 's/^Table//g'`
            contents="Table $((++tableNum)) $contents"
            echo ":= $contents"
             #&&[[ ${BASH_REMATCH[1]} =~ .+ ]] && id="Table $tableNum ${BASH_REMATCH[0]}"  && echo "    table id: $id"
            
            line="$anchorTag$contents$tag2"
            echo ":   $line"
            # create a L.O.T.
            echo "- [$contents](out/test.md#$idInAtag)" >> ListOfTables.md
        elif [[ $idInAtag =~ (^Figure) ]]
        then
            echo "Figureid: ${BASH_REMATCH[1]}"
            # remove 'Figure' off of contents if it exists
            contents=`echo $contents | sed 's/^Figure//g'`
            # add Figure N to the front of contents
            contents="Figure $((++FigureNum)) $contents"
            echo ":= $contents"
           
            line="$anchorTag$contents$tag2"
            echo ":   $line"
            # create a L.O.T.
            echo "- [$contents](out/test.md#$idInAtag)" >> ListOfFigures.md
        fi
    fi

    #NOTES:
    # a tidy tool for markdown/html could make sure that any html tags have open and closing carots on same line <a > <h3 >


#	[[ "$line" =~ ([:space:]*section=[\"\'[:space:]0-9]+) ]] && echo "line $lineNumber found: ${BASH_REMATCH[1]}"
    #echo "$line"
#    [[ "$line" =~ (<h3[:space:]*id[a-z=]+) ]] && tag1="${BASH_REMATCH[1]}" && ( header=$line; capturingHeader=true; ) && echo "line $lineNumber ends header"
    #echo "$header, $capturingHeader"
	# [[ "$line" =~ (</h3>) ]] && header+=$line && echo "$lineNumber end header"
    
    if [ "$lineNumber" == "33" ]
    then
      break #exit
    fi
  done < out/test.md

reference=""
lineNumber=0
refState="0"
refStartLine="0"
#re-read file looking for []() tags
while IFS= read -r line || [ "$line" ]
  do
    lineNumber=$((lineNumber+1))
    case $refState in
        new)
            # try to get full ref
            #[display Title](the-file#the-link)

            # try to get partial ref with Title on next line
            #[display]
            ;;
        ) 
            ;;
        )
            ;;
        )
            ;;
    esac
  if [[ $completeRef ]]
  then
    # parse complete ref into parts
    [[ $reference =~ [^\]]+\( ]] && refString=` echo "${BASH_REMATCH[0]}" | cut -d[`
    &&refLink=${BASH_REMATCH[0]}
  fi

  continue
  exit 1

    if [ "$refStartLine" == "0" ]
    then
        # the following line would search for and return [some-Text](moreText)
        if [[ "$line" =~ \[.+[^\]]\]\(.+\) ]] # full reference found [...](...)
        then
            # full reference found
            echo "$lineNumber: fullref : ${BASH_REMATCH[0]}"
            reference=${BASH_REMATCH[0]}
            refState="0"
        elif [[ "$line" =~ \[.+[^\]]\]\(.+ ]] # took ( off '(.+'
        then 
            # partial ref found: missing link ending parentheses[...](..
            echo "$lineNumber: partlink: ${BASH_REMATCH[0]}"
            reference=${BASH_REMATCH[0]}
            refStartLine=$lineNumber
            refState="1"
            # read nextline
            # echo " : next: $nestline"
        elif [[ "$line" =~ \[.+[^\]]\]$ ]]
        then
            # partial ref found: missing link in parentheses, line ends with bracket[...]
            echo "$lineNumber: misslink: ${BASH_REMATCH[0]}"
            reference=${BASH_REMATCH[0]}
            refStartLine=$lineNumber
            refState="2"
        elif [[ "$line" =~ \[.+[^\]] ]]
        then # if [ is found save line number and check for ] next
            # partial ref found: missing display name ending bracket [...
            refStartLine=$lineNumber
            reference=${BASH_REMATCH[0]}
            echo "$lineNumber: partref : ${BASH_REMATCH[0]}"
            refState="3"
        else
            echo "else hit on line: $lineNumber"
        fi
    else # reference has started
    # look for opening [ that might start a reference title
        case $refState in

          0)
            echo "hit refState 0... error"
            ;;
          1)
            # echo "hit refState 1"
            # partial ref found: missing link ending parentheses[...](..
            # look for )
            if [[ $line =~ [^[:blank:]\)]+\) ]]
            then
              echo ${BASH_REMATCH[0]}
              refStartLine=0
              reference+=${BASH_REMATCH[0]}
              echo "fullRef: $reference"
            else # still in block add text to reference
              #todo this might except spaces which we don't want
              [[ $line =~ .+ ]] && reference+=${BASH_REMATCH[0]} 
              echo "$lineNumber: adding text: ${BASH_REMATCH[0]}"
            fi

            if [ $(($lineNumber-$refStartLine)) -gt 3 ] #problem here
            then
              echo "$lineNumber-$refStartLine"
              refStartLine=0
              reference=""
              echo "couldn't find rest of link for partial ref, must not be a reference"
              refState=0
            fi
            ;;
          2)
            echo "hit refState 2"
            # partial ref found: missing link in parentheses, line ends with bracket[...]
            # look for ( and ) it should be on same line, it would have to be a really long link
            if [[ $line =~ \([^\)]+\) ]]
            then #todo: what if this matched ( but not )
              echo ${BASH_REMATCH[0]}
              refStartLine=0
              reference+=${BASH_REMATCH[0]}
              echo "fullRef: $reference"
            else # still in block add text to reference
              [[ $line =~ .+ ]] && reference+=${BASH_REMATCH[0]}
            fi

            if [ $(($lineNumber-$refStartLine)) -gt 3 ]
            then
              refStartLine=0
              reference=""
              echo "couldn't find link for partial ref, must not be a reference"
              refState=0
            fi
            ;;
          3)
            echo "hit refState 3"
            # partial ref found: missing display name ending bracket [...
            # look for ]() 
            # todo: assumes ..](...) is all on one line 
            if [[ $line =~ [^[:blank:]\]]+\]\(^\)+\) ]]
            then #todo: what if this matched ( but not )
              echo ${BASH_REMATCH[0]}
              refStartLine=0
              reference+=${BASH_REMATCH[0]}
              echo "fullRef: $reference"
            else # still in block add text to reference
              [[ $line =~ .+ ]] && reference+=${BASH_REMATCH[0]}
            fi

            if [ $(($lineNumber-$refStartLine)) -gt 2 ]
            then
              refStartLine=0
              reference=""
              echo "couldn't find rest of link for partial ref, must not be a reference"
              refState=0
            fi
            ;;
          4)
            echo "hit refState 4"
            ;;
          *)
            echo "default hit"
            ;;
        esac

        #echo $line
        #elif [[ "$line" =~ \[.+ ]] && echo ${BASH_REMATCH[0]}
        #    refStartLine=$lineNumber
        #fi
        
    # look for closing ] that might end a reference title
    # then look for ( to start reference link
    # then look for ) to end reference link

    # Rule 1: if it spans more than 3 lines it isn't a link
    # If     
    # verify that link file exists at location given

    fi

    if [ "$lineNumber" == "10" ]
    then
      break #exit
    fi
  done < out/test_2.md

exit

echo "-----1----------"
[[ "US/Central - 10:26 PM (CST)" =~ -[[:space:]]*([0-9]{2}:[0-9]{2}) ]] &&
    echo ${BASH_REMATCH[1]}
echo "-----2----------"
#[[ "<h3 section=11 id=\"1st-one\">" =~ ([:space:]*section=[\"\'[:space:]0-9]+) ]]  && echo ${BASH_REMATCH[1]}
[[ "<h3 section=11 id = \"1st-one\">" =~ ([:space:]*id[=\"\'0-9a-z\-]+) ]]  && idtag=${BASH_REMATCH[1]}
echo "$idtag"

[[ "$idtag" =~ ([a-z0-9\-]+) ]] && echo ${BASH_REMATCH[1]}

[[ "<h3 id = \"1st-one\" section=11 >" =~ ([:space:]*id[[:space:]=\"{1}\'0-9a-z\-]+\") ]]  && idtag=${BASH_REMATCH[1]}
echo "$idtag"

    #echo ${BASH_REMATCH[1]} | cut -d'=' -f2

echo "-----3----------"
#[[ "<h3 section='11' id=\"1st-one\">" =~ ([:space:]*section=[\"\'[:space:]0-9]+) ]] && echo ${BASH_REMATCH[1]}
#	match=`echo ${BASH_REMATCH[1]}`
#	[[ "$match" =~ ([0-9]+) ]] && echo ${BASH_REMATCH[1]}
echo "-----4----------"
#[[ "<h3 section= \"11\" id=\"1st-one\">" =~ ([:space:]*section=[\"\'[:space:]*0-9]+) ]] && echo ${BASH_REMATCH[1]}
echo "-----5----------"
#[[ "<h3 section = \"11\" id=\"1st-one\">" =~ ([:space:]*section[=\"\'[:space:]*0-9]+) ]] && echo ${BASH_REMATCH[1]}
echo "-----6----------"
#[[ "<h3 section  \"=11\" id=\"1st-one\">" =~ ([:space:]*section[=\"\'[:space:]*0-9]+) ]] && echo ${BASH_REMATCH[1]} | cut -d'=' -f2
echo "-----7----------"

# [[ [[ "<h3 section=\"11\"id=\"1st-one\">" =~ ([:space:]*section=[0-9]+) ]] ||
# [[ "<h3 section=\"11\"id=\"1st-one\">" =~ ([:space:]*section=[\'\"][0-9]+[\'\"]) ]] ]] ]] &&
#    echo ${BASH_REMATCH[1]}
# declare




# declare