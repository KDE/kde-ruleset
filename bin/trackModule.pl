#!/usr/bin/env perl
#

use strict;
use warnings;
use Switch;

$| = 1;

my @commands = ();
my $firstrev = 9999999;
my $module = "";

sub listSubDirs
{
    print("Getting a list of subdirs...\n");
    my ($repository, $revision, $root, $path, $recurse) = @_;
    print "\$repository: $repository\n";
    print "\$revision:   $revision\n";
    print "\$root:       $root\n";
    print "\$path:       $path\n";
    print "\$recurse:    $recurse\n";
    my $cmd = "svn ls $repository/$root/$path\@$revision";
    push( @commands, $cmd );

    my @dirs;
    open( my $CMD, "$cmd |" ) || die "listSubDirs: Failed to run \"$cmd\": $!\n";

    print( "listSubDirs: Getting subdirs of '$repository / $root / $path \@ $revision'\n" );
    #print( "> $cmd\n" );
    while( <$CMD> ) {
        chomp;
        if( /(\S+)\/$/ ) {
            print( "listSubDirs:\tFound subdir: '$_'\n" );
            print( "listSubDirs:\tAdding: '$path$_'\n" );
            push( @dirs, "$path$1" );
            push( @dirs, listSubDirs($repository, $revision, $root, "$path$1", $recurse) ) if( $recurse )
        }
    }
    close( $CMD );
    print(" done\n");
    return @dirs;
}

sub getCopyFrom
{
    my ($repository, $revision, $path ) = @_;
    my $cmd = "svn log -v --stop-on-copy $repository/$path\@$revision";
    print( "getCopyFrom: Getting origin of '$repository / $path \@ $revision...\n" );
    #print( "getCopyFrom: > $cmd\n" );
    push( @commands, $cmd );
    my $fromRevision = 0;
    my $fromPath = "";

    my @log = ();

    open( CMD, "$cmd |" ) || die "getCopyFrom: Failed to run \"$cmd\": $!\n";
    while( <CMD> ) {
        chomp;
        if( /^r(\d+) \| / ) {
            @log = ();
        }
        push( @log, $_ );
    }

    #print( "getCopyFrom: - done\n" );

    my $cvs2svnUsed = 0;
    my $cvs2svnCandidate = 0;
    my $currentRev = 0;

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
            #print("> ------\n");
            #print("> \$_: $_\n");
            #print("> \$path:         $path\n");
            #print("> \$root:         $root\n");
            #print("> \$newPath:      $newPath\n");
            #print("> \$origPath:     $origPath\n");
            #print("> \$fromRevision: $fromRevision\n");
            #print("> \$subdir:       $subdir\n");
            #print("> \$components:   @components\n");
            #print("> \$shortPath:     $shortPath\n");

            # case 1: the dir is moved/replaced
            if( $newPath =~ /$path$/ ) {
                print( "getCopyFrom:\t\@r$currentRev: Found '$newPath' from '$origPath' at rev $fromRev\n" );
                open(FILE, ">>$module-rules-auto");
                print( FILE "# $newPath @ $currentRev -> $origPath @ $fromRev\n" );
                close( FILE );
                $fromPath = $origPath;
                last;
            }

            # case 2: A parent is moved/replaced
            if( $shortPath eq $newPath ) {
                print( "getCopyFrom:\t\@r$currentRev: Found parent move '$shortPath' from '$origPath' at rev $fromRev\n" );
                $fromPath = "$origPath/$subdir";
                open(FILE, ">>$module-rules-auto");
                print( FILE "# $newPath @ $currentRev -> $origPath @ $fromRev\n" );
                close( FILE );
                last;
            }

            #print("> $newPath !=~ /$path\$/\n");
            #print("> $shortPath !eq /$newPath\$/\n");
        }

        # case 3: A cvs2svn server side move
        # Directory add followed by every file as a svn cp
        if( /\s+A\s+$path/ ) {
            $cvs2svnCandidate = 1;
        }
        if( $cvs2svnCandidate && /cvs2svn/ ) {
            $cvs2svnUsed = 1;
            last;
        }
    }

    if( $cvs2svnUsed ) {
        foreach( @log ) {
            if( /^r(\d+) \| / ) {
                $currentRev = $1;
            }
            if( /\s+A\s+$path\S+\s+\(from (\S+):(\d+)\)/ ) {
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
                    print( "To manually track this start with \"svn log -v -c$currentRev $repository\"\n" );
                    print( "You may then restart this tool with the new parameters or you can do it manually.\n" );
                    print( "Sorry for the extra trouble!\n" );
                    print( "==========================\n" );
                    my @returnValue = (0,"");
                    return @returnValue;
                }

                print( "getCopyFrom:\t\@r$currentRev: Found cvs2svn move '$path' from '$origPath' at rev $fromRev\n" );
                open(FILE, ">>$module-rules-auto");
                print( FILE "# $path @ $currentRev -> $origPath @ $fromRev\n" );
                close( FILE );
                $fromPath = $origPath;
                $fromRevision = $fromRev;
                last;
            }
        }
    }

    close( CMD );
    if( $fromPath eq "" ) {
        $fromRevision = 0;
    } elsif( substr($fromPath,0,1) eq "/" ) {
        $fromPath = substr($fromPath, 1);
    }
    my @returnVale = ( $fromRevision, $fromPath );
    #print "getCopyFrom: returning: $fromRevision, $fromPath\n";
    return @returnVale;
}

