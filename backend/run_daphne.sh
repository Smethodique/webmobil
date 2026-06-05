#!/bin/bash
set -a
source /home/sami/.hermes/.env
set +a
cd /home/sami/mobile_app_fmp/backend
source venv/bin/activate
exec daphne -b 0.0.0.0 -p 8000 fmp_prep.asgi:application
