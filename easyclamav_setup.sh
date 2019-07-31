#!/bin/bash
#
# @(#) easyclamav_setup.sh ver.0.1.7 2019.07.31
# @author i3244
#
# Description:
#   A shell-script to install minimal ClamAV packages, and setup simple
#   scanning environment.
#

# *****************************************************************************
# $1  package to be installed
# $2  essencial repository
function install_package() {
  echo "Entered: ${FUNCNAME[0]}(${*})"

  yum --disablerepo=* list installed ${1} 2>/dev/null ||
      yum -y --enablerepo=${2} install ${1} || return ${?}

  return 0
}

# *****************************************************************************
# Insert URL of local virus database to be priorred above the default URL.
# (Japan only)
#     Before:
#         DatabaseMirror database.clamav.net
#     After:
#         DatabaseMirror db.jp.clamav.net
#         DatabaseMirror database.clamav.net
#
# $1  configuration file
# $2  current timezone
# $3  local timezone
# $4  URL of local virus database
function set_local_db_url() {
  echo "Entered: ${FUNCNAME[0]}(${*})"

  local conf_file="${1}"
  local local_db_url_line="DatabaseMirror ${4}"

  if [[ ${2} == ${3} ]]; then
    if ! grep -q "^${local_db_url_line}" "${conf_file}"; then
      sed -i "s/^\(DatabaseMirror .*\)$/${local_db_url_line}\n\1/" \
          "${conf_file}" || return ${?}
    fi
  else
    if grep -q "^${local_db_url_line}" "${conf_file}"; then
      sed -i "/^${local_db_url_line}$/d" "${conf_file}" || return ${?}
    fi
  fi

  echo "--------"
  grep "^DatabaseMirror" "${conf_file}"
  echo -e "--------\n"

  return 0
}

# *****************************************************************************
# Get proxy settings on the system.
function get_system_proxy() {

  local proxy_env=

  for proxy_env in "${http_proxy}" "${HTTP_PROXY}"
  do
    if [[ ${proxy_env} =~ : ]]; then
      echo ${proxy_env}
      exit 0
    fi
  done

  proxy_env=$(grep '^proxy=' /etc/yum.conf 2>/dev/null | sed -e 's|^proxy=\(.*\)$|\1|')
  if [[ ${proxy_env} =~ : ]]; then
    echo ${proxy_env}
    exit 0
  fi

  return 0
}

