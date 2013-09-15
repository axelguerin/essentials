<?php
$_conf = array(
    'exceptUids' => array(1),
    'exceptNames' => array('admin'),
);

if(php_sapi_name() == 'cli')
    die('This script cannot be run in command line.');

define('DRUPAL_ROOT', getcwd());
require_once DRUPAL_ROOT . '/includes/bootstrap.inc';
drupal_bootstrap(DRUPAL_BOOTSTRAP_FULL);

$query = db_select('users')->fields('users', array('uid', 'name'));
$result = $query->execute();
while($record = $result->fetchAssoc()) {
    $uid = $record['uid'];
    if(!$uid)
        continue;

    $name = $record['name'];
    if(in_array((int) $uid, $_conf['exceptUids']) || in_array($name, $_conf['exceptNames'])) {
        echo "Skipped {$name} ({$uid})<br>\n";
        continue;
    }

    user_delete($uid);
    echo "Deleted {$name} ({$uid})<br>\n";
}
