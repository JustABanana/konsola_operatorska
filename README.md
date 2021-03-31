# Projekt na konkurs motorola science cup.
Projekt napisaliśmy w języku D korzystając z GTK4 oraz bindingów GTKD(przy okazji mieliśmy własny wkład w rozwój tego projektu :p [link 1](https://github.com/gtkd-developers/gir-to-d/commit/fa68183af917b6cd721600a075648a4cddaa8937), [link 2](https://github.com/gtkd-developers/GtkD/issues/326))

Zaczeliśmy pracę nad projektem około miesiąc przed końcem czasu, kiedy zorientowaliśmy się że nie zdążymy zrobić żyrafy, z tego miesiąca większość czasu spędziliśmy grając w don't strave together więc większa część projektu została napisana w tydzień przed końcem czasu

## Uruchamianie

Projekt działa tylko na linuxie, chociaż stworzenie porta windowsowego nie powinno wymagać zbyt dużego wysiłku.

Ponieważ używamy gtk4 które nie jest jeszcze pakowane dla większośći dystrybucji polecamy skorzystanie z naszego obrazu w dockerze, bazującego na fedorze do kompilacji i uruchamiania. W przyszłości kiedy gtk4 będzie dostępne na innych linuxach nie powinno to już być wymagane.

### Docker

```
git clone 'https://github.com/JustABanana/konsola_operatorska'
cd konsola_operatorska
docker build -t konsola_operatorska .

docker run --rm \
-e DISPLAY=$DISPLAY \
-v /tmp/.X11-unix:/tmp/.X11-unix:rw \
--ipc=host \
-v $PWD:/PWD \
--user $(id -u):$(id -g) \
-it \
--name konsola \
konsola_operatorska bash

cd /PWD
# Przez buga w D pierwsza kompilacja zawsze zawodzi, ponieważ pliki bindingów z gir są dopiero generowane już po kompilacji
dub build -v 
dub build

./konsola_operatorska
```

### Inne systemy

Wymagene biblioteki: gtk4 i [libshumate](https://wiki.gnome.org/Projects/libshumate)
Kompilacja:
```
dub build -v
dub build
```
komenda musi zostać uruchomiona dwa razy z powodu buga w dub

## Dokumentacja
Używamy generatora dokumentacji [adrdox](https://github.com/adamdruppe/adrdox)

Do generowania dokumentacji służy komenda
```
dub run adrdox -- .
```
