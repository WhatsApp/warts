#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

OTP_DIR="${SCRIPT_DIR}/otp"

if [[ -d "${SCRIPT_DIR}/.git" ]]; then
    OTP_DIR="${SCRIPT_DIR}"
fi

MIN_OTP_VERSION="26"

set -x

if [[ ! -d "${OTP_DIR}" ]]; then
    git clone --origin erlang git@github.com:erlang/otp.git "${OTP_DIR}"
fi
cd "${OTP_DIR}"
if [[ ! $(git remote | grep "^WhatsApp$") ]]; then
    git remote add WhatsApp git@github.com:WhatsApp/otp.git
fi
git fetch --all
git push WhatsApp refs/remotes/erlang/master:refs/heads/wa/main --tags
git push WhatsApp refs/remotes/erlang/master:refs/heads/master
git push WhatsApp refs/remotes/erlang/maint:refs/heads/maint
for branch in $(git branch --remotes | grep erlang/maint-); do
    git push WhatsApp "refs/remotes/erlang/${branch#erlang/}:refs/heads/${branch#erlang/}"
done
for otp_tag in $(git tag --list "OTP-*"); do
    if [[ "${otp_tag}" =~ ^OTP-(.*)$ ]]; then
        otp_version="${BASH_REMATCH[1]}"
        if [[ "${otp_version}" > "${MIN_OTP_VERSION}" || "${otp_version}" == "${MIN_OTP_VERSION}" ]]; then
            wa_otp_branch="wa/otp/${otp_version}/pristine"
            if [[ ! $(git rev-parse -q --verify "${wa_otp_branch}") ]]; then
                git branch "${wa_otp_branch}" "${otp_tag}"
            fi
            git push WhatsApp "${wa_otp_branch}"
        fi
    fi
done

exit 0

