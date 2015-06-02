use warnings;
use strict;

use Test::Most;
use Inline::JSON;
use JSON::MaybeXS;
use Data::Dumper;

my $probelist = [ qw( fop_read fop_write fop_ioctl fop_access fop_getattr
                      fop_setattr fop_lookup fop_create fop_remove
                      fop_link fop_rename fop_mkdir fop_rmdir fop_readdir
                      fop_symlink fop_readlink fop_fsync fop_getpage
                      fop_putpage fop_map
                    )
                ];
my $allowedfs = [ qw( ufs zfs dev devfs proc lofs tmpfs nfs ) ];

my $allowedfs_pred = '(' . 
                     join(' || ',
                          map { sprintf('this->fstype == "%s"', $_); }
                          @$allowedfs) .
                     ')';

my $entryprobes = [ map { sprintf('fbt::%s:entry', $_); }
                    @$probelist ];
push @$entryprobes, 'fbt::fop_open:entry';

my $returnprobes = [ map { sprintf('fbt::%s:return', $_); }
                     @$probelist ];
my $retprobes_noopen = $returnprobes;
push @$returnprobes, 'fbt::fop_open:return';

diag Dumper( \$allowedfs_pred );
diag Dumper( \$entryprobes );
diag Dumper( \$returnprobes );

my $desc = {
  module => 'fs',
  stat   => 'logical_ops',
  fields => [ qw( hostname zonename pid execname psargs ppid pexecname
                  ppsargs fstype optype latency ) ],
  fields_internal => [ qw( vnode depth ) ],
  metad => {
    locals => [ { fstype => "string" } ],
    probedesc =>
      [ { probes => $entryprobes,
          alwaysgather => {
            vnode => { gather => 'arg0',
                       store  => 'thread',
                     },
            depth => {
                       gather => 'stackdepth',
                       store  => 'thread',
                     },
          },
          gather => {
            latency => {
                         gather => 'timestamp',
                         store  => 'thread',
                       },
          },
          predicate => '$vnode0 == NULL',
        },
        { probes => [ 'fbt::fop_open:return' ],
          aggregate => { pid       => 'count()',
                         ppid      => 'count()',
                         execname  => 'count()',
                         zonename  => 'count()',
                         optype    => 'count()',
                         hostname  => 'count()',
                         fstype    => 'count()',
                         latency   => 'llquantize($0, 10, 3, 11, 100)',
                         psargs    => 'count()',
                         default   => 'count()',
                         ppsargs   => 'count()',
                         pexecname => 'count()',
                      },
          local => [
            { fstype => 'stringof((*((vnode_t**)self->vnode0))->v_op->vnop_name)' },
          ],
          transforms => {
            pid       => 'lltostr(pid)',
            ppid      => 'lltostr(ppid)',
            hostname  => 'bogus_hostname',
            execname  => 'execname',
            zonename  => 'zonename',
            optype    => '(probefunc + 4)',
            latency   => 'timestamp - $0',
            psargs    => 'curpsinfo->pr_psargs',
            fstype    => 'stringof((*((vnode_t**)self->vnode0))->v_op->vnop_name)',
            ppsargs   => 'curthread->t_procp->p_parent->p_user.u_psargs',
            pexecname => 'curthread->t_procp->p_parent->p_user.u_comm',
          },
          verify => {
            latency => '$0',
            vnode   => '$0',
            depth   => '$0',
          },
          predicate => '$depth0 == stackdepth && $vnode0 != NULL && ' . $allowedfs_pred,
        },
        { probes => $retprobes_noopen,
          aggregate => {
            pid       => 'count()',
            ppid      => 'count()',
            execname  => 'count()',
            zonename  => 'count()',
            optype    => 'count()',
            hostname  => 'count()',
            fstype    => 'count()',
            psargs    => 'count()',
            latency   => 'llquantize($0, 10, 3, 11, 100)',
            default   => 'count()',
            ppsargs   => 'count()',
            pexecname => 'count()',
          },
          local => [ { fstype => 'stringof(((vnode_t*)self->vnode0)->v_op->vnop_name)' } ],
          verify => {
            latency => '$0',
            vnode   => '$0',
            depth   => '$0',
          },
          transforms => {
            pid       => 'lltostr(pid)',
            ppid      => 'lltostr(ppid)',
            hostname  => 'bogus_hostname',
            execname  => 'execname',
            zonename  => 'zonename',
            optype    => '(probefunc + 4)',
            latency   => 'timestamp - $0',
            psargs    => 'curpsinfo->pr_psargs',
            fstype    => 'stringof(((vnode_t*)self->vnode0)->v_op->vnop_name)',
            ppsargs   => 'curthread->t_procp->p_parent->p_user.u_psargs',
            pexecname => 'curthread->t_procp->p_parent->p_user.u_comm'
          },
          predicate => '$depth0 == stackdepth && $vnode0 != NULL && ' . $allowedfs_pred,
        },
        { probes => $returnprobes,
          predicate => '$depth0 == stackdepth',
          clean => {
            vnode   => '$0',
            depth   => '$0',
            latency => '$0',
          },
        },
      ],
  }
};

my $encoder = JSON::MaybeXS->new->pretty;

my $desc_json = $encoder->encode($desc);
diag Dumper( \$desc_json );

use_ok( 'Solaris::Perf::MetaD' );

my $metad = Solaris::Perf::MetaD->new();

isa_ok( $metad, 'Solaris::Perf::MetaD' );



done_testing();
