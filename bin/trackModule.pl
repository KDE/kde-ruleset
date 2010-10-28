#!/usr/bin/env perl
#

use strict;
use warnings;
use Switch;
use File::Basename;
use Data::Dumper;

$| = 1;

my %gargs = (
    'repository' => "",
    'path' => "",
    'revision' => "HEAD",
    'subdirs' => 0,
    'showcommands' => 0,
    'ignore' => "",
    'module' => "",
    'recurseDepth' => 0
);
my @commands = ();
my $firstrev = 9999999;
my %parentMoves;
sub listSubDirs
{
    #print("Getting a list of subdirs...\n");
    my ($repository, $revision, $root, $path, $recurse, $ignore) = @_;
    my $cmd = "svn ls $repository/$root/$path\@$revision";
    push( @commands, $cmd );

    my @dirs;
    open( my $CMD, "-|", "$cmd" ) || die "listSubDirs: Failed to run \"$cmd\": $!\n";

    #print( "listSubDirs: Getting subdirs of '$repository / $root / $path \@ $revision'\n" );
    while( <$CMD> ) {
        chomp;
        if( /(\S+)\/$/ ) {
            if( $ignore ne "" && /$ignore/ ) {
                next;
            }
            if( length( $path ) > 0 && substr( $path, -1 ) ne "/" ) {
                $path = "$path/";
            }
            print( "listSubDirs:\tAdding: $path$_\n" );
            push( @dirs, "$path$1" );
            push( @dirs, listSubDirs($repository, $revision, $root, "$path$1", $recurse + 1, $ignore) ) if( $recurse < $gargs{'recurseDepth'})
        }
    }
    close( $CMD );
    return @dirs;
}

