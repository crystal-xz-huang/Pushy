#!/bin/dash

# ==============================================================================
# TEST09: PUSHY-CHECKOUT and PUSHY-MERGE
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
# Testing usage
# --------------------------------------------------------------------------------------------------------------------------

# Test 1: No pushy repository
pushy-checkout b1 > "$MY_OUTPUT" 2>&1
my_status=$?

2041 pushy-checkout b1 > "$CORRECT_OUTPUT" 2>&1
correct_status=$?

test_name="(pushy-checkout): no pushy repository"
test_command 1 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 2: No first commit
pushy-init > /dev/null 2>&1
pushy-checkout b1 > "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy

2041 pushy-init > /dev/null 2>&1
2041 pushy-checkout b1 > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy

test_name="(pushy-checkout): no first commit"
test_command 2 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 3: Branch name not provided
pushy-checkout > "$MY_OUTPUT" 2>&1
pushy-init > /dev/null 2>&1
touch file1
pushy-add file1 > /dev/null 2>&1
pushy-commit -m "first commit" >> "$MY_OUTPUT" 2>&1
pushy-checkout >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy file1

2041 pushy-checkout > "$CORRECT_OUTPUT" 2>&1
2041 pushy-init > /dev/null 2>&1
touch file1
2041 pushy-add file1 > /dev/null 2>&1
2041 pushy-commit -m "first commit" >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(pushy-checkout): branch name not provided"
test_command 3 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 4: Branch name is invalid
pushy-init > /dev/null 2>&1
touch file1
pushy-add file1 > /dev/null 2>&1
pushy-commit -m "first commit" > /dev/null 2>&1
pushy-checkout -b > "$MY_OUTPUT" 2>&1
pushy-checkout - > "$MY_OUTPUT" 2>&1
pushy-checkout 1 >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy file1

2041 pushy-init > /dev/null 2>&1
touch file1
2041 pushy-add file1 > /dev/null 2>&1
2041 pushy-commit -m "first commit" > /dev/null 2>&1
2041 pushy-checkout -b > "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout - > "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout 1 >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(pushy-checkout): branch name is invalid"
test_command 4 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 5: Branch name does not exist 
pushy-init > /dev/null 2>&1
touch file1
pushy-add file1 > /dev/null 2>&1
pushy-commit -m "first commit" > /dev/null 2>&1
pushy-checkout b1 > "$MY_OUTPUT" 2>&1
pushy-branch b2 > /dev/null 2>&1
pushy-checkout b3 >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy file1

2041 pushy-init > /dev/null 2>&1
touch file1
2041 pushy-add file1 > /dev/null 2>&1
2041 pushy-commit -m "first commit" > /dev/null 2>&1
2041 pushy-checkout b1 > "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch b2 > /dev/null 2>&1
2041 pushy-checkout b3 >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(pushy-checkout): branch name does not exist"
test_command 5 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 6: Branch name is the current branch
pushy-init > /dev/null 2>&1
touch file1
pushy-add file1 > /dev/null 2>&1
pushy-commit -m "first commit" > /dev/null 2>&1
pushy-checkout master > "$MY_OUTPUT" 2>&1
pushy-branch b1 > /dev/null 2>&1
pushy-checkout b1 >> "$MY_OUTPUT" 2>&1
pushy-checkout b1 >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy file1

2041 pushy-init > /dev/null 2>&1
touch file1
2041 pushy-add file1 > /dev/null 2>&1
2041 pushy-commit -m "first commit" > /dev/null 2>&1
2041 pushy-checkout master > "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch b1 > /dev/null 2>&1
2041 pushy-checkout b1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout b1 >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(pushy-checkout): branch name is the current branch"
test_command 6 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# --------------------------------------------------------------------------------------------------------------------------
# Testing pushy-checkout branch_name: switches to a branch
# --------------------------------------------------------------------------------------------------------------------------

