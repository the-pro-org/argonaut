#######################################################################
#
# Argonaut::ClientDaemon -- Action to be done on clients
#
# Copyright (C) 2011-2016 FusionDirectory project
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

package Argonaut::ClientDaemon;

use strict;
use warnings;

use 5.008;

use Argonaut::Libraries::Common qw(:config);

my $base;
BEGIN {
  $base = (USE_LEGACY_JSON_RPC ? "JSON::RPC::Legacy::Procedure" : "JSON::RPC::Procedure");
}
use base $base;

=item echo
return the parameters passed to it
=cut

sub echo : Public {
  my ($s, $args) = @_;
  $main::log->notice("echo method called with args $args");
  return $args;
}

package
    Argonaut::ClientDaemon::system;


=item describe
should be the answer of the system.describe standard JSONRPC call. It seems broken.
=cut
sub describe {
  return {
    sdversion => "1.0",
    name      => 'Argonaut::ClientDaemon',
  };
}

1;

__END__
