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
		this.roles = [];

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

		this.verb = null;
		this.verbType = "vcp";  // by default, assume omitted "lu"
		this.verbRest = [];

		this.subjective = null;
		this.predicate = null;
		this.predicateType = null;
		this.agentive = null;
		this.patientive = null;
		this.genitive = null;
		this.adverbials = [];
		this.datives = [];

		// first find the verb and its type
		let lastVerbSeen = this;  // where we'll attach more verbs
		let hasModal = false;
		let needToAddSi = false;
		for (let i = 0; i < clause.length; i++) {
			let part = clause[i];
			if (part.type === 'vin' || part.type === 'vtr' ||
					part.type === 'vcp' || part.type === 'vm' ||
					part.type === 'vsi') {
				if (this.verb) {
					if (this.verbType !== "vm") {
						this.error(1, "The two verbs [" + this.verb.value +
								"] and [" +
								part.clause.value + "] cannot be in the same clause");
					} else {
						// TODO make sure this thing has <iv>
						hasModal = true;
						this.verbRest.push((part.type === 'vsi') ? part.siComplement : part.clause);
						let newVerb = new VerbTree((part.type === 'vsi') ?
								part.siComplement : part.clause);
						lastVerbSeen.children.push(newVerb);
						lastVerbSeen.roles.push('dependent verb');
						lastVerbSeen = newVerb;
					}
				} else {
					this.verb = (part.type === 'vsi') ? part.siComplement : part.clause;
					if (part.negation) {
						this.negation = part.negation;
						this.children.push(this.negation);
						this.roles.push('negation');
					}
				}
				this.verbType = part.type;
				if (this.verbType === 'vsi') {
					this.verbType = 'vin';
				}
			}
		}

		// now collect the other parts of the sentence
		for (let i = 0; i < clause.length; i++) {
			let part = clause[i];
			if (part['type'] !== 'vin' && part['type'] !== 'vtr' &&
					part['type'] !== 'vcp' && part['type'] !== 'vm' &&
					part['type'] !== 'vsi') {
				let role = null;
				if (part['type'] === 'subjective') {
					if (!this.subjective &&
							(!this.verbType !== "vtr")) {
						this.subjective = part['clause'];
						role = 'subjective';
					} else if (!this.predicate && this.verbType === "vcp") {
						this.predicate = part['clause'];
						role = 'predicate';
						this.predicateType = 'noun';
					} else if (this.verbType === "vin") {
						this.error(1, "The two subjectives [" +
								this.subjective.word +
								"] and [" + part.clause.word +
								"] cannot be in the same clause");
					} else if (this.verb) {
						this.error(1, "Subjective [" + part.clause.word +
								"] cannot be used with transitive verb [" +
								this.verb['value'] + "]");
					}
				}
				if (part['type'] === 'agentive') {
					if (this.verb && this.verbType !== "vtr") {
						this.error(1, "Agentive [" + part.clause.word +
								"] cannot be used with intransitive verb [" +
								mainVerb['value'] + "]");
					} else if (this.agentive) {
						this.error(1, "The two agentives [" +
								this.agentive.word +
								"] and [" + part.clause.word +
								"] cannot be in the same clause");
					} else if (this.subjective) {
						this.error(1, "The agentive [" +
								part.clause.word +
								"] cannot go together with the subjective [" +
								this.subjective.word +
								"] in the same clause");
					} else {
						this.agentive = part['clause'];
						role = 'agentive';
					}
				}
				if (part['type'] === 'patientive') {
					if (this.verb && this.verbType !== "vtr") {
						this.error(1, "Patientive [" + part.clause.word +
								"] cannot be used with intransitive verb [" +
								this.verb['value'] + "]");
					} else if (this.patientive) {
						this.error(1, "The two patientives [" +
								this.patientive.word +
								"] and [" + part.clause.word +
								"] cannot be in the same clause");
					} else if (this.subjective && !hasModal) {
						this.error(1, "The patientive [" +
								part.clause.word +
								"] cannot go together with the subjective [" +
								this.subjective.word +
								"] in the same clause");
					} else {
						this.patientive = part['clause'];
						role = 'patientive';
					}
				}
				if (part['type'] === 'dative') {
					this.datives.push(part['clause']);
					role = 'dative';
				}
				if (part['type'] === 'genitive') {
					if (!this.predicate && this.verbType === "vcp") {
						this.predicate = part['clause'];
						role = 'predicate';
						this.predicateType = 'genitive';
					} else {
						this.error(1, "Genitive [" +
								part.clause.word +
								"] does not belong to any noun");
					}
				}
				if (part['type'] === 'adjective') {
					if (!this.predicate && this.verbType === "vcp") {
						this.predicate = part['clause'];
						role = 'predicate';
						this.predicateType = 'adjective';
					} else if (this.verbType === "vcp") {
						if (role === "predicate (genitive)") {
							this.error(1, "Genitive [" +
									this.predicate.word +
									"] does not connect to any noun");
						} else {
							this.error(1, "The words [" +
									this.predicate.word +
									"] and [" +
									part.clause.word +
									"] cannot both be predicates in the same clause");
						}
					} else {
						this.error(1, "Adjective [" +
								part.clause.word +
								"] cannot be used predicatively with a non-copula " +
								"verb (did you mean to use an adverb instead?)");
					}
				}
				if (part['type'] === 'adverbial') {
					this.adverbials.push(part['clause']);
					role = 'adverbial';
				}
				
				if (role) {
					// special case: put most elements on the main verb
					if ((role !== 'subjective' && role !== 'agentive')
							&& this.verbRest.length > 0) {
						lastVerbSeen.children.push(part['clause']);
						lastVerbSeen.roles.push(role);
					} else {
						this.children.push(part['clause']);
						this.roles.push(role);
					}
				}
			}
		}

		if (this.verb) {
			this.word = this.verb['value'];
			this.translation = getTranslation(this.verb);
		}

		// Special penalties:

		// omitting a verb is rare and should be avoided
		if (!this.verb) {
			this.penalize(0.1);
		}

		// slight penalty for intransitive verb usage, because if both
		// transitive and intransitive usages of a verb are possible we don't
		// want to show both separately
		if (this.verbType === "vin") {
			this.penalize(0.001);
		}
	}

	translate() {

		let subject = [];
		let subjectPlural = false;
		if (this.subjective) {
			subject = [this.subjective.translate()];
			subjectPlural = this.subjective.isPlural();
		}
		if (this.agentive) {
			subject = [this.agentive.translate()];
			subjectPlural = this.agentive.isPlural();
		}

		if (subject.length === 0) {
			subject = ['(something)'];
		}

		let object = [];
		if (this.patientive) {
			object = [this.patientive.translate("object")];
		}
		if (this.predicate) {
			if (this.predicateType === "genitive") {
				object = ['of', this.predicate.translate("object")];
			} else {
				object = [this.predicate.translate("object")];
			}
		}

		let verb = ["(verb omitted)"];
		if (this.verb) {
			verb = getShortTranslation(this.verb).split(' ');

			if (verb[0] === "be") {
				if (this.negation) {
					verb = ['be', 'not'].concat(verb.splice(1));
				}
				verb[0] = subjectPlural ? "are" : "is";
				if (pronouns.hasOwnProperty(subject[0])) {
					verb[0] = pronouns[subject[0]][2];
				}
			} else {
				if (this.negation) {
					if (verb[0] === "can" || verb[0] === "will") {
						verb = [verb[0], 'not'].concat(verb.splice(1));
					} else {
						verb = ['do', 'not'].concat(verb);
					}
				}
				let form = subjectPlural ? "VBP" : "VBZ";
				if (pronouns.hasOwnProperty(subject[0])) {
					form = pronouns[subject[0]][4];
				}
				verb[0] = new Inflectors(verb[0]).conjugate(form);
			}
		} else {
			if (this.subjective
					&& !this.agentive && !this.patientive && !this.topical
					&& (this.genitive || this.predicate || this.datives.length > 0)) {
				verb[0] = subjectPlural ? "are" : "is";
				if (pronouns.hasOwnProperty(subject[0])) {
					verb[0] = pronouns[subject[0]][2];
				}
			}
		}

		for (let i = 0; i < this.verbRest.length; i++) {
			verb.push(getShortTranslation(this.verbRest[i]));
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

		if (this.clause['adjectives']) {
			this.adjectives = [];
			for (let i = 0; i < this.clause['adjectives'].length; i++) {
				let adjective = this.clause['adjectives'][i];
				this.adjectives.push(adjective);
				this.children.push(adjective);
				this.roles.push('adjective');
			}
		}

		if (this.clause['subclauses']) {
			this.subclauses = [];
			for (let i = 0; i < this.clause['subclauses'].length; i++) {
				let subclause = this.clause['subclauses'][i];
				this.subclauses.push(subclause);
				this.children.push(subclause);
				this.roles.push('subclause');
			}
		}
		if (this.clause['possessives']) {
			for (let i = 0; i < this.clause['possessives'].length; i++) {
				this.possessive = this.clause['possessives'][i];
				this.children.push(this.possessive);
				this.roles.push('possessive');
			}
		}
	}

	isPlural() {
		let definition = this.clause['noun']['definition'][0];
		let prefix = definition['conjugated'][2][1];
		return prefix !== "";
	}

	translate(nounCase) {
		let noun = getShortTranslation(this.clause['noun']);
		let determiner = ["a/the"];
		let possessor = [];
		let adjectives = [];
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
		let plural = this.isPlural();
		let postNoun = [];
		switch (definition['conjugated'][2][1]) {
			case 'me':
				determiner = ['two'];
				break;
			case 'pxe':
				determiner = ['three'];
				break;
			case 'ay':
			case '(ay)':
				determiner = [];
				break;
		}
		switch (definition['conjugated'][2][0]) {
			case 'fì':
				determiner = [plural ? 'these' : 'this'];
				break;
			case 'tsa':
				determiner = [plural ? 'those' : 'that'];
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

		if (this.adjectives) {
			for (let i = 0; i < this.adjectives.length; i++) {
				adjectives = adjectives.concat([this.adjectives[i].translate()]);
			}
		}

		if (this.subclauses) {
			for (let i = 0; i < this.subclauses.length; i++) {
				subclauses = subclauses.concat(["that", this.subclauses[i].translate()]);
			}
		}

		return determiner.concat(adjectives).concat([noun]).concat(postNoun)
				.concat(possessor).concat(subclauses).join(' ');
	}
}

class AdpositionClauseTree extends Tree {

	constructor(adposition, nounClause) {
		super();
		this.clause = adposition;
		this.word = this.clause['value'];
		this.translation = getTranslation(adposition);
		this.nounClause = nounClause;
		this.roles.push('noun');
		this.children.push(nounClause);
	}

	translate() {
		let translation = [getShortTranslation(this.clause)];
		translation.push(this.nounClause.translate("object"));
		return translation.join(' ');
	}
}

class VerbTree extends Tree {

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

class ParticleTree extends Tree {

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
const nsi = makeTester('nsi');

const vin = makeTester('vin');
const vtr = makeTester('vtr');
const vcp = makeTester('vcp');
const vm = makeTester('vm');
const vsi = makeTester('vsi');

const adj = makeTester('adj');
const adj_left = makeTester('adj_left');
const adj_right = makeTester('adj_right');

const adv = makeTester('adv');

const adp = makeTester('adp');

const a_left = makeTester('a_left');
const a_right = makeTester('a_right');
const ma = makeTester('ma');
const ke = makeTester('ke');

let processSentence = function (data) {
	return new SentenceTree(data[0]);
}

let processNounClause = function (data) {
	let result = {
		'noun' : data[3]
	};
	let adjs = [];
	if (data[2]) {
		adjs = adjs.concat([new AdjectiveTree(data[2])]);
	}
	if (data[4]) {
		adjs = adjs.concat([new AdjectiveTree(data[4])]);
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

let processParticle = function (data) {
	return new ParticleTree(data[0]);
}
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

sentence_part -> %adj {% (data) => ({'type': 'adjective', 'clause': new AdjectiveTree(data[0])}) %}

sentence_part -> adverbial {% id %}


### VERB CLAUSES ###

v_clause -> negation:? verb {% (data) => ({
	'type': data[1]['type'],
	'clause': data[1]['clause'],
	'siComplement': data[1]['siComplement'],
	'negation': data[0]
}) %}

negation -> %ke {% processParticle %}

verb -> %vin {% (data) => ({'type': 'vin', 'clause': data[0]}) %}
verb -> %vtr {% (data) => ({'type': 'vtr', 'clause': data[0]}) %}
verb -> %vcp {% (data) => ({'type': 'vcp', 'clause': data[0]}) %}
verb -> %vm {% (data) => ({'type': 'vm', 'clause': data[0]}) %}
verb -> %nsi %vsi {% (data) => ({'type': 'vsi', 'clause': data[1], 'siComplement': data[0]}) %}


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

nsi ->
	%n_subjective {% id %}


### ADVERBIALS ###

adverbial -> %adv {%
	function (data) {
		return {
			'type': 'adverbial',
			'clause': new AdverbialTree(data[0])
		};
	}
%}

adverbial -> %adp n_clause_subjective {%
	function (data) {
		return {
			'type': 'adverbial',
			'clause': new AdpositionClauseTree(data[0], data[1])
		};
	}
%}

