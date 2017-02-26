#!/usr/bin/perl
#
# This script performs administrative operations on auto-mount devices and their associated shares.
# It supports the following requests:
#     * getDrives         - reports information on all connected auto-mount devices
#     * getDrive          - reports information on a specific auto-mount device
#     * ejectDrive        - unmounts all supported partitions of specified auto-mount device
#     * unlockDrive       - unlocks an encrypted WD drive and makes its partitions available
#     * updateShare       - changes the share attributes of a partition of an auto-mount device
#     * updateShareAccess - creates, deletes, or updates the access of a auto-mount device's share
#     * deleteUserAccess  - deletes all the share access that references the user being deleted
#     * startupCleanup    - cleans up the auto-mount database and directories during startup
#     * shutdownCleanup   - cleans up the auto-mount database and directories during shutdown
#
# Copyright (c) [2011-2013] Western Digital Technologies, Inc. All rights reserved.

use strict;
use warnings;
use Digest;
use Encode;
use lib '/usr/local/lib';
use wdAutoMountLib;

# Global Variables - return codes and config parameters.

my $STATUS_SUCCESS                         = 0;
my $STATUS_FAILURE                         = 1;
my $STATUS_ERROR_DRIVE_NOT_FOUND           = 2;
my $STATUS_ERROR_DRIVE_NOT_LOCKED          = 3;
my $STATUS_ERROR_PASSWORD_MISSING          = 4;
my $STATUS_ERROR_UNLOCK_FAILED             = 5;
my $STATUS_ERROR_UNLOCK_ATTEMPTS_EXCEEDED  = 6;
my $STATUS_ERROR_STANDBY_TIMER_UNSUPPORTED = 7;

my %configParams = ();

# Process the request and exit with the final status of the operation.

exit(&processRequest());

# Process Request
#
# @global   ARGV            List containing the request and parameters
# @global   configParams    Global configuration parameters (such as file locations)
#
# @return   0 if successful
#           1 if unsuccessful with no reason given
#           2 if unsuccessful due to drive not found
#
# Process the command line request.  The auto-mount database is locked for the duration of the
# operation because they all involve access the database.  The function first makes sure that
# the request is valid and that the argument count is correct.  It then dispatches the proper
# function to perform the requested operation.

sub processRequest {

    # If the request is not valid, terminate the operation.  Otherwise, load the global config
    # parameters and lock the database.

    if (!&validRequest()) {
        return $STATUS_FAILURE;
    }

    &wdAutoMountLib::loadParams(\%configParams, '/etc/nas/wdAutoMount.conf', '.+');
    my $lockHandle = &wdAutoMountLib::lockDatabase(\%configParams);

    # If auto-mount is not enabled, only service the startup and shutdown cleanup requests.
    # Startup cleanup is performed before auto-mount is enabled and shutdown cleanup is performed
    # right after it is disabled.  Allow the get drive request to return successfully without data
    # because UI requests can be received before auto-mount is enabled.  Fail all other requests.

    my $operation = $ARGV[0];
    my $returnValue = $STATUS_FAILURE;
    if (!(-e $configParams{AUTO_MOUNT_PID_FILE}))  {
        if ($operation eq 'startupCleanup') {
            $returnValue = &startupCleanup();
        }
        elsif ($operation eq 'shutdownCleanup') {
            $returnValue = &shutdownCleanup();
        }
        elsif ($operation eq 'getDrives') {
            $returnValue = $STATUS_SUCCESS;
        }
    }

    # If auto-mount is enabled, Then the drive and share related operations can be performed.

    else {

        if ($operation eq 'getDrives') {
            $returnValue = &getDrives();
        }
        elsif ($operation eq 'getDrive') {
            $returnValue = &getDrive($ARGV[1]);
        }
        elsif ($operation eq 'ejectDrive') {
            $returnValue = &ejectDrive($ARGV[1]);
        }
        elsif ($operation eq 'unlockDrive') {
            $returnValue = &unlockDrive($ARGV[1], $ARGV[2], $ARGV[3]);
        }
        elsif ($operation eq 'setStandbyTimer') {
            $returnValue = &setStandbyTimer($ARGV[1], $ARGV[2]);
        }
        elsif ($operation eq 'updateShare') {
            $returnValue = &updateShare($ARGV[1], $ARGV[2], $ARGV[3], $ARGV[4], $ARGV[5], $ARGV[6]);
        }
    }

    # The share access related operations can always be performed (regardless if auto-mount is
    # enabled or disabled).

    if ($operation eq 'updateShareAccess') {
        $returnValue = &updateShareAccess($ARGV[1], $ARGV[2], $ARGV[3]);
    }
    elsif ($operation eq 'deleteUserAccess') {
        $returnValue = &deleteUserAccess($ARGV[1]);
    }

    # Unlock the database and return the final status of the operation.

    &wdAutoMountLib::unlockDatabase($lockHandle);
    return $returnValue;
}

