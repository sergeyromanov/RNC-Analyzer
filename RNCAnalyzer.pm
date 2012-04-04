package RNCAnalyzer;

use 5.014;

use open ':encoding(cp1251)';

use List::Util qw(sum);
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
        my $re = qr{$left_window.+?<w>.+?$lemma.+?</w>.+?$right_window};

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

sub window_stat {
    my($stat) = @_;

    my $result;
    # each element in @stat is a hash of hashes
    for my $i (0..$#$stat) {
        my $attrs = $stat->[$i];
        for my $a_type (sort keys $attrs) {
            my $a_vals = $attrs->{$a_type};
            my @vals = sort {$a_vals->{$b} <=> $a_vals->{$a}} keys $a_vals;
            $result .= join '', "\tmax $a_type in position ",
              $i+1, ": ($vals[0]) => $a_vals->{$vals[0]}\n";
        }
    }

    return $result;
}

sub analyze_file {
    my($fname, $ui_params, $lemma) = @_;

    open my $fh, '<', $fname;

    my $attr_xp = {
        map {
            $_ => XML::LibXML::XPathExpression->new('/w/ana/@'.$_)
        } grep {$ui_params->{'attr'}{$_}} keys $ui_params->{'attr'}
    };

    my($lw, $rw) = @{$ui_params->{'window'}}{qw<left right>};
    my $total_width = sum($lw, $rw, 1);

    my @ngrams;
    while (my $line = <$fh>) {
        my @contexts = get_raw_contexts($line, $total_width);
        @contexts = grep no_stop_punctuation($_), @contexts;
        push @ngrams, grep is_target_ngram($_, $lemma, $lw, $rw), @contexts;
    }

    my $stat;
    my $window_attrs = sub {
        my($xpath, $window, @words) = @_;

        for my $i (0..$#words) {
            for my $attr_type (sort keys $xpath) {
                my $value = xpath_search($words[$i], $xpath->{$attr_type});
                $stat->{$window}[$i]{$attr_type}{$value}++;
            }
        }
    };

    for my $ngram (@ngrams) {
        my @words = get_words_re($ngram);
        next unless scalar(@words) != $total_width;
        $window_attrs->($attr_xp, 'left', @words[0..$lw-1]);
        $window_attrs->($attr_xp, 'right', @words[$lw+1..$#words]);
    }

    my $res = "$lemma\n";
    $res .= "Left window:\n";
    $res .= window_stat($stat->{'left'});
    $res .= "Right window:\n";
    $res .= window_stat($stat->{'right'});
    $res .= "\n";

    return $res;
}

1;
