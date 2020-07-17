const assert = require('assert');

const reykunyu = require('../../navi-reykunyu/reykunyu');
const tslamyu = require('../tslamyu');

const doParse = function(sentence) {
	return tslamyu.doParse(reykunyu.getResponsesFor(sentence));
}
const isAccepted = function(sentence) {
	const result = doParse(sentence);
	if (result.length === 0) {
		return false;
	}
	if (result[0].errors.length > 0) {
		return false;
	}
	return true;
}


describe("verb phrases", function() {
	describe("intransitive sentences", function() {
		specify("with an intransitive verb should be accepted", function () {
			assert(isAccepted('ioang tul'));
			assert(isAccepted('tul ioang'));
		});

		specify("with a transitive verb should be accepted", function () {
			assert(isAccepted('ioang taron'));
			assert(isAccepted('taron ioang'));
		});

		specify("with a copula verb should be accepted", function () {
			assert(isAccepted('ioang lu'));
			assert(isAccepted('lu ioang'));
		});

		specify("with a modal verb should be accepted", function () {
			assert(isAccepted('ioang tsun'));
			assert(isAccepted('tsun ioang'));
		});

		specify("with two verbs should be rejected", function () {
			assert(!isAccepted('tul ioang tìran'));
		});

		specify("without subjective should be accepted", function () {
			assert(isAccepted('tul'));
		});

		specify("with two subjectives should be rejected", function () {
			assert(!isAccepted('ioang tute tul'));
			assert(!isAccepted('ioang tul tute'));
			assert(!isAccepted('tul ioang tute'));
		});
	});


	describe("transitive sentences", function() {

		specify("with a transitive verb should be accepted", function () {
			assert(isAccepted('taron ioangìl tuteti'));
			assert(isAccepted('taron tuteti ioangìl'));
			assert(isAccepted('ioangìl taron tuteti'));
			assert(isAccepted('ioangìl tuteti taron'));
			assert(isAccepted('tuteti taron ioangìl'));
			assert(isAccepted('tuteti ioangìl taron'));
		});

		specify("without agentive or patientive should be accepted", function () {
			assert(isAccepted('taron tuteti'));
			assert(isAccepted('tuteti taron'));
			assert(isAccepted('taron ioangìl'));
			assert(isAccepted('ioangìl taron'));
		});

		specify("with an intransitive verb should be rejected", function () {
			assert(!isAccepted('ioangìl tul tuteti'));
			assert(!isAccepted('ioangìl tul'));
			assert(!isAccepted('tuteti tul'));
		});

		specify("with a copula verb should be rejected", function () {
			assert(!isAccepted('ioangìl lu tuteti'));
			assert(!isAccepted('ioangìl lu'));
			assert(!isAccepted('tuteti lu'));
		});

		specify("with a subjective and a patientive should be rejected", function () {
			assert(!isAccepted('ioang taron tuteti'));
		});

		specify("with a subjective and an agentive should be rejected", function () {
			assert(!isAccepted('ioangìl taron tute'));
		});
	});


	describe("copula (predicative) sentences", function() {

		specify("with a noun as the predicate should be accepted", function () {
			assert(isAccepted('ioang lu tute'));
			assert(isAccepted('lu ioang tute'));
			assert(isAccepted('ioang tute lu'));
		});

		specify("with an adjective as the predicate should be accepted", function () {
			assert(isAccepted('ioang lu lor'));
			assert(isAccepted('lu ioang lor'));
			assert(isAccepted('ioang lor lu'));
			assert(isAccepted('lor lu ioang'));
			assert(isAccepted('lu lor ioang'));
			assert(isAccepted('lor ioang lu'));
		});

		specify("with two adjectives should be rejected", function () {
			assert(!isAccepted('lor lu fe\''));
			assert(!isAccepted('lu lor fe\''));
			assert(!isAccepted('lor fe\' lu'));
		});

		specify("with a genitive as the predicate should be accepted", function () {
			assert(isAccepted('ioang lu oeyä'));
			assert(isAccepted('oeyä lu ioang'));
		});

		specify("with a dative as the predicate should be accepted", function () {
			assert(isAccepted('ioang lu oeru'));
			assert(isAccepted('oeru lu ioang'));
		});
	});
});


describe("noun phrases", function() {
	describe("attributive subclauses", function() {
		specify("with a verb phrase should be accepted", function () {
			assert(isAccepted('lu tute a tul'));
			assert(isAccepted('lu tul a tute'));
			assert(isAccepted('lu tute a taron ioangit'));
			assert(isAccepted('lu taron ioangit a tute'));
			assert(isAccepted('lu ioangit taron a tute'));
			assert(isAccepted('lu tute a ioangìl taron'));
			assert(isAccepted('lu taron ioangìl a tute'));
			assert(isAccepted('lu ioangìl taron a tute'));
		});

		specify("with an adposition phrase should be accepted", function () {
			assert(isAccepted('lu tute a mì sray'));
			assert(isAccepted('lu mì sray a tute'));
		});
	});


	describe("adjectives", function() {
		specify("with one adjective should be accepted", function () {
			assert(isAccepted('lu tute alor'));
			assert(isAccepted('lu lora tute'));
		});

		specify("with two adjectives on both sides should be accepted", function () {
			assert(isAccepted('lu lora tute alor'));
		});

		specify("with two adjectives on the same side should be rejected", function () {
			assert(isAccepted('lu lora lora tute'));
		});
	});


	describe("genitives", function() {
		specify("with an attached genitive should be accepted", function () {
			assert(isAccepted('tul oeyä ioang'));
			assert(isAccepted('tul ioang oeyä'));
		});
	});
});