# Get Drive
#
# @param    handle          The handle of the drive whose information is requested
# @global   configParams    Global configuration parameters (such as file locations)
#
# @return   0 if successful
#           2 if unsuccessful due to drive not found
#
# Output (to stdout) information on the drive specified.  Most of the information is taken from the
# auto-mount database, but some is generated.  The name is built from the vendor and model and the
# total and used capacity of the drive is derived by adding the total and used capacity of all the
# usable partitions on the drive.  The information is output in key=value pairs, which one attribute
# per line.  An extra newline is output after the last attribute to identify the end of the data.

sub getDrive {

    my($handle) = @_;

    # Query the database for information on the specified drive.  If the drive could not be found
    # (which can happen if the drive is no longer connected), then return.

    my $deviceRecord = &wdAutoMountLib::getDeviceDatabaseRecord(\%configParams, "WHERE handle='$handle' AND connected='1' AND lock_state<>'pending'");

    if (!defined($deviceRecord)) {
        return $STATUS_ERROR_DRIVE_NOT_FOUND;
    }

    # Build a drive name from the vendor and model information.

    my $name = $deviceRecord->{vendor} . ' ' . $deviceRecord->{model};
    $name = &wdAutoMountLib::trim($name);
    if ($name eq '') {
        $name = 'USB device';
    }

    my $usage = 0;
    my $capacity = 0;
    my $standbyTimer = 'unsupported';
    my $connected = (($deviceRecord->{connected} eq '1') && ($deviceRecord->{lock_state} ne 'pending')) ? 'true' : 'false';

    my @capacityData = ();
    if ($connected eq 'true') {
        @capacityData = `df 2> /dev/null`;
    }

    # Determine the used and total capacity for each volume and for the drive.

    my @partitionList = &wdAutoMountLib::getPartitionList(\%configParams, "WHERE device_handle='$handle' AND connected='1' AND type<>'swap'");
    foreach my $partitionRecord (@partitionList) {
        $partitionRecord->{capacity} = 0;
        $partitionRecord->{usage} = 0;
        foreach my $data (@capacityData) {
            chomp($data);
            if ($data =~ m|$configParams{AUTO_MOUNT_MOUNT_DIR}/$partitionRecord->{share_name}$|) {
                my @values = split(' ', $data);
                $partitionRecord->{capacity} = &wdAutoMountLib::KiB2MB($values[1]);
                $partitionRecord->{usage} = &wdAutoMountLib::KiB2MB($values[2]);
                $capacity += $values[1];
                $usage += $values[2];
                last;
            }
        }
    }
    $capacity = &wdAutoMountLib::KiB2MB($capacity);
    $usage = &wdAutoMountLib::KiB2MB($usage);

    # Output the drive's information is key=value pairs.

    print("usb_drive\n");
    print("name=$name\n");
    print("handle=$handle\n");
    print("serial_number=$deviceRecord->{serial_number}\n");
    print("vendor=$deviceRecord->{vendor}\n");
    print("model=$deviceRecord->{model}\n");
    print("revision=$deviceRecord->{revision}\n");
    print("ptp=$deviceRecord->{ptp}\n");
    print("smart_status=$deviceRecord->{smart_status}\n");
    print("standby_timer=$deviceRecord->{standby_timer}\n");
    print("lock_state=$deviceRecord->{lock_state}\n");
    if (($deviceRecord->{lock_state} eq 'locked') || ($deviceRecord->{lock_state} eq 'unlocked')) {
        print("password_hint=$deviceRecord->{password_hint}\n");
    }
    print("usage=$usage\n");
    print("capacity=$capacity\n");
    print("vendor_id=$deviceRecord->{vendor_id}\n");
    print("product_id=$deviceRecord->{product_id}\n");
    print("usb_port=$deviceRecord->{usb_port}\n");
    print("usb_version=$deviceRecord->{usb_version}\n");
    print("usb_speed=$deviceRecord->{usb_speed}\n");
    print("is_connected=$connected\n");

    # Output information about all the volumes associated with the drive

    print("volumes\n");
    foreach my $partitionRecord (@partitionList) {
        print("volume\n");
        print("volume_id=$partitionRecord->{id}\n");
        print("base_path=$configParams{AUTO_MOUNT_SHARES_DIR}/$partitionRecord->{share_name}\n");
        print("label=$partitionRecord->{label}\n");
        print("mounted_date=$partitionRecord->{mount_time}\n");
        print("usage=$partitionRecord->{usage}\n");
        print("capacity=$partitionRecord->{capacity}\n");
        print("read_only=$partitionRecord->{read_only}\n");
        print("shares\n");
        print("share=$partitionRecord->{share_name}\n");
        print("\n\n"); # for shares and volume
    }
    print("\n\n"); # for volumes and usb_drive

    return $STATUS_SUCCESS;
}

