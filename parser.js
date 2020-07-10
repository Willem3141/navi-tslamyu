const nearley = require('nearley');
const grammar = require('./navi.js');

//const util = require('util');
const fetch = require('node-fetch');
const Inflectors = require("en-inflectors").Inflectors;

const parser = new nearley.Parser(nearley.Grammar.fromCompiled(grammar));

main();

async function main() {
	let input = process.argv[2];
	let responses = await getResponsesFor(input);

	console.log('\x1b[1m\x1b[34mInput:\x1b[0m');
	let tokens = [];
	for (let i = 0; i < responses.length; i++) {
		let response = responses[i];
		let token = {};
		token['value'] = response['tìpawm'];
		if (response['sì\'eyng'].length === 0) {
			error("Word \x1b[1m" + token['value'] + "\x1b[0m not recognized");
			return;
		}

		let types = [];
		for (let j = 0; j < response['sì\'eyng'].length; j++) {
			let type = getGrammarTypeOf(response['sì\'eyng'][j]);
			if (typeof type === "string") {
				types.push(type);
			} else if (type) {
				types = types.concat(type);
			} else {
				warning("Word \x1b[1m" + token['value'] + "\x1b[0m has type '" +
					response['sì\'eyng'][j]['type'] +
					"' that the grammar analyzer doesn't understand yet");
			}
		}
		if (types.length === 0) {
			error("Word \x1b[1m" + token['value'] + "\x1b[0m has no valid types");
			return;
		}

		token['types'] = types;
		token['definition'] = response['sì\'eyng'];
		tokens.push(token);

		console.log('\x1b[1m' + token['value'] + '\x1b[0m (' + token['types'].join(', ') + ')');
	}

	console.log();

	try {
		parser.feed(tokens);
	} catch (e) {
		error("Parse failed at \x1b[1m" + e['token']['value']['value'] +
			"\x1b[0m (word " + (e['offset'] + 1) + ")");
		return;
	}

	//console.log(util.inspect(parser.results, false, null, true));

	function getGrammarTypeOf(word) {
		let t = word['type'];
		let type = null;
		if (t === 'n' || t === 'n:pr' || t === 'pn') {
			let suffix = word['conjugated'][2][5];
			switch (suffix) {
				case '':
					type = 'n_subjective'; break;
				case 'l':
					type = 'n_agentive'; break;
				case 't':
					type = 'n_patientive'; break;
				case 'r':
					type = 'n_dative'; break;
				case 'ä':
					type = 'n_genitive'; break;
				case 'ri':
					type = 'n_topical'; break;
				default:
					//throw new Error('unknown suffix: ' + suffix);
					break;
			}
		}
		if (t === 'v:in') {
			type = 'vin';
		}
		if (t === 'v:tr') {
			// transitive verbs can also be used intransitively
			type = ['vin', 'vtr'];
		}
		if (t === 'v:cp') {
			// copula verbs can also be used intransitively
			type = ['vin', 'vcp'];
		}
		if (t === 'part') {
			if (word['na\'vi'] === 'a') {
				type = ['a_left', 'a_right'];
			} else if (word['na\'vi'] === 'ma') {
				type = 'ma';
			}
		}
		if (t === 'adv') {
			type = 'adv';
		}
		if (t === 'adj') {
			type = 'adj';
		}
		//if (type === '') {
		//	throw new Error('tslamyu doesn\'t understand word type: ' + t);
		//}
		return type;
	}

	console.log('\x1b[1m\x1b[34mParse results:\x1b[0m ' + parser.results.length + ' possible parse tree(s) found');
	for (let i = 0; i < parser.results.length; i++) {
		let result = parser.results[i];
		//console.log(JSON.stringify(result));
		//console.log(JSON.stringify(new VerbClauseTree(result)));
		let tree = new VerbClauseTree(result);
		outputTree(tree);
		console.log(" -> \"" + tree.translate() + "\"");
	}
}

async function getResponsesFor(query) {
	const response = await fetch('https://reykunyu.wimiso.nl/api/fwew?tìpawm=' + query)
		.then(response => response.json())
		.catch(error => {
			throw error;
		});

	return response;
}

