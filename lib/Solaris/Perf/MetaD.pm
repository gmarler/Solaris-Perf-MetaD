package Solaris::Perf::MetaD;

use strict;
use warnings;

use Moose;
use namespace::autoclean;
use Inline::JSON;
use Carp::Assert;

# 
# A list of valid keys that we are allowed to see in a probedesc. We use a hash
# for faster lookup than iterating over an array.
# 

my $mdProbedescKeys = json: {
  "probes":       "true",
  "gather":       "true",
  "alwaysgather": "true",
  "local":        "true",
  "aggregate":    "true",
  "transforms":   "true",
  "predicate":    "true",
  "clean":        "true",
  "verify":       "true"
};

=method mdValidateMetaD

Validate that a given description of an object makes sense and contains the
correct fields for a Meta-D description.

  desc    An object representing the description of a metric.

=cut


sub mdValidateMetaD {
  my ($self, $desc) = @_;

  my ($probedesc, $ii, $jj, $elt, $key, $ent, $ks, $locals, $allfields);

  assert(defined($desc), 'missing argument metad');

  foreach $key (qw( metad fields )) {
    assert(exists($desc->{$key}), "desc object missing '$key'");
  }

  if (not exists($desc->{'fields_internal'})) {
    $desc->{'fields_internal'} = [];
  }

  #
  # Build a set of all fields for reference, including internal fields
  #
  $allfields = {};

  #for ($ii = 0; $ii < $desc
}

=method mdSanityCheck
 
 Given an object that represents the metric with metad expression and the
 requested instrumentation, sanity check that basic expected properties hold.
 
  desc  An object representation that includes all of the
        module, stat, fields, and Meta-D description.
 
  metric		An object that contains the information necessary to
  		create the instrumentation. It specifies decompositions,
  		predicates, and other options.

=cut 

sub mdSanityCheck
{
  my ($self, $desc, $metric) = @_;

  assert(defined($metric), 'missing argument $metric');

  # Sanity check the $desc
  $self->mdValidateMetaD($desc);
}

# 
# Transform a metric's arguments and its description into a D string.
# 
#  desc		The full metric description, including stat, module,
#  		fields, and metad.
# 
#  metric		The information from the about the specifics regarding
#  		this instrumentation.
# 
#  metadata	Metric metadata
# 
# Returns an object with the following fields:
# 
# 	scripts		An array of scripts to run. Generally there will only be
# 			one, but if we're using the #pragma D zone=%z, then we
# 			may have more.
# 
# 	zero		The value for zero for this metric.
# 
#  hasdecomps	A boolean that tells whether or not there are any
#  		decompositions in the aggregation.
# 
#  hasdists	A boolean that describes whether or not the value will
#  		have distributions.

sub mdGenerateDScript
{
  my ($self, $desc, $metric, $metadata) = @_;

  my ($decomps, $pragmazone, $preds, $fields, $tmp, $zonepred, $ii, $pent,
    $lpred);
  my ($key, $ret, $ltrans, $laggs, $lclean, $zero, $hasdists, $hasdecomps,
    $lverif);
  my $gathered = {};
  my $script;

  $self->mdSanityCheck($desc, $metric);

  $fields     = {};
  $decomps    = {};
  $pragmazone = 0;
  $zonepred   = '';

}



1;

__END__


