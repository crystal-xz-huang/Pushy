#!/bin/dash

# ==============================================================================
# TEST05: PUSHY-COMMIT -A -M
# ==============================================================================

SCRIPT_DIR=$(pwd)
PATH="$SCRIPT_DIR:$PATH"

TEST_DIR=$(mktemp -d)
cd "$TEST_DIR" || exit 1

CORRECT_OUTPUT=$(mktemp)
MY_OUTPUT=$(mktemp)

trap 'rm -rf "$TEST_DIR" "$CORRECT_OUTPUT" "$MY_OUTPUT"' INT TERM EXIT

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


# Test 1: no .pushy directory
(pushy-commit -a -m "first commit") > "$MY_OUTPUT" 2>&1
my_status=$?
(2041 pushy-commit -a -m "first commit") > "$CORRECT_OUTPUT" 2>&1
correct_status=$?

test_name="(no previous init): no .pushy directory initialized"
test_command "1 " "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 2: incorrect usage - message is empty
(pushy-init && pushy-commit -a -m) > "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy
(2041 pushy-init && 2041 pushy-commit -a -m) > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy

test_name="(incorrect usage): no message"
test_command "2 " "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 3: incorrect usage - options in wrong order
(pushy-init && pushy-commit -m -a commit message) > "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy
(2041 pushy-init && 2041 pushy-commit -m -a commit message) > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy

test_name="(incorrect usage): no message and options in wrong order"
test_command "3 " "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 4: incorrect usage - options in wrong order and no message
(pushy-init && pushy-commit -m -a) > "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy
(2041 pushy-init && 2041 pushy-commit -m -a) > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy

test_name="(incorrect usage): invalid option and no message"
test_command "4 " "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 5: pushy-commit -a -abcde
(pushy-init && pushy-commit -a -abcde) > "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy
(2041 pushy-init && 2041 pushy-commit -a -abcde) > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy

test_name="(incorrect usage): invalid option"
test_command "5 " "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 6: pushy-commit -a -m -abcde
(pushy-init && pushy-commit -a -m -abcde) > "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy
(2041 pushy-init && 2041 pushy-commit -a -m -abcde) > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy

test_name="(incorrect usage): message cannot start with a hyphen"
test_command "6 " "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 7: incorrect usage - missing -m option
(pushy-init && pushy-commit -a "first commit") > "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy
(2041 pushy-init && 2041 pushy-commit -a "first commit") > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy

test_name="(incorrect usage): missing -m option"
test_command "7 " "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 8: incorrect usage - message cannot contain newline character
(pushy-init && pushy-commit -a -m "first '\n' commit") > "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy
(2041 pushy-init && 2041 pushy-commit -a -m "first \n commit") > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy

test_name="(incorrect usage): message contains newline character"
test_command "8 " "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 9: no tracked files
(pushy-init && pushy-commit -a -m "first commit") > "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy
(2041 pushy-init && 2041 pushy-commit -a -m "first commit") > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy

test_name="(nothing to commit): no previous pushy-add"
test_command "9 " "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 10: nothing new to commit  
echo 1 > a
pushy-init > /dev/null 2>&1
pushy-add a > /dev/null 2>&1
pushy-commit -a -m "first commit" > "$MY_OUTPUT" 2>&1
touch a > /dev/null 2>&1
pushy-commit -a -m "second commit" >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy a

echo 1 > a
2041 pushy-init > /dev/null 2>&1
2041 pushy-add a > /dev/null 2>&1
2041 pushy-commit -a -m "first commit" > "$CORRECT_OUTPUT" 2>&1
touch a > /dev/null 2>&1
2041 pushy-commit -a -m "second commit" >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy a

test_name="(nothing to commit): 1 commit with no changes"
test_command 10 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 11: nothing new to commit (multiple commits with no changes)
echo 1 > a
pushy-init > /dev/null 2>&1
pushy-add a > /dev/null 2>&1
(pushy-commit -a -m "first commit" && pushy-commit -a -m "second commit") > "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy a

echo 1 > a
2041 pushy-init > /dev/null 2>&1
2041 pushy-add a > /dev/null 2>&1
(2041 pushy-commit -a -m "first commit" && 2041 pushy-commit -a -m "second commit") > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy a