sub getCopyFrom
{
    my $args = $_[0];
    my %returns = ('type' => '', 'path' => '','fromRev' => 0, 'minRev' => 0 );
    my $cmd = "svn log -v --stop-on-copy $args->{'repository'}/$args->{'path'}\@$args->{'rev'}";
    #print( "getCopyFrom: Getting origin of '$repository / $path \@ $revision...\n" );
    push( @commands, $cmd );
    my $path = "/$args->{'path'}";
    my $fromRevision = 0;
    my $fromPath = "";

    my @log = ();

    open( my $CMD, "-|", "$cmd" ) || die "getCopyFrom: Failed to run \"$cmd\": $!\n";
    while( <$CMD> ) {
        chomp;
        if( /^r(\d+) \| / ) {
            @log = ();
        }
        push( @log, $_ );
    }

    my $cvs2svnUsed = 0;
    my $cvs2svnCandidate = 0;
    my $missedCopy = 0;
    my $currentRev = 0;
    my $delayedCopy = 0;
    my $delayedCopyCandidate = 0;
    my $verbose = 0;

    open( my $FILE, ">>", "$gargs{'module'}-rules-auto" ) || die "!$!\n";
    foreach( @log ) {
        if( /^r(\d+) \| / ) {
            $currentRev = $1;
            if($currentRev < $firstrev) {
                $firstrev = $currentRev;
            }
        }
        if( /\s+(?:A|R) (\/\S+) \(from (\/\S+):(\d+)\)/ ) {
            my $origPath = $2;
            my $newPath = $1;
            my $fromRev = $3;
            $fromRevision = $fromRev;
            my @components = split( /\//, "$path" );
            my $subdir = pop( @components );
            my $shortPath = join( "/", @components );
            if( $verbose ) {
                print("> ------\n");
                print("> \$_: $_\n");
                print("> \$path:         $path\n");
                print("> \$newPath:      $newPath\n");
                print("> \$origPath:     $origPath\n");
                print("> \$fromRevision: $fromRevision\n");
                print("> \$subdir:       $subdir\n");
                print("> \$components:   @components\n");
                print("> \$shortPath:    $shortPath\n");
                print("> \$delayedCopyCandidate:    $delayedCopyCandidate\n");
            }
            # case 1: the dir is moved/replaced
            if( $newPath =~ /$path$/ ) {
                print( "getCopyFrom:\t\@r$currentRev: Found '$newPath' from '$origPath' at rev $fromRev\n" );
                print( $FILE "#\t[ Move/Replace: $newPath @ $currentRev <- $origPath @ $fromRev ]\n" );
                $returns{'path'} = $origPath;
                $returns{'fromRev'} = $fromRev;
                $returns{'type'} = "move";
                last;
            }

            # case 2: A parent is moved/replaced
            #if( $shortPath eq $newPath ) {
            if( $shortPath =~ /$newPath(\/.*)?/ ) {
                print( "getCopyFrom:\t\@r$currentRev: Found parent move '$shortPath' from '$origPath' at rev $fromRev\n" );
                my $tmp = "";
                if( defined $1 ) {
                    $tmp = $1;
                }
                $returns{'path'} = "$origPath$tmp/$subdir";
                $returns{'fromRev'} = $fromRev;
                $returns{'type'} = "parent";
                my %history = %returns;
                $history{'path'} = $newPath;
                if( exists $parentMoves{"$newPath:$fromRev"} ) {
                    $returns{'type'} = "skip";
                    #print "> Skipping\n";
                } else {
                    $parentMoves{"$newPath:$fromRev"} = 1;
                }
                #print "Parents: " . Dumper(%parentMoves);
                print( $FILE "#\t[ Parent: $newPath @ $currentRev <- $origPath @ $fromRev ]\n" );
                last;
            }

            # case 3:
            if( $delayedCopyCandidate == 1 && $newPath =~ /$path\// ) {
                print(" getCopyFrom:\t\@r$currentRev: Found dir add with delayed file move/copy '$newPath' from '$origPath' at rev $fromRev\n" );
                my($file, $dir, $suffix) = fileparse($origPath);
                $origPath = substr($dir, 0, -1);
                print( $FILE "#\t[ Delayed: $newPath @ $currentRev <- $origPath @ $fromRev ]\n" );
                $delayedCopy = 1;
                #last;
            }
        }

        # case 3: The directory is added and then populated with files from another path
        # case 4: A cvs2svn server side move, Directory add followed by every file as a svn cp
        if( /\s+A\s+$path$/ ) {
            $delayedCopyCandidate = 1;
            $cvs2svnCandidate = 1;
            print "> cvs2svn or delayed copy ($_)...\n";
        }

        if( $cvs2svnCandidate && /cvs2svn/ ) {
            $cvs2svnUsed = 1;
            $missedCopy = 0;
            last;
        } elsif( $delayedCopyCandidate == 1 && /\s+A (\/$path\/\S+) \(from (\/\S+):(\d+)\)/ ) {
            $delayedCopy = 1;
        }
    }

    if( $cvs2svnUsed ) {
        foreach( @log ) {
            if( /^r(\d+) \| / ) {
                $currentRev = $1;
            }
            if( /\s+A\s+\/$path\/\S+\s+\(from (\S+):(\d+)\)/ ) {
                my $origPath = $1;
                my $fromRev = $2;
                my @components = split( /\//, $path );
                my $subdir = pop( @components );
                my $shortPath = join( "/", @components );
                my $component = "";
                my @origComponents = split( /\//, $origPath );
                do {
                    $component = pop( @origComponents );
                } while( $component && $component ne $subdir );
                $origPath = join( "/", @origComponents ) . "/" . $component;

                if( $origPath eq "/" ) {
                    print( "\n==========================\n" );
                    print( "Unable to determine the source of the move, aborting this operation.\n" );
                    print( "To manually track this start with \"svn log -v -c$currentRev $gargs{'repository'}\"\n" );
                    print( "Sorry for the extra trouble!\n" );
                    print( "==========================\n" );
                    return \%returns;
                }

                print( "getCopyFrom:\t\@r$currentRev: Found cvs2svn move '$path' from '$origPath' at rev $fromRev\n" );
                print( $FILE "#\t[ cvs2svn: $path @ $currentRev -> $origPath @ $fromRev ]\n" );
                $returns{'path'} = $origPath;
                $returns{'fromRev'} = $fromRev;
                $returns{'type'} = "cvs2svn";
                $missedCopy = 0;
                last;
            }
        }
    }

    if( $missedCopy == 1 ) {
        my $msg = "#\tWARNING:\n#\t$path was added in r$currentRev and file(s)/dir(s) was copied into it but no 'from' path was detected, history loss possible.\n";
        print( $FILE "#\t$msg" );
        print( $msg );
    }
    if( $delayedCopy == 1 ) {
        print( "WARNING:\t$path was added in r$currentRev and file(s)/dir(s) was copied into it, a 'from' path was detected but it might contain extra file(s)/dir(s).\n" );
    }

    close( $FILE );
    close( $CMD );
    if( substr($returns{'path'},0,1) eq "/" ) {
        $returns{'path'} = substr($returns{'path'}, 1);
    }
    return \%returns

}

sub getCopyFromRecursive
{
    my $args = $_[0];
    #my ($repository, $module, $revision, $root, $path ) = @_;
    #print("\n------------------------------\n");
    #print("$repository, $module, $revision, $root, $path\n" );
    my @history = ();
    my $fromRev = $args->{'rev'};
    my $fromPath = $args->{'root'};
    $fromPath = "$args->{'root'}/$args->{'path'}" if( $args->{'path'} ne "" );
    
    open(my $FILE, ">>", "$gargs{'module'}-rules-auto") || die "!!$!\n";
    print( $FILE "#\t------< $fromPath >------\n" );    
    my $ret = {};
    push( @history, { 'type' => 'add', 'path' => $args->{'path'}, 'fromRev' => $args->{'rev'}, 'minRev' => 0 } );
    do {
        my %vars = ( 'repository' => $args->{'repository'}, 'rev' => $fromRev, 'path' => $fromPath );
        $ret = getCopyFrom( \%vars );
        $fromRev = $ret->{'fromRev'};
        $fromPath = $ret->{'path'};
        if( $ret->{'fromRev'} > 1 && $ret->{'type'} ne "skip" ) {
            push( @history, $ret );
        }

    } while( $ret->{'fromRev'} > 0 );

    my $minRevision = 0;
    for my $historyPart ( reverse( @history ) ) {
        $historyPart->{'minRev'} = $minRevision;
        $minRevision = $historyPart->{'fromRev'};
    }

    for my $historyPart (@history) {
        if( $historyPart->{'fromRev'} ne "HEAD" || $historyPart->{'minRev'} ne "0" ) {
           print($FILE "#\t[ $historyPart->{'type'} $historyPart->{'path'} $historyPart->{'fromRev'} $historyPart->{'minRev'} ]\n");

            if( $historyPart->{'path'} eq "" ) {
                print( $FILE "match /$args->{'root'}/\n");
            } elsif( $historyPart->{'path'} eq "$args->{'path'}" ) {
                print( $FILE "match /$args->{'root'}/$args->{'path'}/\n" );
            } else {
                print( $FILE  "match /$historyPart->{'path'}/\n");
            }
            print( $FILE  "    repository $args->{'module'}\n");
            if( $args->{'root'} ne $historyPart->{'path'} ) {
                my $prefix = $args->{'path'};
                print( $FILE  "    prefix $prefix/\n" ) if( $prefix ne "" );
            }
            print( $FILE  "    branch master\n");
            print( $FILE  "    max revision $historyPart->{'fromRev'}\n") if( $historyPart->{'fromRev'} ne "HEAD" );
            print( $FILE  "    min revision $historyPart->{'minRev'}\n" ) if( $historyPart->{'minRev'} != 0 );
            print( $FILE  "end match\n\n");
        } else {
            print( $FILE "#\t[ $historyPart->{'type'} $historyPart->{'path'} $historyPart->{'fromRev'} $historyPart->{'minRev'} ]\n");
        }
    }
    close($FILE);
    #print("\n------------------------------\n");
}

my $argnum;

for($argnum = 0; $argnum <= $#ARGV; $argnum++ ) {
    print "Argument #$argnum: $ARGV[$argnum]\n";
    switch ($ARGV[$argnum]) {
        case "--repo"   { $gargs{'repository'} = $ARGV[++$argnum]; }
        case "--path"   { $gargs{'path'} = $ARGV[++$argnum]; }
        case "--module" { $gargs{'module'} = $ARGV[++$argnum]; }
        case "--rev"    { $gargs{'revision'} = $ARGV[++$argnum]; }
        case "--subdirs"{ $gargs{'subdirs'} = 1; }
        case "--showcommands" { $gargs{'showcommands'} = 1; }
        case "--recurse" { $gargs{'recurseDepth'} = $ARGV[++$argnum]; }
        case "--ignore" { $gargs{'ignore'} = $ARGV[++$argnum]; }
        else            { print "Unknown option: $ARGV[$argnum]\n"; exit; }
    }
}
if( $#ARGV < 5 || $#ARGV > 12 ) {
    print( "Usage: trackModule.pl --repo repository --path path --module module [--rev revision] [--subdirs] [--showcommands] [--recurse depth] [--ignore path]\n");
    exit;
}
print Dumper(%gargs);

my @dirs = ("");
if( $gargs{'subdirs'} != 0 ) {
    print("Getting a list of subdirs...\n");
    my @subdirs = listSubDirs( $gargs{'repository'}, $gargs{'revision'}, $gargs{'path'}, "", 0, $gargs{'ignore'} );
    push( @dirs, @subdirs );
}

#splice( @dirs, 0, 0, $path );

my %foundDirRevisions;

open(my $FILE, ">", "$gargs{'module'}-rules-auto") || die "!$!\n";

while(@ARGV) {
    print( $FILE "# $ARGV[0]" );
    shift @ARGV;
}
print( $FILE "\n" );
print( $FILE "create repository $gargs{'module'}\n");
print( $FILE "end repository\n\n");
close( $FILE);
foreach( @dirs )
{
    print( "Scanning '$gargs{'path'} / $_'...\n" );
    my %arg = ( 'repository' => $gargs{'repository'}, 'module' => $gargs{'module'}, 'rev' => $gargs{'revision'}, 'root' => $gargs{'path'}, 'path' => $_ );
    getCopyFromRecursive( \%arg );
}

if( $gargs{'showcommands'} != 0 ) {
    open( $FILE, ">>", "$gargs{'module'}-rules-auto") || die "!$!\n";
    print( $FILE "#Used commands...\n" );
    foreach( @commands ) {
        print( $FILE "#$_\n" );
    }
    close( $FILE);
}

print( "First revision used: $firstrev\n" );
open( $FILE, ">>", "$gargs{'module'}-rules-auto") || die "!$!\n";
print($FILE "match /\n");
print($FILE "end match\n");
print($FILE "#First revision used: $firstrev\n" );
close($FILE);
