#!/bin/bash

cd /workspaces/tei-publisher-ner
echo Starting Named Entity Recognition API on port 8001
nohup python3 -m spacy project run serve > ner.log 2>&1 &