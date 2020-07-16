const tslamyu = require('./tslamyu');

//const util = require('util');
const fetch = require('node-fetch');

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
	results = tslamyu.doParse(responses, verbose);

	if (verbose) {
		console.log('\x1b[1m\x1b[34mParse results:\x1b[0m ' + results.length + ' possible parse tree(s) found');
	}
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

