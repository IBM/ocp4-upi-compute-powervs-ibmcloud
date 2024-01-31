#!/bin/bash

VPC_REGION=$(
        case "$POWERVS_ZONE" in
            ("dal10") echo "us-south" ;;
            ("dal12") echo "us-south" ;;
            ("us-south") echo "us-south" ;;
            ("wdc06") echo "us-east" ;;
            ("us-east") echo "us-east" ;;
            ("sao01") echo "br-sao" ;;
            ("tor01") echo "ca-tor" ;;
            ("mon01") echo "ca-mon" ;;
            ("mad01") echo "eu-es" ;;
            ("eu-de-1") echo "eu-de" ;;
            ("eu-de-2") echo "eu-de" ;;
            ("lon04") echo "eu-gb" ;;
            ("lon06") echo "eu-gb" ;;
            ("syd04") echo "eu-gb" ;;
            ("syd05") echo "au-syd" ;;
            ("tok04") echo "jp-tok" ;;
            ("osa21") echo "jp-osa" ;;
            (*) echo "$POWERVS_ZONE" ;;
        esac)
