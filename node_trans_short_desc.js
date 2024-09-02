var fs = require('fs');
var fsExtra = require('fs-extra');
//var https = require('https');
var request = require('request');
//var args = process.argv.slice(2);
const currentDirectory = process.cwd();
var googleAPIKey = "";//SET WHEN GOING TO USE!!!
var cwdSplit = currentDirectory.split("\\");
console.log("currentDirectory = " + currentDirectory);
var lastDirSplit = cwdSplit.slice(0, -1);
var lastDir = lastDirSplit.join("\\");
console.log("lastDir = " + lastDir);
fs.readFile(lastDirSplit.join("/") + "/google_api_key.txt", function (err, apiKey) {
    if (err) {
        console.log("ERROR GETTING GOOGLE API KEY: " + JSON.stringify(err));
    } else {
        googleAPIKey = apiKey;
        fs.readFile(currentDirectory + "/android/fastlane/metadata/android/en-US/short_description.txt", function (err, short_description) {
            if (err) {
                console.log("READ FILE TITLE ERROR: " + JSON.stringify(err));
            } else {
                console.log("READ FILE: short_description = " + short_description);
                var lgPath = currentDirectory + "/android/fastlane/metadata/android";
                fs.readdir(lgPath, (err, files) => {
                    var transFile = "af", transFiles = [], fileSplit = [];
                    transFiles = files.filter(function (file) {
                        return fs.statSync(lgPath + '/' + file.split("/")[0]).isDirectory();
                    });

                    //EMPTY NON-ENGLISH DIRECTORIES:
                    //for (var i = 0; i < transFiles.length; i++) {
                    //    if (transFiles[i] !== "en-US") {
                    //        fsExtra.emptyDirSync(lgPath + '/' + transFiles[i]);
                    //    }
                    //}

                    var createTransFiles = function (fileIndex, short_description, transFiles) {
                        if (fileIndex < transFiles.length) {
                            var targetLanguage = transFiles[fileIndex];
                            //console.log("TRANS FILE JSON # KEYS BEFORE = " + Object.keys(transObj).length);

                            //if (transObj[transKey]) {
                            //ALREADY EXISTS, DO NEXT(CONTINUE)!
                            //    fileIndex++;
                            //    createJsonFile(fileIndex, transKey, transString, transFiles);
                            //} else if (targetLanguage.includes("en")) {
                            if (targetLanguage.includes("en")) {
                                fileIndex++;
                                setTimeout(function () {
                                    createTransFiles(fileIndex, short_description, transFiles);
                                }, 100);
                            } else {
                                var url = 'https://translation.googleapis.com/language/translate/v2?key=' + googleAPIKey;
                                url += '&q=' + encodeURI(short_description);
                                url += `&source=en`;
                                url += `&target=` + targetLanguage;
                                url += `&format=text`;
                                request(url, function (error, response, body) {
                                    if (!error && response.statusCode == 200) {
                                        var parsedBody = JSON.parse(body);
                                        var translatedText = parsedBody.data.translations[0].translatedText;
                                        console.log("translatedText = " + translatedText);
                                        var metaTransDir = currentDirectory + "/android/fastlane/metadata/android/" + targetLanguage;
                                        if (!fs.existsSync(metaTransDir)) {
                                            // If it doesn't exist, create it
                                            fs.mkdirSync(metaTransDir);
                                        }
                                        if (translatedText.length > 80) {
                                            console.log("translatedText length> 80 = " + translatedText.length + ", SHORTENING...");
                                            translatedText = translatedText.substring(0, 76) + "...";
                                            console.log("translatedText shortened = " + translatedText);
                                        }
                                        fs.writeFile(metaTransDir + "/short_description.txt", translatedText, 'utf8', function () {
                                            console.log("WROTE FILE: short_description.txt FOR " + targetLanguage + ".");
                                            fileIndex++;
                                            setTimeout(function () {
                                                createTransFiles(fileIndex, short_description, transFiles);
                                            }, 100);
                                        });
                                    } else {
                                        console.log("google cloud translate ERROR: " + JSON.stringify(error) + ", RESPONSE = " + JSON.stringify(response) + ", BODY = " + JSON.stringify(body));
                                    }
                                });
                            }
                        } else {
                            console.log("TRANSLATED ALL FILES!");
                        }
                    }
                    createTransFiles(0, short_description, transFiles);
                });
            }
        });
    }
});