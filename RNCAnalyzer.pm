#!/usr/bin/env perl
package RNCAnalyzer;

use strict;
use 5.014;
use utf8;

use open ':encoding(cp1251)';

use Encode qw(decode);
use XML::LibXML;

sub analyze_file {
    my($fname, $attr) = @_;

    open my $fh, '<', $fname;

    my %trigrams;
    my $lemma = (split '\.', $fname)[0];
    $lemma = decode 'cp1251', $lemma;
    my $word_xp = XML::LibXML::XPathExpression
      ->new('/p/se/w');
    my $lemma_xp = XML::LibXML::XPathExpression
      ->new('/w/ana[@lex="'.$lemma.'"]');
    # my $semf_xp = XML::LibXML::XPathExpression
    #   ->new('/w/ana[@SEMF]');
    my $attr_xp = XML::LibXML::XPathExpression
      ->new('/w/ana/@'.$attr);

    my($dom, $xc);
    my($parsed, $words, $lemmas);
    my $result;
    while (<$fh>) {
        s/^\s+//; s/\s+$//;
        s/^[^<]+//;
        if (/^<p\s*>/ && /<\/p>$/) {
            $parsed++;
            $dom = XML::LibXML->load_xml({string => $_});
            $xc = XML::LibXML::XPathContext->new($dom);
            my @nodes = $xc->findnodes($word_xp);
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
                # if (my @lemmas = $xcl->findnodes($semf_xp)) {
                #     if ($nodes[$i-1] && $nodes[$i+1]) {
                #         push @$result, [@nodes[$i-1..$i+1]];
                #         $lemmas += scalar @lemmas;
                #     }
                # }
            }
        }
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