# Get Drives
#
# @global   configParams    Global configuration parameters (such as file locations)
#
# @return   0 to indicate success (operation can't fail)
#
# Output (to stdout) information on all the drives in the database.  The information is output in
# key=value pairs, with one attribute per line.

sub getDrives {

    my @handleList = &wdAutoMountLib::getDriveHandles(\%configParams, "WHERE connected='1' AND lock_state<>'pending'");

    print("usb_drives\n");
    foreach my $handle (@handleList) {
        &getDrive($handle);
    }
    print("\n"); # for usb_drives
    return $STATUS_SUCCESS;
}

# Eject Drive
#
# @param    handle          The handle of the drive to be ejected
# @global   configParams    Global configuration parameters (such as file locations)
#
# @return   0 if successful
#           2 if unsuccessful due to drive not found
#
# Unmounts and deletes all shares associated with the specified drives partitions.  It then marks
# the drive and its partitions as "not connected" so that they will no longer be reported by storage
# management.

sub ejectDrive {

    my($handle) = @_;

    # Make sure the specified drive exists and is still connected.

    my $deviceRecord = &wdAutoMountLib::getDeviceDatabaseRecord(\%configParams, "WHERE handle='$handle' AND connected='1'");

    if (!defined($deviceRecord)) {
        return $STATUS_ERROR_DRIVE_NOT_FOUND;
    }

    my @partitionList = &wdAutoMountLib::getPartitionList(\%configParams, "WHERE device_handle='$handle' AND connected='1'");

    # First, send volume remove notifications for all the partitions to be ejected.

    foreach my $partitionRecord (@partitionList) {
        &wdAutoMountLib::volumeChangeNotification(\%configParams, $partitionRecord, 'remove');
    }

    # For every partition associated with the drive: unmount it, remove its mount directory, mark
    # the partition as removed in the database, and log a "partition ejected event".

    foreach my $partitionRecord (@partitionList) {
        &wdAutoMountLib::unmountAndDeleteShare(\%configParams, $partitionRecord, 'eject');
        &wdAutoMountLib::markPartitionAsRemoved(\%configParams, $partitionRecord);
        &wdAutoMountLib::logPartitionEvent('info', 'Partition ejected', $partitionRecord);
    }

    # Spin down the drive if it has a SCSI generic device.

    if (($deviceRecord->{scsi_devname} ne '') && ($deviceRecord->{scsi_devname} ne 'pending')) {
        &wdAutoMountLib::performSystemCommand("sg_start --stop $deviceRecord->{scsi_devname}");
    }

    # Mark the drive as removed in the database, log a device ejected event, and perform change
    # notification (which increments a USB update count).

    &wdAutoMountLib::markDeviceAsRemoved(\%configParams, "WHERE handle='$handle'");
    &wdAutoMountLib::logDeviceEvent('info', 'Device ejected', $deviceRecord);
    &wdAutoMountLib::databaseChangeNotification();

    return $STATUS_SUCCESS;
}

# Unlock Drive
#
# @param    handle          The handle of the drive to be ejected
# @param    password        The password to unlock the drive (in UTF-8)
# @param    save            Indicates if the password is to be saved (true/false)
# @global   configParams    Global configuration parameters (such as file locations)
#
# @return   0 if successful
#           2 if unsuccessful due to drive not found
#           3 if unsuccessful due to the drive not being locked
#           4 if unsuccessful due to the password missing
#           5 if unsuccessful due to unlock failing
#           6 if unsuccessful due to unlock failing and maximum attempts reached
#
# Attempts to unlock the specified drive with the password given.  If the password is not given
# and save is set to false, the stored password is deleted.

