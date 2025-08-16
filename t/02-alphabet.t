#!perl

use strict;
use warnings;
#use Data::Printer;
use Data::Dumper;
use Graphics::Penplotter::GcodeXY;
use Test::Simple 'no_plan';
use Font::FreeType;

my $font    = 'arial.ttf';
my $string1 = "EFILTZ";  # 2 crossings
my $string2 = "ABCDGHJK";
my $string3 = "MNOPQR";
my $string4 = "0123456789";
my $string5 = "!£$%^&*()_+";
my $string6 = "-_=+{}[]:@~;'#<>?,./";
my $string7 = "efiltz";
my $string8 = "abcdghjk";
my $string9 = "mnopqr";


# create a gcode object
my $g = new GcodeXY(
   papersize => "A3",
   units     => "pt",
   check     => 1,
   optimize  => 1,
   id        => "alphabet",
   #warn      => 1
   );

   $g->addfontpath("~/Documents/fonts/lexia/",
                   "~/Documents/fonts/main/",
                   "~/Documents/fonts/other/"
                  );
my $y = 100;
my $x = 50;
my $face = $g->setfont($font, 100);

   foreach my $i (1 .. 9) {
         ok($g->gsave());
         ok($g->translate($x,$i*$y));
         ok($g->stroketextfill($face, eval('$string' . $i)));
         ok($g->grestore());
   }

