use strict;
use 5.014;
use utf8;

use Test::More;
use XML::LibXML ();

use_ok( 'RNCAnalyzer' );

my $str = do {local $/ = <DATA>};
my @w = RNCAnalyzer::get_words(RNCAnalyzer::prepare($str));
is(scalar @w, 17, "Extract all words from line");

my $lemma_xp = XML::LibXML::XPathExpression->new('/w/ana[@lex="лом"]');
ok(RNCAnalyzer::has_lemma($w[5], $lemma_xp), "Word tag has correct lemma");
ok(!RNCAnalyzer::has_lemma($w[6], $lemma_xp), "Word tag doesn't have correct lemma");

done_testing();

__DATA__
1	 <w><ana lex='Не' gr='PART,norm='/>Не</w> <w><ana lex='стоить' gr='V,ipf,norm=sg,indic,3p,praes,act,indic' sem='d:root'/>стоит</w> <w><ana lex='использовать' gr='V,norm=(inf,pf,act|inf,ipf,act)' sem='d:pref der:v '/>использовать</w> <w><ana lex='как' gr='ADV-PRO,norm=' sem='r:rel t:manner '/>как</w> <w><ana lex='каменный' gr='A,norm=(nom,sg,m,plen|acc,sg,m,inan,plen)' sem='r:rel der:s dt:stuff dt:stone'/>каменный</w> <w><ana lex='лом' gr='S,m,inan,norm=(nom,sg|acc,sg)' sem='r:concr t:tool:instr top:rod der:v | r:concr pt:aggr sc:thing der:v '/>лом</w> <w><ana lex='с' gr='PR,norm='/>с</w> <w><ana lex='острый' gr='A,norm=ins,pl,plen' sem='r:qual t:physq ev'/>острыми</w> <w><ana lex='край' gr='S,m,inan,norm=ins,pl' sem='r:concr t:space pt:part pc:X'/>краями</w>, <w><ana lex='так' gr='ADV-PRO,norm=' sem='r:dem der:a dt:degr'/>так</w> <w><ana lex='и' gr='CONJ,norm='/>и</w> <w><ana lex='речной' gr='A,norm=(nom,pl,plen|acc,pl,inan,plen)' sem='r:rel der:s dt:space '/>речные</w> <w><ana lex='камень' gr='S,m,inan,norm=(nom,pl|acc,pl)' sem='r:concr t:stuff t:stone'/>камни</w>, <w><ana lex='круглый' gr='A,norm=(nom,pl,plen|acc,pl,inan,plen)' sem='r:qual t:physq:form'/>круглые</w>, <w><ana lex='с' gr='PR,norm='/>с</w> <w><ana lex='гладкий' gr='A,norm=(gen,sg,f,plen|dat,sg,f,plen|ins,sg,f,plen|loc,sg,f,plen)' sem='r:rel t:physq:form'/>гладкой</w> <w><ana lex='поверхность' gr='S,f,inan,norm=ins,sg' sem='r:concr t:space top:surface'/>поверхностью</w>.