# *****************************************************************************
# Set proxy authentication settings to the configuration file.
# $1  configuration file
# $2  http_proxy environment
function set_proxy_settings() {
  echo "Entered: ${FUNCNAME[0]}(${*})"

  local conf_file="${1}"
  local proxy_env="${2}"
  local proxy_server=
  local proxy_port=
  local proxy_user=
  local proxy_pass=

  if [[ "${proxy_env}" != "" ]]; then
    proxy_env=${proxy_env/http:\/\//}   # Remove 'http://'.
    proxy_env=${proxy_env/https:\/\//}  # Remove 'https://'.
    proxy_env=${proxy_env////}          # Remove all '/'.

    proxy_port=${proxy_env##*:} # Get string (port) right than the last ':'
    proxy_env=${proxy_env%:*}   # Remove the last ':' and right string.

    if [[ ${proxy_env} =~ @ ]]; then
      # When '@' exists, get server, user and password.
      proxy_server=$(echo ${proxy_env} | cut -d@ -f2)
      proxy_user=$(echo ${proxy_env} | cut -d@ -f1 | cut -d: -f1)
      proxy_pass=$(echo ${proxy_env} | cut -d@ -f1 | cut -d: -f2)
    else
      # When not exist '@', get server.
      proxy_server=${proxy_env}
    fi
  fi

  # Set server and port to the configuration file.
  if [[ ${proxy_server} != "" && ${proxy_port} != "" ]]; then
    sed -i "s/^#*HTTPProxyServer.*$/HTTPProxyServer ${proxy_server}/" \
        "${conf_file}" || return ${?}
    sed -i "s/^#*HTTPProxyPort.*$/HTTPProxyPort ${proxy_port}/" \
        "${conf_file}" || return ${?}
  else
    sed -i "s/^HTTPProxyServer.*$/#HTTPProxyServer myproxy.com/" \
        "${conf_file}" || return ${?}
    sed -i "s/^HTTPProxyPort.*$/#HTTPProxyPort 1234/" \
        "${conf_file}" || return ${?}
  fi

  # Set user and password to the configuration file.
  if [[ "${proxy_user}" != "" ]]; then
    sed -i "s/^#*HTTPProxyUsername.*$/HTTPProxyUsername ${proxy_user}/" \
        "${conf_file}" || return ${?}
    sed -i "s/^#*HTTPProxyPassword.*$/HTTPProxyPassword ${proxy_pass}/" \
        "${conf_file}" || return ${?}
  else
    sed -i "s/^HTTPProxyUsername.*$/#HTTPProxyUsername myusername/" \
        "${conf_file}" || return ${?}
    sed -i "s/^HTTPProxyPassword.*$/#HTTPProxyPassword mypass/" \
        "${conf_file}" || return ${?}
  fi

  echo "--------"
  grep "^#*HTTPProxy" "${conf_file}"
  echo -e "--------\n"

  return 0
}

# *****************************************************************************
# Set SELinux boolean to on.
# $1  getenforce
# $2  SELinux boolean value
function set_selinux_bool() {
  echo "Entered: ${FUNCNAME[0]}(${*})"

  local sebool="${2}"

  if [[ ${1} == "Enforcing" ]]; then
    if [[ $(getsebool ${sebool} | awk '{print $3}') != on ]]; then
      setsebool -P ${sebool} on || return ${?}
    fi
  else
    if [[ $(getsebool ${sebool} | awk '{print $3}') != off ]]; then
      setsebool -P ${sebool} off || return ${?}
    fi
  fi

  echo "--------"
  getsebool ${sebool}
  echo -e "--------\n"

  return 0
}

# *****************************************************************************
# Entry point

if [[ ${EASYCLAMAV_STATUS} != "stop" ]]; then

  cd $(dirname "${0}")

  source easyclamav.conf || exit ${?}

  # Install epel-release and clamav.
  install_package epel-release  extras    || exit ${?}
  install_package clamav        epel,base || exit ${?}

  # Insert URL of local virus database to be priorred above the default URL.
  set_local_db_url \
      "/etc/freshclam.conf" \
      $(timedatectl status | grep "^\s*Time zone:\s*Asia/Tokyo" | awk '{print $3}') \
      "Asia/Tokyo" \
      "db.jp.clamav.net" || exit ${?}

  # Set proxy authentication settings to the configuration file.
  set_proxy_settings \
      "/etc/freshclam.conf" \
      "$(get_system_proxy)" || exit ${?}

  # Set SELinux boolean to on.
  set_selinux_bool $(getenforce) antivirus_can_scan_system  || exit ${?}
  set_selinux_bool $(getenforce) antivirus_use_jit          || exit ${?}

  # Copy batch script and configuration file.
  [[ -d ${EASYCLAMAV_HOME} ]] || mkdir -pv "${EASYCLAMAV_HOME}"
  cp -fv easyclamav      "${EASYCLAMAV_HOME}" || exit ${?}
  cp -fv easyclamav.conf "${EASYCLAMAV_HOME}" || exit ${?}
  chmod -v +x "${EASYCLAMAV_HOME}/easyclamav"
  echo "--------"
  ls -l "${EASYCLAMAV_HOME}"
  echo -e "--------\n"

  # Create excluding list.
  exclude_list="${EASYCLAMAV_HOME}/exclude_list"
  : >"${exclude_list}"
  for exclude_path in "${EXCLUDE_PATHS[@]}"
  do
    echo "${exclude_path}" >>"${exclude_list}"
  done
  echo "${MOVE_DIRECTORY}/" >>"${exclude_list}"
  echo "--------"
  cat "${exclude_list}"
  echo -e "--------\n"

  # Create batch schedule.
  schedule_file="/etc/cron.d/easyclamav"
  echo "${SCAN_SCHEDULE} root '${EASYCLAMAV_HOME}/easyclamav'" \
      >"${schedule_file}" || exit ${?}
  echo "--------"
  cat "${schedule_file}"
  echo -e "--------\n"

  echo "Completed."
  exit 0
fi

