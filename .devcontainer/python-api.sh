#!/bin/bash

cd /workspaces/tei-publisher-ner
echo Starting Named Entity Recognition API on port 8001
nohup python3 -m uvicorn main:app --reload --host 0.0.0.0 --port 8001 > ner.log 2>&1 &