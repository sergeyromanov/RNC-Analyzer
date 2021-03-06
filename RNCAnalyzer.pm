package RNCAnalyzer;

use 5.014;

use open ':encoding(cp1251)';

use Algorithm::Combinatorics qw(variations_with_repetition);
use Data::Dumper;
use List::MoreUtils qw(uniq);
use List::Util qw(sum);
# use Log::Log4perl ();
use Try::Tiny qw(try catch);
use XML::LibXML ();

# Log::Log4perl->init("log4perl.conf");
# my $log = Log::Log4perl->get_logger("RNCAnalyzer");

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

sub no_stop_punctuation {
    my $context = shift;

    $context = drop_markup($context);
    if ($context =~ /("?\.|!)\s/) {

        return 0;
    }
    else { return 1 }
}

sub is_target_ngram {
    my($context, $lemma, $lw, $rw) = @_;

    if ($context =~ m!$lemma!) {
        my $word = '<w>.*?<\/w>';
        my $left_window = join '[^<]*', ($word)x$lw;
        my $right_window = join '[^<]*', ($word)x$rw;
        my $re = qr{$left_window.+?<w>.+?['"]$lemma['"].+?</w>.+?$right_window}i;

        return $context =~ m!$re!;
    }
    else { return 0 }
}

sub get_words_re {
    return $_[0] =~ m!(<w>.*?<\/w>)!g;
}

sub xpath_search {
    my($str, $xpath) = @_;

    my $xc = XML::LibXML::XPathContext->new(
        XML::LibXML->load_xml({string => $str})
    );
    my $value = $xc->findvalue($xpath);
    $value =~ s/^\s+//; $value =~ s/\s+$//;

    return $value;
}

sub get_ngrams {
    my($fh, $lemma, $lw, $rw) = @_;

    my @res;
    while (my $line = <$fh>) {
        my @contexts = get_raw_contexts($line, sum($lw, $rw, 1));
        @contexts = grep no_stop_punctuation($_), @contexts;
        push @res, grep is_target_ngram($_, $lemma, $lw, $rw), @contexts;
    }

    return @res;
}

sub parse_ngram {
    my($xpath, $words) = @_;

    my $ngram_struct;
    for my $attr_type (keys $xpath) {
        for my $i (0..$#$words) {
            my $prop = xpath_search($words->[$i], $xpath->{$attr_type});
            $ngram_struct->{$i}{$attr_type} = $prop;
        }
    }

    return $ngram_struct;
}

sub gather_stat_for_variation {
    my($var, $lw, $ngrams) = @_;

    my $stat;
    for my $ngram (@$ngrams) {
        my($key, $lex, @key_arr);
        for my $i (0..$#$var) {
            my $prop = $ngram->{$i}{$var->[$i]} || '_';
            $key .= ($i == $lw ? "($prop)" : $prop).'++';
            $key_arr[$i] = $i == $lw ? "($prop)" : $prop;
            $lex->[$i] = $ngram->{$i}{lex} || '_';
        }
        $stat->{ $key =~ s(\+\+$)()r }{num}++;
        $stat->{ $key =~ s(\+\+$)()r }{key_arr} = \@key_arr;
        push @{$stat->{ $key =~ s(\+\+$)()r }{lex}}, $lex;
    }

    return $stat;
}

sub stat_record {
    my($struct, $variation, $lw) = @_;

    my $line;
    for my $i (0..$#$variation) {
        $line .= $struct->{key_arr}[$i];
        if (
            $i == $lw
            || $variation->[$i] =~ /lex/
            || $struct->{key_arr}[$i] =~ /_/
        ) {
            $line .= '++';
            next;
        }
        else {
            $line .= '|';
            my @lexs = uniq map {$_->[$i]} @{$struct->{lex}};
            $line .= join ',', @lexs;
            $line .= '++';
        }
    }

    return $line =~ s(\+\+$)()r;
}

sub prepare_res {
    my($variation, $stat, $top, $lw) = @_;

    my $res;
    $variation->[$lw] = "($variation->[$lw])";
    $res .= join '++', @$variation;
    $res .= "\n";
    my @sorted_keys = sort {$stat->{$b}{num} <=> $stat->{$a}{num}} keys $stat;
    my $sum = sum map $stat->{$_}{num}, keys $stat;
    for my $i (0..$top-1) {
        my $part = $stat->{$sorted_keys[$i]}{num} * 100 / $sum;
        $part =~ s!(?<=\.\d\d).*$!!;
        $res .= $stat->{$sorted_keys[$i]}{num}
          ." ($part%)\t\t"
          .stat_record($stat->{$sorted_keys[$i]}, $variation, $lw)."\n";
    }
    $res .= "\n\n";

    return $res;
}

sub analyze_file {
    my($fname, $ui_params, $lemma) = @_;

    open my $fh, '<', $fname;

    my $attr_xp = {
        map {
            $_ => XML::LibXML::XPathExpression->new('/w/ana/@'.$_)
        } grep {$ui_params->{attr}{$_}} keys $ui_params->{attr}
    };

    my($lw, $rw) = @{$ui_params->{window}}{qw<left right>};
    my $total_width = sum($lw, $rw, 1);

    my @ngrams = get_ngrams($fh, $lemma, $lw, $rw);

    my @ngram_struct;
    for my $ngram (@ngrams) {
        my @words = get_words_re($ngram);
        next unless scalar(@words) == $total_width;
        push @ngram_struct, parse_ngram($attr_xp, \@words);
    }
    my @variations = variations_with_repetition([keys $attr_xp], $total_width);
    my $res;
    for my $variation (@variations) {
        my $stat = gather_stat_for_variation($variation, $lw, \@ngram_struct);
        $res .= prepare_res($variation, $stat, $ui_params->{top_output}, $lw);
    }

    return $res;
}

1;
