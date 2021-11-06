import sys
import spacy.util
import spacy
import json
import argparse
from pathlib import Path

parser = argparse.ArgumentParser(description='Process the input text given on stdin via named entity recognition')
parser.add_argument('--info', help='list class for selected language', action='store_true')
parser.add_argument('--meta', help='get metadata for a model', action='store_true')
parser.add_argument('--model', help='explicitely use the given model', nargs='?', default='en_core_web_sm')
args = parser.parse_args()

if args.info:
    print(json.dumps(spacy.util.get_installed_models(), ensure_ascii=False))
    sys.exit(0)

inFile = sys.stdin

path = Path(args.model)
if path.exists():
    nlp = spacy.load(path, disable=["tok2vec", "tagger", "parser", "attribute_ruler", "lemmatizer"])
else:
    nlp = spacy.load(args.model, disable=["tok2vec", "tagger", "parser", "attribute_ruler", "lemmatizer"])

if args.meta:
    info = {
        "lang": nlp.meta['lang'],
        "components": nlp.meta['components'],
        "labels": nlp.meta['labels']
    }
    print(json.dumps(info, ensure_ascii=False))
    sys.exit(0)

lang = nlp.meta["lang"]
labels = {}
if lang == 'de':
    labels = {
        "PER": "person",
        "LOC": "place",
        "ORG": "organisation"
    }
elif lang == 'en':
    labels = {
        "PERSON": "person",
        "GPE": "place",
        "ORG": "organisation"
    }

try:
    doc = nlp(inFile.read())

    entities = []
    for ent in doc.ents:
        if ent.label_ in labels:
            entities.append({
                'text': ent.text,
                'type': labels[ent.label_],
                'start': ent.start_char
            })

    output = json.dumps(entities, ensure_ascii=False)

    print(output)
except Exception as err:
    print(f"Fehler: {err}")
    sys.exit(1)