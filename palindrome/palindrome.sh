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
ARGUMENTS=$(echo "${@}")
ARGUMENTS_SENTENCE=$(echo "${@}" | cut -d ' ' -f 2-)
ARGUMENTS_NUMBER=$(echo "${#}")
ALL_SPECIAL_CHARACTERS='[ !"#$%&'\''()*+,./:;<=>?@\^_`{|}~]'
SPECIAL_CHARACTERS_EXCEPT_SPACE='[!"#$%&'\''()*+,./:;<=>?@\^_`{|}~]'

######################################################################
# Verify if words contains numbers.
#
# Globals:
#   ARGUMENTS
# Locals:
#   checkNumbersArguments
# Arguments:
#   None
# Return:
#   0 if the words don't contain numbers, non-0 if error.  
######################################################################
function validityWordsNumber() {
    local checkNumbersArguments=$(echo "${ARGUMENTS}" | grep '[0-9]')
        
    if ! test "${checkNumbersArguments}" 
    then
        return 0
    else
        errorNumbers
        return 1
    fi
}

######################################################################
# Search for words containing numbers and display them on
# a GTK+ dialog.
#
# Globals:
#   ARGUMENTS
# Locals:
#   resValidityWordsNumber
#   checkLineNumbers
#   line
# Arguments:
#   None
# Outputs:
#   Display invalid words, via a GTK+ dialog, containing
#   at least one number.
######################################################################
function errorNumbers() {
    local resValidityWordsNumber="${?}"

    if test "${resValidityWordsNumber}" -eq 1
    then
        echo "${ARGUMENTS}" | tr ' ' "\n" > wordsNumber.txt

        while read line 
        do
            local checkLineNumbers=$(echo "${line}" | grep -o '[0-9]')

            if test "${checkLineNumbers}"
            then               
                echo "[Invalid word] "${line}" contains "${checkLineNumbers}"."
            fi
        done < wordsNumber.txt

        rm wordsNumber.txt
    fi
}

######################################################################
# Remove accents from words.
#
# Globals:
#   ARGUMENTS
#   ARGUMENTS_SENTENCE
# Locals:
#   sentence
# Arguments:
#   None
# Return:
#   0 if the accents have been removed correctly, non-0 if error. 
######################################################################
function noAccents() {
    if ! test $(echo "${ARGUMENTS}" | grep '^-s')
    then
        echo "${ARGUMENTS}" | iconv -f UTF-8 -t ASCII//TRANSLIT > lower.txt
    else
        echo "${ARGUMENTS_SENTENCE}" | iconv -f UTF-8 -t ASCII//TRANSLIT > lower.txt
    fi
}

######################################################################
# Remove special characters from words of a sentence.
#
# Globals:
#   ALL_SPECIAL_CHARACTERS
# Locals:
#   noSpecialCharactersSentence
# Arguments:
#   None
# Return:
#   0 if the special characters have been removed correctly, 
#   non-0 if error. 
######################################################################
function noSpecialCharactersInSentence() {
    local noSpecialCharactersSentence=$(cat lower.txt) 
    echo "${noSpecialCharactersSentence}" | tr -d "${ALL_SPECIAL_CHARACTERS}" > lower.txt
}

######################################################################
# Convert words to lower case.
#
# Globals:
#   ARGUMENTS
# Locals:
#   noAccentsArgument
#   noAccentsSentence
# Arguments:
#   None
# Return:
#   0 if the conversion was successful, non-0 if error.
######################################################################
function convertLower() {
    if ! test $(echo "${ARGUMENTS}" | grep '^-s')
    then
        local noAccentsArgument=$(cat lower.txt | head -n 1)

        echo "${noAccentsArgument}" | tr '[A-Z]' '[a-z]' | tr ' ' "\n" > lower.txt
    else
        local noAccentsSentence=$(cat lower.txt)

        echo "${noAccentsSentence}" | tr '[A-Z]' '[a-z]' > lower.txt
    fi
}

