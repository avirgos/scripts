#!/bin/bash

######################################################################
# Template
######################################################################
set -o errexit # Exit if command failed.
set -o pipefail # Exit if pipe failed.
set -o nounset # Exit if variable not set.
# Remove the initial space and instead use '\n'.
IFS=$'\n\t'

######################################################################
# Global variables
######################################################################
ARGUMENTS_PASSWORD_LENGTH=$(echo "${@}" | cut -d ' ' -f2)
ARGUMENTS_PASSWORD_MIN_LENGTH=8

######################################################################
# Generate a random password with the length chose by the user.
#
# Globals:s
#   ARGUMENTS_PASSWORD_LENGTH
# Locals:
#   passwordValid
#   allCharacters
#   password
# Arguments:
#   -g passwordLength
# Outputs:
#   Displays, on the standard output, the password generated.
######################################################################
function generator() {
    if ! test "${ARGUMENTS_PASSWORD_LENGTH}" = "-g" && ! test "${ARGUMENTS_PASSWORD_LENGTH}" -lt "${ARGUMENTS_PASSWORD_MIN_LENGTH}"
    then 
        local passwordValid=false
        local allCharacters='A-Za-z0-9[] !"#$%&'\''()*+,-./:;<=>?@\^_`{|}~'

        while test "${passwordValid}" = false
        do
            local password=$(< /dev/urandom tr -dc "${allCharacters}" | head -c "${ARGUMENTS_PASSWORD_LENGTH}" | tr -d '\n')
            
            if test $(echo "${password}" | grep '[a-z][A-Z][0-9][][ !"#$%&'\''()*+,-./:;<=>?@\^_`{|}~]')
            then
                echo "${password}"
                passwordValid=true
            fi 
        done
    else
        helpUser
    fi
}

######################################################################
# Get help.
#
# Globals:
#   None
# Locals:
#   None
# Arguments:
#   -h
# Outputs:
#   Displays, on the standard output, how to use the script.
######################################################################
function helpUser() {
    echo "Precision: passwordLength less than 8 is not allowed for security reasons.
    Usage: password-generator {
        -g passwordLength
        -h }"

    zenity --info \
           --title="Help" \
           --width=450 \
           --text="Precision: passwordLength less than 8 is not allowed for security reasons.\n
           Usage: password-generator {
                    -g passwordLength
                    -h }"
}

######################################################################
# Main program
######################################################################
if test "${#}" -eq 0 
then 
    helpUser
else 
    case "${1}" in
        -g)
            generator ;;
        -h)
            helpUser ;;
        *)
            helpUser ;;
    esac
fi