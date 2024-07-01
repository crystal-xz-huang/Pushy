#!/bin/dash

# ==============================================================================
# TEST08: PUSHY-BRANCH
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

    if diff "$expected" "$actual" > /dev/null && [ "$correct_status" -eq "$my_status" ]; then
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
            echo "\033[31mMy output (left) did not match expected output (right)\033[0m"
            diff --color=always -y "$actual" "$expected"  
        fi
        exit 1
    fi
}

# --------------------------------------------------------------------------------------------------------------------------
# Testing pushy-branch: lists all branches 
# --------------------------------------------------------------------------------------------------------------------------

# Test 1: No pushy repository
pushy-branch > "$MY_OUTPUT" 2>&1
my_status=$?

2041 pushy-branch > "$CORRECT_OUTPUT" 2>&1
correct_status=$?

test_name="(pushy-branch): no pushy repository"
test_command 1 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 2: No first commit
pushy-init > /dev/null 2>&1
pushy-branch > "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy

2041 pushy-init > /dev/null 2>&1
2041 pushy-branch > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy

test_name="(pushy-branch): no first commit"
test_command 2 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 3: One branch (master)
pushy-init > /dev/null 2>&1
echo "hello" > file1
pushy-add file1 > /dev/null 2>&1
pushy-commit -m "first commit" > /dev/null 2>&1
pushy-branch > "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy file1

2041 pushy-init > /dev/null 2>&1
echo "hello" > file1
2041 pushy-add file1 > /dev/null 2>&1
2041 pushy-commit -m "first commit" > /dev/null 2>&1
2041 pushy-branch > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(pushy-branch): list one branch => master"
test_command 3 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 4: Multiple branches
pushy-init > /dev/null 2>&1
echo "hello" > file1
pushy-add file1 > /dev/null 2>&1
pushy-commit -m "first commit" > /dev/null 2>&1
pushy-branch > "$MY_OUTPUT" 2>&1
pushy-branch b1 >> "$MY_OUTPUT" 2>&1
pushy-branch b2 >> "$MY_OUTPUT" 2>&1
pushy-branch a1 >> "$MY_OUTPUT" 2>&1
pushy-branch c2 >> "$MY_OUTPUT" 2>&1
pushy-branch z0 >> "$MY_OUTPUT" 2>&1
pushy-branch >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy file1

2041 pushy-init > /dev/null 2>&1
echo "hello" > file1
2041 pushy-add file1 > /dev/null 2>&1
2041 pushy-commit -m "first commit" > /dev/null 2>&1
2041 pushy-branch > "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch b1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch b2 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch a1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch c2 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch z0 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(pushy-branch): list multiple branches"
test_command 4 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# --------------------------------------------------------------------------------------------------------------------------
# Testing pushy-branch [branch_name]: creates a new branch
# --------------------------------------------------------------------------------------------------------------------------

# Test 5: No pushy repository
pushy-branch b1 > "$MY_OUTPUT" 2>&1
my_status=$?

2041 pushy-branch b1 > "$CORRECT_OUTPUT" 2>&1
correct_status=$?

test_name="(pushy-branch branch_name): no pushy repository"
test_command 5 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 6: No first commit
pushy-init > /dev/null 2>&1
pushy-branch b1 > "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy

2041 pushy-init > /dev/null 2>&1
2041 pushy-branch b1 > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy

test_name="(pushy-branch branch_name): no first commit"
test_command 6 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 7: Invalid branch names
pushy-init > /dev/null 2>&1
echo "hello" > file1
pushy-add file1 > /dev/null 2>&1
pushy-commit -m "first commit" > /dev/null 2>&1
pushy-branch -b1 > "$MY_OUTPUT" 2>&1
pushy-branch 1 >> "$MY_OUTPUT" 2>&1
pushy-branch _b1 >> "$MY_OUTPUT" 2>&1
pushy-branch b_1 >> "$MY_OUTPUT" 2>&1
pushy-branch b#9 >> "$MY_OUTPUT" 2>&1
pushy-branch 123 >> "$MY_OUTPUT" 2>&1
pushy-branch -a__9 >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy file1