# Test 7: Switch to a branch 
pushy-init > "$MY_OUTPUT" 2>&1
seq 1 7 >7.txt
pushy-add 7.txt > /dev/null 2>&1
pushy-commit -m commit-1 >> "$MY_OUTPUT" 2>&1      # commit 0 on master
pushy-log >> "$MY_OUTPUT" 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
pushy-branch b1 >> "$MY_OUTPUT" 2>&1
pushy-checkout b1 >> "$MY_OUTPUT" 2>&1
pushy-log >> "$MY_OUTPUT" 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
sed -Ei 's/2/42/' 7.txt
cat 7.txt >> "$MY_OUTPUT" 2>&1
pushy-commit -a -m commit-2 >> "$MY_OUTPUT" 2>&1    # commit 1 on b1
pushy-checkout master >> "$MY_OUTPUT" 2>&1
cat 7.txt >> "$MY_OUTPUT" 2>&1
sed -Ei 's/5/24/' 7.txt
cat 7.txt >> "$MY_OUTPUT" 2>&1
pushy-commit -a -m commit-3 >> "$MY_OUTPUT" 2>&1    # commit 2 on master
pushy-log >> "$MY_OUTPUT" 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
# pushy-merge b1 -m merge-message >> "$CORRECT_OUTPUT" 2>&1
# cat 7.txt >> "$CORRECT_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy 7.txt

2041 pushy-init > "$CORRECT_OUTPUT" 2>&1
seq 1 7 >7.txt
2041 pushy-add 7.txt > /dev/null 2>&1
2041 pushy-commit -m commit-1 >> "$CORRECT_OUTPUT" 2>&1   # commit 0 on master
2041 pushy-log >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch b1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout b1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-log >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
sed -Ei 's/2/42/' 7.txt
cat 7.txt >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-commit -a -m commit-2 >> "$CORRECT_OUTPUT" 2>&1 # commit 1 on b1
2041 pushy-checkout master >> "$CORRECT_OUTPUT" 2>&1
cat 7.txt >> "$CORRECT_OUTPUT" 2>&1
sed -Ei 's/5/24/' 7.txt
cat 7.txt >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-commit -a -m commit-3 >> "$CORRECT_OUTPUT" 2>&1 # commit 2 on master
2041 pushy-log >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
# 2041 pushy-merge b1 -m merge-message >> "$CORRECT_OUTPUT" 2>&1
# cat 7.txt >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy 7.txt

test_name="(pushy-checkout): switch to a branch"
test_command 7 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"


# Test 8: Branches share the same index and commit history initially
pushy-init > "$MY_OUTPUT" 2>&1
seq 1 7 >7.txt
pushy-add 7.txt > /dev/null 2>&1
pushy-commit -m commit-1 >> "$MY_OUTPUT" 2>&1
pushy-branch b1 >> "$MY_OUTPUT" 2>&1
seq 1 8 >8.txt
pushy-log >> "$MY_OUTPUT" 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
pushy-checkout b1 >> "$MY_OUTPUT" 2>&1
pushy-log >> "$MY_OUTPUT" 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy 7.txt 8.txt


2041 pushy-init > "$CORRECT_OUTPUT" 2>&1
seq 1 7 >7.txt
2041 pushy-add 7.txt > /dev/null 2>&1
2041 pushy-commit -m commit-1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch b1 >> "$CORRECT_OUTPUT" 2>&1
seq 1 8 >8.txt
2041 pushy-log >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout b1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-log >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy 7.txt 8.txt

test_name="(pushy-checkout): branches share the same index and commit history initially"
test_command 8 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 9: Branches have different index and commit history after a commit is made to one branch
pushy-init > "$MY_OUTPUT" 2>&1
seq 1 7 >7.txt
pushy-add 7.txt > /dev/null 2>&1
pushy-commit -m commit-1 >> "$MY_OUTPUT" 2>&1
pushy-branch b1 >> "$MY_OUTPUT" 2>&1
seq 1 8 >8.txt
pushy-checkout b1 >> "$MY_OUTPUT" 2>&1
pushy-add 8.txt > /dev/null 2>&1
pushy-commit -m commit-2 >> "$MY_OUTPUT" 2>&1
pushy-log >> "$MY_OUTPUT" 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
pushy-checkout master >> "$MY_OUTPUT" 2>&1
pushy-log >> "$MY_OUTPUT" 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy 7.txt 8.txt 

