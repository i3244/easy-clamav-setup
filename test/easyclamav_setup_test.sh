#!/bin/bash
#
# @(#) easyclamav_setup_test.sh ver.0.1.8 2019.08.26
# @author i3244

# *****************************************************************************
function oneTimeSetUp() {
  rm -fv /etc/cron.d/easyclamav
  rm -frv ${EASYCLAMAV_HOME}
  yum -y erase clamav*
  yum -y erase epel-release
  rm -fv /etc/freshclam*
  setsebool -P antivirus_can_scan_system off
  setsebool -P antivirus_use_jit off
}

# *****************************************************************************
function setUp() {
  cp -fv files/freshclam.conf /etc
}

# *****************************************************************************
function test_install_epel() {
  install_package epel-release extras
  assertTrue "install epel failed." ${?}

  yum --disablerepo=* list installed epel-release
  assertTrue "epel not installed." ${?}

  install_package epel-release extras
  assertTrue "install epel failed." ${?}

  yum --disablerepo=* list installed epel-release
  assertTrue "epel not installed." ${?}
}

function test_install_clamav() {
  install_package clamav epel,base
  assertTrue "install clamav failed." ${?}

  yum --disablerepo=* list installed clamav
  assertTrue "clamav not installed." ${?}

  install_package clamav epel,base
  assertTrue "install clamav failed." ${?}

  yum --disablerepo=* list installed clamav
  assertTrue "clamav not installed." ${?}
}

# *****************************************************************************
function test_set_local_db_url_japanese() {
  local conf_file="/etc/freshclam.conf"

  set_local_db_url \
      "${conf_file}" \
      "Asia/Tokyo" \
      "Asia/Tokyo" \
      "db.jp.clamav.net"

  assertTrue "set_local_db_url failed." ${?}

  assertEquals "after set_local_db_url, url lines must be 2." \
      2 \
      $(grep "^DatabaseMirror" ${conf_file} | wc -l)

  assertEquals "set_local_db_url jp url must be above default." \
      "DatabaseMirror db.jp.clamav.net" \
      "$(grep "^DatabaseMirror" ${conf_file} | head -n 1)"

  assertEquals "set_local_db_url default url must be under jp." \
      "DatabaseMirror database.clamav.net" \
      "$(grep "^DatabaseMirror" ${conf_file} | tail -n 1)"

  set_local_db_url \
      "${conf_file}" \
      "Asia/Tokyo" \
      "Asia/Tokyo" \
      "db.jp.clamav.net"

  assertTrue "set_local_db_url failed." ${?}

  assertEquals "after set_local_db_url, url lines must be 2." \
      2 \
      $(grep "^DatabaseMirror" ${conf_file} | wc -l)
}

function test_set_local_db_url_not_japanese() {
  local conf_file="/etc/freshclam.conf"

  set_local_db_url \
      "${conf_file}" \
      "Pacific/Honolulu" \
      "Asia/Tokyo" \
      "db.jp.clamav.net"

  assertTrue "set_local_db_url failed." ${?}

  assertEquals "after set_local_db_url, url lines must be 1." \
      1 \
      $(grep "^DatabaseMirror" ${conf_file} | wc -l)

  assertEquals "set_local_db_url jp url must be default." \
      "DatabaseMirror database.clamav.net" \
      "$(grep "^DatabaseMirror" ${conf_file})"

  set_local_db_url \
      "${conf_file}" \
      "Pacific/Honolulu" \
      "Asia/Tokyo" \
      "db.jp.clamav.net"

  assertTrue "set_local_db_url failed." ${?}

  assertEquals "after set_local_db_url, url lines must be 1." \
      1 \
      $(grep "^DatabaseMirror" ${conf_file} | wc -l)
}

# *****************************************************************************
function test_set_proxy_settings_proto_user_pass_server_port_slash() {
  local conf_file="/etc/freshclam.conf"
  local proxy_env="http://testuser:testpass@testserver:8888/"

  set_proxy_settings \
      "${conf_file}" \
      "${proxy_env}"

  assertTrue "set_proxy_settings failed." ${?}

  assertEquals "after set_proxy_settings, proxy setting lines must be 4." \
      4 \
      $(grep "^HTTPProxy" ${conf_file} | wc -l)

  assertEquals "bad proxy user." \
      testuser \
      $(grep "^HTTPProxyUsername" ${conf_file} | awk '{print $2}')

  assertEquals "bad proxy pass." \
      testpass \
      $(grep "^HTTPProxyPassword" ${conf_file} | awk '{print $2}')

  assertEquals "bad proxy server." \
      testserver \
      $(grep "^HTTPProxyServer" ${conf_file} | awk '{print $2}')

  assertEquals "bad proxy port." \
      8888 \
      $(grep "^HTTPProxyPort" ${conf_file} | awk '{print $2}')

  set_proxy_settings \
      "${conf_file}" \
      "${proxy_env}"

  assertTrue "set_proxy_settings failed." ${?}

  assertEquals "after set_proxy_settings, proxy setting lines must be 4." \
      4 \
      $(grep "^HTTPProxy" ${conf_file} | wc -l)

  set_proxy_settings \
      "${conf_file}" \
      ""

  assertTrue "set_proxy_settings failed." ${?}

  assertEquals "after set_proxy_settings, proxy setting lines must be 0." \
      0 \
      $(grep "^HTTPProxy" ${conf_file} | wc -l)
}