sub unlockDrive {
    my($handle, $password, $save) = @_;

    # Make sure the specified drive exists and is still connected.

    my $deviceRecord = &wdAutoMountLib::getDeviceDatabaseRecord(\%configParams, "WHERE handle='$handle' AND connected='1'");
    if (!defined($deviceRecord)) {
        return $STATUS_ERROR_DRIVE_NOT_FOUND;
    }

    # If the request is to delete the password (where no password specified and save set to false),
    # clear the password hash and return success.  Otherwise, if the password isn't set, fail the
    # request.

    $save = lc($save);
    if (!defined($password) || ($password eq '')) {
        if ($save eq 'false') {
            &wdAutoMountLib::performDatabaseCommand(\%configParams, "UPDATE Devices SET password_hash='' WHERE handle='$handle'");
            return $STATUS_SUCCESS;
        }
        return $STATUS_ERROR_PASSWORD_MISSING;
    }

    # If the drive is not locked, fail the request.

    if ($deviceRecord->{lock_state} ne 'locked') {
        return $STATUS_ERROR_DRIVE_NOT_LOCKED;
    }

    # Get the drive's security information.  Combine the password salt with the password and
    # convert both from UTF-8 to UTF-16LE in order to create the password hash.

    my $securityRecord = &wdAutoMountLib::getSecurityInfo($deviceRecord);
    my $result = encode("UTF-16LE", $securityRecord->{salt} . $password);
    my @byteArray = unpack ('C*', $result);

    my $sha256 = Digest->new("SHA-256");
    foreach my $byte (@byteArray) {
        $sha256->add(pack("C", $byte));
    }

    # Create the password hash.

    my $hash = $sha256->digest();

    for (my $iterations = 1; $iterations < $securityRecord->{iterations}; $iterations++) {
        $sha256->add($hash);
        $hash = $sha256->digest();
    }

    # Convent it into a hex string (the format needed to save the password and used by the unlock
    # function).  Then, attempt to unlock the drive.  The new lock state of the drive will be
    # returned.

    my $password_hash = '';
    @byteArray = unpack ('C*', $hash);
    foreach my $byte (@byteArray) {
        my $val = sprintf("%02x", $byte);
        $password_hash .= $val;
    }

    $deviceRecord->{password_hash} = $password_hash;

    my $status = $STATUS_ERROR_UNLOCK_FAILED;
    my $lock_state = &wdAutoMountLib::unlockDrive($deviceRecord);

    # If the unlock succeeded, the new lock state will be unlocked.  If successful and the
    # password is to be saved, save it to the database.

    if ($lock_state eq 'unlocked') {
        my $passwordHash = '';
        if ($save eq 'true') {
            $passwordHash = ", password_hash='$deviceRecord->{password_hash}'";
        }
        &wdAutoMountLib::performDatabaseCommand(\%configParams, "UPDATE Devices SET lock_state='$lock_state' $passwordHash WHERE handle='$handle'");
        $status = $STATUS_SUCCESS;
    }
    elsif ($lock_state eq 'unlocksExceeded') {
        $status = $STATUS_ERROR_UNLOCK_ATTEMPTS_EXCEEDED;
    }

    return $status;
}

# Set standby timer
#
# @param    handle          The handle of the drive to set timer
# @param    standby_timer   Number of deciseconds before entering standby
#
# @return   STATUS_SUCCESS
#           STATUS_ERROR_DRIVE_NOT_FOUND
#           STATUS_ERROR_STANDBY_TIMER_UNSUPPORTED
#           STATUS_FAILURE;
#
# Attempts to set standby timer of specified drive.

sub setStandbyTimer {
    my($handle, $standby_timer) = @_;

    my $status = $STATUS_SUCCESS;

    # Make sure the specified drive exists and is still connected.

    my $deviceRecord = &wdAutoMountLib::getDeviceDatabaseRecord(\%configParams, "WHERE handle='$handle' AND connected='1'");
    if (!defined($deviceRecord)) {
        return $STATUS_ERROR_DRIVE_NOT_FOUND;
    }

    my $setStandbyTimerResult = &wdAutoMountLib::setStandbyTimer($deviceRecord, $standby_timer);

    if ( $setStandbyTimerResult eq 'unsupported' ) {
        $status = $STATUS_ERROR_STANDBY_TIMER_UNSUPPORTED;
    }
    elsif ( $setStandbyTimerResult eq 'error' ) {
        $status = $STATUS_FAILURE;
    }
    else {
        print("status=success\n");
        print("standby_timer=$setStandbyTimerResult\n\n");
        &wdAutoMountLib::performDatabaseCommand(\%configParams, "UPDATE Devices SET standby_timer='$setStandbyTimerResult' WHERE handle='$deviceRecord->{handle}'");
        &wdAutoMountLib::databaseChangeNotification();
    }

    return $status;
}

