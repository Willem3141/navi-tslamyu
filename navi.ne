# Na'vi grammar in Nearley format

# Helper functions
@{%

const Inflectors = require("en-inflectors").Inflectors;

function getTranslation(word) {
	if (word['definition']) {
		return word['definition'][0]['translations'][0]['en'];
	}
	return null;
}

function getShortTranslation(word) {
	let result = word['definition'][0];

	if (result["short_translation"]) {
		return result["short_translation"];
	}

	let translation = result["translations"][0]["en"];
	translation = translation.split(',')[0];
	translation = translation.split(';')[0];
	translation = translation.split(' (')[0];

	if (result["type"][0] === "v"
			&& translation.indexOf("to ") === 0) {
		translation = translation.substr(3);
	}

	return translation;
}

// in order:
//  * object form
//  * possessive form
//  * form of "to be" to use for the present tense
//  * form of "to be" to use for the past tense
//  * form of other verbs to use for the present tense
const pronouns = {
	"I": ["me", "my", "am", "was", "VBP"],
	"you": ["you", "your", "are", "were", "VBP"],
	"he": ["him", "his", "is", "was", "VBZ"],
	"she": ["her", "her", "is", "was", "VBZ"],
	"he/she": ["him/her", "his/her", "is", "was", "VBZ"],
	"his self": ["himself", "his own", "is", "was", "VBZ"],
	"it": ["it", "its", "is", "was", "VBZ"],
	"we": ["us", "our", "are", "were", "VBP"],
	"they": ["them", "their", "are", "were", "VBP"],
}

class Tree {
	constructor() {
		this.word = null;
		this.translation = null;
		this.children = [];

		this.penalty = 0;
		this.errors = [];
	}

	penalize(penalty) {
		this.penalty += penalty;
	}

	error(penalty, error) {
		this.penalty += penalty;
		this.errors.push(error);
	}

	getPenalty() {
		let penalty = this.penalty;
		for (let i = 0; i < this.children.length; i++) {
			penalty += this.children[i].getPenalty();
		}
		return penalty;
	}

	getErrors() {
		let errors = [...this.errors];
		for (let i = 0; i < this.children.length; i++) {
			errors = errors.concat(this.children[i].getErrors());
		}
		return errors;
	}
}

class SentenceTree extends Tree {

	constructor(clause) {
		super();

		this.subjective = null;
		this.agentive = null;
		this.patientive = null;
		this.genitive = null;
		this.adverbials = [];
		this.datives = [];

		for (let i = 0; i < clause.length; i++) {
			let part = clause[i];
			if (part['type'] === 'vin' || part['type'] === 'vtr' ||
					part['type'] === 'vcp') {
				this.verbType = part['type'];
				if (this.verb) {
					this.error(1, "two verbs [" + this.verb['value'] +
							"] and [" +
							part['clause']['value'] + "] in the same clause");
				} else {
					this.verb = part['clause'];
				}
			} else {
				if (part['type'] === 'subjective') {
					if (this.subjective) {
						// error: two subjectives (TODO except if vcp)
					} else {
						this.subjective = part['clause'];
					}
				}
				if (part['type'] === 'agentive') {
					if (this.agentive) {
						// error: two agentives
					} else {
						this.agentive = part['clause'];
					}
				}
				if (part['type'] === 'patientive') {
					if (this.patientive) {
						// error: two patientives
					} else {
						this.patientive = part['clause'];
					}
				}
				if (part['type'] === 'dative') {
					this.datives.push(part['clause']);
				}
				if (part['type'] === 'genitive') {
					if (this.genitive) {
						// error: two genitives
					} else {
						this.genitive = part['clause'];
					}
				}
				if (part['type'] === 'adverbial') {
					this.adverbials.push(part['clause']);
				}
				this.children.push(part['clause']);
			}
		}

		if (this.verb) {
			this.word = this.verb['value'];
			this.translation = getTranslation(this.verb);
		}

		// handle errors
		if (!this.verb) {
			this.penalize(0.1);
		}
		if (this.verbType === "vin") {
			if (this.agentive) {
				this.error(1, "Agentive [" + this.agentive['word'] +
						"] cannot be used with intransitive verb [" +
						this.verb['value'] + "]");
			} else if (this.patientive) {
				this.error(1, "Patientive [" + this.patientive['word'] +
						"] cannot be used with intransitive verb [" +
						this.verb['value'] + "]");
			}
		}
		if (this.verbType === "vtr") {
			if (this.subjective) {
				this.error(1, "Subjective [" + this.subjective['word'] +
						"] cannot be used with transitive verb [" +
						this.verb['value'] + "]");
			}
		}
		if (this.genitive) {
			if (this.verbType === "vin" || this.verbType === "vtr") {
				this.error(2, "Genitive [" + this.genitive['word'] +
						"] does not belong to anything");
			} else {
				// these "lu oeyä" constructions are rather rare
				this.penalize(0.1);
			}
		}
	}

	translate() {

		let subject = [];
		if (this.subjective) {
			subject = [this.subjective.translate()];
		}
		if (this.agentive) {
			subject = [this.agentive.translate()];
		}

		if (subject.length === 0) {
			subject = ['(something)'];
		}

		let object = [];
		if (this.patientive) {
			object = [this.patientive.translate("object")];
		}
		if (this.predicate) {
			object = [this.predicate.translate("object")];
		}
		if (this.genitive) {
			object = [this.genitive.translate("possessive")];
		}

		let verb = ["(verb omitted)"];
		if (this.verb) {
			verb = getShortTranslation(this.verb).split(' ');
			if (verb[0] === "be") {
				verb[0] = "is";
				if (pronouns.hasOwnProperty(subject[0])) {
					verb[0] = pronouns[subject[0]][2];
				}
			} else {
				let form = "VBZ";
				if (pronouns.hasOwnProperty(subject[0])) {
					form = pronouns[subject[0]][4];
				}
				verb[0] = new Inflectors(verb[0]).conjugate(form);
			}
		} else {
			if (this.subjective
					&& !this.agentive && !this.patientive && !this.topical
					&& (this.genitive || this.predicate || this.datives.length > 0)) {
				verb[0] = "is";
				if (pronouns.hasOwnProperty(subject[0])) {
					verb[0] = pronouns[subject[0]][2];
				}
			}
		}

		let adverbials = [];
		if (this.adverbials) {
			for (let i = 0; i < this.adverbials.length; i++) {
				let adv = this.adverbials[i];
				adverbials = adverbials.concat([adv.translate()]);
			}
		}
		if (this.datives) {
			for (let i = 0; i < this.datives.length; i++) {
				let dative = this.datives[i];
				adverbials = adverbials.concat(['to', dative.translate('object')]);
			}
		}
		return subject.concat(verb).concat(object).concat(adverbials).join(' ');
	}
}

class NounClauseTree extends Tree {

	constructor(clause) {
		super();
		this.clause = clause;
		this.word = this.clause['noun']['value'];
		this.translation = getTranslation(this.clause['noun']);

		if (this.clause['subclauses']) {
			this.subclauses = [];
			for (let i = 0; i < this.clause['subclauses'].length; i++) {
				let sub = this.clause['subclauses'][i];
				let subclause = sub;
				subclause['role'] = 'subclause';
				this.subclauses.push(subclause);
				this.children.push(subclause);
			}
		}
		if (this.clause['possessives']) {
			for (let i = 0; i < this.clause['possessives'].length; i++) {
				let poss = this.clause['possessives'][i];
				this.possessive = poss;
				this.possessive['role'] = 'possessive';
				this.children.push(this.possessive);
			}
		}
	}

	translate(nounCase) {
		let noun = getShortTranslation(this.clause['noun']);
		let determiner = ["a/the"];
		let possessor = [];
		let subclauses = [];
		let definition = this.clause['noun']['definition'][0];

		// special case: proper nouns
		if (definition['type'] === "n:pr") {
			noun = this.clause['noun']['definition'][0]['na\'vi'];
			determiner = [];
		}

		// special case: pronouns
		if (pronouns.hasOwnProperty(noun) || noun === "this" || noun === "that") {
			determiner = [];
		}
		if (pronouns.hasOwnProperty(noun)) {
			if (nounCase === "object") {
				noun = pronouns[noun][0];
			} else if (nounCase === "possessive") {
				noun = pronouns[noun][1];
			}
		} else {
			if (nounCase === "possessive") {
				noun += "'s";
			}
		}

		// handle affixes
		let plural = false;
		let postNoun = [];
		switch (definition['conjugated'][2][1]) {
			case 'me':
				plural = true;
				determiner = ['two'];
				break;
			case 'pxe':
				plural = true;
				determiner = ['three'];
				break;
			case 'ay':
			case '(ay)':
				plural = true;
				determiner = [];
				break;
		}
		switch (definition['conjugated'][2][0]) {
			case 'fì':
				determiner = ['this'];
				break;
			case 'tsa':
				determiner = ['that'];
				break;
			case 'pe':
				determiner = ['which'];
				break;
			case 'fra':
				determiner = ['every'];
				break;
		}
		switch (definition['conjugated'][2][4]) {
			case 'pe':
				determiner = ['which'];
				break;
			case 'o':
				determiner = ['some'];
				break;
		}
		switch (definition['conjugated'][2][3]) {
			case 'tsyìp':
				noun = "little " + noun;
				break;
			case 'fkeyk':
				postNoun = ['of ' + noun];
				noun = 'state';
				break;
		}
		switch (definition['conjugated'][2][2]) {
			case 'fne':
				postNoun = ['of ' + noun];
				noun = 'type';
				break;
		}
		if (plural) {
			noun = new Inflectors(noun).toPlural();
		}

		// handle possessives attached to this noun
		if (this.possessive) {
			let possessiveTranslation = this.possessive.translate("object");

			if (possessiveTranslation.split(' ').length === 1) {
				determiner = [this.possessive.translate("possessive")];
			} else {
				possessor = ["of", possessiveTranslation];
			}
		}

		if (this.subclauses) {
			for (let i = 0; i < this.subclauses.length; i++) {
				subclauses = subclauses.concat(["that", this.subclauses[i].translate()]);
			}
		}

		return determiner.concat([noun]).concat(postNoun)
				.concat(possessor).concat(subclauses).join(' ');
	}
}

class AdjectiveTree extends Tree {

	constructor(clause) {
		super();
		this.clause = clause;
		this.word = this.clause['value'];
		this.translation = getTranslation(this.clause);
	}

	translate() {
		let translation = getShortTranslation(this.clause);
		return translation;
	}
}

class AdverbialTree extends Tree {

	constructor(clause) {
		super();
		this.clause = clause;
		this.word = this.clause['value'];
		this.translation = getTranslation(this.clause);
	}

	translate() {
		let translation = getShortTranslation(this.clause);
		return translation;
	}
}

function makeTester(name) {
	return {
		'test': x => x['types'].includes(name)
	};
}

const n_subjective = makeTester('n_subjective');
const n_agentive = makeTester('n_agentive');
const n_patientive = makeTester('n_patientive');
const n_dative = makeTester('n_dative');
const n_genitive = makeTester('n_genitive');
const n_topical = makeTester('n_topical');

const vin = makeTester('vin');
const vtr = makeTester('vtr');
const vcp = makeTester('vcp');

const adj = makeTester('adj');
const adj_left = makeTester('adj_left');
const adj_right = makeTester('adj_right');

const adv = makeTester('adv');

const a_left = makeTester('a_left');
const a_right = makeTester('a_right');
const ma = makeTester('ma');

let processSentence = function (data) {
	return new SentenceTree(data[0]);
}

let processNounClause = function (data) {
	let result = {
		'noun' : data[3]
	};
	let adjs = [];
	if (data[2]) {
		adjs = adjs.concat([data[2]]);
	}
	if (data[4]) {
		adjs = adjs.concat([data[4]]);
	}
	if (adjs.length > 0) {
		result['adjectives'] = adjs;
	}
	let subs = [];
	if (data[1]) {
		subs = subs.concat([data[1][0]]);
	}
	if (data[5]) {
		subs = subs.concat([data[5][1]]);
	}
	if (subs.length > 0) {
		result['subclauses'] = subs;
	}
	let possessives = [];
	if (data[0]) {
		possessives = possessives.concat([data[0][0]]);
	}
	if (data[6]) {
		possessives = possessives.concat([data[6][0]]);
	}
	if (possessives.length > 0) {
		result['possessives'] = possessives;
	}
	return new NounClauseTree(result);
};
%}


