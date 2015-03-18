// Node server for listening to firebase and sending off a celery task
// Good documentation and examples at https://github.com/mher/node-celery
// Note: Startup takes 2 seconds since 
var http = require('http');
var Firebase = require("firebase");
var nconf = require('nconf');

//
// Setup nconf to use (in-order):
//   1. Command-line arguments
//   2. Environment variables
//   3. A file located at 'path/to/config.json'
//
nconf.argv()
	 .env();
nconf.file({ file: '../config/' + nconf.get('KEEPER_ENV') + '.json' });

console.log();

var startTime = new Date();
startTime.setSeconds(startTime.getSeconds() + 5);

var imageFirebaseRef = new Firebase(nconf.get('FIREBASE_URL') + "/imageData");
imageFirebaseRef.authWithCustomToken(nconf.get('FIREBASE_KEY'), function(error, result) {
  if (error) {
	console.log("Login Failed!", error);
  } else {
	console.log("Authenticated successfully with payload:", result.auth);
	console.log("Auth expires at:", new Date(result.expires * 1000));
  }
});

var photosFirebaseRef = new Firebase(nconf.get('FIREBASE_URL') + "/photos");
photosFirebaseRef.authWithCustomToken(nconf.get('FIREBASE_KEY'), function(error, result) {
  if (error) {
	console.log("Login Failed!", error);
  } else {
	console.log("Authenticated successfully with payload:", result.auth);
	console.log("Auth expires at:", new Date(result.expires * 1000));
  }
});

var celery = require('node-celery'),
	client = celery.createClient({
		CELERY_BROKER_URL: 'amqp://guest:guest@localhost:5672//',
		CELERY_RESULT_BACKEND: 'amqp'
	});

client.on('error', function(err) {
	console.log(err);
});

/*
  Gets called with a photoData object and kicks off the celery task
*/
function processPhotoData(photoData) {
	console.log("Executing photoKey: " + photoData.key());
	client.call('celery_textrec.processPhotoByKey', [photoData.key()], function(result) {
		res.writeHead(200);
		res.end('Success');
	});
};

/*
  This gets called when imageData is created or changed.
  First see if this is startup, if so, skip.
  If not, then see if the uploaded value is true, if not, skip.
  Lastly, grab the photoData and process it.
*/
function processImageData(imageData) {
	now = new Date();
	if (now > startTime) {
		if (imageData.val().uploaded) {
			photosFirebaseRef.orderByChild("imageKey").equalTo(imageData.key()).on("value", function(photoDatas) {
				photoDatas.forEach(processPhotoData);
			});
		} else {
			console.log("Got imageKey " + imageData.key() + " but uploaded value was false");
		}
	} else {
		console.log("Starting and got: " + imageData.key());
	}
};

imageFirebaseRef.on("child_added", function(imageData) {
	processImageData(imageData);
});

imageFirebaseRef.on("child_changed", function(imageData) {
	processImageData(imageData);
});

/*
// Left here for debugging
var server = http.createServer(function(req, res) {
	console.log(RMGarbage.debug("' ' * ,, , E VALUE PROPOSITION UN"))
	res.writeHead(200);
	res.end('Success');
});
server.listen(8080);
*/
