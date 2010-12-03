#!/usr/bin/env perl

use strict;
use warnings;
use diagnostics;
use File::Basename;
use Data::Dumper;
use Switch;

$| = 1;

my %gargs = (
    'repository' => "",
    'path' => [],
    'showcommands' => 0,
    'module' => "",
    'mode' => 0,
    'root' => "",
    'append' => 0,
    'ignore' => ""
);
my @commands = ();

sub listSubDirs
{
    print("Getting a list of subdirs...\n");
    my $args = $_[0];
    #print "list:" . Dumper($args);
    $args->{'root'} = "" if $args->{'root'} eq "/";
    $args->{'root'} = "$args->{'root'}/" if substr($args->{'root'},-1) ne "/" and $args->{'root'} ne "/"; 
    my $cmd = "svn ls $args->{'repository'}$args->{'root'}$args->{'path'}";
    push( @commands, $cmd );
    my @dirs;
    push( @dirs, "$args->{'root'}$args->{'path'}" );
    open( my $CMD, "-|", "$cmd" ) || die "listSubDirs: Failed to run \"$cmd\": $!\n";

    print( "listSubDirs: Running: $cmd\n" );
    while( <$CMD> ) {
        chomp;
        if( /(\S+)\/$/ ) {
            if( $args->{'ignore'} eq "" or not /$args->{'ignore'}/ ) {
                if( length( $args->{'path'} ) > 0 && substr( $args->{'path'}, -1 ) ne "/" ) {
                    $args->{'path'} = "$args->{'path'}/";
                }
                print( "listSubDirs:\tAdding: $args->{'path'}$_\n" );
                #push( @dirs, "$args->{'path'}$1" );
                my %subargs = %{$args};
                $subargs{'path'} = "$args->{'path'}$_";
                push( @dirs, listSubDirs(\%subargs) );
            } else {
                print( "listSubDirs:\tSkipping; $args->{'path'}$_\n" );
            }
        } else {
            if( length( $args->{'path'} ) > 0 && substr( $args->{'path'}, -1 ) eq "/" ) {
                $args->{'path'} = substr($args->{'path'}, 0, -1);
            }
            my $file = "$args->{'path'}/$_";
            print( "listSubDirs:\tAdding: $file\n" );
            push( @dirs, $file );
        }
    }
    close( $CMD );
    return @dirs;
}

sub addRevisionsForPath
{
    my ($revs, $repository, $root, $path) = @_;
    my $args = $_[0];
    #print "add:" . Dumper($args);

    $args->{'root'} = "" if $args->{'root'} eq "/";
    $args->{'root'} = "$args->{'root'}/" if substr($args->{'root'},-1) ne "/" and $args->{'root'} ne "/"; 
    my $cmd = "svn log -v $args->{'repository'}$args->{'root'}$args->{'path'}";
    #print( "addRevisionsForPath: Running: $cmd\n" );
    push( @commands, $cmd );
    #print(" $cmd\n");
    open( my $CMD, "-|", "$cmd" ) || die "getRevisions: Failed to run \"$cmd\": $!\n";
    my $nbr = 0;
    my $last = -1;
    my $rev;
    print "$args->{'path'}: ";
    while( <$CMD> ) {
        if( /^r(\d+) / ) {
            $rev = $1;
            $args->{'revisions'}->{$rev} = 1;
            $nbr++;
            $last = $rev;
        }
    }
    close( $CMD );
    print "$nbr revs ($last)\n";
}

my $argnum;

for($argnum = 0; $argnum <= $#ARGV; $argnum++ ) {
    print "Argument #$argnum: $ARGV[$argnum]\n";
    switch ($ARGV[$argnum]) {
        case "--repo"   { $gargs{'repository'} = $ARGV[++$argnum]; }
        case "--path"   { push( @{$gargs{'path'}}, $ARGV[++$argnum] ); }
        case "--module" { $gargs{'module'} = $ARGV[++$argnum]; }
        case "--append" { $gargs{'append'} = 1; }
        case "--root"   { $gargs{'root'} = $ARGV[++$argnum]; }
        case "--ignore" { $gargs{'ignore'} = "$ARGV[++$argnum]"; }
        else            { print "Unknown option: $ARGV[$argnum]\n"; exit; }
    }
}
if( $#ARGV < 5 ) {
    print( "Usage: generateRevisionList.pl --repo repository --root rootpath --path path [--path path]* --module module [--append] [--ignore path]\n" );
    exit;
}
print Dumper(%gargs);

my $fileName = "$gargs{'module'}-revisions.txt";
print("Getting a list of paths...\n");
my %args = ( 'repository' => $gargs{'repository'}, 'root' => $gargs{'root'}, 'path' => "", 'ignore' => $gargs{'ignore'} );
my @dirs;

foreach my $dir (@{$gargs{'path'}}) {
    print "$dir\n";
    $args{'path'} = $dir;
    push @dirs, listSubDirs( \%args );
}

my %revs = ();
my $i = 0;
foreach( @dirs )
{
    #print( "Scanning '$gargs{'path'} / $_'...\n" );
    my %arg = ( 'repository' => $gargs{'repository'}, 'module' => $gargs{'module'},
                'root' => $gargs{'root'}, 'path' => $_, 'revisions' => \%revs );
    addRevisionsForPath( \%arg );
    #print "Res:" . Dumper(%arg);
    #exit if( $i gt 2 );
    #$i++;
}

my $mode = ">";
$mode = ">>" if( $gargs{'append'} eq 1 );

open(my $FILE, $mode, "$fileName") || die "!$!\n";
foreach my $rev ( keys(%revs) ) {
	print $FILE "$rev\n";
}
close($FILE);