2041 pushy-init > "$CORRECT_OUTPUT" 2>&1
seq 1 7 >7.txt
2041 pushy-add 7.txt > /dev/null 2>&1
2041 pushy-commit -m commit-1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch b1 >> "$CORRECT_OUTPUT" 2>&1
seq 1 8 >8.txt
2041 pushy-checkout b1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-add 8.txt > /dev/null 2>&1
2041 pushy-commit -m commit-2 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-log >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout master >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-log >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy 7.txt 8.txt

test_name="(pushy-checkout): branches have different index and commit history after a commit is made to one branch"
test_command 9 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 10: Branches have different index and commit history after a commit is made to the other branch
pushy-init > "$MY_OUTPUT" 2>&1
seq 1 7 >7.txt
pushy-add 7.txt > /dev/null 2>&1
pushy-commit -m commit-1 >> "$MY_OUTPUT" 2>&1
pushy-branch b1 >> "$MY_OUTPUT" 2>&1
seq 1 8 >8.txt
pushy-checkout b1 >> "$MY_OUTPUT" 2>&1
pushy-add 8.txt > /dev/null 2>&1
pushy-commit -m commit-2 >> "$MY_OUTPUT" 2>&1
pushy-checkout master >> "$MY_OUTPUT" 2>&1
seq 1 9 >9.txt
pushy-add 9.txt > /dev/null 2>&1
pushy-commit -m commit-3 >> "$MY_OUTPUT" 2>&1
master_status=$(pushy-status)
master_log=$(pushy-log)
pushy-log >> "$MY_OUTPUT" 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
pushy-checkout b1 >> "$MY_OUTPUT" 2>&1
branch_status=$(pushy-status)
branch_log=$(pushy-log)
pushy-log >> "$MY_OUTPUT" 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy 7.txt 8.txt 9.txt

# check that pushy-status and pushy-log are different for the master and branch b1
if [ "$master_status" = "$branch_status" ]; then
    echo "pushy-status of branch b1 is the same as master branch" >> "$MY_OUTPUT" 
elif [ "$master_log" = "$branch_log" ]; then
    echo "pushy-log of branch b1 is the same as master branch" >> "$MY_OUTPUT" 
fi

2041 pushy-init > "$CORRECT_OUTPUT" 2>&1
seq 1 7 >7.txt
2041 pushy-add 7.txt > /dev/null 2>&1
2041 pushy-commit -m commit-1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch b1 >> "$CORRECT_OUTPUT" 2>&1   
seq 1 8 >8.txt
2041 pushy-checkout b1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-add 8.txt > /dev/null 2>&1
2041 pushy-commit -m commit-2 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout master >> "$CORRECT_OUTPUT" 2>&1
seq 1 9 >9.txt
2041 pushy-add 9.txt > /dev/null 2>&1
2041 pushy-commit -m commit-3 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-log >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout b1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-log >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy 7.txt 8.txt 9.txt

test_name="(pushy-checkout): branches have different index and commit history after a commit is made to the other branch"
test_command 10 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 11: Branches have the same working directory for uncommitted changes
pushy-init > "$MY_OUTPUT" 2>&1
seq 1 7 >7.txt
pushy-add 7.txt > /dev/null 2>&1
pushy-commit -m commit-1 >> "$MY_OUTPUT" 2>&1
pushy-branch b1 >> "$MY_OUTPUT" 2>&1
seq 1 8 >8.txt
pushy-checkout b1 >> "$MY_OUTPUT" 2>&1
seq 1 9 >9.txt
pushy-add 9.txt > /dev/null 2>&1
pushy-log >> "$MY_OUTPUT" 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
pushy-checkout master >> "$MY_OUTPUT" 2>&1
pushy-log >> "$MY_OUTPUT" 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy 7.txt 8.txt 9.txt

2041 pushy-init > "$CORRECT_OUTPUT" 2>&1
seq 1 7 >7.txt
2041 pushy-add 7.txt > /dev/null 2>&1
2041 pushy-commit -m commit-1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch b1 >> "$CORRECT_OUTPUT" 2>&1
seq 1 8 >8.txt
2041 pushy-checkout b1 >> "$CORRECT_OUTPUT" 2>&1
seq 1 9 >9.txt
2041 pushy-add 9.txt > /dev/null 2>&1 # add 9.txt to b1
2041 pushy-log >> "$CORRECT_OUTPUT" 2>&1   
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout master >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-log >> "$CORRECT_OUTPUT" 2>&1  
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy 7.txt 8.txt 9.txt

