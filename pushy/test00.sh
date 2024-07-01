#!/bin/dash

# ==============================================================================
# TEST00: PUSHY-INIT
# ==============================================================================

# Add the directory containing the pushy script to the PATH
SCRIPT_DIR=$(pwd)
PATH="$SCRIPT_DIR:$PATH"

# Create and move to a temporary directory to run the tests
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR" || exit 1 

# Remove the temporary directory when the script exits
trap 'rm -rf "$TEST_DIR"' INT TERM EXIT

# Function to compare the expected output and status with the actual output and status
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

# Test 1: Check if the usage message is correct when ./pushy-init is called with an argument
test="pushy-init with an argument prints an error message"
expected_output=$(2041 pushy-init a 2>&1) 
expected_status=$?
actual_output=$("$SCRIPT_DIR/pushy-init" a 2>&1)
actual_status=$?
test_command 1 "$test" "$expected_output" "$expected_status" "$actual_output" "$actual_status"

# Test 2: Check that no .pushy directory is created when ./pushy-init is called with an argument
if [ ! -d ".pushy" ]; then
    echo "Test 2 PASS: no .pushy directory is created when pushy-init is called with an argument"
else
    echo "Test 2 FAIL: .pushy directory was created when pushy-init was called with an argument"
fi

# Test 3: Check that ./pushy-init prints the correct output
test="pushy-init prints the correct output on success"
expected_output=$(2041 pushy-init 2>&1)
expected_status=$?
rm -rf .pushy  # Remove the .pushy directory to test the output of ./pushy-init
actual_output=$("$SCRIPT_DIR/pushy-init" 2>&1)
actual_status=$?
test_command 3 "$test" "$expected_output" "$expected_status" "$actual_output" "$actual_status"

# Test 4: Check that the .pushy directory is created after running ./pushy-init
if [ -d ".pushy" ]; then
    echo "Test 4 PASS: .pushy directory is created after running pushy-init"
else
    echo "Test 4 FAIL: .pushy directory was not created after running pushy-init"
fi

# Test 5: Check that the .pushy directory is not empty after running ./pushy-init
if [ "$(ls -A .pushy)" ]; then
    echo "Test 5 PASS: .pushy directory is initialised"
else
    echo "Test 5 FAIL: .pushy directory is empty"
fi

# Test 6: Check if the error message is correct when .pushy already exists
test="pushy-init when .pushy already exists"
expected_output=$(2041 pushy-init 2>&1)
expected_status=$?
actual_output=$("$SCRIPT_DIR/pushy-init" 2>&1)
actual_status=$?
test_command 6 "$test" "$expected_output" "$expected_status" "$actual_output" "$actual_status"

# Test 7: Check that only one .pushy directory is created in the current directory
num_pushy_dirs=$(find . -name ".pushy" | wc -w)
if [ "$num_pushy_dirs" -eq 1 ]; then
    echo "Test 7 PASS: only one .pushy directory was found"
else
    echo "Test 7 FAIL: $num_pushy_dirs .pushy directories were found"
fi