test_name="(nothing to commit): 2 commits with no changes"
test_command 11 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 12: add with non-existent files then commit
pushy-init > /dev/null 2>&1
(pushy-add file1 file2 && pushy-commit -a -m "first commit") > "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy

2041 pushy-init > /dev/null 2>&1
(2041 pushy-add file1 file2 && 2041 pushy-commit -a -m "first commit") > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy

test_name="(nothing to commit): add with non-existent files then commit"
test_command 12 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 13: commit once with changes to all staged files
touch file1
touch file2
(pushy-init && pushy-add file1 file2) > /dev/null 2>&1
echo "hello" > file1
echo "world" > file2
(pushy-commit -a -m "first commit") > "$MY_OUTPUT" 2>&1
(pushy-show 0:file1 && pushy-show 0:file2) >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy file1 file2

touch file1
touch file2
(2041 pushy-init && 2041 pushy-add file1 file2) > /dev/null 2>&1
echo "hello" > file1
echo "world" > file2
(2041 pushy-commit -a -m "first commit") > "$CORRECT_OUTPUT" 2>&1
(2041 pushy-show 0:file1 && 2041 pushy-show 0:file2) >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1 file2

test_name="(success): 1 commit with changes to all staged files"
test_command 13 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 14: commit twice with changes to all staged files
echo "line1" > file1
echo "line2" > file2
(pushy-init && pushy-add file1 file2) > /dev/null 2>&1
pushy-commit -a -m "first commit" > "$MY_OUTPUT" 2>&1
(pushy-show 0:file1 && pushy-show 0:file2) >> "$MY_OUTPUT" 2>&1
echo "line3" >> file1
echo "line4" >> file2
(pushy-commit -a -m "second commit") >> "$MY_OUTPUT" 2>&1
(pushy-show 1:file1 && pushy-show 1:file2) >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy file1 file2

echo "line1" > file1
echo "line2" > file2
(2041 pushy-init && 2041 pushy-add file1 file2) > /dev/null 2>&1
(2041 pushy-commit -a -m "first commit") > "$CORRECT_OUTPUT" 2>&1
(2041 pushy-show 0:file1 && 2041 pushy-show 0:file2) >> "$CORRECT_OUTPUT" 2>&1
echo "line3" >> file1
echo "line4" >> file2
(2041 pushy-commit -a -m "second commit") >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-show 1:file1 && 2041 pushy-show 1:file2) >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1 file2

test_name="(success): commit twice with changes to all staged files"
test_command 14 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 15: commit with changes to 1 staged files and 1 untracked file
touch file1
touch file2
(pushy-init && pushy-add file1) > /dev/null 2>&1
echo "hello" > file1
echo "world" > file2
(pushy-commit -a -m "first commit") > "$MY_OUTPUT" 2>&1
my_status=$?
(pushy-show 0:file1 && pushy-show 0:file2) >> "$MY_OUTPUT" 2>&1
rm -rf .pushy file1 file2

touch file1
touch file2
(2041 pushy-init && 2041 pushy-add file1) > /dev/null 2>&1
echo "hello" > file1
echo "world" > file2
(2041 pushy-commit -a -m "first commit") > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
(2041 pushy-show 0:file1 && 2041 pushy-show 0:file2) >> "$CORRECT_OUTPUT" 2>&1
rm -rf .pushy file1 file2

test_name="(success): commit with changes to 1 staged files and 1 untracked file"
test_command 15 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 16: commit with changes to 1 staged file and 1 untracked file 
echo "line1" > file1
echo "line2" > file2
(pushy-init && pushy-add file1 file2) > /dev/null 2>&1
pushy-commit -a -m "commit 1" > "$MY_OUTPUT" 2>&1
echo "line3" > file1
touch file2
touch file3
pushy-commit -a -m "commit 2" >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy file1 file2 file3

echo "line1" > file1
echo "line2" > file2
(2041 pushy-init && 2041 pushy-add file1 file2) > /dev/null 2>&1
2041 pushy-commit -a -m "commit 1" > "$CORRECT_OUTPUT" 2>&1
echo "line3" > file1
touch file2
touch file3
2041 pushy-commit -a -m "commit 2" >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1 file2 file3

test_name="(success): commit with 2 staged files (1 modified) and 1 untracked file"
test_command 16 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