test_name="(pushy-checkout): branches have the same working directory for uncommitted changes"
test_command 11 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 12: Branches have different working directory for committed changes
pushy-init > "$MY_OUTPUT" 2>&1
seq 1 7 >7.txt
pushy-add 7.txt > /dev/null 2>&1
pushy-commit -m commit-1 >> "$MY_OUTPUT" 2>&1
pushy-branch b1 >> "$MY_OUTPUT" 2>&1
seq 1 8 >8.txt
pushy-checkout b1 >> "$MY_OUTPUT" 2>&1
seq 1 9 >9.txt
pushy-add 9.txt > /dev/null 2>&1
pushy-commit -m commit-2 >> "$MY_OUTPUT" 2>&1
pushy-checkout master >> "$MY_OUTPUT" 2>&1
seq 1 10 >10.txt
pushy-add 10.txt > /dev/null 2>&1
pushy-commit -m commit-3 >> "$MY_OUTPUT" 2>&1
pushy-checkout b1 >> "$MY_OUTPUT" 2>&1
pushy-log >> "$MY_OUTPUT" 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
pushy-checkout master >> "$MY_OUTPUT" 2>&1
pushy-log >> "$MY_OUTPUT" 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy 7.txt 8.txt 9.txt 10.txt

2041 pushy-init > "$CORRECT_OUTPUT" 2>&1
seq 1 7 >7.txt
2041 pushy-add 7.txt > /dev/null 2>&1
2041 pushy-commit -m commit-1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch b1 >> "$CORRECT_OUTPUT" 2>&1
seq 1 8 >8.txt
2041 pushy-checkout b1 >> "$CORRECT_OUTPUT" 2>&1
seq 1 9 >9.txt
2041 pushy-add 9.txt > /dev/null 2>&1
2041 pushy-commit -m commit-2 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout master >> "$CORRECT_OUTPUT" 2>&1
seq 1 10 >10.txt
2041 pushy-add 10.txt > /dev/null 2>&1
2041 pushy-commit -m commit-3 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout b1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-log >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout master >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-log >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy 7.txt 8.txt 9.txt 10.txt

test_name="(pushy-checkout): branches have different working directory for committed changes"
test_command 12 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 13: Checkout with work that would be over-written
pushy-init > "$MY_OUTPUT" 2>&1
echo hello >a
pushy-add a > /dev/null 2>&1
pushy-commit -m commit-A >> "$MY_OUTPUT" 2>&1   # a is hello in master
pushy-branch branchA >> "$MY_OUTPUT" 2>&1
echo world >b 
pushy-add b > /dev/null 2>&1
pushy-commit -m commit-B >> "$MY_OUTPUT" 2>&1   
pushy-checkout branchA >> "$MY_OUTPUT" 2>&1
echo new contents >b                            # b is world in branchA but is new contents in master
pushy-checkout master >> "$MY_OUTPUT" 2>&1
# pushy-checkout: error: Your changes to the following files would be overwritten by checkout:
# b
pushy-add b > /dev/null 2>&1
pushy-commit -m commit-C >> "$MY_OUTPUT" 2>&1
pushy-checkout master >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy a b

2041 pushy-init > "$CORRECT_OUTPUT" 2>&1
echo hello >a
2041 pushy-add a > /dev/null 2>&1
2041 pushy-commit -m commit-A >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch branchA >> "$CORRECT_OUTPUT" 2>&1
echo world >b
2041 pushy-add b > /dev/null 2>&1
2041 pushy-commit -m commit-B >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout branchA >> "$CORRECT_OUTPUT" 2>&1
echo new contents >b
2041 pushy-checkout master >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-add b > /dev/null 2>&1
2041 pushy-commit -m commit-C >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout master >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy a b

test_name="(pushy-checkout): checkout with work that would be over-written"
test_command 13 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"


