#!/usr/bin/env node

/*
  gifty by tcoyze
  Translate text to GIFS then attach it to a tweet!
*/

var program = require('commander');
var Giphy = require('giphy');
var twitterAPI = require('node-twitter-api');
var async = require('async');
var request = require('request');
var fs = require('fs');


// REQUIRED: Load your twitter credentials here...
var twitterConsumerKey = "CONSUMER_KEY";
var twitterConsumerSecret = "CONSUMER_SECRET";
var twitterAccessToken = "ACCESS_TOKEN";
var twitterAccessSecret = "ACCESS_TOKEN_SECRET";

// Required for sending a tweet
var twitter = new twitterAPI({
    consumerKey: twitterConsumerKey,
    consumerSecret: twitterConsumerSecret,
    callback: 'CALLBACK_URL'
});

// Required for uploading GIF
var tokenSecrets = {
  consumer_key: twitterConsumerKey,
  consumer_secret: twitterConsumerSecret,
  token: twitterAccessToken,
  token_secret: twitterAccessSecret
};

// Init Giphy Object with Beta Dev Token
var giphy = new Giphy('dc6zaTOxFJmzC');

var sys = require('util')
var exec = require('child_process').exec;

program
  .version('1.0.0')
  .option('--translate [value]', 'Translate string into a GIF')
  .option('--tweet [value]', 'Tweet like so: "hello world"')
  .option('--id [value]', 'ID of GIF that you want to upload')
  .parse(process.argv);

if(program.translate){
  giphy.translate({s: program.translate}, function(error, body, res){
    if(body && body.data && body.data.id){
      console.log("This is your GIF's ID: " + body.data.id)
      url = "https://media.giphy.com/media/" + body.data.id + "/giphy.gif"
      exec("open " + url, puts);
    }
    else{
      console.log("Could not find a GIF for that!");
    }

  });
}

if(program.tweet){

  var mediaId;
  var media = false;
  var url = "";

  if(program.id){
    media = true;
    url = "https://media.giphy.com/media/" + program.id + "/giphy.gif"
  }

  var buff;

    var dataStringChunks = [];
    var dataString = "";
    var totalBytes = 0;
    var MB = 0;

    var itemNum = 0;
    var mediaIdVideo = "";

    async.series([
      function(cb){
        if(media){
          request({
            method: 'GET',
            url: url,
            encoding: 'binary'
          }, function(error, response, body){

            var b = new Buffer(body.toString(), 'binary');
            buff = b.toString('base64');

            dataStringChunks = [];
            dataString = buff;
            totalBytes = b.length;

            MB = Math.ceil(dataString.length / 5000000);

            for(var i = 1; i <= MB; i++){
                if(dataString.length > 5000000){
                  dataStringChunks[dataStringChunks.length] = dataString.slice(0,5000000);
                  dataString = dataString.slice(5000000, dataString.length);
                }
                else{
                  dataStringChunks[dataStringChunks.length] = dataString.slice(0,dataString.length);
                  dataString = dataString.slice(dataString.length, dataString.length);
                }
            }
            cb();

          });
        }
        else{
          cb();
        }
      },
      function(cb){

        if(media){
          var form;
          var req = request({
                      url: "https://upload.twitter.com/1.1/media/upload.json",
                      method: "POST",
                      oauth: tokenSecrets,
                      json: true
                    }, function(error, response, body){
                      if(error)
                        console.log(error);

                      if(body && body.media_id_string)
                        mediaIdVideo = body.media_id_string;
                      else{
                        console.log("NO ID");
                        mediaIdVideo = "";
                      }
                      cb();
                    });

          form = req.form();
          form.append('total_bytes', totalBytes);
          form.append('media_type', "image/gif");
          form.append('command', 'INIT');

          console.log("SENDING TWITTER VIDEO UPLOAD -> INIT COMMAND");
        }
        else{
          cb();
        }

      },
      function(cb){

        if(media){
          async.eachSeries(dataStringChunks, function(itemz, cb2){
            var form;
            var req = request({
                        url: "https://upload.twitter.com/1.1/media/upload.json",
                        method: "POST",
                        oauth: tokenSecrets
                      }, function(error, response, body){
                        console.log("SENT PART: " + itemNum);
                        itemNum++;
                        cb2();
                      });

            form = req.form();

            form.append('media_data', itemz);
            form.append('segment_index', itemNum);
            form.append('media_id', mediaIdVideo);
            form.append('command', 'APPEND');
          }, function(error2, results2){
            console.log("TWITTER VIDEO UPLOAD -> COMPLETED APPEND COMMAND");
            cb();
          });
        }
        else{
          cb();
        }
      },
      function(cb){

        if(media){
          var form;
          var req = request({
                      url: "https://upload.twitter.com/1.1/media/upload.json",
                      method: "POST",
                      oauth: tokenSecrets,
                      json: true
                    }, function(error, response, body){

                      if (error){
                        console.log("ERROR: FINALIZE TWITTER VIDEO UPLOAD");
                        console.log(error);
                      }

                      console.log("TWITTER VIDEO UPLOAD -> COMPLETED FINALIZE COMMAND");
                      cb();
                    });

          form = req.form();
          form.append('media_id', mediaIdVideo);
          form.append('command', 'FINALIZE');

          console.log("SENDING TWITTER VIDEO UPLOAD -> FINALIZE COMMAND");
        }
        else{
          cb();
        }
      },
      function(cb){
        var statusObj = {status: program.tweet};

        if(mediaIdVideo != "")
          statusObj["media_ids"] = [mediaIdVideo];

        twitter.statuses("update",
          statusObj,
          twitterAccessToken,
          twitterAccessSecret,
          function(error, data, response) {

            if(error){
              console.log("ERROR: UPDATE TWITTER STATUS");
              console.log(error);
            }

            console.log("YOUR TWEET OBJECT ID:");

            if(data && data.id)
              console.log(data.id);

            cb();

          });

      }
    ], function(error, results){
      console.log("TWITTER UPDATE: COMPLETE");
    });

}

function puts(error, stdout, stderr) { console.log(stdout) }