# Update Share
#
# @param    share_name      Name of share to be updated
# @param    new_share_name  New name of share (if not an empty string)
# @param    description     New description of share (if not an empty string)
# @param    public_access   New public access share setting (if not an empty string)
# @param    media_serving   New type of media served by the share (if not an empty string)
# @param    remote_access   New remote access share setting (if not an empty string)
# @global   configParams    Global configuration parameters (such as file locations)
#
# @return   0 if successful
#           1 if unsuccessful
#
# Updates the share with the attributes specified.  If the name is changed, the partition label
# will be changed to match.  This will caused the old share to be deleted and a new one created
# with the new name.  It will also cause the partition to be unmounted and remounted with the
# new name.

sub updateShare {
    my($share_name, $new_share_name, $description, $public_access, $media_serving, $remote_access) = @_;

    # Accept 1 and 0 for true and false (just convert them)

    $public_access = ($public_access eq '1') ? 'true' : ($public_access eq '0') ? 'false' : $public_access;
    $remote_access = ($remote_access eq '1') ? 'true' : ($remote_access eq '0') ? 'false' : $remote_access;

    # Make sure that the partition associated with the specified share exists and is still
    # connected.  If not, fail the request.

    my $partitionRecord = &wdAutoMountLib::getPartitionDatabaseRecord(\%configParams, "WHERE share_name='$share_name' AND connected='1'");
    if (!defined($partitionRecord)) {
        &wdAutoMountLib::logEvent('warn', "updateShare - share no longer connected: $share_name");
        return $STATUS_FAILURE;
    }

    # If any of the share settings changed, use their new value.

    $public_access = lc($public_access);
    my $privateToPublic = 0;
    $privateToPublic = 1 if (($partitionRecord->{public_access} eq 'false') && ($public_access eq 'true'));
    $partitionRecord->{description} = $description if ($description ne '');
    $partitionRecord->{public_access} = $public_access if ($public_access ne '');
    $partitionRecord->{media_serving} = $media_serving if ($media_serving ne '');

    # If the share name changed, we will also change the partition's label, the name of the mount
    # point, and the name of the symlink in the shares directory.  The rename utility for NTFS and
    # HFS+ require the partition to be mounted when the name is changed.  The utilities for the
    # other filesystem types require the partition not to be mounted.  Therefore, where the name is
    # changed is the sequence depends on the partition's filesystem type.

    my $status = $STATUS_SUCCESS;
    my $shareNameChanged = 0;
    if (($new_share_name ne '') && ($new_share_name ne $partitionRecord->{share_name})) {
        if (&wdAutoMountLib::validatePartitionLabel($partitionRecord, $new_share_name) != $STATUS_SUCCESS) {
            &wdAutoMountLib::logEvent('warn', "updateShare - invalid partition label: $new_share_name (filesystem $partitionRecord->{type})");
            return $STATUS_FAILURE;
        }

        # For NTFS and HFS+, rename the partition while it's mounted.

        if ($partitionRecord->{type} =~ /ntfs|hfsplus/) {
            if (&wdAutoMountLib::renamePartitionLabel($partitionRecord, $new_share_name) != $STATUS_SUCCESS) {
                &wdAutoMountLib::logEvent('warn', "updateShare - rename (ntfs/hfsplus) partition failed: $share_name");
                return $STATUS_FAILURE;
            }
        }

        # Delete the share, unmount the partition, and delete the mount point and share symlink.

        &wdAutoMountLib::unmountAndDeleteShare(\%configParams, $partitionRecord, 'rename');

        # Rename the partition for the filesystem types that require the partition to be unmounted.

        if (!($partitionRecord->{type} =~ /ntfs|hfsplus/)) {
            $status = &wdAutoMountLib::renamePartitionLabel($partitionRecord, $new_share_name);
        }

        # If the rename was successful, apply the name change (by updating the partition record).
        # If the operation failed, the partition will be remounted and share recreated using the
        # original name.

        if ($status != $STATUS_SUCCESS) {
            &wdAutoMountLib::logEvent('warn', "updateShare - rename partition failed: $share_name");
        }
        else {
            $partitionRecord->{share_name} = $new_share_name;
            $partitionRecord->{label} = $new_share_name;
            $shareNameChanged = 1;
        }

        # Recreate the share and remount the partition (using the new name if the rename was
        # successful or the old name if it was not).

        my $mountStatus = &wdAutoMountLib::mountAndCreateShare(\%configParams, $partitionRecord, 'partial');
        if ($mountStatus != $STATUS_SUCCESS) {
            &wdAutoMountLib::logEvent('warn', "updateShare - remount and recreate share failed: $share_name");
            $status = $STATUS_FAILURE
        }
    }

    # If the share name has changed, rename the share that previously used the name (if there is
    # one) and set the database update to rename the share name for the share's access records.  If
    # the share has changed from private to public, set the database update to delete all of its
    # private access records. Then, perform the database update.

    my $shareAccessUpdate = undef;
    if ($shareNameChanged) {
        &wdAutoMountLib::renameConflictingShare(\%configParams, $new_share_name);
        $shareAccessUpdate = "UPDATE ShareAccess SET share_name='$partitionRecord->{share_name}' WHERE share_name='$share_name'";
    }

    if ($privateToPublic) {
        $shareAccessUpdate = "DELETE FROM ShareAccess WHERE share_name='$share_name'";
    }

    &wdAutoMountLib::performDatabaseCommands(\%configParams, "UPDATE Partitions SET share_name='$partitionRecord->{share_name}', label='$partitionRecord->{label}', description='$partitionRecord->{description}', public_access='$partitionRecord->{public_access}', media_serving='$partitionRecord->{media_serving}' WHERE share_name='$share_name'", $shareAccessUpdate);
    &wdAutoMountLib::logPartitionEvent('info', 'Partition updated', $partitionRecord);

    return $status;
}