# Test 14: Check that the working directory is updated when switching branches
pushy-init > "$MY_OUTPUT" 2>&1
echo hello >a
pushy-add a > /dev/null 2>&1
pushy-commit -m commit-A > /dev/null 2>&1
pushy-branch b1 > /dev/null 2>&1
echo world >>a
pushy-checkout b1 >> "$MY_OUTPUT" 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
cat a >> "$MY_OUTPUT" 2>&1
pushy-checkout master >> "$MY_OUTPUT" 2>&1
pushy-add a > /dev/null 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
pushy-checkout b1 >> "$MY_OUTPUT" 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
pushy-checkout master > /dev/null 2>&1
pushy-commit -a -m commit-B > /dev/null 2>&1
pushy-checkout b1 >> "$MY_OUTPUT" 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
cat a >> "$MY_OUTPUT" 2>&1
pushy-checkout master >> "$MY_OUTPUT" 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
cat a >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy a

2041 pushy-init > "$CORRECT_OUTPUT" 2>&1
echo hello >a
2041 pushy-add a > /dev/null 2>&1
2041 pushy-commit -m commit-A > /dev/null 2>&1
2041 pushy-branch b1 > /dev/null 2>&1
echo world >>a # a is hello world in master
2041 pushy-checkout b1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1 
cat a >> "$CORRECT_OUTPUT" 2>&1 # a is hello world in b1
2041 pushy-checkout master >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-add a > /dev/null 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout b1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1 # a is hello world in b1
2041 pushy-checkout master > /dev/null 2>&1
2041 pushy-commit -a -m commit-B > /dev/null 2>&1 # a is hello world in master
2041 pushy-checkout b1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
cat a >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout master >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
cat a >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy a

test_name="(pushy-checkout): Check that the working directory is updated when switching branches"
test_command 14 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"


# --------------------------------------------------------------------------------------------------------------------------
# Testing pushy-merge
# --------------------------------------------------------------------------------------------------------------------------

# Test 14: Successful merge
pushy-init > "$MY_OUTPUT" 2>&1
seq 1 7 >7.txt
pushy-add 7.txt > /dev/null 2>&1
pushy-commit -m commit-0 >> "$MY_OUTPUT" 2>&1
pushy-branch b1 >> "$MY_OUTPUT" 2>&1
pushy-checkout b1 >> "$MY_OUTPUT" 2>&1
sed -Ei s/2/42/ 7.txt 
pushy-commit -a -m commit-1 >> "$MY_OUTPUT" 2>&1
pushy-checkout master >> "$MY_OUTPUT" 2>&1
sed -Ei s/5/24/ 7.txt
pushy-commit -a -m commit-2 >> "$MY_OUTPUT" 2>&1
pushy-merge b1 -m merge-message >> "$MY_OUTPUT" 2>&1
pushy-log >> "$MY_OUTPUT" 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
cat 7.txt >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy 7.txt

2041 pushy-init > "$CORRECT_OUTPUT" 2>&1
seq 1 7 >7.txt
2041 pushy-add 7.txt > /dev/null 2>&1
2041 pushy-commit -m commit-0 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch b1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout b1 >> "$CORRECT_OUTPUT" 2>&1
sed -Ei s/2/42/ 7.txt
2041 pushy-commit -a -m commit-1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout master >> "$CORRECT_OUTPUT" 2>&1
sed -Ei s/5/24/ 7.txt
2041 pushy-commit -a -m commit-2 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-merge b1 -m merge-message >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-log >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
cat 7.txt >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?

test_name="(pushy-merge): successful merge - fast-forward"
test_command 14 "$test_name" "$CORRECT_OUTPUT" "$CORRECT_OUTPUT" "$correct_status" "$my_status"