sub getCopyFromRecursive
{
    my ($repository, $module, $revision, $root, $path ) = @_;
    print("\n------------------------------\n");
    print("$repository, $module, $revision, $root, $path\n" );
    my @history = ();
    my $fromRev = $revision;
    my $fromPath = "$root";
    $fromPath = "$root/$path" if( $path ne "" );

    push( @history, [$path, $revision] );
    #if( $revision ne "HEAD" ) {
    #    $revision -= 1;
    #}
    do {
        ($fromRev, $fromPath) = getCopyFrom( $repository, $fromRev, $fromPath );
        #if( $revision ne "HEAD" ) {
        #    $revision -= 1;
        #}
        if( $fromRev > 1) {
            push( @history, [$fromPath, $fromRev] );
            #print( "getCopyFromRecursive: $fromPath @ $fromRev\n" );
        }

    } while( $fromRev > 0 );
    open(FILE, ">>$module-rules-auto");
    #print(FILE "#===================================\n");
    #print(FILE "# Directory rules (skeleton)...\n\n");
    my $minRevision = 0;
    for my $historyPart ( reverse( @history ) ) {
        #print( "\t[ @$historyPart ]\n");
        push( @$historyPart, $minRevision );
        $minRevision = @$historyPart[1];
    }

    for my $historyPart (@history) {
        print(FILE "#\t[ @$historyPart ]\n");

        if( @$historyPart[0] eq "" ) {
            print( FILE "match /$root/\n");
        } elsif( @$historyPart[0] eq "$path" ) {
            print( FILE "match /$root/$path/\n" );
        } else {
            print(FILE  "match /@$historyPart[0]/\n");
        }
        print(FILE  "    repository KDE/$module\n");
        if( $root ne @$historyPart[0] ) {
            my $prefix = "$path";
            #if( @$historyPart[0] =~ /(^trunk\/$module\/)/ ||
            #    @$historyPart[0] =~ /(^trunk\/KDE\/$module\/)/ ||
            #    @$historyPart[0] =~ /(^branches.*\/$module\/)/ ||
            #    @$historyPart[0] =~ /(^tags.*\/$module\/)/ ) {
            #    $prefix = substr( @$historyPart[0], length( $1 ) );
            #    print(FILE "#\tprefix: $prefix, \$1: $1\n");
            #}
            print(FILE  "    prefix $prefix/\n" ) if( $prefix ne "" );
        }
        print(FILE  "    branch master\n");
        print(FILE  "    max revision @$historyPart[1]\n") if( @$historyPart[1] ne "HEAD" );
        print(FILE  "    min revision @$historyPart[2]\n" ) if( @$historyPart[2] != 0 );
        print(FILE  "end match\n\n");
    }
    close(FILE);
    print("\n------------------------------\n");
}

my $repository;
my $path;
my $revision = "HEAD";
#my $module;
my $argnum;
my $subdirs = 0;
my $showcommands = 0;
my $recurse = 0;

for($argnum = 0; $argnum <= $#ARGV; $argnum++ ) {
    print "Argument #$argnum: $ARGV[$argnum]\n";
    switch ($ARGV[$argnum]) {
        case "--repo"   { $repository = $ARGV[++$argnum]; }
        case "--path"   { $path = $ARGV[++$argnum]; }
        case "--module" { $module = $ARGV[++$argnum]; }
        case "--rev"    { $revision = $ARGV[++$argnum]; }
        case "--subdirs"{ $subdirs = 1; }
        case "--showcommands" { $showcommands = 1; }
        case "--recurse" { $recurse = 1; }
        else            { print "Unknown option: $ARGV[$argnum]\n"; exit; }
    }
}
if( $#ARGV < 5 || $#ARGV > 10 ) {
    print( "Usage: trackModule.pl --repo repository --path path --module module [--rev revision] [--subdirs] [--showcommands] [--recurse]\n");
    exit;
}
print <<EOF;
Got:
  \$repository: $repository
  \$path:       $path
  \$module:     $module
  \$revision:   $revision
  \$subdirs:    $subdirs
  \$recurse:    $recurse
EOF

my @dirs = ("");
if( $subdirs ) {
    my @subdirs = listSubDirs( $repository, $revision, $path, "", $recurse );
    push( @dirs, @subdirs );
}

#splice( @dirs, 0, 0, $path );

my %foundDirRevisions;

open(FILE, ">$module-rules-auto") || die;
print(FILE "create repository $module\n");
print(FILE "end repository\n\n");
close(FILE);
foreach( @dirs )
{
    print( "Scanning '$_'...\n" );
    getCopyFromRecursive( $repository, $module, $revision, $path, $_ );
}

if( $showcommands ) {
    open(FILE, ">>$module-rules-auto");
    print(FILE "#Used commands...\n" );
    foreach( @commands ) {
        print(FILE "#$_\n" );
    }
    close(FILE);
}

print( "First revision used: $firstrev" );
open(FILE, ">>$module-rules-auto") || die;
print(FILE "match /\n");
print(FILE "end match\n");
print(FILE "#First revision used: $firstrev\n" );
close(FILE);
