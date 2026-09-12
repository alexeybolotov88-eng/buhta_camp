# Kodak Gold analog grade

`retro_film.py` applies one shared analog look to a set of photos.

Kodak Gold (default):

```bash
python3 scripts/retro_film.py photo-a.jpg photo-b.jpg -o output/retro-photos/film-grade
```

Polaroid SX-70, no frame, Instagram 4:5 crop:

```bash
python3 scripts/retro_film.py --look polaroid --no-border --instagram --prefix polaroid \
  -o output/retro-photos/polaroid photo-a.jpg photo-b.jpg
```
