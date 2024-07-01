#!/bin/dash

# ==============================================================================
# TEST04: PUSHY-SHOW
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
    correct_status=$5
    my_status=$6

    if diff -u "$expected" "$actual" > /dev/null && [ "$correct_status" -eq "$my_status" ]; then
        # print "passed" in green text
        echo "Test $test_no $test_name - \033[32mpassed\033[0m"
    else 
        # print "failed" in red text
        echo "Test $test_no $test_name - \033[31mfailed\033[0m"
        if [ "$correct_status" -ne "$my_status" ]; then
            echo "Expected exit status of \033[32m$correct_status\033[0m but received \033[31m$my_status\033[0m" 
        fi

        if ! diff "$expected" "$actual" > /dev/null; then
            # print the difference in the expected and actual output 
            diff -y "$expected" "$actual"  --color
        fi
        exit 1
    fi
}


# Test 1: no pushy directory
pushy-show > "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
2041 pushy-show > "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
test="pushy-show: no pushy directory"
test_command 1 "$test" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"

# Test 2: incorrect number of arguments
pushy-show a b > "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
2041 pushy-show a b > "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
test="pushy-show: incorrect number of arguments, must have 1 argument"
test_command 2 "$test" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"

# Test 3: incorrect argument, missing colon
pushy-init > /dev/null 2>&1  
pushy-show 0a > "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
rm -rf .pushy

2041 pushy-init > /dev/null 2>&1
2041 pushy-show > "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
rm -rf .pushy

test="pushy-show: incorrect argument, missing colon"
test_command 3 "$test" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"

# Test 4: no file given
pushy-init > /dev/null 2>&1
pushy-show 0: > "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
rm -rf .pushy
2041 pushy-init > /dev/null 2>&1
2041 pushy-show 0: > "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
rm -rf .pushy
test="pushy-show: incorrect argument, no file given"
test_command 4 "$test" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"

# Test 5: unknown commit
pushy-init > /dev/null 2>&1
pushy-show 0:a > "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
rm -rf .pushy
2041 pushy-init > /dev/null 2>&1
2041 pushy-show 0:a > "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
rm -rf .pushy
test="pushy-show: unknown commit"
test_command 5 "$test" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"

# Test 6: empty filename given
pushy-init > /dev/null 2>&1
pushy-show : > "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
rm -rf .pushy
2041 pushy-init > /dev/null 2>&1
2041 pushy-show : > "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
rm -rf .pushy
test="pushy-show: empty filename given"
test_command 6 "$test" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"

# Test 7: no commit given
echo "this is file1" > file1
echo "this is file2" > file2

pushy-init > /dev/null 2>&1
(pushy-add file1 file2) > /dev/null 2>&1
(pushy-commit -m "first commit") > /dev/null 2>&1
(pushy-show :file1) > "$ACTUAL_OUTPUT" 2>&1
(pushy-show :file2) >> "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
rm -rf .pushy

2041 pushy-init > /dev/null 2>&1
2041 pushy-add file1 file2 > /dev/null 2>&1
2041 pushy-commit -m "first commit" > /dev/null 2>&1
2041 pushy-show :file1 > "$EXPECTED_OUTPUT" 2>&1
2041 pushy-show :file2 >> "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
rm -rf .pushy

test="pushy-show: no commit given"
test_command 7 "$test" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"

# Test 8: show file from a commit
pushy-init > /dev/null 2>&1
pushy-add file1 > /dev/null 2>&1
pushy-commit -m "first commit" > /dev/null 2>&1
pushy-show 0:file1 > "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
rm -rf .pushy

2041 pushy-init > /dev/null 2>&1
2041 pushy-add file1 > /dev/null 2>&1
2041 pushy-commit -m "first commit" > /dev/null 2>&1
2041 pushy-show 0:file1 > "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
rm -rf .pushy

test="pushy-show: show file from a commit"
test_command 8 "$test" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"

# Test 9: file not found in commit
pushy-init > /dev/null 2>&1
pushy-add file1 > /dev/null 2>&1
pushy-commit -m "first commit" > /dev/null 2>&1
pushy-show 0:file2 > "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
rm -rf .pushy

2041 pushy-init > /dev/null 2>&1
2041 pushy-add file1 > /dev/null 2>&1
2041 pushy-commit -m "first commit" > /dev/null 2>&1
2041 pushy-show 0:file2 > "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
rm -rf .pushy

test="pushy-show: file not found in commit"
test_command 9 "$test" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"

# Test 10: file not found in index 
pushy-init > /dev/null 2>&1
pushy-add file2 > /dev/null 2>&1
pushy-commit -m "first commit" > /dev/null 2>&1
pushy-show :file1 > "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
rm -rf .pushy

2041 pushy-init > /dev/null 2>&1
2041 pushy-add file2 > /dev/null 2>&1
2041 pushy-commit -m "first commit" > /dev/null 2>&1
2041 pushy-show :file1 > "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
rm -rf .pushy

test="pushy-show: file not found in index"
test_command 10 "$test" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"

# Test 11: show file from index
pushy-init > /dev/null 2>&1
pushy-add file1 file2 > /dev/null 2>&1
pushy-commit -m "first commit" > /dev/null 2>&1
pushy-show :file1 > "$ACTUAL_OUTPUT" 2>&1
pushy-show :file2 >> "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
rm -rf .pushy

2041 pushy-init > /dev/null 2>&1
2041 pushy-add file1 file2 > /dev/null 2>&1
2041 pushy-commit -m "first commit" > /dev/null 2>&1
2041 pushy-show :file1 > "$EXPECTED_OUTPUT" 2>&1
2041 pushy-show :file2 >> "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
rm -rf .pushy

