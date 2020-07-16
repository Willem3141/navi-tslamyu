This is a (currently very incomplete!) parser for the Na'vi language.

It uses Reykunyu's API (at https://reykunyu.wimiso.nl) to parse individual words in the input sentence, and then uses a nearley grammar to parse these tokens into a parse tree.

## Usage

* Install [nearley](https://github.com/kach/nearley): `sudo npm install -g nearley`
* Compile the grammar: `nearleyc navi.ne -o navi.js`
* Parse a sentence: `node runParser.js "<sentence to parse>"` (or use it programmatically: `tslamyu.doParse(...)`)

## Supported grammar features

Only a very limited set of grammar features are supported at the moment:

* nouns
    * including conjugated nouns with **fì-/tsa-**, **-fkeyk** and similar affixes
    * subclauses attached to nouns by **a**
    * genitive attached to nouns
* pronouns
* intransitive verbs
    * subjective
* transitive verbs
    * agentive
    * patientive
    * intransitive usage of transitive verb
* copula verbs
    * with adjectives or nouns as the predicate
* modal verbs (to do: require **<iv>** in the dependent verb)
* **si** verbs
* adjectives
    * predicative usage
    * attributive usage
* adverbials
    * adverbs
    * dative
    * adpositions
* negation (**ke** / **rä'ä**)

Anything else is unsupported for now, including:

* adverbials
    * adpositions attached to a noun
    * vocatives
* topical
* numbers
* **f**-words
    * also **taluna**, **krra**, etc.
* interjections (**kaltxì**, **wiya**)
* **san** / **sìk**
* **fte** and **tsnì** phrases
* verb infixes
    * especially **<eyk>** and **<äp>** don't change transitivity yet

Many of these can only be implemented after they are supported in navi-reykunyu first.

