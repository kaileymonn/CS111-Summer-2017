#!/bin/bash
#
# sanity check script for Project 2B
#tarball name
#tarball contents
#student identification 
#makefile targets
#use of expected functions
#error free build
#make clean
#make dist
#re-make
#unrecognized parameters
#recognizes standard parameters
#output seems to include the right fields
#
LAB="lab2b"
README="README"
MAKEFILE="Makefile"

SOURCES="lab2_list.c SortedList.c SortedList.h"
DATA="lab2b_list.csv"
GRAPHS="lab2b_1.png lab2b_2.png lab2b_3.png lab2b_4.png lab2b_5.png"
PROFILE="profile.out"

EXPECTED="$SOURCES $DATA $GRAPHS $PROFILE"
EXPECTEDS=""
PGM="lab2_list"
PGMS=$PGM

TIMEOUT=5

let errors=0

if [ -z "$1" ]
then
    echo usage: $0 your-student-id
    exit 1
else
    student=$1
fi

# make sure the tarball has the right name
tarball="$LAB-$student.tar.gz"
if [ ! -s $tarball ]
then
    echo "ERROR: Unable to find submission tarball:" $tarball
    exit 1
fi

# make sure we can untar it
TEMP="/tmp/TestTemp.$$"
echo "... Using temporary testing directory" $TEMP
function cleanup {
    cd
    rm -rf $TEMP
    exit $1
}

mkdir $TEMP
cp $tarball $TEMP
cd $TEMP
echo "... untaring" $tarbsll
tar xvf $tarball
if [ $? -ne 0 ]
then
    echo "ERROR: Error untarring $tarball"
    cleanup 1
fi

# make sure we find all the expected files
echo "... checking for expected files"
for i in $README $MAKEFILE $EXPECTED
do
    if [ ! -s $i ]
	then
	echo "ERROR: unable to find file" $i
	let errors+=1
	else
	echo "        $i ... OK"
	fi
done

# make sure the README contains name and e-mail
echo "... checking for submitter info in $README"
function idString {
    result=`grep $1 $README | cut -d: -f2 | tr -d \[:blank:\] | tr -d "\r"`
    if [ -z "$result" ]
	then
	echo "ERROR - $README contains no $1";
	let errors+=1
	elif [ -z "$2" ]
	then
	# no match required
	echo "        $1 ... $result"
	else
	f1=`echo $result | cut -f1 -d,`
	f2=`echo $result | cut -f2 -d,`
	if [ "$f1" == "$2" ]
	    then
	    echo "        $1 ... $f1"
	    elif [ -n "$f2" -a "$2" == "$f2" ]
	    then
	    echo "        $1 ... $f1,$f2"
	    else
	    echo "ERROR: $1 does not include $2"
	    let errors+=1
	    fi
	fi
}

idString "NAME:"
idString "EMAIL:"
idString "ID:" $student

function makeTarget {
    result=`grep $1: $MAKEFILE`
    if [ $? -ne 0 ]
	then
	echo "ERROR: no $1 target in $MAKEFILE"
	let errors+=1
	else
	echo "        $1 ... OK"
	fi
}

echo "... checking for expected make targets"
makeTarget "clean"
makeTarget "dist"
makeTarget "tests"
makeTarget "graphs"
makeTarget "profile"

# make sure we find files with all the expected suffixes
echo "... checking for other files of expected types"
for s in $EXPECTEDS
do
    names=`echo *.$s`
    if [ "$names" = '*'.$s ]
	then
	echo "ERROR: unable to find any .$s files"
	let errors+=1
	else
	for f in $names
	do
	    echo "        $f ... OK"
	    done
	fi
done

# make sure we can build the expected program
echo "... building default target(s)"
make 2> STDERR
RET=$?
if [ $RET -ne 0 ]
then
    echo "ERROR: default make fails RC=$RET"
    let errors+=1
fi
if [ -s STDERR ]
then
    echo "ERROR: make produced output to stderr"
    let errors+=1
fi

# test a make clean
echo "... make clean"
make clean 2> STDERR
RET=$?
if [ $RET -ne 0 ]
then
    echo "ERROR: make clean fails RC=$RET"
    let errors+=1
fi
if [ -s STDERR ]
then
    echo "ERROR: make clean produced output to stderr:"
    cat STDERR
    let errors+=1
fi

# make sure that all products are removed
echo "... confirming removal of Makefile products"
for t in $PGMS $GRAPHS $DATA $tarball
do 
    if [ -s $t ]
	then
	echo "ERROR: make clean leaves $t"
	let errors+=1
	fi
done

# make sure the intermediates are removed
echo "... confirming removal of object modules and debug symbols"
for t in *.o *.dSYM
do
    if [ -s $t ]
	then
	echo "ERROR: make clean leaves $t"
	let errors+=1
	fi
done

# test a make dist
echo "... make dist"
make dist 2> STDERR
RET=$?
if [ $RET -ne 0 ]
then
    echo "ERROR: make dist fails RC=$RET"
    let errors+=1
fi
# we expect stderr output from some of these tests

