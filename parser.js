const nearley = require('nearley');
const grammar = require('./navi.js');

//const util = require('util');
const fetch = require('node-fetch');

const parser = new nearley.Parser(nearley.Grammar.fromCompiled(grammar));

let verbose = false;
main();

async function main() {
	let input = process.argv[2];
	if (input === "-v" || input === "--verbose") {
		verbose = true;
		input = process.argv[3];
	}
	let responses = await getResponsesFor(input);

	if (verbose) {
		console.log('\x1b[1m\x1b[34mInput:\x1b[0m');
	}
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

		if (verbose) {
			console.log('\x1b[1m' + token['value'] + '\x1b[0m (' + token['types'].join(', ') + ')');
		}
	}

	if (verbose) {
		console.log();
	}

	try {
		parser.feed(tokens);
	} catch (e) {
		throw e;
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
			type = 'vtr';
		}
		if (t === 'v:cp') {
			// copula verbs can also be used intransitively
			type = 'vcp';
		}
		if (t === 'v:m') {
			// modal verbs can also be used intransitively
			type = 'vm';
		}
		if (t === 'part') {
			if (word['na\'vi'] === 'a') {
				type = ['a_left', 'a_right'];
			} else if (word['na\'vi'] === 'ma') {
				type = 'ma';
			} else if (word['na\'vi'] === 'ke' || word['na\'vi'] === 'rä\'ä') {
				type = 'ke';
			}
		}
		if (t === 'adv') {
			type = 'adv';
		}
		if (t === 'adj') {
			type = 'adj';
		}
		if (t === 'adp' || t === "adp:len") {
			type = 'adp';
		}
		//if (type === '') {
		//	throw new Error('tslamyu doesn\'t understand word type: ' + t);
		//}
		return type;
	}

	if (verbose) {
		console.log('\x1b[1m\x1b[34mParse results:\x1b[0m ' + parser.results.length + ' possible parse tree(s) found');
	}
	let results = parser.results;
	results.sort((a, b) => a.getPenalty() - b.getPenalty());
	let correct = results[0].getErrors().length === 0;
	if (verbose) {
		for (let i = 0; i < results.length; i++) {
			let result = results[i];
			console.log('───────────────────────────────────────────────────');
			outputTree(result);
			console.log("(penalty: " + result.getPenalty() + ")");
			for (let j = 0; j < result.getErrors().length; j++) {
				error(result.getErrors()[j]);
			}
			console.log(" -> \"" + result.translate() + "\"");
		}
		console.log('───────────────────────────────────────────────────');
	} else {
		let lastTranslation = null;
		for (let i = 0; i < results.length; i++) {
			let result = results[i];
			if (i > 0 && result.getPenalty() > results[0].getPenalty()) {
				break;
			}
			for (let j = 0; j < result.getErrors().length; j++) {
				error(result.getErrors()[j]);
			}
			let translation = result.translate();
			if (correct && translation !== lastTranslation) {
				console.log(" -> \"" + translation + "\"");
				lastTranslation = translation;
			}
		}
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

function outputTree(tree, prefix1 = '', prefix2 = '', role = null) {
	let mainText = '';
	if (role) {
		mainText += '\x1b[33m' + role + ': \x1b[0m';
	}
	mainText += '\x1b[1m' + tree['word'] + '\x1b[0m';
	if (tree['translation']) {
		mainText += ' -> ' + tree['translation'];
	}
	console.log(prefix1 + mainText);
	if (tree['children']) {
		let prefixLength = 1;
		if (role) {
			prefixLength = role.length + 3;
		}
		for (let i = 0; i < tree['children'].length; i++) {
			if (i === tree['children'].length - 1) {
				outputTree(tree['children'][i],
					prefix2 + spaces(prefixLength) + '└─ ',
					prefix2 + spaces(prefixLength) + '   ',
					tree['roles'][i]);
			} else {
				outputTree(tree['children'][i],
					prefix2 + spaces(prefixLength) + '├─ ',
					prefix2 + spaces(prefixLength) + '│  ',
					tree['roles'][i]);
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

