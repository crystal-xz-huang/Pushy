#!/bin/dash

# ==============================================================================
# TEST02: PUSHY-COMMIT -M
# ==============================================================================

SCRIPT_DIR=$(pwd)
PATH="$SCRIPT_DIR:$PATH"

TEST_DIR=$(mktemp -d)
cd "$TEST_DIR" || exit 1

EXPECTED_OUTPUT=$(mktemp)
ACTUAL_OUTPUT=$(mktemp)

trap 'rm -rf "$TEST_DIR" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$FAILED_TESTS"' INT TERM EXIT

test_command() {
    test_no=$1
    test_name=$2
    expected=$3
    actual=$4
    correct_status=$5
    my_status=$6

    if diff -u "$expected" "$actual" > /dev/null && [ "$correct_status" -eq "$my_status" ]; then
        # print "passed" in green text
        echo "Test $test_no pushy-commit -m $test_name - \033[32mpassed\033[0m"
    else 
        # print "failed" in red text
        echo "Test $test_no pushy-commit -m $test_name - \033[31mfailed\033[0m"
        if [ "$correct_status" -ne "$my_status" ]; then
            echo "Expected exit status of \033[32m$correct_status\033[0m but received \033[31m$my_status\033[0m" 
        fi

        if ! diff "$expected" "$actual" > /dev/null; then
            echo "Correct output:"
            # Print the expected output in green 
            echo "\033[32m$(cat "$expected")\033[0m"
            echo "Your output:"
            # Print the actual output in red
            echo "\033[31m$(cat "$actual")\033[0m"
        fi
        echo "-----------------------------------------"
    fi
}

# Test 1: no .pushy directory
pushy-commit -m "initial commit" > "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
2041 pushy-commit -m "initial commit" > "$EXPECTED_OUTPUT" 2>&1
expected_status=$?

test_name="(no previous init): no .pushy directory initialized"
test_command 1 "$test_name" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"

# Test 2: pushy-commit with no arguments and no .pushy directory
pushy-commit > "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
2041 pushy-commit > "$EXPECTED_OUTPUT" 2>&1
expected_status=$?

test_name="(no previous init): incorrect usage and no .pushy directory initialized"
test_command 2 "$test_name" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"

# Test 3: pushy-commit with no arguments
(pushy-init && pushy-commit) > "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
rm -rf .pushy
(2041 pushy-init && 2041 pushy-commit) > "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
rm -rf .pushy

test_name="(incorrect usage): no arguments" 
test_command 3 "$test_name" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"

# Test 4: pushy-commit -m 
(pushy-init && pushy-commit -m) > "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
rm -rf .pushy
(2041 pushy-init && 2041 pushy-commit -m) > "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
rm -rf .pushy

test_name="(incorrect usage): no message"
test_command 4 "$test_name" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"


# Test 5: pushy-commit -m -abcde
(pushy-init && pushy-commit -m -abcde) > "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
rm -rf .pushy
(2041 pushy-init && 2041 pushy-commit -m -abcde) > "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
rm -rf .pushy

test_name="(incorrect usage): message is cannot start with a hyphen"
test_command 5 "$test_name" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"


# Test 6: pushy-commit with no staged files
(pushy-init && pushy-commit -m "initial commit") > "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
rm -rf .pushy
(2041 pushy-init && 2041 pushy-commit -m "initial commit") > "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
rm -rf .pushy

test_name="(nothing to commit): no previous pushy-add"
test_command 6 "$test_name" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"

# Test 7: pushy-commit with no new changes
echo 1 > a
pushy-init > /dev/null 2>&1
pushy-add a > /dev/null 2>&1
pushy-commit -m "commit message1" > "$ACTUAL_OUTPUT" 2>&1
touch a > /dev/null 2>&1
pushy-commit -m "commit message2" > "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
rm -rf .pushy

2041 pushy-init > /dev/null 2>&1
2041 pushy-add a > /dev/null 2>&1
2041 pushy-commit -m "commit message1" > "$EXPECTED_OUTPUT" 2>&1
touch a > /dev/null 2>&1
2041 pushy-commit -m "commit message2" > "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
rm -rf .pushy

test_name="(nothing to commit): commit 1 unmodified staged files"
test_command 7 "$test_name" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"

