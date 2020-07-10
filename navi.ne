# Na'vi grammar in Nearley format

# Helper functions
@{%
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
		return result;
	};
%}


#sentence -> n_clause_topic:? verb_clause {%
	#	function (data) {
	#		return {
	#			'topic': data[0],
	#			'main_clause': data[1]
	#		};
	#	}
	#%}
sentence -> verb_clause {% id %}

verb_clause ->
	vin_clause {% id %}
	| vtr_clause {% id %}
	| vcp_clause {% id %}


### INTRANSIIVE VERB CLAUSES ###

vin_clause ->
	vin_clause_bare {% id %}
	| vin_clause_subjective {% id %}

# bare intransitive verb clause: only a verb, no subject
vin_clause_bare ->
	adverbial:* %vin adverbial:*
	{%
		function (data) {
			let result = {
				'clause_type': 'intransitive',
				'verb': data[1]
			};
			let advs = [];
			if (data[0]) {
				advs = advs.concat(data[0]);
			}
			if (data[2]) {
				advs = advs.concat(data[2]);
			}
			if (advs.length > 0) {
				result['adverbials'] = advs;
			}
			return result;
		}
	%}

# intransitive verb clause with a subject
# (is a bare clause with a subjective added to it)
vin_clause_subjective ->
	(adverbial:* n_clause_subjective vin_clause_bare
	{%
		function (data) {
			let result = {...data[2]};
			result['subjective'] = data[1];
			let advs = result['adverbials'] ? [...result['adverbials']] : [];
			advs = data[0].concat(advs);
			if (advs.length > 0) {
				result['adverbials'] = advs;
			}
			return result;
		}
	%}
	| vin_clause_bare n_clause_subjective adverbial:*
	{%
		function (data) {
			let result = {...data[0]};
			result['subjective'] = data[1];
			let advs = result['adverbials'] ? [...result['adverbials']] : [];
			advs = advs.concat(data[2]);
			if (advs.length > 0) {
				result['adverbials'] = advs;
			}
			return result;
		}
	%})
	{% id %}


### TRANSIIVE VERB CLAUSES ###

# a vtr_clause_bare cannot be a vtr_clause, because otherwise such a clause
# would be ambiguous (vin_clause_bare vs vtr_clause_bare)
vtr_clause ->
	vtr_clause_agentive {% id %}
	| vtr_clause_patientive {% id %}
	| vtr_clause_full {% id %}

# bare transitive verb clause: only a verb, no agentive or patientive
vtr_clause_bare ->
	adverbial:* %vtr adverbial:*
	{%
		function (data) {
			let result = {
				'clause_type': 'transitive',
				'verb': data[1]
			};
			let advs = [];
			advs = advs.concat(data[0]);
			advs = advs.concat(data[2]);
			if (advs.length > 0) {
				result['adverbials'] = advs;
			}
			return result;
		}
	%}

# transitive verb clause with an agentive
# (is a bare clause with an agentive added to it)
vtr_clause_agentive ->
	(adverbial:* n_clause_agentive vtr_clause_bare
	{%
		function (data) {
			let result = {...data[2]};
			result['agentive'] = data[1];
			let advs = result['adverbials'] ? [...result['adverbials']] : [];
			advs = data[0].concat(advs);
			if (advs.length > 0) {
				result['adverbials'] = advs;
			}
			return result;
		}
	%}
	| vtr_clause_bare n_clause_agentive adverbial:*
	{%
		function (data) {
			let result = {...data[0]};
			result['agentive'] = data[1];
			let advs = result['adverbials'] ? [...result['adverbials']] : [];
			advs = advs.concat(data[2]);
			if (advs.length > 0) {
				result['adverbials'] = advs;
			}
			return result;
		}
	%})
	{% id %}

# transitive verb clause with a patientive
# (is a bare clause with a patientive added to it)
vtr_clause_patientive ->
	(adverbial:* n_clause_patientive vtr_clause_bare
	{%
		function (data) {
			let result = {...data[2]};
			result['patientive'] = data[1];
			let advs = result['adverbials'] ? [...result['adverbials']] : [];
			advs = data[0].concat(advs);
			if (advs.length > 0) {
				result['adverbials'] = advs;
			}
			return result;
		}
	%}
	| vtr_clause_bare n_clause_patientive adverbial:*
	{%
		function (data) {
			let result = {...data[0]};
			result['patientive'] = data[1];
			let advs = result['adverbials'] ? [...result['adverbials']] : [];
			advs = advs.concat(data[2]);
			if (advs.length > 0) {
				result['adverbials'] = advs;
			}
			return result;
		}
	%})
	{% id %}