######################################################################
# Check if words are palindromes.
#
# Globals:
#   None
# Locals:
#   resValidity
#   resNoAccents
#   resConvertLower
#   checkReverse
#   line
# Arguments:
#   aWord otherWord... infiniteWord
# Return:
#   0 if words are palindromes, non-0 if error.
######################################################################
function isPalindrome() {
    validityWordsNumber
    local resValidityNumber="${?}"

    if test "${resValidityNumber}" -eq 0
    then
        noAccents
        local resNoAccents="${?}"
    fi

    if test "${resNoAccents}" -eq 0
    then
        convertLower
        local resConvertLower="${?}"
    fi
    
    if test "${resConvertLower}" -eq 0
    then
        while read line
        do
            local checkReverse=$(echo "${line}" | rev)
            if test "${line}" = "${checkReverse}"
            then
                echo ""${1}" is a palindrome." >> isPalindrome.txt
            else
                echo ""${1}" is not a palindrome." >> isNotPalindrome.txt
            fi    

            shift
        done < lower.txt

        rm lower.txt

        if test -s isPalindrome.txt 
        then
            cat isPalindrome.txt 
            rm isPalindrome.txt
        fi

        if test -s isNotPalindrome.txt
        then
            cat isNotPalindrome.txt
            rm isNotPalindrome.txt
        fi    
    fi
}

######################################################################
# Check if the sentence is a palindrome.
#
# Globals:
#   ARGUMENTS_SENTENCE
# Locals:
#   resValidityWordsNumber
#   resNoAccents
#   resNoSpecialCharacters
#   resConvertLower
#   checkReverse
#   line
# Arguments:
#   -s mySentence
# Return:
#   0 if the sentence is a palindrome, non-0 if error.
######################################################################
function sentenceIsPalindrome() {
    if test "${ARGUMENTS_NUMBER}" -le 1
    then
        echo "The sentence is empty. Please try again."
            
        zenity --error \
               --width=200 \
               --text="The sentence is empty.\n
               Please try again."

        exit 1
    fi

    validityWordsNumber
    local resValidityNumber="${?}"

    if test "${resValidityNumber}" -eq 0
    then
        noAccents
        local resNoAccents="${?}"
    fi

    if test "${resNoAccents}" -eq 0
    then
        noSpecialCharactersInSentence
        local resNoSpecialCharactersInSentence="${?}"
    fi

    if test "${resNoSpecialCharactersInSentence}" -eq 0
    then
        convertLower
        local resConvertLower="${?}"
    fi

    if test "${resConvertLower}" -eq 0
    then
        while read line
        do
            local checkReverse=$(echo "${line}" | rev)

            if test "${line}" = "${checkReverse}"
            then
                echo "\""${ARGUMENTS_SENTENCE}"\" is a palindrome."
            else
                echo "\""${ARGUMENTS_SENTENCE}"\" is not a palindrome."
            fi    
        done < lower.txt
        
        rm lower.txt
    fi
}

######################################################################
# Get help.
#
# Globals:
#   ALL_SPECIAL_CHARACTERS
# Locals:
#   None
# Arguments:
#   -h
# Outputs:
#   Display, via a GTK+ dialog, how to use the script.
######################################################################
function helpUser() {
    echo 'Reminder : the following special characters '${ALL_SPECIAL_CHARACTERS}' are forbidden for *words mode*.
    Usage: palindrome {
        aWord otherWord... infiniteWord
        -s mySentence
        -h }'
    
    zenity --info \
           --title="Help" \
           --width=550 \
           --text='Reminder : the following special characters [!"#$%&amp;'\''()*+,./:;&lt;=>?@\^_`{|}~] are forbidden for *words mode*.\n
           Usage: palindrome {
                   aWord otherWord... infiniteWord
                   -s mySentence
                   -h }'
}

######################################################################
# Main program
######################################################################
if test "${#}" -eq 0
then
    helpUser
elif ! test $(echo "${@}" | grep '[]'${SPECIAL_CHARACTERS_EXCEPT_SPACE}'') && ! test $(echo "${@}" | grep '^-.$') && ! test $(echo "${@}" | grep '^-s')
then
    isPalindrome "${@}"
else
    case "${1}" in
    -h)
        helpUser ;;
    -s)
        sentenceIsPalindrome ;;
    *)
        helpUser ;;
    esac
fi