# Test 8: pushy-commit with nothing new to commit
echo "hello" > file1
echo "world" > file2
(pushy-init && pushy-add file1 file2) > /dev/null 2>&1
(pushy-commit -m "commit 1") > "$ACTUAL_OUTPUT" 2>&1
pushy-add file1 file2 > /dev/null 2>&1
(pushy-commit -m "commit 2") >> "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
rm -rf .pushy file1 file2

echo "hello" > file1
echo "world" > file2
(2041 pushy-init && 2041 pushy-add file1 file2) > /dev/null 2>&1
(2041 pushy-commit -m "commit 1") > "$EXPECTED_OUTPUT" 2>&1
2041 pushy-add file1 file2 > /dev/null 2>&1
(2041 pushy-commit -m "commit 2") >> "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
rm -rf .pushy file1 file2

test_name="(nothing to commit): commit 2 unmodified staged files"s
test_command 8 "$test_name" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"


# Test 9: pushy-commit twice in a row
echo "hello" > file1
echo "world" > file2
(pushy-init && pushy-add file1 file2) > /dev/null 2>&1
(pushy-commit -m "commit 1") > "$ACTUAL_OUTPUT" 2>&1
touch file1 > /dev/null 2>&1
touch file2 > /dev/null 2>&1
(pushy-commit -m "commit 2") >> "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
rm -rf .pushy file1 file2

echo "hello" > file1
echo "world" > file2
(2041 pushy-init && 2041 pushy-add file1 file2) > /dev/null 2>&1
(2041 pushy-commit -m "commit 1") > "$EXPECTED_OUTPUT" 2>&1
touch file1 > /dev/null 2>&1
touch file2 > /dev/null 2>&1
(2041 pushy-commit -m "commit 2") >> "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
rm -rf .pushy file1 file2

test_name="(nothing to commit): commit 2 unmodified staged files"
test_command 9 "$test_name" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"

# Test 10: pushy-commit with staged files
echo "hello" > file1
echo "world" > file2
(pushy-init && pushy-add file1 file2 && pushy-commit -m "commit 1") > "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
rm -rf .pushy 
(2041 pushy-init && 2041 pushy-add file1 file2 && 2041 pushy-commit -m "commit 1") > "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
rm -rf .pushy file1 file2

test_name="(successful commit): 1 commit with 2 staged files"
test_command 10 "$test_name" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"

# Test 11: pushy-commit with multiple staged files
echo "line1" > file1
echo "line2" > file2
echo "line3" > file3
echo "line4" > file4
(pushy-init && pushy-add file1 file2) > /dev/null 2>&1
(pushy-commit -m "commit 1" && pushy-add file3 file4 && pushy-commit -m "commit 2") > "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
rm -rf .pushy
(2041 pushy-init && 2041 pushy-add file1 file2) > /dev/null 2>&1
(2041 pushy-commit -m "commit 1" && 2041 pushy-add file3 file4 && 2041 pushy-commit -m "commit 2") > "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
rm -rf .pushy file1 file2 file3 file4

test_name="(successful commit): 2 commits with 4 staged files"
test_command 11 "$test_name" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"


# Test 12: pushy-commit 
echo "line1" > file1
echo "line2" > file2
echo "line3" > file3
pushy-init > /dev/null 2>&1
(pushy-add file1 && pushy-commit -m "commit 1") > "$ACTUAL_OUTPUT" 2>&1
(pushy-add file2 && pushy-commit -m "commit 2") >> "$ACTUAL_OUTPUT" 2>&1
(pushy-add file3 && pushy-commit -m "commit 3") >> "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
rm -rf .pushy

2041 pushy-init > /dev/null 2>&1
(2041 pushy-add file1 && 2041 pushy-commit -m "commit 1") > "$EXPECTED_OUTPUT" 2>&1
(2041 pushy-add file2 && 2041 pushy-commit -m "commit 2") >> "$EXPECTED_OUTPUT" 2>&1
(2041 pushy-add file3 && 2041 pushy-commit -m "commit 3") >> "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
rm -rf .pushy file1 file2 file3

test_name="(successful commit): 3 commits with 3 staged files"
test_command 12 "$test_name" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"