function wordToString(word) {
	let result = '\x1b[1m' + word['value'] + '\x1b[0m';

	if (word['definition']) {
		result += ' -> ' + word['definition'][0]['translations'][0]['en'];
	}

	return result;
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

const pronouns = {
	"I": ["me", "my", "am"],
	"you": ["you", "your", "are"],
	"he": ["him", "his", "is"],
	"she": ["her", "her", "is"],
	"he/she": ["him/her", "his/her", "is"],
	"his self": ["himself", "his own", "is"],
	"it": ["it", "its", "is"],
	"we": ["us", "our", "are"],
	"they": ["them", "their", "are"],
}

function VerbClauseTree(clause) {
	this.clause = clause;
	this.word = wordToString(clause['verb']);
	this.children = [];

	if (clause['subjective']) {
		this.subjective = new NounClauseTree(clause['subjective'])
		this.subjective['role'] = 'subjective';
		this.children.push(this.subjective);
	}
	if (clause['agentive']) {
		this.agentive = new NounClauseTree(clause['agentive'])
		this.agentive['role'] = 'agentive';
		this.children.push(this.agentive);
	}
	if (clause['patientive']) {
		this.patientive = new NounClauseTree(clause['patientive'])
		this.patientive['role'] = 'patientive';
		this.children.push(this.patientive);
	}
	if (clause['predicate']) {
		if (clause['predicate']['type'] === 'adjective') {
			this.predicate = new AdjectiveTree(clause['predicate'])
			this.predicate['role'] = 'predicate';
			this.children.push(this.predicate);
		}
	}
	if (clause['adverbials']) {
		this.adverbials = [];
		this.datives = [];
		for (let i = 0; i < clause['adverbials'].length; i++) {
			let adv = clause['adverbials'][i];
			let adverbial;
			if (adv['type'] === 'adverb') {
				adverbial = new AdverbialTree(adv['adverb']);
				adverbial['role'] = 'adverb';
				this.adverbials.push(adverbial);
			} else if (adv['type'] === 'dative') {
				adverbial = new NounClauseTree(adv['dative']);
				adverbial['role'] = 'dative';
				this.datives.push(adverbial);
			}
			this.children.push(adverbial);
		}
	}

	this.translate = function() {

		let subject = [];
		if (this.subjective) {
			subject = [this.subjective.translate()];
		}
		if (this.agentive) {
			subject = [this.agentive.translate()];
		}

		if (subject.length === 0) {
			subject = ['it'];  // TODO hmm
		}

		let object = [];
		if (this.patientive) {
			object = [this.patientive.translate("object")];
		}
		if (this.predicate) {
			object = [this.predicate.translate("object")];
		}

		let verb = getShortTranslation(this.clause['verb']).split(' ');
		if (verb[0] === "be") {
			if (pronouns.hasOwnProperty(subject[0])) {
				verb[0] = pronouns[subject[0]][2];
			} else {
				verb[0] = "is";
			}
		} else {
			let form = "VBZ";  // "walks"
			verb[0] = new Inflectors(verb[0]).conjugate(form);
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

function NounClauseTree(clause) {
	this.clause = clause;
	this.word = wordToString(clause['noun']);
	this.children = [];

	if (clause['subclauses']) {
		this.subclauses = [];
		for (let i = 0; i < clause['subclauses'].length; i++) {
			let sub = clause['subclauses'][i];
			let subclause = new VerbClauseTree(sub);
			subclause['role'] = 'subclause';
			this.subclauses.push(subclause);
			this.children.push(subclause);
		}
	}
	if (clause['possessives']) {
		for (let i = 0; i < clause['possessives'].length; i++) {
			let poss = clause['possessives'][i];
			this.possessive = new NounClauseTree(poss);  // FIXME could have more than one possessive ...
			this.possessive['role'] = 'possessive';
			this.children.push(this.possessive);
		}
	}

	this.translate = function(nounCase) {
		let noun = getShortTranslation(this.clause['noun']);
		let determiner = ["a/the"];
		let possessor = [];
		let subclauses = [];

		// special case: proper nouns
		if (this.clause['noun']['definition'][0]['type'] === "n:pr") {
			noun = this.clause['noun']['definition'][0]['na\'vi'];
			determiner = [];
		}

		if (pronouns.hasOwnProperty(noun)) {
			determiner = [];
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

		if (this.possessive) {
			let possessiveTranslation = this.possessive.translate("possessive");

			if (possessiveTranslation.split(' ').length === 1) {
				determiner = [possessiveTranslation];
			} else {
				possessor = ["of", possessiveTranslation];
			}
		}

		if (this.subclauses) {
			for (let i = 0; i < this.subclauses.length; i++) {
				subclauses = subclauses.concat(["[", "that", this.subclauses[i].translate(), "]"]);
			}
		}

		return determiner.concat([noun]).concat(possessor).concat(subclauses).join(' ');
	}
}

function AdjectiveTree(clause) {
	this.clause = clause;
	this.word = wordToString(clause);
	this.children = [];

	this.translate = function() {
		let translation = getShortTranslation(this.clause);
		return translation;
	}
}

function AdverbialTree(clause) {
	this.clause = clause;
	this.word = wordToString(clause);
	this.children = [];

	this.translate = function() {
		let translation = getShortTranslation(this.clause);
		return translation;
	}
}

function outputTree(tree, prefix1 = '', prefix2 = '') {
	let mainText = '';
	if (tree['role']) {
		mainText += '\x1b[33m' + tree['role'] + ': \x1b[0m';
	}
	mainText += tree['word'];
	console.log(prefix1 + mainText);
	if (tree['children']) {
		let prefixLength = 1;
		if (tree['role']) {
			prefixLength = tree['role'].length + 3;
		}
		for (let i = 0; i < tree['children'].length; i++) {
			if (i === tree['children'].length - 1) {
				outputTree(tree['children'][i],
					prefix2 + spaces(prefixLength) + '└─ ',
					prefix2 + spaces(prefixLength) + '   ');
			} else {
				outputTree(tree['children'][i],
					prefix2 + spaces(prefixLength) + '├─ ',
					prefix2 + spaces(prefixLength) + '│  ');
			}
		}
	}
}

function spaces(n) {
	return Array(n + 1).join(' ');
}

function warning(msg) {
	console.log('Warning: ' + msg);
}

function error(msg) {
	console.log('\x1b[31m\x1b[1mError:\x1b[0m ' + msg);
}

