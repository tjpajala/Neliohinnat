Neliohinnat
===========

## LICENSE

<a rel="license" href="http://creativecommons.org/licenses/by-nc/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc/4.0/88x31.png" /></a><br />
This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc/4.0/">Creative Commons Attribution-NonCommercial 4.0 International License</a>.

## UPDATE 7.3.2016

The service was update with apartment price data from year 2015, and the predictions are now given for year 2017. The repository was updated so that all original scripts and data were moved to folders ending in `_2015`, and new scripts and data are in folders enging in `_2016`.

## Introduction

Apartment price trends across Finland, on the level of zip codes, based on open data from Tilastokeskus. See the interactive visualisation [Kannattaakokauppa](http://kannattaakokauppa.fi/#/) and related blog posts at [Reaktor](http://reaktor.com/blog/asuntojen-trendit-ja-miten-niista-tehdaan-luotettavia-ennusteita), [rOpenGov](http://ropengov.github.io/r/2015/06/11/apartment-prices/), and [Louhos](http://louhos.github.io/news/2015/05/07/asuntohintojen-muutokset/). 

Discussion on [Hacker News](https://news.ycombinator.com/item?id=9503580).

Also news coverage at [HS](http://www.hs.fi/kotimaa/a1430886950224), [Tivi](http://www.tivi.fi/Kaikki_uutiset/2015-05-07/Ryhtym%C3%A4ss%C3%A4-asuntokaupoille-Katso-miten-asuntosi-hinta-kehittyy-tulevaisuudessa-3221240.html) and [Helsingin Uutiset](http://www.helsinginuutiset.fi/artikkeli/284968-nain-paljon-asuntosi-maksaa-vuonna-2016-koko-suomen-kattava-ennustepalvelu-aloitti).

## Data sources

Apartment price data for the postal codes is from [Statistics Finland][statfi] open data [API][statfi-api] (see [Terms of Use][statfi-terms]). 
Postal code region names, municipalities and population data is from Statistics Finland [Paavo - Open data by postal code area][paavo]. Postal code area map is from [Duukkis] and licensed under CC BY 4.0.

The data sets are accessed with the [pxweb and [gisfin] package from [rOpenGov]. See the script `source/get_data.R` for details.

[statfi]: http://tilastokeskus.fi/meta/til/ashi.html
[statfi-api]: http://www.stat.fi/org/avoindata/api.html
[statfi-terms]: http://tilastokeskus.fi/org/lainsaadanto/yleiset_kayttoehdot_en.html
[paavo]: http://www.tilastokeskus.fi/tup/paavo/index_en.html
[pxweb]: https://github.com/ropengov/pxweb
[rOpenGov]: http://ropengov.github.io/
[gisfin]: https://github.com/ropengov/gisfin
[Duukkis]: http://www.palomaki.info/apps/pnro/

## Source code

See the `source_2016`-folder for latest source code.


## Statistical model

See description in English in [rOpenGov-blog](http://ropengov.github.io/r/2015/06/11/apartment-prices/) and in Finnish in [Louhos-blog](http://louhos.github.io/news/2015/05/07/asuntohintojen-muutokset/).
