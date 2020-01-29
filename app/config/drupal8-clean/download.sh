#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

#[ -z "$CMS_VERSION" ] && CMS_VERSION=8.7.x
[ -z "$CMS_VERSION" ] && CMS_VERSION=8
CIVI_VERSION_COMP=$(civicrm_composer_ver "$CIVI_VERSION")

mkdir "$WEB_ROOT"
drush8 -y dl drupal-${CMS_VERSION} --destination="$WEB_ROOT" --drupal-project-rename
mv "$WEB_ROOT/drupal" "$WEB_ROOT/web"

pushd "$WEB_ROOT/web" >> /dev/null
  drush8 dl -y devel-1 libraries userprotect
  composer require civicrm/civicrm-asset-plugin:'~1.0.0' civicrm/civicrm-setup:'0.4.0 as 0.2.99' civicrm/civicrm-{core,packages,drupal-8}:"$CIVI_VERSION_COMP" --prefer-source

  ## FIXME: All of the following should be removed/replaced as things get cleaner.
  composer require "cache/integration-tests:dev-master#b97328797ab199f0ac933e39842a86ab732f21f9" ## Issue: it's a require-dev in civicrm-core for E2E/Cache/*; how do we pull in civi require-dev without all other require-dev?
  case "$CIVI_VERSION" in
    5.21*) git scan -N am https://github.com/civicrm/civicrm-core/pull/16328 ; ;; ## Issue: Patches needed in 5.21
    5.22*) git scan -N am https://github.com/civicrm/civicrm-core/pull/16413 ; ;; ## Issue: Patches needed in 5.22 have one trivial difference
    master) git scan -N am https://github.com/civicrm/civicrm-core/pull/{16403,16405,16406,16407,16409} ; ;; ## Issue: This list may be volatile as PRs are getting reviewed.
    *) cvutil_fatal "This build type is temporarily limited to branch which have a corresponding patchset." ; ;;
  esac
  extract-url --cache-ttl 172800 vendor/civicrm/civicrm-core/l10n=http://download.civicrm.org/civicrm-l10n-core/archives/civicrm-l10n-daily.tar.gz ## Issue: Don't write directly into vendor tree
popd >> /dev/null