function test_set_proxy_settings_user_pass_server_port() {
  local conf_file="/etc/freshclam.conf"
  local proxy_env="testuser:testpass@testserver:8888"

  set_proxy_settings \
      "${conf_file}" \
      "${proxy_env}"

  assertTrue "set_proxy_settings failed." ${?}

  assertEquals "after set_proxy_settings, proxy setting lines must be 4." \
      4 \
      $(grep "^HTTPProxy" ${conf_file} | wc -l)

  assertEquals "bad proxy user." \
      testuser \
      $(grep "^HTTPProxyUsername" ${conf_file} | awk '{print $2}')

  assertEquals "bad proxy pass." \
      testpass \
      $(grep "^HTTPProxyPassword" ${conf_file} | awk '{print $2}')

  assertEquals "bad proxy server." \
      testserver \
      $(grep "^HTTPProxyServer" ${conf_file} | awk '{print $2}')

  assertEquals "bad proxy port." \
      8888 \
      $(grep "^HTTPProxyPort" ${conf_file} | awk '{print $2}')

  set_proxy_settings \
      "${conf_file}" \
      "${proxy_env}"

  assertTrue "set_proxy_settings failed." ${?}

  assertEquals "after set_proxy_settings, proxy setting lines must be 4." \
      4 \
      $(grep "^HTTPProxy" ${conf_file} | wc -l)
}

function test_set_proxy_settings_server_port() {
  local conf_file="/etc/freshclam.conf"
  local proxy_env="testserver:8888"

  set_proxy_settings \
      "${conf_file}" \
      "${proxy_env}"

  assertTrue "set_proxy_settings failed." ${?}

  assertEquals "after set_proxy_settings, proxy setting lines must be 2." \
      2 \
      $(grep "^HTTPProxy" ${conf_file} | wc -l)

  assertEquals "bad proxy server." \
      testserver \
      $(grep "^HTTPProxyServer" ${conf_file} | awk '{print $2}')

  assertEquals "bad proxy port." \
      8888 \
      $(grep "^HTTPProxyPort" ${conf_file} | awk '{print $2}')

  set_proxy_settings \
      "${conf_file}" \
      "${proxy_env}"

  assertTrue "set_proxy_settings failed." ${?}

  assertEquals "after set_proxy_settings, proxy setting lines must be 2." \
      2 \
      $(grep "^HTTPProxy" ${conf_file} | wc -l)
}

# *****************************************************************************
function test_set_selinux_bool_antivirus_can_scan_system() {
  local sebool="antivirus_can_scan_system"

  set_selinux_bool "Enforcing" "${sebool}"

  assertTrue "set_selinux_bool failed." ${?}

  assertEquals "set_selinux_bool must set on." \
      on \
      $(getsebool "${sebool}" | awk '{print $3}')

  set_selinux_bool "Disabled" "${sebool}"

  assertTrue "set_selinux_bool failed." ${?}

  assertEquals "set_selinux_bool must set off." \
      off \
      $(getsebool "${sebool}" | awk '{print $3}')
}

function test_set_selinux_bool_antivirus_use_jit() {
  local sebool="antivirus_use_jit"

  set_selinux_bool "Enforcing" "${sebool}"

  assertTrue "set_selinux_bool failed." ${?}

  assertEquals "set_selinux_bool must set on." \
      on \
      $(getsebool "${sebool}" | awk '{print $3}')

  set_selinux_bool "Disabled" "${sebool}"

  assertTrue "set_selinux_bool failed." ${?}

  assertEquals "set_selinux_bool must set off." \
      off \
      $(getsebool "${sebool}" | awk '{print $3}')
}

# *****************************************************************************
# Entry point

source ../easyclamav.conf || exit ${?}

source ../easyclamav_setup.sh || exit ${?}

# Load and run shUnit2.
source lib/shunit2