test="pushy-show: show file from index"
test_command 11 "$test" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"

# Test 12: invalid filenames - filename must start with a letter or number
pushy-init > /dev/null 2>&1
pushy-show :-file > "$ACTUAL_OUTPUT" 2>&1
pushy-show :#file >> "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
rm -rf .pushy

2041 pushy-init > /dev/null 2>&1
2041 pushy-show :-file > "$EXPECTED_OUTPUT" 2>&1
2041 pushy-show :#file >> "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
rm -rf .pushy

test="pushy-show: invalid filenames, filename must start with a letter or number"
test_command 12 "$test" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"

# Test 13: valid filenames- can only contain alphanumeric or ._-
pushy-init > /dev/null 2>&1
pushy-show :file! > "$ACTUAL_OUTPUT" 2>&1
pushy-show :file@ >> "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
rm -rf .pushy

2041 pushy-init > /dev/null 2>&1
2041 pushy-show :file! > "$EXPECTED_OUTPUT" 2>&1
2041 pushy-show :file@ >> "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
rm -rf .pushy

test="pushy-show: valid filenames, can only contain alphanumeric or ._- characters"
test_command 13 "$test" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"

# Test 14: valid filenames- can only contain alphanumeric or ._-
pushy-init > /dev/null 2>&1
echo "this is file1" > file.1
pushy-add file.1 > /dev/null 2>&1
pushy-commit -m "first commit" > /dev/null 2>&1
pushy-show :file.1 > "$ACTUAL_OUTPUT" 2>&1
pushy-show :file_1 >> "$ACTUAL_OUTPUT" 2>&1
pushy-show :file-1 >> "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
rm -rf .pushy

2041 pushy-init > /dev/null 2>&1
echo "this is file1" > file.1
2041 pushy-add file.1 > /dev/null 2>&1
2041 pushy-commit -m "first commit" > /dev/null 2>&1
2041 pushy-show :file.1 > "$EXPECTED_OUTPUT" 2>&1
2041 pushy-show :file_1 >> "$EXPECTED_OUTPUT" 2>&1
2041 pushy-show :file-1 >> "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
rm -rf .pushy

test="pushy-show: valid filenames, can only contain alphanumeric or ._- characters"
test_command 14 "$test" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"

# Test 15: autotest
pushy-init > /dev/null 2>&1
echo line 1 > a 
echo hello world > b
pushy-add a b > /dev/null 2>&1
pushy-commit -m "first commit" > "$ACTUAL_OUTPUT" 2>&1
echo line 2 >> a
pushy-add a > /dev/null 2>&1
pushy-commit -m "second commit" >> "$ACTUAL_OUTPUT" 2>&1
pushy-log >> "$ACTUAL_OUTPUT" 2>&1
pushy-show 0:a >> "$ACTUAL_OUTPUT" 2>&1
pushy-show 1:a >> "$ACTUAL_OUTPUT" 2>&1
pushy-show :a >> "$ACTUAL_OUTPUT" 2>&1
pushy-show 0:b >> "$ACTUAL_OUTPUT" 2>&1
pushy-show 1:b >> "$ACTUAL_OUTPUT" 2>&1
pushy-show :b >> "$ACTUAL_OUTPUT" 2>&1
echo line 3 >> a 
pushy-add a > /dev/null 2>&1
echo line 4 >> a 
pushy-show 0:a >> "$ACTUAL_OUTPUT" 2>&1
pushy-show 1:a >> "$ACTUAL_OUTPUT" 2>&1
pushy-show :a >> "$ACTUAL_OUTPUT" 2>&1
pushy-show 0:b >> "$ACTUAL_OUTPUT" 2>&1
pushy-show 1:b >> "$ACTUAL_OUTPUT" 2>&1
pushy-show :b >> "$ACTUAL_OUTPUT" 2>&1
actual_status=$?
rm -rf .pushy a b

2041 pushy-init > /dev/null 2>&1
echo line 1 > a
echo hello world > b
2041 pushy-add a b > /dev/null 2>&1
2041 pushy-commit -m "first commit" > "$EXPECTED_OUTPUT" 2>&1
echo line 2 >> a
2041 pushy-add a > /dev/null 2>&1
2041 pushy-commit -m "second commit" >> "$EXPECTED_OUTPUT" 2>&1
2041 pushy-log >> "$EXPECTED_OUTPUT" 2>&1
2041 pushy-show 0:a >> "$EXPECTED_OUTPUT" 2>&1
2041 pushy-show 1:a >> "$EXPECTED_OUTPUT" 2>&1
2041 pushy-show :a >> "$EXPECTED_OUTPUT" 2>&1
2041 pushy-show 0:b >> "$EXPECTED_OUTPUT" 2>&1
2041 pushy-show 1:b >> "$EXPECTED_OUTPUT" 2>&1
2041 pushy-show :b >> "$EXPECTED_OUTPUT" 2>&1
echo line 3 >> a
2041 pushy-add a > /dev/null 2>&1
echo line 4 >> a
2041 pushy-show 0:a >> "$EXPECTED_OUTPUT" 2>&1
2041 pushy-show 1:a >> "$EXPECTED_OUTPUT" 2>&1
2041 pushy-show :a >> "$EXPECTED_OUTPUT" 2>&1
2041 pushy-show 0:b >> "$EXPECTED_OUTPUT" 2>&1
2041 pushy-show 1:b >> "$EXPECTED_OUTPUT" 2>&1
2041 pushy-show :b >> "$EXPECTED_OUTPUT" 2>&1
expected_status=$?
rm -rf .pushy a b

test="pushy-show: autotest subset0_9"
test_command 15 "$test" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$expected_status" "$actual_status"