### SENTENCE PARTS ###

sentence -> sentence_part:+ {% processSentence %}

sentence_part -> v_clause {% id %}

sentence_part -> n_clause_subjective {% (data) => ({'type': 'subjective', 'clause': data[0]}) %}
sentence_part -> n_clause_agentive {% (data) => ({'type': 'agentive', 'clause': data[0]}) %}
sentence_part -> n_clause_patientive {% (data) => ({'type': 'patientive', 'clause': data[0]}) %}
sentence_part -> n_clause_dative {% (data) => ({'type': 'dative', 'clause': data[0]}) %}
sentence_part -> n_clause_genitive {% (data) => ({'type': 'genitive', 'clause': data[0]}) %}
sentence_part -> n_clause_topical {% (data) => ({'type': 'topical', 'clause': data[0]}) %}

sentence_part -> adverbial {% id %}

### VERB CLAUSES ###

v_clause -> verb {% id %}

verb -> %vin {% (data) => ({'type': 'vin', 'clause': data[0]}) %}
verb -> %vtr {% (data) => ({'type': 'vtr', 'clause': data[0]}) %}
verb -> %vcp {% (data) => ({'type': 'vcp', 'clause': data[0]}) %}

### NOUN CLAUSES ###

n_clause_subjective ->
	(n_clause_genitive):?
	(sentence %a_left):?
	%adj_left:? %n_subjective %adj_right:?
	(%a_right sentence):?
	(n_clause_genitive):?
	{% processNounClause %}