# transitive verb clause with an agentive and a patientive
vtr_clause_full ->
	(adverbial:* n_clause_patientive vtr_clause_agentive
	{%
		function (data) {
			let result = {...data[2]};
			result['patientive'] = data[1];
			let advs = result['adverbials'] ? [...result['adverbials']] : [];
			advs = advs.concat(data[0]);
			if (advs.length > 0) {
				result['adverbials'] = advs;
			}
			return result;
		}
	%}
	| vtr_clause_agentive n_clause_patientive adverbial:*
	{%
		function (data) {
			let result = {...data[0]};
			result['patientive'] = data[1];
			let advs = result['adverbials'] ? [...result['adverbials']] : [];
			advs = advs.concat(data[2]);
			if (advs.length > 0) {
				result['adverbials'] = advs;
			}
			return result;
		}
	%}
	| adverbial:* n_clause_agentive adverbial:* n_clause_patientive vtr_clause_bare
	{%
		function (data) {
			let result = {...data[4]};
			result['agentive'] = data[1];
			result['patientive'] = data[3];
			let advs = result['adverbials'] ? [...result['adverbials']] : [];
			advs = data[0].concat(data[2]).concat(advs);
			if (advs.length > 0) {
				result['adverbials'] = advs;
			}
			return result;
		}
	%}
	| vtr_clause_bare n_clause_patientive adverbial:* n_clause_agentive adverbial:*
	{%
		function (data) {
			let result = {...data[0]};
			result['agentive'] = data[3];
			result['patientive'] = data[1];
			let advs = result['adverbials'] ? [...result['adverbials']] : [];
			advs = advs.concat(data[2]).concat(data[4]);
			if (advs.length > 0) {
				result['adverbials'] = advs;
			}
			return result;
		}
	%})
	{% id %}


### COPULA VERB CLAUSES ###

# a vcp_clause_bare cannot be a vcp_clause, because otherwise such a clause
# would be ambiguous (vin_clause_bare vs vcp_clause_bare)
# similarly, a vcp_clause_noun would be ambiguous (vin_clause_subjective)
vcp_clause ->
	vcp_clause_adj {% id %}
	| vcp_clause_noun_adj {% id %}
	| vcp_clause_noun_noun {% id %}

# bare copula verb clause: only a verb, no subject
vcp_clause_bare ->
	adverbial:* %vcp adverbial:*
	{%
		function (data) {
			let result = {
				'clause_type': 'copula',
				'verb': data[1]
			};
			let advs = [];
			advs = advs.concat(data[0]);
			advs = advs.concat(data[2]);
			if (advs.length > 0) {
				result['adverbials'] = advs;
			}
			return result;
		}
	%}

# copula verb clause with an adjective as the predicate
# (is a bare clause with an adjective added to it)
vcp_clause_adj ->
	(adverbial:* %adj vcp_clause_bare
	{%
		function (data) {
			let result = {...data[2]};
			result['predicate'] = {...data[1]};
			result['predicate']['type'] = 'adjective';
			let advs = result['adverbials'] ? [...result['adverbials']] : [];
			advs = data[0].concat(advs);
			if (advs.length > 0) {
				result['adverbials'] = advs;
			}
			return result;
		}
	%}
	| vcp_clause_bare %adj adverbial:*
	{%
		function (data) {
			let result = {...data[0]};
			result['predicate'] = {...data[1]};
			result['predicate']['type'] = 'adjective';
			let advs = result['adverbials'] ? [...result['adverbials']] : [];
			advs = advs.concat(data[2]);
			if (advs.length > 0) {
				result['adverbials'] = advs;
			}
			return result;
		}
	%})
	{% id %}