# Update Share Access
#
# @param    share_name      Name of share whose access is being updated
# @param    local_username  Name of user with access to share
# @param    access_level    Access level user has to share (R0, RW, or none)
# @global   configParams    Global configuration parameters (such as file locations)
#
# @return   0 if successful
#           1 if unsuccessful
#
# Update the access level to the share for the user specified.  This request is used to add,
# remove, or update access.  This function persists share access setting for shares associated
# with USB drive partitions so that they be restored the next time the drive is reconnected to
# the NAS.

sub updateShareAccess {
    my($share_name, $local_username, $access_level) = @_;

    # Make sure that the partition associated with the specified share exists and is still
    # connected.  If not, fail the request.

    my $partitionRecord = &wdAutoMountLib::getPartitionDatabaseRecord(\%configParams, "WHERE share_name='$share_name'");
    if (!defined($partitionRecord)) {
        return $STATUS_FAILURE;
    }

    # Determine if the access is being added, removed, updated, or not changed.  If the access
    # level is 'NA', then access is being removed.  If there is no record of access to this share
    # from this user, then access is being added.  Otherwise, access is being updated.  However,
    # make sure the access level has changed before updating the database.  There are times when
    # the UI will send an update when nothing has changed because a user updated a different
    # parameter on a page that included access.  The UI will send updates for everything on the
    # page.

    my $command = undef;
    if ($access_level eq 'NA') {
        $command = "DELETE FROM ShareAccess WHERE share_name='$share_name' AND local_username='$local_username'";
    }
    else {
        my $shareAccessRecord = &wdAutoMountLib::getShareAccessDatabaseRecord(\%configParams, "WHERE share_name='$share_name' AND local_username='$local_username'");
        if (!defined($shareAccessRecord)) {
            $command = "INSERT INTO ShareAccess VALUES ('$share_name', '$local_username', '$access_level')";
        }
        elsif ($shareAccessRecord->{access_level} ne $access_level) {
            $command = "UPDATE ShareAccess SET access_level='$access_level' WHERE share_name='$share_name' AND local_username='$local_username'";
        }
    }

    if (defined($command)) {
        &wdAutoMountLib::performDatabaseCommand(\%configParams, $command);
    }

    return $STATUS_SUCCESS;
}

# Delete User Share
#
# @param    $local_username     Name of user being deleted
# @global   configParams        Global configuration parameters (such as file locations)
#
# @return   0 because request is always successful
#
# When a user is deleted, the user will no longer have access to any shares.  This function removes
# any record of share access for the user being deleted from the auto-mount database.

