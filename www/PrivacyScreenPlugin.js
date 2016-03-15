var exec = require('cordova/exec');

var PrivacyScreen = {
	enable: function() {
		return new Promise( function(success, error) {
            exec(success, error, "PrivacyScreen", "enable");
		});
	}
}

module.exports = PrivacyScreen;
