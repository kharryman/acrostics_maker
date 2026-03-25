var fs = require('fs');
var fsExtra = require('fs-extra');
var https = require('https');
var request = require('request');
const path = require('path');


const currentDirectory = process.cwd();
var args = process.argv.slice(1);

var googleAPIKey = "";//SET WHEN GOING TO USE!!!
//var cwdSplit = currentDirectory.split("\\");
const cwdSplit = currentDirectory.split(path.sep); //PLATFORM INDEPENDENT.
var lastDirSplit = cwdSplit.slice(0, -1);

fs.readFile(lastDirSplit.join("/") + "/google_api_key.txt", function (err, apiKey) {
    if (err) {
        console.log("ERROR GETTING GOOGLE API KEY: " + JSON.stringify(err));
    } else {
        googleAPIKey = apiKey;
        fs.readFile(currentDirectory + "/release_notes.txt", function (err, notes) {
            if (err) {
                console.log("READ FILE RELEAE NOTES ERROR: " + JSON.stringify(err));
            } else {
                console.log("READ FILE: release_notes.txt! notes = " + notes);
                var lgPath = currentDirectory + "/ios/fastlane/metadata";
                fs.readdir(lgPath, (err, transFiles) => {
                    if (!err) {
                        transFiles = transFiles.filter(function (file) {
                            return fs.statSync(lgPath + '/' + file.split("/")[0]).isDirectory() && file.split("/")[0] !== "review_information";
                        });
                        console.log("transFiles = " + transFiles);
                        //EMPTY NON-ENGLISH DIRECTORIES:
                        //for (var i = 0; i < transFiles.length; i++) {
                        //    if (transFiles[i] !== "en-US") {
                        //        fsExtra.emptyDirSync(lgPath + '/' + transFiles[i] + "/changelogs");
                        //    }
                        //}
                        var isCreate = "false";
                        var enPath = currentDirectory + "/ios/fastlane/metadata/en-US";
                        fs.readdir(enPath, (err, enLogs) => {
                            if (!err) {
                                var newestEnLog = "", newestEnLogVers = 1, enLogVer = 1, enLogSplit = [];
                                console.log("enLogs = " + enLogs);
                                for (var i = 0; i < enLogs.length; i++) {
                                    enLogVer = parseInt(enLogs[i].split(".")[0]);
                                    if (enLogVer >= newestEnLogVers) {
                                        newestEnLog = enLogs[i];
                                        newestEnLogVers = enLogVer;
                                    }
                                }
                                console.log("newestEnLogVers = " + newestEnLogVers + ", newestEnLog = " + newestEnLog);

                                var createNotesFile = function (fileIndex, transString, transFiles) {
                                    if (fileIndex < transFiles.length) {
                                        var targetLanguage = transFiles[fileIndex];
                                        if (targetLanguage.includes("en")) {
                                            var writeEnNotes = notes;
                                            if (writeEnNotes.length >= 500) {
                                                //console.log("RELEASE NOTES = " + releaseNotes);
                                                writeEnNotes = String(writeEnNotes).substring(0, 497) + "...";
                                            }
                                            fs.writeFile(currentDirectory + "/ios/fastlane/metadata/" + targetLanguage + "/release_notes.txt", writeEnNotes, 'utf8', function () {
                                                console.log("WROTE FILE: release_notes.txt FOR " + targetLanguage + ".");
                                                fileIndex++;
                                                setTimeout(function () {
                                                    createNotesFile(fileIndex, transString, transFiles);
                                                }, 100);
                                            });
                                        } else {
                                            var url = 'https://translation.googleapis.com/language/translate/v2?key=' + googleAPIKey;
                                            url += '&q=' + encodeURI(transString);
                                            url += `&source=en`;
                                            url += `&target=` + targetLanguage;
                                            url += `&format=text`;
                                            request(url, function (error, response, body) {
                                                if (!error && response.statusCode == 200) {
                                                    var parsedBody = JSON.parse(body);
                                                    var translatedNotes = parsedBody.data.translations[0].translatedText;

                                                    console.log("translatedNotes = " + translatedNotes);
                                                    var langDir = currentDirectory + "/ios/fastlane/metadata/" + targetLanguage;
                                                    if (!fs.existsSync(langDir)) {
                                                        fs.mkdirSync(langDir);
                                                    }
                                                    if (translatedNotes.length >= 500) {
                                                        //console.log("RELEASE NOTES = " + releaseNotes);
                                                        translatedNotes = String(translatedNotes).substring(0, 497) + "...";
                                                    }
                                                    fs.writeFile(currentDirectory + "/ios/fastlane/metadata/" + targetLanguage + "/release_notes.txt", translatedNotes, 'utf8', function () {
                                                        console.log("WROTE release_notes.txt FOR " + targetLanguage + ".");
                                                        fileIndex++;
                                                        setTimeout(function () {
                                                            createNotesFile(fileIndex, transString, transFiles);
                                                        }, 100);
                                                    });
                                                } else {
                                                    console.log("google cloud translate ERROR: " + JSON.stringify(error) + ", RESPONSE = " + JSON.stringify(response) + ", BODY = " + JSON.stringify(body));
                                                }
                                            });
                                        }
                                    }
                                }
                                //if (isCreate === "true") {
                                createNotesFile(0, notes, transFiles);
                                //}
                            }
                        });
                    }
                });
            }
        });
    }
});