echo "... confirming creation of tarball"
if [ ! -s $tarball ]
then
    echo "ERROR: make dist does not create $tarball"
    let errors+=1
fi

# test a make after a make clean
echo "... re-building default target(s)"
make 2> STDERR
RET=$?
if [ $RET -ne 0 ]
then
    echo "ERROR: default make fails RC=$RET"
    let errors+=1
fi
if [ -s STDERR ]
then
    echo "ERROR: make produced output to stderr:"
    cat STDERR
    let errors+=1
fi




echo "... checking for expected products"
for p in $PGMS
do
    if [ ! -x $p ]
	then
	echo "ERROR: unable to find expected executable" $p
	let errors+=1
	else
	echo "        $p ... OK"
	fi
done

# see if it accepts the expected arguments
function testrc {
    if [ $1 -ne $2 ]
	then
	echo "ERROR: expected RC=$2, GOT $1"
	let errors+=1
	fi
}

# see if they detect and report invalid arguments
for p in $PGMS
do
    echo "... $p detects/reports bogus arguments"
    ./$p --bogus > /dev/null 2>STDERR
    testrc $? 1
    if [ ! -s STDERR ]
	then
	echo "No Usage message to stderr for --bogus"
	let errors+=1
	else
	cat STDERR
	fi
done

# sanity test on basic output
#--threads=
#--iterations=
#--yield=
#--sync=
#--lists=
#
# (a) are the parameters recognized, and do they seem to have effect
# (b) is the output propertly formatted and consistent with the parameters
#
threads=1
iterations=2
yield="idl"
lists=2
opsper=3
for s in m s
do
    echo "... testing $LIST_PGM --iterations=$iterations --threads=$threads --yield=$yield --sync=$s --lists=$lists"
    ./$PGM --iterations=$iterations --threads=$threads --yield=$yield --sync=$s  --lists=$lists> STDOUT
    testrc $? 0
    echo "        RC=0 ... OK"

    # check number of fields (2B: 8)
    fields=`cat STDOUT | tr "," " " | wc -w`
    if [ "$fields" = "8" ]
	then
	echo "        number of fields ... $fields (includes wait time)"
	else
	echo "INCORRECT NUMBER OF FIELDS: " `cat STDOUT`
	let errors+=1
	fi

    # check field 1 = tag
    f=1
    v=`cat STDOUT | cut -d, -f$f`
    if [ "$v" = "list-$yield-$s" ]
	then
	echo "        output tag ... OK"
	else
	echo "FIELD $f: wrong tag: " `cat STDOUT`
	let errors+=1
	fi

    # check field 2 = threads
    f=2
    v=`cat STDOUT | cut -d, -f$f`
    if [ "$v" = "$threads" ]
	then
	echo "        threads field ... OK"
	else
	echo "FIELD $f != #threads: " `cat STDOUT`
	let errors+=1
	fi

    # check field 3 = iterations
    f=3
    v=`cat STDOUT | cut -d, -f$f`
    if [ "$v" = "$iterations" ]
	then
	echo "        iterations field ... OK"
	else
	echo "FIELD $f != #iterations: " `cat STDOUT`
	let errors+=1
	fi

    # check field 4 = lists
    f=4
    v=`cat STDOUT | cut -d, -f$f`
    if [ "$v" -eq "$lists" ]
	then
	echo "        lists field ... OK"
	else
	echo "FIELD $f != #lists: " `cat STDOUT`
	let errors+=1
	fi

    # check field 5 = ops
    f=5
    v=`cat STDOUT | cut -d, -f$f`
    if [ $v -eq $((threads*iterations*opsper)) ]
	then
	echo "        operations field ... threads x iterations x $opsper"
	else
	echo "FIELD $f SHOWS incorrect ops: " `cat STDOUT`
	let errors+=1
	fi

    # check field 6 = total time per run
    f=6
    t=`cat STDOUT | cut -d, -f$f`
    if [ $t -lt 2 -o $t -gt 10000000 ]
	then
	echo "FIELD $f is not a reasonable execution time: $t"
	let errors+=1
	else
	echo "        tot time ... plausible"
	fi

    # check field 7 = time per operation
    f=7
    v=`cat STDOUT | cut -d, -f$f`
    let avg=$((t/(threads*iterations*opsper)))
    if [ $v -gt $((avg+1)) -o $v -lt $((avg-1)) ]
	then
	echo "FIELD $f != tot/ops: " `cat STDOUT`
	let errors+=1
	else
	echo "        tot/ops ... OK"
	fi

    # check field 8 ... wait time
    f=8
    v=`cat STDOUT | cut -d, -f$f`
    if [ $v -lt 2 -o $v -gt $avg ]
	then
	echo "FIELD $f implausible wait/op: " `cat STDOUT`
	let errors+=1
	else
	echo "        wait/op ... plausible"
	fi
done

# that's all the tests I could think of
echo
if [ $errors -eq 0 ]; then
    echo "SUBMISSION $tarball ... passes sanity check"
    echo
    echo
    cleanup 0
else
    echo "SUBMISSION $tarball ... fails sanity check with $errors errors!"
    echo
    echo
    cleanup -1
fi