sub deleteUserAccess {
    my($local_username) = @_;
    &wdAutoMountLib::performDatabaseCommand(\%configParams, "DELETE FROM ShareAccess WHERE local_username='$local_username'");
    return $STATUS_SUCCESS;
}

# Startup Cleanup
#
# @global   configParams    Global configuration parameters (such as file locations)
#
# @return   0 to indicate success (operation can't fail)
#
# Perform the necessary cleanup at system shutdown or the enabling of the USB auto-mount service.
# This is necessary when the system is powered off while USB partitions are still mounted.  The
# cleanup involves deleting all the sym links in the share directory (that reference a USB mount
# point), removing all the directories in the USB mount directory,  deleting all the dynamic volume
# shares in both the trustees and orion database, and marking all drives and partitions are "not
# connected" in the USB database.

sub startupCleanup {

    # Delete the sym links in the share directory that reference mount points.

    my @directoryList = `ls $configParams{AUTO_MOUNT_SHARES_DIR}`;
    foreach my $directoryName (@directoryList) {
        chomp($directoryName);
        my $directoryInfo = `ls -l $configParams{AUTO_MOUNT_SHARES_DIR}/$directoryName`;
        if ($directoryInfo =~ m|^l.*\s*->\s*$configParams{AUTO_MOUNT_MOUNT_DIR}|) {
            &wdAutoMountLib::performSystemCommand("unlink $configParams{AUTO_MOUNT_SHARES_DIR}/$directoryName");
        }
    }

    # Delete all the USB Mount Points (they are the only directories in the mount directory).  If
    # the mount directory doesn't exist, create it and set the correct permission.  Incase the
    # auto-mount directory is not specified (in a development environment), don't delete anything.
    # Also, don't delete a mount point if it is still mounting (which should never happen, but we
    # don't want to delete the user's data if it ever did).

    if ($configParams{AUTO_MOUNT_MOUNT_DIR} ne '') {
        @directoryList = `ls $configParams{AUTO_MOUNT_MOUNT_DIR} 2>&1`;
        foreach my $directoryName (@directoryList) {
            chomp($directoryName);
            if ($directoryName =~ /No such file or directory/) {
                &wdAutoMountLib::performSystemCommand("mkdir $configParams{AUTO_MOUNT_MOUNT_DIR}");
                &wdAutoMountLib::performSystemCommand("chmod 777 $configParams{AUTO_MOUNT_MOUNT_DIR}");
            }
            elsif (!&wdAutoMountLib::directoryMounted("$configParams{AUTO_MOUNT_MOUNT_DIR}/$directoryName")) {
                &wdAutoMountLib::performSystemCommand("rm -Rf $configParams{AUTO_MOUNT_MOUNT_DIR}/$directoryName");
            }
        }
    }

    # Delete all the shares in the trustees database that are not valid (they have no corresponding
    # share directory).  These should all be dynamic volume shares, but can also be caused by an
    # an error creating or deleting shares (since the operations involve multiple steps which are
    # not atomic and power could be lost during the operation).

    @directoryList = `ls $configParams{AUTO_MOUNT_SHARES_DIR}`;
    my @ShareList = `/usr/local/sbin/getShares.sh all`;
    foreach my $shareName (@ShareList) {
        chomp($shareName);
        if (($shareName ne 'Public') && ($shareName ne '')) {
            my $directoryFound = 0;
            foreach my $directoryName (@directoryList) {
                chomp($directoryName);
                if ($directoryName eq $shareName) {
                    $directoryFound = 1;
                }
            }
            if (!$directoryFound) {
                &wdAutoMountLib::performSystemCommand("/usr/local/sbin/deleteShare.sh \"$shareName\" &> /dev/null");
            }
        }
    }

    # Delete all the USB related shares from the orion database.  There are only USB shares at
    # startup when the system has been powered off while USB drives were connected (without going
    # through an orderly shutdown).

    system("/usr/bin/php /usr/local/sbin/wdAutoMountBridge.php \"deleteDynamicShares\" &> /dev/null");

    # Mark all USB drives and partitions as "not connected" in the USB database.

    &wdAutoMountLib::performDatabaseCommand(\%configParams, "UPDATE Devices SET connected='0', devname='', devpath='', scsi_devname=''");
    &wdAutoMountLib::performDatabaseCommand(\%configParams, "UPDATE Partitions SET connected='0', devname=''");

    # Sync the Partitions from the autoMount database with the Volumes in the Orion database.

    my @volumeIdList = `/usr/bin/php /usr/local/sbin/wdAutoMountBridge.php \"getVolumeIds\"`;
    my @partitionList = &wdAutoMountLib::getPartitionList(\%configParams, '');

    # Remove any external volumes in the Orion database that are not in the autoMount database
    # (external volumes have IDs greater than the max internal volume ID).

    foreach my $volumeId (@volumeIdList) {
        chomp($volumeId);
        if ($volumeId > $configParams{AUTO_MOUNT_MAX_INTERNAL_VOLUME_ID}) {
            my $found = 0;
            foreach my $partitionRecord (@partitionList) {
                if ($partitionRecord->{id} eq $volumeId) {
                    $found = 1;
                    last;
                }
            }
            if (!$found) {
                system("/usr/bin/php /usr/local/sbin/wdAutoMountBridge.php \"deleteVolume\" \"$volumeId\"");
            }
        }
    }

    # Remove any partitions in the autoMount database that are not in the Orion database.

    foreach my $partitionRecord (@partitionList) {
        my $found = 0;
        foreach my $volumeId (@volumeIdList) {
            chomp($volumeId);
            if ($partitionRecord->{id} eq $volumeId) {
                $found = 1;
                last;
            }
        }
        if (!$found) {
            &wdAutoMountLib::performDatabaseCommand(\%configParams, "DELETE FROM Partitions WHERE id='$partitionRecord->{id}'");
        }
    }

    return $STATUS_SUCCESS;
}

