REFDIR=./ref
RESDIR=./results

# expect val1 val2 testname [debug|abort]
function expect {
    if [ $1 = $2 ]; then
        _res=0
        printf  "%-40s %s\n" $3 ok
    else
        _res=1
        if [ $# -ge 4 ] && [ $4 = "debug" ]; then
            printf "%-40s %s (expected:#%s# got: #%s#)\n" $3 fail $2 $1
        else
            printf "%-40s %s\n" $3 fail
        fi
        if [ $# -ge 4 ] && [ $4 = "abort" ]; then
            echo aborting
            exit 1
        fi
    fi
    return $_res
}

function dont_expect {
    if [ $1 != $2 ]; then
        _res=0
        printf "%-40s %s\n" $3 ok
    else
        _res=1
        printf "%-40s %s\n" $3 fail
        if [ $# -ge 4 && T $4 = "abort" ]; then
            echo aborting
            exit 1
        fi
    fi
    return $_res
}

# cmp file1 file2
function cmp {
    if [ $# -ne 2 ]; then echo cmp needs 2 files; exit 1; fi
    sum1=$(cat $1 | shasum)
    sum2=$(cat $2 | shasum)
    if [ "$sum1" != "$sum2" ]; then
        return 1
    fi
    return 0
}

function dcheck {
    _e=$(expect $*)
    if [ $? = 0 ]; then
        cmp $RESDIR/$3 $REFDIR/$3
        if [ $? != 0 ]; then
            echo "$_e" "(diff failed)"
            return 1
        fi
    fi
    echo "$_e"
}

# Diff-test. Most common type of test where we run a command and compare
# its output with the expected reference output.
# Usage: dtest <testname> "pipe | of | commands | in | quotes"
# e.g.  dtest echo.4 echo -n foo bar baz
#       dtest echo.6 "echo 1 2 3 4 5 | sum"

function dtest {
    _name=$1
    shift
    sh -c "$*" >$RESDIR/$_name
    dcheck $? 0 $_name
}

