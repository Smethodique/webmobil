#!/bin/sh
set -e

python manage.py migrate --noinput
python manage.py collectstatic --noinput

exec daphne fmp_prep.asgi:application -b 0.0.0.0 -p 8000