# Test 15: Merge a branch into master
pushy-init > "$MY_OUTPUT" 2>&1
seq -f "line %.0f" 1 7 >a;
seq -f "line %.0f" 1 7 >b;
seq -f "line %.0f" 1 7 >c;
seq -f "line %.0f" 1 7 >d;
pushy-add a b c d >> "$MY_OUTPUT" 2>&1
pushy-commit -m commit-0 >> "$MY_OUTPUT" 2>&1    # commit 0 on master
pushy-branch b1 >> "$MY_OUTPUT" 2>&1
pushy-checkout b1 >> "$MY_OUTPUT" 2>&1
seq -f "line %.0f" 0 7 >a;
seq -f "line %.0f" 1 8 >b;
seq -f "line %.0f" 1 7 >e;
pushy-add e >> "$MY_OUTPUT" 2>&1
pushy-commit -a -m commit-1 >> "$MY_OUTPUT" 2>&1 # commit 1 on b1 (file e is added to b1)
pushy-checkout master >> "$MY_OUTPUT" 2>&1 
sed -i 4d c;
seq -f "line %.0f" 0 8 >d;
seq -f "line %.0f" 1 7 >f;
pushy-add f >> "$MY_OUTPUT" 2>&1
pushy-commit -a -m commit-2 >> "$MY_OUTPUT" 2>&1 # commit 2 on master
pushy-merge b1 -m merge1 >> "$MY_OUTPUT" 2>&1    # merge b1 into master
pushy-log >> "$MY_OUTPUT" 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
pushy-show 3:a >> "$MY_OUTPUT" 2>&1
pushy-show 3:b >> "$MY_OUTPUT" 2>&1
pushy-show 3:c >> "$MY_OUTPUT" 2>&1
pushy-show 3:d >> "$MY_OUTPUT" 2>&1
pushy-show 3:e >> "$MY_OUTPUT" 2>&1
pushy-show 3:f >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy a b c d e f

2041 pushy-init > "$CORRECT_OUTPUT" 2>&1
seq -f "line %.0f" 1 7 >a
seq -f "line %.0f" 1 7 >b
seq -f "line %.0f" 1 7 >c
seq -f "line %.0f" 1 7 >d
2041 pushy-add a b c d >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-commit -m commit-0 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch b1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout b1 >> "$CORRECT_OUTPUT" 2>&1
seq -f "line %.0f" 0 7 >a
seq -f "line %.0f" 1 8 >b
seq -f "line %.0f" 1 7 >e
2041 pushy-add e >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-commit -a -m commit-1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout master >> "$CORRECT_OUTPUT" 2>&1
sed -i 4d c
seq -f "line %.0f" 0 8 >d
seq -f "line %.0f" 1 7 >f
2041 pushy-add f >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-commit -a -m commit-2 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-merge b1 -m merge1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-log >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-show 3:a >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-show 3:b >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-show 3:c >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-show 3:d >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-show 3:e >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-show 3:f >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy a b c d e f

test_name="(pushy-merge): successful merge - merge a branch into master"
test_command 15 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 16: Merge conflict
pushy-init > "$MY_OUTPUT" 2>&1
seq 1 7 >7.txt 
pushy-add 7.txt > /dev/null 2>&1
pushy-commit -m commit-0 >> "$MY_OUTPUT" 2>&1
pushy-branch b1 >> "$MY_OUTPUT" 2>&1
pushy-checkout b1 >> "$MY_OUTPUT" 2>&1
sed -Ei s/2/42/ 7.txt
pushy-commit -a -m commit-1 >> "$MY_OUTPUT" 2>&1
pushy-checkout master >> "$MY_OUTPUT" 2>&1
sed -Ei s/5/24/ 7.txt 
pushy-commit -a -m commit-2 >> "$MY_OUTPUT" 2>&1
pushy-merge b1 -m merge-message >> "$MY_OUTPUT" 2>&1
pushy-log >> "$MY_OUTPUT" 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy 7.txt

2041 pushy-init > "$CORRECT_OUTPUT" 2>&1
seq 1 7 >7.txt 
2041 pushy-add 7.txt > /dev/null 2>&1
2041 pushy-commit -m commit-0 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch b1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout b1 >> "$CORRECT_OUTPUT" 2>&1
sed -Ei s/2/42/ 7.txt
2041 pushy-commit -a -m commit-1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout master >> "$CORRECT_OUTPUT" 2>&1
sed -Ei s/5/24/ 7.txt
2041 pushy-commit -a -m commit-2 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-merge b1 -m merge-message >> "$CORRECT_OUTPUT" 2>&1
# pushy-merge: error: These files can not be merged:
# 7.txt
2041 pushy-log >> "$CORRECT_OUTPUT" 2>&1
# 2 commit-2
# 0 commit-0
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
# 7.txt - same as repo
correct_status=$?
rm -rf .pushy 7.txt

