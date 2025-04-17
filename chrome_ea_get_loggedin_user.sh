#!/bin/bash

# Function to extract JSON values
# CREDIT to this code goes to @Pico: https://macadmins.slack.com/archives/CGXNNJXJ9/p1652222365989229?thread_ts=1651786411.413349&cid=CGXNNJXJ9
# Also https://github.com/PicoMitchell
getJSONValue() {
    # $1: JSON string OR file path to parse
    # $2: JSON key path to look up (using dot or bracket notation)
    printf '%s' "$1" | /usr/bin/osascript -l 'JavaScript' \
        -e "let json = $.NSString.alloc.initWithDataEncoding($.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile$(/usr/bin/uname -r | /usr/bin/awk -F '.' '($1 > 18) { print "AndReturnError(ObjC.wrap())" }'), $.NSUTF8StringEncoding)" \
        -e 'if ($.NSFileManager.defaultManager.fileExistsAtPath(json)) json = $.NSString.stringWithContentsOfFileEncodingError(json, $.NSUTF8StringEncoding, ObjC.wrap())' \
        -e "const value = JSON.parse(json.js)$([ -n "${2%%[.[]*}" ] && echo '.')$2" \
        -e 'if (typeof value === "object") { JSON.stringify(value, null, 4) } else { value }'
}

# Get the current console user
currentUser=$(echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && !/loginwindow/ { print $3 }')

# Path to Chrome profiles
chromeProfilesPath="/Users/$currentUser/Library/Application Support/Google/Chrome"

# Allowed domain list
allowedDomains=(
    "company.com"
    "company.org"
)

# Initialize the UserEmails variable
UserEmails=""

# Profiles to include (Default and Profile*)
profilesToCheck=("Default")
while IFS= read -r -d '' profile; do
    profilesToCheck+=("$(basename "$profile")")
done < <(find "$chromeProfilesPath" -maxdepth 1 -type d -name "Profile*" -print0)

# Iterate through all Chrome profiles
for profile in "${profilesToCheck[@]}"; do
    profilePath="$chromeProfilesPath/$profile"
    
    if [ -d "$profilePath" ]; then
        # Extract the logged-in user email from the Preferences file
        userEmail=$(getJSONValue "$profilePath/Preferences" "account_info[0].email" 2>/dev/null)
        
        # Skip if no email is found
        if [[ -z "$userEmail" ]]; then
            echo "No email found for profile: $profile"
            continue
        fi
        
        # Check if the email contains any of the allowed domains
        for domain in "${allowedDomains[@]}"; do
            if [[ "$userEmail" == *"$domain" ]]; then
                echo "Profile: $profile"
                echo "Logged in user: $userEmail"
                
                # Append the userEmail to UserEmails
                UserEmails+="$userEmail"$'\n'
                break
            fi
        done
    fi
done

# Output the UserEmails variable
#echo "Final Result:"
echo "$UserEmails"

if [[ -n "$UserEmails" ]]; then
    FinalResult="$UserEmails"
else
    FinalResult="not found"
fi


echo -n "<result>"$FinalResult"</result>"
