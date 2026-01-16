#!/bin/bash

cd /workspaces/tei-publisher-ner
echo Starting Named Entity Recognition API on port 8001
gunicorn scripts.main:app -w 2 -k uvicorn.workers.UvicornH11Worker -b 0.0.0.0:8001 --daemon