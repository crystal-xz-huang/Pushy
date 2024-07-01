#!/bin/dash

# ==============================================================================
# TEST01: PUSHY-ADD
# ==============================================================================

SCRIPT_DIR=$(pwd)
PATH="$SCRIPT_DIR:$PATH"

TEST_DIR=$(mktemp -d)
cd "$TEST_DIR" || exit 1

trap "rm -rf $TEST_DIR" EXIT

touch a b c

test_command() {
    test_number=$1
    test_name=$2
    expected_output=$3
    expected_status=$4
    actual_output=$5
    actual_status=$6
    if [ "$expected_output" != "$actual_output" ] && [ "$expected_status" != "$actual_status" ]; then
        echo "Test $test_number FAIL: $test_name"
        if [ "$expected_output" != "$actual_output" ]; then
            echo "expected \"$expected_output\" but got \"$actual_output\""
        elif [ "$expected_status" != "$actual_status" ]; then
            echo "expected exit status $expected_status, but got exit status $actual_status"
        fi
    else 
        echo "Test $test_number PASS: $test_name"
    fi
}


# Test 1: pushy-add when .pushy directory is not initialized
test_name="pushy-add multiple files when .pushy directory is not initialized"
expected_output=$(2041 pushy-add a b c 2>&1) 
expected_status=$?
actual_output=$("$SCRIPT_DIR/pushy-add" a b c 2>&1)
actual_status=$?
test_command "1 " "$test_name" "$expected_output" "$expected_status" "$actual_output" "$actual_status"


# Test 2: pushy-add with no arguments when .pushy directory is not initialized
test_name="pushy-add with no arguments when .pushy directory is not initialized"
expected_output=$(2041 pushy-add 2>&1)
expected_status=$?
actual_output=$("$SCRIPT_DIR/pushy-add" 2>&1)
actual_status=$?
test_command "2 " "$test_name" "$expected_output" "$expected_status" "$actual_output" "$actual_status"


# Test 3: pushy-add with no arguments when .pushy directory is initialized
test="pushy-add with no arguments when .pushy directory is initialized"
expected_output=$(2041 pushy-init; 2041 pushy-add 2>&1)
expected_status=$?
rm -rf .pushy
actual_output=$("$SCRIPT_DIR/pushy-init"; "$SCRIPT_DIR/pushy-add" 2>&1)
actual_status=$?
rm -rf .pushy
test_command "3 " "$test" "$expected_output" "$expected_status" "$actual_output" "$actual_status"

# Test 4: pushy-add a file that does not exist in the current working directory
test="pushy-add a file that does not exist in the current working directory"
expected_output=$(2041 pushy-init; 2041 pushy-add d 2>&1)
expected_status=$?
rm -rf .pushy
actual_output=$("$SCRIPT_DIR/pushy-init"; "$SCRIPT_DIR/pushy-add" d 2>&1)
actual_status=$?
rm -rf .pushy
test_command "4 " "$test" "$expected_output" "$expected_status" "$actual_output" "$actual_status"

# Test 5: pushy-add multiple files with one file that does not exist in the current working directory
test="pushy-add multiple files with one file that does not exist in the current working directory"
expected_output=$(2041 pushy-init; 2041 pushy-add a b c d 2>&1)
expected_status=$?
rm -rf .pushy
actual_output=$("$SCRIPT_DIR/pushy-init"; "$SCRIPT_DIR/pushy-add" a b c d 2>&1)
actual_status=$?
rm -rf .pushy
test_command "5 " "$test" "$expected_output" "$expected_status" "$actual_output" "$actual_status"


# Test 6: pushy-add does not work given pathnames with slashes
test="pushy-add pathnames"
expected_output=$(2041 pushy-init; 2041 pushy-add a/b 2>&1)
expected_status=$?
rm -rf .pushy
actual_output=$("$SCRIPT_DIR/pushy-init"; "$SCRIPT_DIR/pushy-add" a/b 2>&1)
actual_status=$?
rm -rf .pushy
test_command "6 " "$test" "$expected_output" "$expected_status" "$actual_output" "$actual_status"

