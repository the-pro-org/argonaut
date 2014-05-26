package Argonaut::Debconf::Template;

=head1 DESCRIPTION

Abstraction of the 'template' part of a complete Debconf key.

This corresponds to the entries traditionally saved to files:

=over 2

=item /var/log/installer/cdebconf/templates.dat

=item /var/cache/debconf/templates.dat

=back

=cut

use warnings;
use strict;

use base qw/Argonaut::Debconf::Class/;

use Argonaut::Debconf::Common qw/:public/;

sub _init {
  __PACKAGE__->metadata->setup(
      attributes          => [qw/
        cn default description extendedDescription type choices
        owners
      /],

      unique_attributes   => [qw/
        cn
      /],

      base_dn             => $C->ldap_base,
  )
}

1

__END__
=head1 REFERENCES

=head1 AUTHORS

SPINLOCK - Advanced GNU/Linux networks in commercial and education sectors.

Copyright (C) 2011, Davor Ocelic <docelic@spinlocksolutions.com>
Copyright (C) 2011-2013 FusionDirectory project

Copyright 2011, SPINLOCK Solutions,
  http://www.spinlocksolutions.com/,
  http://techpubs.spinlocksolutions.com/

=head1 LICENSE

GNU GPL v3 or later. http://www.gnu.org/licenses/gpl.html

=cut