# copula verb clause with a noun as the subject and an adjective as the
# predicate
vcp_clause_noun_adj ->
	(adverbial:* n_clause_subjective vcp_clause_adj
	{%
		function (data) {
			let result = {...data[2]};
			result['subjective'] = data[1];
			let advs = result['adverbials'] ? [...result['adverbials']] : [];
			advs = data[0].concat(advs);
			if (advs.length > 0) {
				result['adverbials'] = advs;
			}
			return result;
		}
	%}
	| vcp_clause_adj n_clause_subjective adverbial:*
	{%
		function (data) {
			let result = {...data[0]};
			result['subjective'] = data[1];
			let advs = result['adverbials'] ? [...result['adverbials']] : [];
			advs = data[2].concat(advs);
			if (advs.length > 0) {
				result['adverbials'] = advs;
			}
			return result;
		}
	%}
	| adverbial:* %adj adverbial:* n_clause_subjective vcp_clause_bare
	{%
		function (data) {
			let result = {...data[4]};
			result['subjective'] = data[3];
			result['predicate'] = {...data[1]};
			result['predicate']['type'] = 'adjective';
			let advs = result['adverbials'] ? [...result['adverbials']] : [];
			advs = data[0].concat(data[2]).concat(advs);
			if (advs.length > 0) {
				result['adverbials'] = advs;
			}
			return result;
		}
	%}
	| vcp_clause_bare n_clause_subjective adverbial:* %adj adverbial:*
	{%
		function (data) {
			let result = {...data[0]};
			result['subjective'] = data[1];
			result['predicate'] = {...data[3]};
			result['predicate']['type'] = 'adjective';
			let advs = result['adverbials'] ? [...result['adverbials']] : [];
			advs = advs.concat(data[2]).concat(data[4]);
			if (advs.length > 0) {
				result['adverbials'] = advs;
			}
			return result;
		}
	%})
	{% id %}

# copula verb clause with a noun as the subject and another noun as the
# predicate
vcp_clause_noun_noun ->
	(adverbial:* n_clause_subjective adverbial:* n_clause_subjective vcp_clause_bare
	{%
		function (data) {
			let result = {...data[4]};
			result['subjective'] = data[1];
			result['predicate'] = {...data[3]};
			result['predicate']['type'] = 'noun';
			let advs = result['adverbials'] ? [...result['adverbials']] : [];
			advs = data[0].concat(data[2]).concat(advs);
			if (advs.length > 0) {
				result['adverbials'] = advs;
			}
			return result;
		}
	%}
	| adverbial:* n_clause_subjective vcp_clause_bare n_clause_subjective adverbial:*
	{%
		function (data) {
			let result = {...data[2]};
			result['subjective'] = data[1];
			result['predicate'] = {...data[3]};
			result['predicate']['type'] = 'noun';
			let advs = result['adverbials'] ? [...result['adverbials']] : [];
			advs = data[0].concat(advs).concat(data[4]);
			if (advs.length > 0) {
				result['adverbials'] = advs;
			}
			return result;
		}
	%}
	| vcp_clause_bare n_clause_subjective adverbial:* n_clause_subjective adverbial:*
	{%
		function (data) {
			let result = {...data[0]};
			result['subjective'] = data[1];
			result['predicate'] = {...data[3]};
			result['predicate']['type'] = 'noun';
			let advs = result['adverbials'] ? [...result['adverbials']] : [];
			advs = advs.concat(data[2]).concat(data[4]);
			if (advs.length > 0) {
				result['adverbials'] = advs;
			}
			return result;
		}
	%})
	{% id %}


### NOUN CLAUSES ###

n_clause_subjective ->
	(n_clause_genitive):?
	(verb_clause %a_left):?
	%adj_left:? %n_subjective %adj_right:?
	(%a_right verb_clause):?
	(n_clause_genitive):?
	{% processNounClause %}

n_clause_agentive ->
	(n_clause_genitive):?
	(verb_clause %a_left):?
	%adj_left:? %n_agentive %adj_right:?
	(%a_right verb_clause):?
	(n_clause_genitive):?
	{% processNounClause %}

n_clause_patientive ->
	(n_clause_genitive):?
	(verb_clause %a_left):?
	%adj_left:? %n_patientive %adj_right:?
	(%a_right verb_clause):?
	(n_clause_genitive):?
	{% processNounClause %}

n_clause_dative ->
	(n_clause_genitive):?
	(verb_clause %a_left):?
	%adj_left:? %n_dative %adj_right:?
	(%a_right verb_clause):?
	(n_clause_genitive):?
	{% processNounClause %}

n_clause_genitive ->
	(n_clause_genitive):?
	(verb_clause %a_left):?
	%adj_left:? %n_genitive %adj_right:?
	(%a_right verb_clause):?
	(n_clause_genitive):?
	{% processNounClause %}

n_clause_topical ->
	(n_clause_genitive):?
	(verb_clause %a_left):?
	%adj_left:? %n_topical %adj_right:?
	(%a_right verb_clause):?
	(n_clause_genitive):?
	{% processNounClause %}


### OTHERS ###

adverbial -> %adv {%
	function (data) {
		return {
			'type': 'adverb',
			'adverb': data[0]
		};
	}
%}
adverbial -> n_clause_dative {%
	function (data) {
		return {
			'type': 'dative',
			'dative': data[0]
		};
	}
%}