# Test 7: pushy-add a directory
test="pushy-add a directory"
mkdir e
expected_output=$(2041 pushy-init > /dev/null 2>&1; 2041 pushy-add e 2>&1)
expected_status=$?
rm -rf .pushy
actual_output=$("$SCRIPT_DIR/pushy-init" > /dev/null 2>&1; "$SCRIPT_DIR/pushy-add" e 2>&1)
actual_status=$?
rm -rf .pushy
test_command "7 " "$test" "$expected_output" "$expected_status" "$actual_output" "$actual_status"
rm -rf e

# Test 8: pushy-add a file not in the current working directory
test="pushy-add a file not in the current working directory"
mkdir e
touch e/f
expected_output=$(2041 pushy-init; 2041 pushy-add f 2>&1)
expected_status=$?
rm -rf .pushy
actual_output=$("$SCRIPT_DIR/pushy-init"; "$SCRIPT_DIR/pushy-add" f 2>&1)
actual_status=$?
test_command "8 " "$test" "$expected_output" "$expected_status" "$actual_output" "$actual_status"
rm -rf e

# Test 9: pushy-add does not add any files to the index on error
test="pushy-add does not add any files to the index on error"
index_dir=$(find .pushy -type d -name "index") 
no_of_files=$(ls -A "$index_dir" | wc -w) 
if [ "$no_of_files" -eq 0 ]; then
    echo "Test 9  PASS: $test"
else
    echo "Test 9  FAIL: $test"
    echo "expected 0 files in the index directory, but got $no_of_files"
fi

# Test 10: pushy-add adds files to the index on success
test="pushy-add multiple files to the index"
output=$("$SCRIPT_DIR/pushy-add" a b c 2>&1)    # expect no output 
exit_status=$?
index_files=$(ls -A "$index_dir" | wc -w) 

if [ "$output" = "" ] && [ "$exit_status" -eq 0 ] && [ "$index_files" -eq 3 ]; then
    echo "Test 10 PASS: $test"
else
    echo "Test 10 FAIL: $test"
    if [ "$output" != "" ]; then
        echo "expected no output, but got \"$output\""
    elif [ "$exit_status" -ne 0 ]; then
        echo "expected exit status \"0\", but got \"$exit_status\""
    elif [ "$index_files" -ne 3 ]; then
        echo "expected 3 files in the index, but got $index_files"
    fi
fi

# Test 11: pushy-add multiple files with one file that is already in the index
test="pushy-add multiple files with one file that is already in the index"
touch d e f
output=$("$SCRIPT_DIR/pushy-add" a d e f 2>&1) # expect no output
exit_status=$?
current_index_files=$(ls -A "$index_dir" | wc -w) # expect 6 files in the index: a, b, c, d, e, f

if [ "$output" = "" ] && [ "$exit_status" -eq 0 ] && [ "$current_index_files" -eq 6 ]; then
    echo "Test 11 PASS: $test"
else
    echo "Test 11 FAIL: $test"
    if [ "$output" != "" ]; then
        echo "expected no output, but got \"$output\""
    elif [ "$exit_status" -ne 0 ]; then
        echo "expected exit status \"0\", but got \"$exit_status\""
    elif [ "$current_index_files" -ne 6 ]; then
        echo "expected 6 files in the index, but got $current_index_files"
    fi
fi

# Test 12: pushy-add updates the index with the latest version of the file
test="pushy-add updates the index with the latest version of the file"
echo "hello" > a
output=$("$SCRIPT_DIR/pushy-add" a 2>&1)   # expect no output
exit_status=$?
file_compare=$(diff a "$index_dir/a" 2>&1) # expect no output
if [ "$output" = "" ] && [ "$exit_status" -eq 0 ] && [ "$file_compare" = "" ]; then
    echo "Test 12 PASS: $test"
else
    echo "Test 12 FAIL: $test"
    if [ "$output" != "" ]; then
        echo "expected no output, but got \"$output\""
    elif [ "$exit_status" -ne 0 ]; then
        echo "expected exit status \"0\", but got \"$exit_status\""
    elif [ "$file_compare" != "" ]; then
        echo "expected no output, but got \"$file_compare\""
    fi
fi

