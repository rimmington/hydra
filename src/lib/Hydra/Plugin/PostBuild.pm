package Hydra::Plugin::PostBuild;

use strict;
use parent 'Hydra::Plugin';
use Cwd;
use Data::Dump;
use Hydra::Helper::CatalystUtils;
use autodie qw( system );

sub buildFinished {
    my ($self, $build, $dependents) = @_;
    return unless $build->buildstatus == 0;

    my $script = ($build->buildoutputs)[0]->path . "/build-support/hydra-post-build";
    return unless -e $script;

    my $tempdir = File::Temp->newdir("hydra-post-build-" . $build->id . "-XXXXX", TMPDIR => 1);
    my $filename = $tempdir . '/revisions.json';
    my $eval = getFirstEval($build);

    open(my $fh, '>:encoding(UTF-8)', $filename) or die "Could not open file '$filename' $!";
    print $fh "{";
    foreach my $curInput ($eval->jobsetevalinputs) {
        next unless ($curInput->type eq "git" || $curInput->type eq "hg");
        print $fh ('"' . $curInput->name . '": "' . $curInput->revision . '", ');
    }
    seek($fh, -2, 1);  # Erase last ', '
    print $fh "} ";
    close $fh;

    my $dir = getcwd;
    chdir $tempdir;
    eval {
        system("$script $filename");
    };
    my $err = $@;
    chdir $dir;
    die $err if defined $err;
}

1;
