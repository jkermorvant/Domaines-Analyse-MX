#!/bin/bash

domains_no_mx=""
domains_no_oxygen_mx=""
domains_missing_oxygen_mx=""
domains_unequals_mx_weight=""

IFS=$'\n'
for domain in $(mysql --batch --execute="SELECT domain FROM domains;" -- oxygen | tail -n +2); do
    IFS=''
    mx_list="$(dig +short -t MX $domain @8.8.8.8)"

    if [ "$mx_list" == "" ]; then
        domains_no_mx="$domains_no_mx $domain"
        continue
    fi

    mx_list_target="$(echo $mx_list | awk '{print $2}' | tr '\r\n' ' ')"
    IFS=$' \t\n'
    mx_list_ip="$(dig +short -t A $mx_list_target @8.8.8.8 | grep -E "^[0-9\.]+$")"
    IFS=''

    echo $mx_list_ip | grep -E "^195\.160\.18[89]\.2$" > /dev/null
    if [ $? -eq 1 ]; then
        domains_no_oxygen_mx="$domains_no_oxygen_mx $domain"
        continue
    fi

    count=$(echo $mx_list_ip | grep -E "^195\.160\.18[89]\.2$" | wc -l)
    if [ $count -ne 2 ]; then
        domains_missing_oxygen_mx="$domains_missing_oxygen_mx $domain"
        continue
    fi

    count=$(echo $mx_list | awk '{print $1}' | uniq | wc -l)
    if [ $count -ne 1 ]; then
        domains_unequals_mx_weight="$domains_unequals_mx_weight $domain"
        continue
    fi
done

IFS=" "

if [ "$domains_no_mx" != "" ]; then
    echo "DOMAINES SANS MX DÉCLARÉS :"
    for domain in $domains_no_mx; do
        echo "    $domain"
    done
fi
echo ""

if [ "$domains_no_oxygen_mx" != "" ]; then
    echo "DOMAINES SANS MX OXYGEN :"
    for domain in $domains_no_oxygen_mx; do
        echo "    $domain"
    done
fi
echo ""

if [ "$domains_missing_oxygen_mx" != "" ]; then
    echo "DOMAINES MANQUANT UN OU PLUSIEURS MX OXYGEN :"
    for domain in $domains_missing_oxygen_mx; do
        echo "    $domain"
    done
fi
echo ""

if [ "$domains_unequals_mx_weight" != "" ]; then
    echo "DOMAINES AVEC DES MX DE POIDS INÉGAUX :"
    for domain in $domains_unequals_mx_weight; do
        echo "    $domain"
    done
fi
