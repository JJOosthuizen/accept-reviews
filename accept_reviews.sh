#!/bin/bash

# Define the module and status to look for
module="$1"
#status="Assigned"
status="Invited"

folder_path="/home/wtc/student_work/reviews/java-reviews/$module"

# Create the folder if it doesn't exist
if [ ! -d "$folder_path" ]; then
  mkdir "$folder_path"
fi

# Run the command and capture the output
output=$(wtc-lms reviews)
# Get the reviews that match the module and status
reviews=$(echo "$output" | grep "$module.*$status") 
#echo "$reviews"
#stores reviews into and array
readarray -t reviews_array <<< "$reviews"

# Check if there are any reviews for the module and status
if [ -z "$reviews" ]; then
  echo "There are no reviews for module $module with status $status"
  echo "You might already have accepted 3 reviews for $module. Or you forgot to login!"
  exit 0
fi

# Initialize a counter for the number of reviews accepted
num_accepted=0
# empty array
names=()
# Loop through the reviews and accept up to 3 of them
while read -r line; do
  if [ "$num_accepted" -lt 3 ]; then
    #create random number
    rand_num=$((RANDOM%${#reviews_array[@]}))
    
    #get the review using the random number
    rand_selected_review=${reviews_array[rand_num]}

    #filter to only get the code
    code=$(echo "$rand_selected_review" | sed -n 's/.*(\(.*\)).*/\1/p')
    #echo "$code"
    #accept the review like normal using LMS
    wtc-lms accept "$code"
   
    #get the review's details/information
    accepted_reviews=$(wtc-lms review_details "$code")
    #get the students username
    name=$(wtc-lms review_details "$code" | grep "Submission Members:" | cut -d "@" -f 1 | cut -d ":" -f 2 | tr -d '[:space:]')
    #add the student to an Array
    names+=("$name")
    
    printf "\nStudent $name submission has been accepted.\n\n"
    #get the gitlab url and clone the project to the directory indicated
    git_url=$(wtc-lms review_details $code | grep "Git Url:" | cut -d' ' -f3)
    git clone $git_url ~/student_work/reviews/java-reviews/$module/$name/submission_code
    #just makes a dir with the 3 word key word for the review
    mkdir ~/student_work/reviews/java-reviews/$module/$name/$code
    
    printf "\n\nFinished downloading their submission!\n\n"
    #add 1 after downloading the review
    num_accepted=$((num_accepted+1))
  fi
done <<< "$reviews"

# prints out all 3 students usernames and project locations
printf "\n\nFinished accepting all 3 reviews.\nStudents that you are reviewing:\n"
for name in "${names[@]}"; do
  printf "* ${name}\nReview of submission can be found at:\n~${folder_path}/${name}\n"
done
