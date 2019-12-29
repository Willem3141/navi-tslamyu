const nearley = require('nearley');
const grammar = require('./navi.js');
const util = require('util');
const reykunyu = require('../navi-reykunyu/searcher.js');

const parser = new nearley.Parser(nearley.Grammar.fromCompiled(grammar));

let input = process.argv[2];
let responses = reykunyu.getResponsesFor(input);
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
		} else {
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
	let type = word['type'];
	if (type === 'n' || type === 'pn') {
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
				throw new Error('unknown suffix: ' + suffix);
		}
	}
	if (type === 'v:in') {
		type = 'vin';
	}
	if (type === 'v:tr') {
		type = ['vin', 'vtr'];
	}
	if (type === 'part') {
		if (word['na\'vi'] === 'a') {
			type = ['a_left', 'a_right'];
		}
	}
	return type;
}

console.log();
console.log('\x1b[1m\x1b[34mParse results:\x1b[0m ' + parser.results.length + ' possible parse tree(s) found');
for (let i = 0; i < parser.results.length; i++) {
	let result = parser.results[i];
	outputTree(verbClauseToTree(result));
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
			let adverbial = adverbialToTree(adv);
			adverbial['role'] = 'adverbial';
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