test_name="(pushy-merge): merge conflict"
test_command 16 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 17: Delete branch with unmerged work
pushy-init > "$MY_OUTPUT" 2>&1
echo hello >a 
pushy-add a > /dev/null 2>&1
pushy-commit -m commit-A >> "$MY_OUTPUT" 2>&1
pushy-branch branch1 >> "$MY_OUTPUT" 2>&1
pushy-checkout branch1 >> "$MY_OUTPUT" 2>&1
echo world >b
pushy-add b > /dev/null 2>&1
pushy-commit -a -m commit-B >> "$MY_OUTPUT" 2>&1
pushy-checkout master >> "$MY_OUTPUT" 2>&1
pushy-branch -d branch1 >> "$MY_OUTPUT" 2>&1
pushy-merge branch1 -m merge-message >> "$MY_OUTPUT" 2>&1
# Fast-forward: no commit created
pushy-branch -d branch1 >> "$MY_OUTPUT" 2>&1
pushy-branch >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy a b

2041 pushy-init > "$CORRECT_OUTPUT" 2>&1
echo hello >a
2041 pushy-add a > /dev/null 2>&1
2041 pushy-commit -m commit-A >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch branch1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout branch1 >> "$CORRECT_OUTPUT" 2>&1
echo world >b
2041 pushy-add b > /dev/null 2>&1
2041 pushy-commit -a -m commit-B >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout master >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch -d branch1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-merge branch1 -m merge-message >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch -d branch1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy a b

test_name="(pushy-merge): delete branch with unmerged work"
test_command 17 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 18: Merge errors
pushy-init > "$MY_OUTPUT" 2>&1
seq 1 7 >7.txt 
pushy-add 7.txt > /dev/null 2>&1
pushy-commit -m commit-0 >> "$MY_OUTPUT" 2>&1
pushy-branch b1 >> "$MY_OUTPUT" 2>&1
pushy-checkout b1 >> "$MY_OUTPUT" 2>&1
sed -Ei s/2/42/ 7.txt
pushy-commit -a -m commit-1 >> "$MY_OUTPUT" 2>&1
pushy-checkout master >> "$MY_OUTPUT" 2>&1
sed -Ei s/5/24/ 7.txt
pushy-commit -a -m commit-2 >> "$MY_OUTPUT" 2>&1
pushy-merge b1 >> "$MY_OUTPUT" 2>&1
pushy-merge non-existent-branch -m message >> "$MY_OUTPUT" 2>&1
pushy-merge b1 -m message >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy 7.txt

2041 pushy-init > "$CORRECT_OUTPUT" 2>&1
seq 1 7 >7.txt
2041 pushy-add 7.txt > /dev/null 2>&1
2041 pushy-commit -m commit-0 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch b1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout b1 >> "$CORRECT_OUTPUT" 2>&1
sed -Ei s/2/42/ 7.txt
2041 pushy-commit -a -m commit-1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout master >> "$CORRECT_OUTPUT" 2>&1
sed -Ei s/5/24/ 7.txt
2041 pushy-commit -a -m commit-2 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-merge b1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-merge non-existent-branch -m message >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-merge b1 -m message >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy 7.txt

