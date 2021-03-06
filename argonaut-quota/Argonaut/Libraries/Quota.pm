#######################################################################
#
# Argonaut::Libraries::Quota packages - get quota from ldap
#
# Copyright (c) 2012-2016 FusionDirectory project
#
# Author: Côme BERNIGAUD
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
#
#######################################################################

package Argonaut::Libraries::Quota;

use strict;
use warnings;

use 5.008;

use Quota;

use Argonaut::Libraries::Common qw(:ldap);

BEGIN
{
  use Exporter ();
  use vars qw(@EXPORT_OK @ISA $VERSION);
  $VERSION = '2012-04-24';
  @ISA = qw(Exporter);

  @EXPORT_OK = qw(write_warnquota_file write_quotatab_file get_quota_settings apply_quotas);
}

=head1
Warnquota

Write warnquota and quotatab files
=cut
sub write_warnquota_file {
  my ($settings,$warnquota_file) = @_;
  my $warnquota;

  open ($warnquota, q{>}, $warnquota_file) or die "Could not open file $warnquota_file";

  # edition of warnquota.conf
  print $warnquota "MAIL_CMD               = ".$settings->{'mail_cmd'}."\n";
  print $warnquota "CC_TO                  = ".$settings->{'cc_to'}."\n";
  print $warnquota "FROM                   = ".$settings->{'from'}."\n";
  print $warnquota "SUBJECT                = ".$settings->{'subject'}."\n";
  # Support email for assistance (included in generated mail)
  print $warnquota "SUPPORT                = ".$settings->{'support'}."\n";
  # Support phone for assistance (included in generated mail)
  # The message to send
  print $warnquota "MESSAGE                = ".$settings->{'message'}."\n";
  # The signature of the mail
  print $warnquota "SIGNATURE              = ".$settings->{'signature'}."\n";
  # character set the email is to be send in
  print $warnquota "CHARSET                = ".$settings->{'charset'}."\n";
  # add LDAP support
  print $warnquota "LDAP_MAIL              = true"."\n";
  print $warnquota "LDAP_SEARCH_ATTRIBUTE  = ".$settings->{'ldap_searchattribute'}."\n";
  print $warnquota "LDAP_MAIL_ATTRIBUTE    = mail\n";
  print $warnquota "LDAP_BASEDN            = ".$settings->{'ldap_basedn'}."\n";
  print $warnquota "LDAP_URI               = ".$settings->{'ldap_uri'}."\n";
  print $warnquota "LDAP_USER_DN           = ".$settings->{'ldap_userdn'}."\n";
  print $warnquota "LDAP_PASSWORD          = ".$settings->{'ldap_userpwd'}."\n";
  # end of warnquota.conf

  close ($warnquota);
}

sub write_quotatab_file {
  my ($settings,$quotatab_file) = @_;
  my $quotatab;

  open ($quotatab, q{>}, $quotatab_file) or die "Could not open file $quotatab_file";

  # Begin of quota tab edition
  my @quotaDeviceParameters = @{$settings->{'device_parameters'}};
  if ($#quotaDeviceParameters >= 0) {
    foreach (@quotaDeviceParameters) {
      my @quotaDeviceParameter = split /:/, $_, -1;
      print $quotatab $quotaDeviceParameter[0].":".$quotaDeviceParameter[2]."\n";
    }
  }

  close ($quotatab);
  # end of quota tab edition
}

sub get_quota_settings {
  my ($config,$filter,$inheritance) = @_;
  my $settings = argonaut_get_generic_settings(
    'quotaService',
    {
      'hostname'              => 'cn',
      'mail_cmd'              => 'quotaMailCommand',
      'cc_to'                 => 'quotaCarbonCopyMail',
      'from'                  => 'quotaMsgFromSupport',
      'subject'               => 'quotaMsgSubjectSupport',
      'support'               => 'quotaMsgContactSupport',
      'message'               => 'quotaMsgContentSupport',
      'signature'             => 'quotaMsgSignatureSupport',
      'charset'               => 'quotaMsgCharsetSupport',
      'ldap_searchattribute'  => 'quotaLdapSearchIdAttribute',
      'ldap_userdn'           => 'quotaLdapServerUserDn',
      'ldap_userpwd'          => 'quotaLdapServerUserPassword',
      'ldap_dn'               => 'quotaLdapServer',
      'device_parameters'     => ['quotaDeviceParameters', asref => 1],
    },
    $config,$filter,$inheritance
  );

  my ($ldap,$ldap_base) = argonaut_ldap_handle($config);

  my $mesg = $ldap->search( # perform a search
    base    => $settings->{'ldap_dn'},
    scope   => 'base',
    filter  => "(objectClass=goLdapServer)",
    attrs   => ['goLdapBase','goLdapURI']
  );
  if ($mesg->count <= 0) {
    die "Could not found LDAP server ".$settings->{'ldap_dn'}."\n";
  }
  $settings->{'ldap_basedn'}  = ($mesg->entries)[0]->get_value('goLdapBase');
  $settings->{'ldap_uri'}     = ($mesg->entries)[0]->get_value('goLdapURI');

  return $settings;
}

sub apply_quotas {
  my ($config,$hostname) = @_;

  my ($ldap,$ldap_base) = argonaut_ldap_handle($config);

  my $mesg = $ldap->search( # perform a search
            base   => $ldap_base,
            filter => "(objectClass=systemQuotas)",
            attrs => ['quota','uid','uidNumber','gidNumber']
            );

  foreach my $entry ($mesg->entries) {
    my $uid = $entry->get_value("uidNumber");
    my $gid = $entry->get_value("gidNumber");
    my $isUser = (defined $entry->get_value("uid"));
    my @quotas = $entry->get_value("quota");
    foreach my $quota (@quotas) {
      my ($dev,$blocksoft,$blockhard,$inodesoft,$inodehard,$server,$adminlist) = split (':',$quota);
      if ($server eq $hostname) {
        if ($isUser) {
          print "applying quota ($blocksoft, $blockhard, $inodesoft, $inodehard) on $dev for uid $uid\n";
          Quota::setqlim($dev, $uid, $blocksoft,$blockhard, $inodesoft,$inodehard);
        } else {
          print "applying quota ($blocksoft, $blockhard, $inodesoft, $inodehard) on $dev for gid $gid\n";
          Quota::setqlim($dev, $gid, $blocksoft, $blockhard, $inodesoft, $inodehard, 0, 1);
        }
      }
    }
  }
  Quota::sync();
}

END {}

1;

__END__
