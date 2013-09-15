<?php
define('DRUPAL_ROOT', getcwd());
require_once DRUPAL_ROOT . '/includes/bootstrap.inc';
drupal_bootstrap(DRUPAL_BOOTSTRAP_FULL);

$user = new stdClass;
$user->is_new = true;
user_save($user, array(
    'uid' => 1,
    'name' => 'admin',
    'pass' => 'admin',
    'status' => 1,
));