test_name="(pushy-merge): merge errors"
test_command 18 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 19: Merge with many branches
pushy-init > "$MY_OUTPUT" 2>&1
echo 0 >level0 
pushy-add level0 > /dev/null 2>&1
pushy-commit -m root >> "$MY_OUTPUT" 2>&1
pushy-branch b0 >> "$MY_OUTPUT" 2>&1
pushy-branch b1 >> "$MY_OUTPUT" 2>&1
pushy-checkout b0 >> "$MY_OUTPUT" 2>&1
echo 0 >level1 
pushy-add level1 > /dev/null 2>&1
pushy-commit -m 0 >> "$MY_OUTPUT" 2>&1
pushy-checkout b1 >> "$MY_OUTPUT" 2>&1
echo 1 >level1
pushy-add level1 > /dev/null 2>&1
pushy-commit -m 1 >> "$MY_OUTPUT" 2>&1
pushy-checkout b0 >> "$MY_OUTPUT" 2>&1
pushy-branch b00 >> "$MY_OUTPUT" 2>&1
pushy-branch b01 >> "$MY_OUTPUT" 2>&1
pushy-checkout b1 >> "$MY_OUTPUT" 2>&1
pushy-branch b10 >> "$MY_OUTPUT" 2>&1
pushy-branch b11 >> "$MY_OUTPUT" 2>&1
pushy-checkout b00 >> "$MY_OUTPUT" 2>&1
echo 00 >level2
pushy-add level2 > /dev/null 2>&1
pushy-commit -m 00 >> "$MY_OUTPUT" 2>&1
pushy-checkout b01 >> "$MY_OUTPUT" 2>&1
echo 01 >level2
pushy-add level2 > /dev/null 2>&1
pushy-commit -m 01 >> "$MY_OUTPUT" 2>&1
pushy-checkout b10 >> "$MY_OUTPUT" 2>&1
echo 10 >level2
pushy-add level2 > /dev/null 2>&1
pushy-commit -m 10 >> "$MY_OUTPUT" 2>&1
pushy-checkout b11 >> "$MY_OUTPUT" 2>&1
echo 11 >level2
pushy-add level2 > /dev/null 2>&1
pushy-commit -m 11 >> "$MY_OUTPUT" 2>&1
pushy-checkout master >> "$MY_OUTPUT" 2>&1
pushy-log >> "$MY_OUTPUT" 2>&1
pushy-checkout b1 >> "$MY_OUTPUT" 2>&1
pushy-log >> "$MY_OUTPUT" 2>&1
pushy-checkout b01 >> "$MY_OUTPUT" 2>&1
pushy-log >> "$MY_OUTPUT" 2>&1
pushy-checkout b11 >> "$MY_OUTPUT" 2>&1
pushy-log >> "$MY_OUTPUT" 2>&1
pushy-checkout master >> "$MY_OUTPUT" 2>&1
pushy-merge b0 -m merge0 >> "$MY_OUTPUT" 2>&1
pushy-merge b00 -m merge00 >> "$MY_OUTPUT" 2>&1
pushy-log >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy level0 level1 level2

2041 pushy-init > "$CORRECT_OUTPUT" 2>&1
echo 0 >level0
2041 pushy-add level0 > /dev/null 2>&1
2041 pushy-commit -m root >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch b0 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch b1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout b0 >> "$CORRECT_OUTPUT" 2>&1
echo 0 >level1
2041 pushy-add level1 > /dev/null 2>&1
2041 pushy-commit -m 0 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout b1 >> "$CORRECT_OUTPUT" 2>&1
echo 1 >level1
2041 pushy-add level1 > /dev/null 2>&1
2041 pushy-commit -m 1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout b0 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch b00 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch b01 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout b1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch b10 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-branch b11 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout b00 >> "$CORRECT_OUTPUT" 2>&1
echo 00 >level2
2041 pushy-add level2 > /dev/null 2>&1
2041 pushy-commit -m 00 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout b01 >> "$CORRECT_OUTPUT" 2>&1
echo 01 >level2
2041 pushy-add level2 > /dev/null 2>&1
2041 pushy-commit -m 01 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout b10 >> "$CORRECT_OUTPUT" 2>&1
echo 10 >level2
2041 pushy-add level2 > /dev/null 2>&1
2041 pushy-commit -m 10 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout b11 >> "$CORRECT_OUTPUT" 2>&1
echo 11 >level2
2041 pushy-add level2 > /dev/null 2>&1
2041 pushy-commit -m 11 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout master >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-log >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout b1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-log >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout b01 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-log >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout b11 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-log >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-checkout master >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-merge b0 -m merge0 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-merge b00 -m merge00 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-log >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy level0 level1 level2

test_name="(pushy-merge): merge with many branches"
test_command 19 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"