n_clause_agentive ->
	(n_clause_genitive):?
	(sentence %a_left):?
	%adj_left:? %n_agentive %adj_right:?
	(%a_right sentence):?
	(n_clause_genitive):?
	{% processNounClause %}

n_clause_patientive ->
	(n_clause_genitive):?
	(sentence %a_left):?
	%adj_left:? %n_patientive %adj_right:?
	(%a_right sentence):?
	(n_clause_genitive):?
	{% processNounClause %}

n_clause_dative ->
	(n_clause_genitive):?
	(sentence %a_left):?
	%adj_left:? %n_dative %adj_right:?
	(%a_right sentence):?
	(n_clause_genitive):?
	{% processNounClause %}

n_clause_genitive ->
	(n_clause_genitive):?
	(sentence %a_left):?
	%adj_left:? %n_genitive %adj_right:?
	(%a_right sentence):?
	(n_clause_genitive):?
	{% processNounClause %}

n_clause_topical ->
	(n_clause_genitive):?
	(sentence %a_left):?
	%adj_left:? %n_topical %adj_right:?
	(%a_right sentence):?
	(n_clause_genitive):?
	{% processNounClause %}


### OTHERS ###

adverbial -> %adv {%
	function (data) {
		return {
			'type': 'adverbial',
			'clause': new AdverbialTree(data[0])
		};
	}
%}

