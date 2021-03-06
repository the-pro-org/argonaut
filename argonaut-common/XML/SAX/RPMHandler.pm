#######################################################################
#
# XML::SAX::RPMHandler -- get and parse RPM Packages.
#
# Copyright (C) 2015-2016 FusionDirectory project
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

package XML::SAX::RPMHandler;

use strict;
use warnings;

use base qw(XML::SAX::Base);

  sub new {
    my $type = shift;
    my $self = {
      'packages'  => shift,
      'package'   => undef,
      'key'       => undef,
      'fields'    => shift,
      'regexps'   => shift,
      'from'      => shift,
      'to'        => shift,
      'indice'    => shift || 0,
    };
    return bless $self, $type;
  }

  sub start_document {
    my ($self, $doc) = @_;
    $self->{package}  = undef;
    $self->{key}      = undef;
  }

  sub start_element {
    my ($self, $el) = @_;
    if ($el->{LocalName} eq 'package') {
      $self->{package}  = {};
      $self->{key}      = undef;
    } elsif ((defined $self->{package}) && (defined $self->{fields}->{$el->{LocalName}})) {
      $self->{key}    = $el->{LocalName};
      $self->{attrs}  = $el->{Attributes};
      $self->{data}   = '';
    }
  }

  sub characters {
    my ($self, $data) = @_;
    if ((defined $self->{package}) && (defined $self->{key})) {
      if ($self->{key} eq 'name') {
        if ((ref($self->{packages}) eq 'HASH') && (defined $self->{packages}->{$data->{Data}})) {
          $self->{package} = undef;
          return;
        }
        if (defined $self->{regexps}) {
          my $match = 0;
          foreach my $regexp (@{$self->{regexps}}) {
            if ($data->{Data} =~ /$regexp/) {
              $match = 1;
              last;
            }
          }
          if($match == 0) {
            $self->{package} = undef;
            return;
          }
        }
      }
      $self->{data} .= $data->{Data};
    }
  }

  sub end_element {
    my ($self, $el) = @_;
    if (defined $self->{package}) {
      if ($el->{LocalName} eq 'package') {
        if (ref($self->{packages}) eq 'ARRAY') {
          push @{$self->{packages}}, $self->{package};
        } elsif (ref($self->{packages}) eq 'HASH') {
          $self->{packages}->{$self->{package}->{$self->{fields}->{'name'}}} = $self->{package};
        }
        $self->{package} = undef;
        $self->{indice}++;
        if ((defined $self->{to}) && ($self->{indice} >= $self->{to})) {
          die 'LIMIT_REACHED';
        }
      } elsif (defined $self->{fields}->{$el->{LocalName}}) {
        if (ref($self->{fields}->{$el->{LocalName}}) eq 'CODE') {
          $self->{fields}->{$el->{LocalName}}($self->{package}, $self->{key}, $self->{data}, $self->{attrs});
        } else {
          $self->{package}->{$self->{fields}->{$el->{LocalName}}} = $self->{data};
        }
        $self->{key} = undef;
      }
    }
  }
1;

=pod
Example:

my $packages = [];
my $parser = XML::SAX::ParserFactory->parser(
  Handler => XML::SAX::RPMHandler->new(
    $packages,
    {
      'name' => 'PACKAGE',
      'description' => sub {
        my ($package, undef, $data) = @_;
        $package->{'DESCRIPTION'} = $data;
      },
      'version' => sub {
        my ($package, undef, $data, $attrs) = @_;
        $package->{'VERSION'} = $attrs->{'{}ver'}->{'Value'}.'-'.$attrs->{'{}rel'}->{'Value'};
      },
    },
    [
      '^kernel',
    ],
  )
);

$parser->parse_uri("Centos/6/os/x86_64/primary.xml");
=cut
