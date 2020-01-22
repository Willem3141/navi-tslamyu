This is a (currently very incomplete!) parser for the Na'vi language.

It uses navi-reykunyu to parse individual words in the input sentence, and then uses a nearley grammar to parse these tokens into a parse tree.

## Usage

* Install [nearley](https://github.com/kach/nearley): `sudo npm install -g nearley`
* Compile the grammar: `nearleyc navi.ne -o navi.js`
* Install [navi-reykunyu](https://github.com/Willem3141/navi-reykunyu) by cloning that repository to the same directory where you cloned navi-tslamyu
* Install the database of Na'vi words [navi-tsim](https://github.com/Willem3141/navi-tsim) by cloning that somewhere, and linking (or copying) the directory `aylì'u` to the `navi-reykunyu` directory.
* Parse a sentence: `node parser.js "<sentence to parse>"`

(Yes, this procedure is ugly. It will be made more streamlined in the future...)

## Supported grammar features

Only a very limited set of grammar features are supported at the moment:

* nouns
    * including conjugated nouns with **fì-/tsa-**, **-fkeyk** and similar affixes
* intransitive verbs
    * subjective
* transitive verbs
    * agentive
    * patientive
    * intransitive usage of transitive verb
* adverbs
* vocatives
* subclauses attached to nouns by **a**

Anything else is unsupported for now, including:

* adjectives
    * predicative usage
    * attributive usage
* verbs with infixes
* **si** verbs
* modal verbs (requiring **<iv>** in the dependent verb)
* pronouns
* negation (**ke** / **rä'ä**)
* dative, genitive, topical
* numbers
* **f**-words
* interjections (**kaltxì**, **wiya**)

Many of these can only be implemented after they are supported in navi-reykunyu first.