# Shutdown Cleanup
#
# @global   configParams    Global configuration parameters (such as file locations)
#
# @return   0 to indicate success (operation can't fail)
#
# Perform the necessary cleanup due to a system shutdown or the disabling of the USB auto-mount
# service.  A software "eject" is performed on every USB device connected.  This will cause the
# device's partitions to be unmounted and associated shares to be deleted.

sub shutdownCleanup {

    my @handleList = &wdAutoMountLib::getDriveHandles(\%configParams, "WHERE connected='1'");

    foreach my $handle (@handleList) {
        &ejectDrive($handle);
    }

    return $STATUS_SUCCESS;
}

# Valid Request
#
# @global   ARGV            List containing the request and parameters
#
# @return   0 if request is valid
#           1 if request is invalid (unsupported operation or incorrect argument count)
#
# Determine if the request is valid by checking the operation and number of arguments specified.
# If the specified operation is invalid or the number of arguments are incorrect, output an
# error and the correct usage of the script.

sub validRequest {

    my $argCount = $#ARGV + 1;
    my $requiredArgCount = 1;
    my $valid = 1;

    # If at least one argument was specified, check if the requested operation is valid.
    # If not, output an error message.  Otherwise, determine the number of arguments
    # needed for the operation.

    if ($argCount != 0) {
        my $operation = $ARGV[0];

        if (!($operation =~ /^(getDrive(s|)|(eject|unlock)Drive|(startup|shutdown)Cleanup|updateShare(Access|)|deleteUserAccess|setStandbyTimer)$/)) {
            print "Invalid command\n";
            $valid = 0;
        }
        elsif (($operation eq 'getDrive') || ($operation eq 'ejectDrive')|| ($operation eq 'deleteUserAccess')) {
            $requiredArgCount = 2;
        }
        elsif ($operation eq 'setStandbyTimer') {
            $requiredArgCount = 3;
        }
        elsif (($operation eq 'unlockDrive') || ($operation eq 'updateShareAccess')) {
            $requiredArgCount = 4;
        }
        elsif ($operation eq 'updateShare') {
            $requiredArgCount = 7;
        }
    }

    # If the operation wasn't already found to be invalid, check if the number of arguments is
    # correct.  If not, output an error message.

    if ($valid && ($requiredArgCount != $argCount)) {
        print "Incorrect number of arguments\n";
        $valid = 0;
    }

    # If the request is invalid, output the proper usage of the script.

    if (!$valid) {
        print "usage: usbAutoMountAdm.pm <getDrives/startupCleanup/shutdownCleanup>\n";
        print "                          <getDrive/ejectDrive> <handle>\n";
        print "                          <setStandbyTimer> <handle> <standbyTimer>\n";
        print "                          <unlockDrive> <handle> <password> <save>\n";
        print "                          <deleteUserAccess> <local_username>\n";
        print "                          <updateShareAccess> <shareName> <local_username> <access_level>\n";
        print "                          <updateShare> <shareName> <newShareName> <description> <publicAccess> <mediaServing> <remoteAccess>\n";
    }
    return $valid;
}
