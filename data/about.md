# Markdown Content

Files in the data collection which end with `.md` will be rendered as markdown. By default this uses the HTML template `templates/pages/markdown.html`, which you can change as you like.

Markdown is rendered on the client side using [marked](https://marked.js.org/).

## Paragraphs

Lorem ipsum dolor sit amet, **consectetur adipiscing** elit. Aenean ac metus ipsum. Curabitur molestie, nunc id molestie feugiat, odio justo sagittis turpis, vel rhoncus erat arcu id sem. *Morbi tincidunt aliquam* libero, ullamcorper molestie enim ornare at. Etiam vitae ligula quis ~justo tincidunt pharetra~. Donec et turpis ipsum. `Pellentesque` semper ligula vitae ipsum aliquam, eu blandit massa porta. Praesent porta orci eu lorem varius ullamcorper. Mauris imperdiet nunc id ipsum tincidunt dignissim. Fusce rhoncus varius turpis, et lacinia purus tempor quis.

## Lists

1. do this first
2. then do the following
   * think about what you don't want to do
   * take a break

## Embedded code

```xml
<opener>
    <dateline>
        <date when="1957-11-15">November 15, 1957</date>
    </dateline>
    <salute> Dearest <name ref="#GravesWilliam" type="person"><abbr>Wm</abbr></name>: </salute>
</opener>
```

## Images

![embedded image](playground.png)

## Quotes

> Good luck in your interview. If you are wholly at your ease - and why not? - all will go well. 
> But try to raise some sort of enthusiasm for your proposed career: dont-care-ism doesn't go down well.

## Tables

| Tables   |      Are      |  Cool |
|----------|:-------------:|------:|
| col 1 is |  left-aligned | $1600 |
| col 2 is |    centered   |   $12 |
| col 3 is | right-aligned |    $1 |