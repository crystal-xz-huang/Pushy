#!/bin/dash

# ==============================================================================
# TEST03: PUSHY-LOG
# ==============================================================================

SCRIPT_DIR=$(pwd)
PATH="$SCRIPT_DIR:$PATH"

TEST_DIR=$(mktemp -d)
cd "$TEST_DIR" || exit 1

EXPECTED_OUTPUT=$(mktemp)
ACTUAL_OUTPUT=$(mktemp)

trap 'rm -rf "$TEST_DIR" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT"' INT TERM EXIT

test_command() {
    test_no=$1
    test_name=$2
    expected=$3
    actual=$4
    expected_exit_status=$5
    actual_exit_status=$6

    if ! diff -u "$expected" "$actual" > /dev/null || [ "$expected_exit_status" -ne "$actual_exit_status" ]; then
        echo "TEST $test_no FAIL: $test_name" 
        if [ "$expected_exit_status" -ne "$actual_exit_status" ]; then
            echo "Exit status: expected $expected_exit_status, actual $actual_exit_status"
        fi

        if ! diff -u "$expected" "$actual" > /dev/null; then
            echo "Expected output:"
            echo "$(cat "$expected")"
            echo "\n"
            echo "Actual output:" 
            echo "$(cat "$actual")"
            echo "\n"
        fi
    fi
}

# Test 1: .pushy directory is not found
test_name="pushy-log: .pushy directory is not found"
pushy-log > "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
2041 pushy-log > "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
test_command 1 "$test_name" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"

# Test 2: incorrect usage - arguments are given 
test_name="pushy-log: incorrect usage - arguments are given"
pushy-log arg1 arg2 > "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
2041 pushy-log arg1 arg2 > "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
test_command 2 "$test_name" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"

# Test 3: correct usage - initialised .pushy directory but no commits
test_name="pushy-log: no commits to log"
(pushy-init && pushy-log) > "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
rm -rf .pushy
(2041 pushy-init && 2041 pushy-log )> "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
rm -rf .pushy
test_command 3 "$test_name" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"

# Test 4: one commit to log
echo "hello" > file1
test_name="pushy-log: 1 commit to log"
(pushy-init && pushy-add file1 && pushy-commit -m "commit 1" && pushy-log) > "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
rm -rf .pushy
(2041 pushy-init && 2041 pushy-add file1 && 2041 pushy-commit -m "commit 1" && 2041 pushy-log) > "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
rm -rf .pushy
test_command 4 "$test_name" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"

# Test 5: two commits to log
test_name="pushy-log: 2 commits to log"
echo "hello again" >> file1
echo "world" > file2
pushy-init > /dev/null 2>&1 
(pushy-add file1 && pushy-commit -m "commit 1" && pushy-log) > "$ACTUAL_OUTPUT" 2>&1
(pushy-add file2 && pushy-commit -m "commit 2" && pushy-log) >> "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
rm -rf .pushy

2041 pushy-init > /dev/null 2>&1 
(2041 pushy-add file1 && 2041 pushy-commit -m "commit 1" && 2041 pushy-log) > "$EXPECTED_OUTPUT" 2>&1
(2041 pushy-add file2 && 2041 pushy-commit -m "commit 2" && 2041 pushy-log) >> "$EXPECTED_OUTPUT" 2>&1 
expected_status=$?
rm -rf .pushy
test_command 5 "$test_name" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"

# Test 6: four commits to log
test_name="pushy-log: four commits to log"
echo "hello once again" >> file1
echo "world again" >> file2
echo "hello" > file3
echo "world" > file4
pushy-init > /dev/null 2>&1
(pushy-add file1 && pushy-commit -m "commit 1" && pushy-log) > "$ACTUAL_OUTPUT" 2>&1
(pushy-add file2 && pushy-commit -m "commit 2" && pushy-log) >> "$ACTUAL_OUTPUT" 2>&1
(pushy-add file3 && pushy-commit -m "commit 3" && pushy-log) >> "$ACTUAL_OUTPUT" 2>&1
(pushy-add file4 && pushy-commit -m "commit 4" && pushy-log) >> "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
rm -rf .pushy

2041 pushy-init > /dev/null 2>&1
(2041 pushy-add file1 && 2041 pushy-commit -m "commit 1" && 2041 pushy-log) > "$EXPECTED_OUTPUT" 2>&1
(2041 pushy-add file2 && 2041 pushy-commit -m "commit 2" && 2041 pushy-log) >> "$EXPECTED_OUTPUT" 2>&1 
(2041 pushy-add file3 && 2041 pushy-commit -m "commit 3" && 2041 pushy-log) >> "$EXPECTED_OUTPUT" 2>&1
(2041 pushy-add file4 && 2041 pushy-commit -m "commit 4" && 2041 pushy-log) >> "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
rm -rf .pushy
test_command 6 "$test_name" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"

