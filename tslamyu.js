const nearley = require('nearley');
const grammar = require('./navi.js');

module.exports = {
	doParse: doParse
}

function doParse(responses, verbose = false) {

	const parser = new nearley.Parser(nearley.Grammar.fromCompiled(grammar));

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
		throw "Parse failed at [" + e['token']['value']['value'] +
			"] (word " + (e['offset'] + 1) + ")";
	}

	//console.log(util.inspect(parser.results, false, null, true));

	let results = parser.results;
	results.sort((a, b) => a.getPenalty() - b.getPenalty());
	return results;
}

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
	if (t === 'n:si') {
		type = 'vsi_comp';
	}
	if (t === 'v:in' || t === "v:?") {
		type = 'vin';
	}
	if (t === 'v:tr') {
		type = 'vtr';
	}
	if (t === 'v:cp') {
		type = 'vcp';
	}
	if (t === 'v:m') {
		type = 'vm';
	}
	if (t === 'v:si') {
		type = 'vsi';
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
		if (word['conjugated'][2] === "prenoun") {
			type = 'adj_left';
		} else if (word['conjugated'][2] === "postnoun") {
			type = 'adj_right';
		} else {
			type = 'adj';
		}
	}
	if (t === 'adp' || t === "adp:len") {
		type = 'adp';
	}
	//if (type === '') {
	//	throw new Error('tslamyu doesn\'t understand word type: ' + t);
	//}
	return type;
}

function warning(msg) {
	console.log('Warning: ' + msg);
}

function error(msg) {
	console.log('\x1b[31m\x1b[1mError:\x1b[0m ' + msg);
}

