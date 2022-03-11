#!/bin/sh

echo "Apply database migrations"
./bin/python manage.py migrate

echo "Starting server"
./bin/python manage.py runserver 0.0.0.0:8000