2041 pushy-init > /dev/null 2>&1
echo "hello" > file1
2041 pushy-add file1 > /dev/null 2>&1
2041 pushy-commit -m "first commit" > /dev/null 2>&1
2041 pushy-branch -b1 > "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch 1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch _b1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch b_1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch b#9 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch 123 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch -a__9 >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(pushy-branch branch_name): invalid branch name"
test_command 7 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"


# Test 8: Branchname already exists
pushy-init > /dev/null 2>&1
echo "hello" > file1
pushy-add file1 > /dev/null 2>&1
pushy-commit -m "first commit" > /dev/null 2>&1
pushy-branch b1 > "$MY_OUTPUT" 2>&1
pushy-branch b1 >> "$MY_OUTPUT" 2>&1
pushy-branch master >> "$MY_OUTPUT" 2>&1
pushy-branch >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy file1

2041 pushy-init > /dev/null 2>&1
echo "hello" > file1
2041 pushy-add file1 > /dev/null 2>&1
2041 pushy-commit -m "first commit" > /dev/null 2>&1
2041 pushy-branch b1 > "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch b1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch master >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(pushy-branch branch_name): branch name already exists"
test_command 8 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 9: Create a new branch with the same commit directory, index and HEAD as the current branch
pushy-init > /dev/null 2>&1
echo "hello" > file1
pushy-add file1 > /dev/null 2>&1
pushy-commit -m "first commit" > /dev/null 2>&1
pushy-branch b1 > "$MY_OUTPUT" 2>&1
pushy-branch >> "$MY_OUTPUT" 2>&1
pushy-log >> "$MY_OUTPUT" 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
pushy-checkout b1 >> "$MY_OUTPUT" 2>&1
pushy-log >> "$MY_OUTPUT" 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy file1

2041 pushy-init > /dev/null 2>&1
echo "hello" > file1
2041 pushy-add file1 > /dev/null 2>&1
2041 pushy-commit -m "first commit" > /dev/null 2>&1
2041 pushy-branch b1 > "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-log >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout b1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-log >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(pushy-branch branch_name): create a new branch"
test_command 9 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# --------------------------------------------------------------------------------------------------------------------------
# Testing pushy-branch -d branch_name: deletes a branch
# --------------------------------------------------------------------------------------------------------------------------

# Test 10: No pushy repository
pushy-branch -d b1 > "$MY_OUTPUT" 2>&1
my_status=$?

2041 pushy-branch -d b1 > "$CORRECT_OUTPUT" 2>&1
correct_status=$?

test_name="(pushy-branch -d branch_name): no pushy repository"
test_command 10 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 11: No first commit
pushy-init > /dev/null 2>&1
pushy-branch -d b1 > "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy

2041 pushy-init > /dev/null 2>&1
2041 pushy-branch -d b1 > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy

# Test 12: Branch name not provided or is "-d"
pushy-init > /dev/null 2>&1
echo "hello" > file1
pushy-add file1 > /dev/null 2>&1
pushy-commit -m "first commit" > /dev/null 2>&1
pushy-branch -d > "$MY_OUTPUT" 2>&1
pushy-branch -d -d >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy file1

2041 pushy-init > /dev/null 2>&1
echo "hello" > file1
2041 pushy-add file1 > /dev/null 2>&1
2041 pushy-commit -m "first commit" > /dev/null 2>&1
2041 pushy-branch -d > "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch -d -d >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(pushy-branch -d branch_name): branch name not provided or is \"-d\""
test_command 12 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 13: Branch name starts with "-"
pushy-init > /dev/null 2>&1
echo "hello" > file1
pushy-add file1 > /dev/null 2>&1
pushy-commit -m "first commit" > /dev/null 2>&1
pushy-branch -d -b1 > "$MY_OUTPUT" 2>&1
pushy-branch -d -a_8 >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy file1

