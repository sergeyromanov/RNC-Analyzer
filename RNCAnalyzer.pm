package RNCAnalyzer;

use strict;
use 5.014;
use utf8;

use open ':encoding(cp1251)';

use Try::Tiny qw(try catch);
use XML::LibXML;

my %ATTRS = (
    0 => 'gr',
    1 => 'lex',
    2 => 'sem',
);

sub analyze_file {
    my($fname, $attr, $lemma) = @_;

    open my $fh, '<', $fname;
    my %trigrams;
    my $lemma_xp = XML::LibXML::XPathExpression
      ->new('/w/ana[@lex="'.$lemma.'"]');
    my $attr_xp = XML::LibXML::XPathExpression
      ->new('/w/ana/@'.$ATTRS{$attr});
    my $word_xp = [
        XML::LibXML::XPathExpression->new('/p/w'),
        XML::LibXML::XPathExpression->new('/p/se/w'),
        XML::LibXML::XPathExpression->new('/p/se/st/w'),
    ];

    my($parsed, $words, $lemmas);
    my $result;
    while (my $line = <$fh>) {
        $line =~ s/[^>]+$//;
        $line =~ s/^[^<]+//;
        # some files have closing parts for singular XHTML tags;
        # we need to remove those parts so parser could handle tags
        $line =~ s/<\/ana>//g;
        unless ($line =~ m/^<p\s*>/) {
            $line =~ s/^/<p>/;
            $line =~ s/$/<\/p>/;
        }
        # if ($line =~ m/^<(p|se|w)\s*>/) {
            my($dom, $xc);
            $parsed++;
            try { $dom = XML::LibXML->load_xml({string => $line}) };
            $xc = XML::LibXML::XPathContext->new($dom);
            my @nodes;
            XP: for my $xp (@$word_xp) {
                try { @nodes = $xc->findnodes($xp) };
                last XP if scalar @nodes > 0;
            }
            next unless scalar @nodes > 0;

            for my $i (0..$#nodes) {
                # TODO: more natural way?
                my $xcl = XML::LibXML::XPathContext->new(
                    XML::LibXML->load_xml({string => $nodes[$i]->toString})
                );
                if (my @lemmas = $xcl->findnodes($lemma_xp)) {
                    # check last in not empty; what about first ($i=0)?
                    if ($nodes[$i-1] && $nodes[$i+1]) {
                        push @$result, [@nodes[$i-1..$i+1]];
                        $lemmas += scalar @lemmas;
                    }
                }
            }
        # }
    }
    for my $ngram (@$result) {
        my $xc = XML::LibXML::XPathContext->new(
            XML::LibXML->load_xml({string => $ngram->[0]->toString})
        );
        my $left = $xc->findvalue($attr_xp);
        $left =~ s/^\s+//; $left =~ s/\s+$//;
        my $xc = XML::LibXML::XPathContext->new(
            XML::LibXML->load_xml({string => $ngram->[2]->toString})
        );
        my $right = $xc->find($attr_xp);
        $right =~ s/^\s+//; $right =~ s/\s+$//;
        $trigrams{(join '<>', $left, $lemma, $right)}++ if $left || $right;
    }
    # say "Total: $., parsed: $parsed, lemmas: $lemmas";
    my @sorted_keys = sort {$trigrams{$b} <=> $trigrams{$a}} keys %trigrams;
    my $result;
    $result .=
      join '', $lemma, ' (out of ', scalar (keys %trigrams), ')', $/;
    $result .=
      join '', $_, ' => ', $trigrams{$_}, $/ for @sorted_keys[0..10];
    $result .= "\n\n";

    return $result;
}

1;
