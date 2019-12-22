const nearley = require('nearley');
const grammar = require('./navi.js');
const util = require('util');

const parser = new nearley.Parser(nearley.Grammar.fromCompiled(grammar));

//let input = process.argv[2].split(' ');
let input = [
	{'value': 'nìngay', 'types': ['adv']},
	{'value': 'rey', 'types': ['vin']},
	{'value': 'po', 'types': ['n_subjective']},
	{'value': 'a', 'types': ['a_left', 'a_right']},
	{'value': 'tute', 'types': ['n_subjective']},
	{'value': 'apxa', 'types': ['adj', 'adj_left', 'adj_right']},
	{'value': 'tul', 'types': ['vin']}
];
/*let input = [
	{'value': 'taronyul', 'types': ['n_agentive']},
	{'value': 'apxa', 'types': ['adj', 'adj_left', 'adj_right']},
	{'value': 'ioangit', 'types': ['n_patientive']},
	{'value': 'taron', 'types': ['vtr']}
];*/
parser.feed(input);

console.log(util.inspect(parser.results, false, null, true));
