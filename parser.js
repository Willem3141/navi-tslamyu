const nearley = require('nearley');
const grammar = require('./navi.js');
const util = require('util');

const fetch = require('node-fetch');

const parser = new nearley.Parser(nearley.Grammar.fromCompiled(grammar));

main();

async function main() {
	let input = process.argv[2];
	let responses = await getResponsesFor(input);
	let tokens = [];
	for (let i = 0; i < responses.length; i++) {
		let response = responses[i];
		let token = {};
		token['value'] = response['tìpawm'];
		let types = [];
		for (let j = 0; j < response['sì\'eyng'].length; j++) {
			let type = getGrammarTypeOf(response['sì\'eyng'][j]);
			if (typeof type === "string") {
				types.push(type);
			} else if (type) {
				types = types.concat(type);
			}
		}
		token['types'] = types;
		token['definition'] = response['sì\'eyng'];
		tokens.push(token);
	}

	console.log('\x1b[1m\x1b[34mInput:\x1b[0m');
	for (let i = 0; i < tokens.length; i++) {
		let token = tokens[i];
		console.log('\x1b[1m' + token['value'] + '\x1b[0m (' + token['types'].join(', ') + ')');
	}

	/*let inputTokens = [
		{'value': 'nìngay', 'types': ['adv']},
		{'value': 'rey', 'types': ['vin']},
		{'value': 'po', 'types': ['n_subjective']},
		{'value': 'a', 'types': ['a_left', 'a_right']},
		{'value': 'tute', 'types': ['n_subjective']},
		{'value': 'apxa', 'types': ['adj', 'adj_left', 'adj_right']},
		{'value': 'tul', 'types': ['vin']}
	];*/
	/*let input = [
		{'value': 'taronyul', 'types': ['n_agentive']},
		{'value': 'apxa', 'types': ['adj', 'adj_left', 'adj_right']},
		{'value': 'ioangit', 'types': ['n_patientive']},
		{'value': 'taron', 'types': ['vtr']}
	];*/
	parser.feed(tokens);

	//console.log(util.inspect(parser.results, false, null, true));

	function getGrammarTypeOf(word) {
		let t = word['type'];
		let type = null;
		if (t === 'n' || t === 'pn') {
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
			type = ['vin', 'vtr'];
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
		//if (type === '') {
		//	throw new Error('tslamyu doesn\'t understand word type: ' + t);
		//}
		return type;
	}

	console.log();
	console.log('\x1b[1m\x1b[34mParse results:\x1b[0m ' + parser.results.length + ' possible parse tree(s) found');
	for (let i = 0; i < parser.results.length; i++) {
		let result = parser.results[i];
		//console.log(JSON.stringify(result));
		//console.log(JSON.stringify(verbClauseToTree(result)));
		outputTree(verbClauseToTree(result));
	}
}

async function getResponsesFor(query) {
	const response = await fetch('https://reykunyu.wimiso.nl/api/fwew?tìpawm=' + query)
		.then(response => response.json())
		.catch(error => {
			message.channel.send("Something went wrong while searching. Please try again later, or ping Wllìm if this problem persists.")
			return;
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

function verbClauseToTree(clause) {
	let result = {
		'word': wordToString(clause['verb']),
		'children': []
	};
	if (clause['subjective']) {
		let subjective = nounClauseToTree(clause['subjective'])
		subjective['role'] = 'subjective';
		result['children'].push(subjective);
	}
	if (clause['agentive']) {
		let agentive = nounClauseToTree(clause['agentive'])
		agentive['role'] = 'agentive';
		result['children'].push(agentive);
	}
	if (clause['patientive']) {
		let patientive = nounClauseToTree(clause['patientive'])
		patientive['role'] = 'patientive';
		result['children'].push(patientive);
	}
	if (clause['adverbials']) {
		for (let i = 0; i < clause['adverbials'].length; i++) {
			let adv = clause['adverbials'][i];
			let adverbial;
			if (adv['type'] === 'adverb') {
				adverbial = adverbialToTree(adv['adverb']);
				adverbial['role'] = 'adverb';
			} else if (adv['type'] === 'vocative') {
				adverbial = nounClauseToTree(adv['noun']);
				adverbial['role'] = 'vocative';
			}
			result['children'].push(adverbial);
		}
	}
	return result;
}

function nounClauseToTree(clause) {
	let result = {
		'word': wordToString(clause['noun']),
		'children': []
	};
	if (clause['subclauses']) {
		for (let i = 0; i < clause['subclauses'].length; i++) {
			let sub = clause['subclauses'][i];
			let subclause = verbClauseToTree(sub);
			subclause['role'] = 'subclause';
			result['children'].push(subclause);
		}
	}
	if (clause['possessives']) {
		for (let i = 0; i < clause['possessives'].length; i++) {
			let poss = clause['possessives'][i];
			let possessive = nounClauseToTree(poss);
			possessive['role'] = 'possessive';
			result['children'].push(possessive);
		}
	}
	return result;
}

function adverbialToTree(clause) {
	let result = {
		'word': wordToString(clause),
		'children': []
	};
	return result;
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

