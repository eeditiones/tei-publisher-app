import sys
import spacy
import json

def mapType(label):
    if label == "LOC" or label == "placeName":
        return "place"
    else:
        return "person"

inFile = sys.stdin
lang = sys.argv[1]

model = "en_core_web_sm"

if lang == 'de':
    model = "de_core_news_sm"
elif lang == 'pl':
    model = "pl_core_news_sm"

nlp = spacy.load(model)
doc = nlp(inFile.read())

entities = []
for ent in doc.ents:
    if ent.label_ == 'PER' or ent.label_ == 'LOC' or ent.label_ == 'persName' or ent.label_ == 'placeName':
        entities.append({
            'text': ent.text,
            'type': mapType(ent.label_),
            'start': ent.start_char
        })

output = json.dumps(entities, ensure_ascii=False)

print(output)