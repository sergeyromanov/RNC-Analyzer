package RNCAnalyzer;

use 5.014;
use utf8;

use open ':encoding(cp1251)';

use List::Util qw(min);
use Log::Log4perl ();
use Try::Tiny qw(try catch);
use XML::LibXML ();

Log::Log4perl->init("log4perl.conf");
my $log = Log::Log4perl->get_logger("RNCAnalyzer");

my $word_xp = [
    XML::LibXML::XPathExpression->new('/p/w'),
    XML::LibXML::XPathExpression->new('/p/se/w'),
    XML::LibXML::XPathExpression->new('/p/se/st/w'),
];

sub has_lemma {
    my($node, $xpath) = @_;

    # TODO: more natural way?
    my $xcl = XML::LibXML::XPathContext->new(
        XML::LibXML->load_xml({string => $node->toString})
    );
    my @lemmas = $xcl->findnodes($xpath);

    return scalar @lemmas > 0
      ? 1
      : 0
}

sub get_words {
    my $xml = shift;

    my($dom, $xc);
    try { $dom = XML::LibXML->load_xml({string => $xml}) };
    $xc = XML::LibXML::XPathContext->new($dom);
    my @words;
    XP: for my $xp (@$word_xp) {
        try { @words = $xc->findnodes($xp) };
        last XP if scalar @words > 0;
    }

    return @words;
}

sub prepare {
    my $line = shift;

    $line =~ s/[^>]+$//;
    $line =~ s/^[^<]+//;
    # some files have closing parts for singular XHTML tags;
    # we need to remove those parts so parser could handle tags
    $line =~ s/<\/ana>//g;
    unless ($line =~ m/^<p\s*>/) {
        $line =~ s/^/<p>/;
        $line =~ s/$/<\/p>/;
    }

    return $line;
}

sub drop_markup {
    return $_[0] =~ s/<.+?>//gr
}

sub get_raw_contexts {
    my($str, $width) = @_;

    my $word = '<w>.*?<\/w>';
    my $re_string = join '[^<]*', ($word)x$width;
    my $re = qr/$re_string/;
    $str =~ s/<\/?se>//g;

    return $str =~ m!(?=($re))!g;
}

sub filter_on_punctuation {
    my $context = shift;

    $context = drop_markup($context);
    if ($context =~ /\s("?\.)\s/) {

        return 0;
    }
    else { return 1 }
}

sub has_lemma_re {
    my($context, $lemma) = @_;

    if ($context =~ m!</w>.*?$lemma!) {

        return 1;
    }
    else { return 0 }

}

sub analyze_file {
    my($fname, $ui_params, $lemma) = @_;

    open my $fh, '<', $fname;
    my %trigrams;
    my $lemma_xp = XML::LibXML::XPathExpression
      ->new('/w/ana[@lex="'.$lemma.'"]');
    my $attr_xp = {
        map {
            $_ => XML::LibXML::XPathExpression->new('/w/ana/@'.$_)
        } grep {$ui_params->{'attr'}{$_}} keys $ui_params->{'attr'}
    };

    my($parsed, $words, $lemmas);
    my $result;
    while (my $line = <$fh>) {
        $line = prepare($line);
        $parsed++;
        my @nodes = get_words($line);

        next unless scalar @nodes > 0;

        for my $i (0..$#nodes) {
            if (has_lemma($nodes[$i], $lemma_xp)) {
                # check last in not empty; what about first ($i=0)?
                if ($nodes[$i-1] && $nodes[$i+1]) {
                    push @$result, [@nodes[$i-1..$i+1]];
                    $lemmas++;
                }
            }
        }
    }
    for my $ngram (@$result) {
        my(@left_attrs, @right_attrs);
        for my $attr_type (sort keys $attr_xp) {
            my $xc = XML::LibXML::XPathContext->new(
                XML::LibXML->load_xml({string => $ngram->[0]->toString})
            );
            my $left = $xc->findvalue($attr_xp->{$attr_type});
            $left =~ s/^\s+//; $left =~ s/\s+$//;
            push @left_attrs, "[$attr_type](".$left.")";
            my $xc = XML::LibXML::XPathContext->new(
                XML::LibXML->load_xml({string => $ngram->[2]->toString})
            );
            my $right = $xc->find($attr_xp->{$attr_type});
            $right =~ s/^\s+//; $right =~ s/\s+$//;
            push @right_attrs, "[$attr_type](".$right.")";
        }
        if (@left_attrs || @right_attrs) {
            my $key = join '<>',
              (join '', @left_attrs),
              $lemma,
              (join '', @right_attrs);
            $trigrams{$key}++;
        }
    }
    # say "Total: $., parsed: $parsed, lemmas: $lemmas";
    my @sorted_keys = sort {$trigrams{$b} <=> $trigrams{$a}} keys %trigrams;
    my $result;
    $result .=
      join '', $lemma, ' (out of ', scalar (keys %trigrams), ')', $/;
    $result .= join '', $_, ' => ', $trigrams{$_}, $/
      for @sorted_keys[0..min($#sorted_keys, $ui_params->{'top_output'}-1)];
    $result .= "\n\n";

    return $result;
}

1;