2041 pushy-init > /dev/null 2>&1
echo "hello" > file1
2041 pushy-add file1 > /dev/null 2>&1
2041 pushy-commit -m "first commit" > /dev/null 2>&1
2041 pushy-branch -d -b1 > "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch -d -a_8 >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

# Test 13: Branch name is invalid
pushy-init > /dev/null 2>&1
echo "hello" > file1
pushy-add file1 > /dev/null 2>&1
pushy-commit -m "first commit" > /dev/null 2>&1
pushy-branch -d -b1 > "$MY_OUTPUT" 2>&1 
pushy-branch -d 1 >> "$MY_OUTPUT" 2>&1
pushy-branch -d _b1 >> "$MY_OUTPUT" 2>&1
pushy-branch -d b_1 >> "$MY_OUTPUT" 2>&1
pushy-branch -d b#9 >> "$MY_OUTPUT" 2>&1
pushy-branch -d 123 >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy file1

2041 pushy-init > /dev/null 2>&1
echo "hello" > file1
2041 pushy-add file1 > /dev/null 2>&1
2041 pushy-commit -m "first commit" > /dev/null 2>&1
2041 pushy-branch -d -b1 > "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch -d 1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch -d _b1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch -d b_1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch -d b#9 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch -d 123 >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(pushy-branch -d branch_name): invalid branch name"
test_command 13 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 14: Branch name does not exist
pushy-init > /dev/null 2>&1
echo "hello" > file1
pushy-add file1 > /dev/null 2>&1
pushy-commit -m "first commit" > /dev/null 2>&1
pushy-branch -d b1 > "$MY_OUTPUT" 2>&1
pushy-branch -d new >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy file1

2041 pushy-init > /dev/null 2>&1
echo "hello" > file1
2041 pushy-add file1 > /dev/null 2>&1
2041 pushy-commit -m "first commit" > /dev/null 2>&1
2041 pushy-branch -d b1 > "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch -d new >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(pushy-branch -d branch_name): branch name does not exist"
test_command 14 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 15: Branch name is master
pushy-init > /dev/null 2>&1
echo "hello" > file1
pushy-add file1 > /dev/null 2>&1
pushy-commit -m "first commit" > /dev/null 2>&1
pushy-branch -d master > "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy file1

2041 pushy-init > /dev/null 2>&1
echo "hello" > file1
2041 pushy-add file1 > /dev/null 2>&1
2041 pushy-commit -m "first commit" > /dev/null 2>&1
2041 pushy-branch -d master > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(pushy-branch -d branch_name): branch name is master"
test_command 15 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 16: Branch name is the current branch
pushy-init > /dev/null 2>&1
echo "hello" > file1
pushy-add file1 > /dev/null 2>&1
pushy-commit -m "first commit" > /dev/null 2>&1
pushy-branch b1 > /dev/null 2>&1
pushy-checkout b1 > /dev/null 2>&1
pushy-branch -d b1 > "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy file1

2041 pushy-init > /dev/null 2>&1
echo "hello" > file1
2041 pushy-add file1 > /dev/null 2>&1
2041 pushy-commit -m "first commit" > /dev/null 2>&1
2041 pushy-branch b1 > /dev/null 2>&1
2041 pushy-checkout b1 > /dev/null 2>&1
2041 pushy-branch -d b1 > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(pushy-branch -d branch_name): branch name is the current branch"
test_command 16 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 17: Delete a branch
pushy-init > /dev/null 2>&1
echo "hello" > file1
pushy-add file1 > /dev/null 2>&1
pushy-commit -m "first commit" > /dev/null 2>&1
pushy-branch b1 > /dev/null 2>&1
pushy-branch -d b1 > "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy file1

2041 pushy-init > /dev/null 2>&1
echo "hello" > file1
2041 pushy-add file1 > /dev/null 2>&1
2041 pushy-commit -m "first commit" > /dev/null 2>&1
2041 pushy-branch b1 > /dev/null 2>&1
2041 pushy-branch -d b1 > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(pushy-branch -d branch_name): delete a branch"
test_command 17 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"



