var fs = require('fs');
var fsExtra = require('fs-extra');
//var https = require('https');
var request = require('request');
const currentDirectory = process.cwd();
var args = process.argv.slice(2);
var googleAPIKey = "";//SET WHEN GOING TO USE!!!
var cwdSplit = currentDirectory.split("\\");
console.log("currentDirectory = " + currentDirectory);
var lastDirSplit = cwdSplit.slice(0, -1);
var lastDir = lastDirSplit.join("\\");
console.log("lastDir = " + lastDir);
var appVersion = args[0];

console.log("appVersion = " + appVersion);
if (!appVersion || isNaN(appVersion)) {
    console.log("Need to input version as an integer!");
} else {
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
                    var lgPath = currentDirectory + "/android/fastlane/metadata/android";
                    fs.readdir(lgPath, (err, transFiles) => {
                        if (!err) {
                            transFiles = transFiles.filter(function (file) {
                                return fs.statSync(lgPath + '/' + file.split("/")[0]).isDirectory();
                            });
                            console.log("transFiles = " + transFiles);
                            //EMPTY NON-ENGLISH DIRECTORIES:
                            //for (var i = 0; i < transFiles.length; i++) {
                            //    if (transFiles[i] !== "en-US") {
                            //        fsExtra.emptyDirSync(lgPath + '/' + transFiles[i] + "/changelogs");
                            //    }
                            //}

                            var isCreate = "false";
                            var enPath = currentDirectory + "/android/fastlane/metadata/android/en-US/changelogs";
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
                                    fs.readFile(currentDirectory + "/android/fastlane/metadata/android/en-US/changelogs/" + newestEnLog, function (err, getOldNotes) {
                                        var oldNotes = "";
                                        if (!err) {
                                            oldNotes = getOldNotes;
                                        }
                                        console.log("notes = " + notes);
                                        console.log("oldNotes = " + oldNotes);
                                        if (String(oldNotes) !== String(notes)) {
                                            isCreate = "true";
                                        }
                                        console.log("node_cpy_trans_release_notes.js appVersion = " + appVersion + ", isCreate = " + isCreate);
                                        console.log("NUMBER FILES = " + transFiles.length);

                                        var createNotesFile = function (fileIndex, transString, transFiles) {
                                            if (fileIndex < transFiles.length) {
                                                var targetLanguage = transFiles[fileIndex];
                                                var metaTransDir = currentDirectory + "/android/fastlane/metadata/android/" + targetLanguage + "/changelogs";
                                                //if (!fs.existsSync(metaTransDir)) {
                                                // If it doesn't exist, create it
                                                //    fs.mkdirSync(metaTransDir);
                                                //}
                                                if (targetLanguage.includes("en")) {
                                                    fs.writeFile(metaTransDir + "/" + appVersion.toString() + ".txt", notes, 'utf8', function () {
                                                        console.log("WROTE FILE: " + appVersion.toString() + ".txt FOR " + targetLanguage + ".");
                                                        fileIndex++;
                                                        setTimeout(function () {
                                                            createNotesFile(fileIndex, transString, transFiles);
                                                        }, 100);
                                                    });
                                                } else if (isCreate === "false") {
                                                    console.log("READING FILE: " + metaTransDir + "/" + newestEnLog);
                                                    fs.readFile(metaTransDir + "/" + newestEnLog, function (err, oldTransNotes) {
                                                        console.log("oldTransNotes = " + oldTransNotes);
                                                        if (oldTransNotes) {
                                                            fs.writeFile(metaTransDir + "/" + appVersion.toString() + ".txt", oldTransNotes, 'utf8', function () {
                                                                console.log("WROTE FILE: " + appVersion.toString() + ".txt FOR " + targetLanguage + ".");
                                                                fileIndex++;
                                                                setTimeout(function () {
                                                                    createNotesFile(fileIndex, transString, transFiles);
                                                                }, 100);
                                                            });
                                                        }else{
                                                            fileIndex++;
                                                            setTimeout(function () {
                                                                createNotesFile(fileIndex, transString, transFiles);
                                                            }, 100);
                                                        }
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
                                                            var langDir = currentDirectory + "/android/fastlane/metadata/android/" + targetLanguage;
                                                            if (!fs.existsSync(langDir)) {
                                                                fs.mkdirSync(langDir);
                                                            }
                                                            if (!fs.existsSync(langDir + "/changelogs")) {
                                                                fs.mkdirSync(langDir + "/changelogs");
                                                            }
                                                            fs.writeFile(currentDirectory + "/android/fastlane/metadata/android/" + targetLanguage + "/changelogs/" + appVersion + ".txt", translatedNotes, 'utf8', function () {
                                                                console.log("WROTE FILE: " + appVersion + ".txt FOR " + targetLanguage + ".");
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
                                    });
                                }
                            });
                        }
                    });
                }
            });
        }
    });
}